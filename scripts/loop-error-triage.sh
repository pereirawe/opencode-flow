#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# loop-error-triage.sh — classify loop-journal errors and route them to the
# right tracker (issue #244).
#
# Reads newline-delimited JSON event journals produced by `loop-journal.sh`,
# keeps actionable errors (>= --min-severity), deduplicates them, and
# classifies each as `global` (opencode config/tooling: scripts/, agents/,
# commands/, skills/, standards/, workflow.md, AGENTS.md, opencode.json,
# Makefile) or `project` (the workspace where the loop ran). Global issues are
# written to `~/.config/opencode/known_issues.md`; project issues to
# `<workspace>/.opencode/known_issues.md` (fallback `<workspace>/known_issues.md`).
#
# Default mode is --plan (read-only): it writes a human digest + a machine TSV
# of proposals under `.opencode/preflight/`. --apply files the proposals as
# canonical `bug` entries (Status backlog) via `scripts/append-issue.sh`.
#
# Usage:
#   loop-error-triage.sh [--journal <file>]... [--loop <name>] [--id <n>] [--label <l>]
#                        [--min-severity low|medium|high|critical]
#                        [--max <n>] [--plan|--apply] [--from <proposals.tsv>]
#                        [--global-tracker <file>] [--project-tracker <file>]
#
# Exit codes: 0 ok, 3 usage error.

MIN_SEV="medium"; MAX=20; MODE="plan"; FROM=""; LABEL="batch"; LOOP_ID=""
GLOBAL_OVERRIDE=""; PROJECT_OVERRIDE=""
declare -a JOURNALS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --journal|--loop|--id|--label|--min-severity|--max|--from|--global-tracker|--project-tracker)
      [ $# -ge 2 ] || { echo "loop-error-triage: missing value for '$1'" >&2; exit 3; } ;;
  esac
  case "$1" in
    --journal)          JOURNALS+=("$2"); shift 2 ;;
    --loop)             LABEL="$2"; shift 2 ;;
    --id)               LOOP_ID="$2"; shift 2 ;;
    --label)            LABEL="$2"; shift 2 ;;
    --min-severity)     MIN_SEV="$2"; shift 2 ;;
    --max)              MAX="$2"; shift 2 ;;
    --plan)             MODE="plan"; shift ;;
    --apply)            MODE="apply"; shift ;;
    --from)             FROM="$2"; shift 2 ;;
    --global-tracker)   GLOBAL_OVERRIDE="$2"; shift 2 ;;
    --project-tracker)  PROJECT_OVERRIDE="$2"; shift 2 ;;
    *) echo "loop-error-triage: unknown flag '$1'" >&2; exit 3 ;;
  esac
done

sev_num() { case "$1" in low) echo 1 ;; medium) echo 2 ;; high) echo 3 ;; critical) echo 4 ;; *) echo 2 ;; esac; }
MIN_NUM="$(sev_num "$MIN_SEV")"

GLOBAL_FILE="${GLOBAL_OVERRIDE:-$ISSUES_FILE}"
PROJECT_FILE="${PROJECT_OVERRIDE:-}"
if [ -z "$PROJECT_FILE" ]; then
  if [ -f "$(pwd -P)/.opencode/known_issues.md" ]; then
    PROJECT_FILE="$(pwd -P)/.opencode/known_issues.md"
  elif [ -f "$(pwd -P)/known_issues.md" ]; then
    PROJECT_FILE="$(pwd -P)/known_issues.md"
  else
    PROJECT_FILE="$(pwd -P)/.opencode/known_issues.md"
  fi
fi

if [ "${#JOURNALS[@]}" -eq 0 ]; then
  BASE="${OCF_LOOP_JOURNAL_DIR:-$(pwd -P)/.opencode/loop-journal}"
  if [ -d "$BASE" ]; then
    # Isolate a single loop when a label/id is given; otherwise scan all journals.
    PAT="*.jsonl"
    if [ -n "$LOOP_ID" ]; then
      PAT="loop-${LABEL}-${LOOP_ID}.jsonl"
    elif [ "$LABEL" != "batch" ]; then
      PAT="loop-${LABEL}-*.jsonl"
    fi
    while IFS= read -r f; do JOURNALS+=("$f"); done < <(ls -1 "$BASE"/$PAT 2>/dev/null || true)
  fi
fi

if [ "${#JOURNALS[@]}" -eq 0 ] && [ -z "$FROM" ]; then
  echo "[loop-error-triage] no journal files found (label=$LABEL)"
  exit 0
fi

AWK_JGET='
function jget(s, key,   pat, i, start, out, c, esc) {
  pat = "\"" key "\":\""
  i = index(s, pat)
  if (i == 0) return ""
  start = i + length(pat)
  out = ""; esc = 0
  for (i = start; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (esc) { out = out c; esc = 0; continue }
    if (c == "\\") { out = out c; esc = 1; continue }
    if (c == "\"") break
    out = out c
  }
  return out
}
'

# entries — emit TSV: severity, scope, location, command, exit_code, loop, id, phase, message
entries() {
  local f
  for f in "${JOURNALS[@]}"; do
    [ -f "$f" ] || continue
    awk "$AWK_JGET"'
      function e(x) { return (x == "" ? "__EMPTY__" : x) }
      /^\{/ {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
          e(jget($0,"severity")), e(jget($0,"scope")), e(jget($0,"location")),
          e(jget($0,"command")), e(jget($0,"exit_code")), e(jget($0,"loop")),
          e(jget($0,"id")), e(jget($0,"phase")), e(jget($0,"message"))
      }
    ' "$f"
  done
}

classify_scope() { # <location> <command> <message>
  local loc="${1:-}" cmd="${2:-}" msg="${3:-}" hay cwd
  hay="$loc $cmd $msg"
  cwd="$(pwd -P)"
  # Absolute path under the opencode config tree => always global.
  case "$hay" in
    *"$CONFIG_DIR/"*) echo global; return ;;
    "$CONFIG_DIR") echo global; return ;;
  esac
  # Bare config-relative paths are global only while running inside the config
  # repo itself; in a target project, `scripts/...` is project code.
  if [ "$cwd" = "$CONFIG_DIR" ]; then
    case "$hay" in
      *"scripts/"*|*"agents/"*|*"commands/"*|*"skills/"*|*"standards/"*) echo global; return ;;
      *"workflow.md"*|*"AGENTS.md"*|*"opencode.json"*|*"Makefile"*) echo global; return ;;
    esac
  fi
  echo project
}

# next_id — first free id across the tracker AND its resolved archive, so the
# router never recreates an id already archived (known issue #29).
next_id() { # <tracker-file>
  local f="$1" r n1 n2
  r="$(dirname "$f")/resolved_issues.md"
  n1="$(awk '/^### [0-9]+\./ {n=$2} END {print n+1}' "$f" 2>/dev/null || true)"
  n2=""
  [ -f "$r" ] && n2="$(awk '/^### [0-9]+\./ {n=$2} END {print n+1}' "$r" 2>/dev/null || true)"
  [ -z "$n1" ] && n1=1
  [ -z "$n2" ] && n2=1
  if [ "$n1" -ge "$n2" ]; then echo "$n1"; else echo "$n2"; fi
}

short() { printf '%s' "${1:-}" | tr '\t\n' '  ' | cut -c1-160; }

# de — decode the "__EMPTY__" sentinel emitted by entries() back to an empty
# string. `read` with IFS=$'\t' collapses truly-empty fields (tab is IFS
# whitespace), which shifted every column when a journal event had an empty
# scope/message; the sentinel keeps the field count intact.
de() { if [ "$1" = "__EMPTY__" ]; then printf ''; else printf '%s' "$1"; fi; }

mkdir -p "$PROJECT_ISSUES_DIR/preflight"
DIGEST="$PROJECT_ISSUES_DIR/preflight/loop-errors-$LABEL.md"
PROPOSALS="$PROJECT_ISSUES_DIR/preflight/loop-errors-$LABEL.proposals.tsv"

declare -A SEEN
declare -a P_SCOPE P_SEV P_LOC P_CMD P_EC P_LOOP P_ID P_PHASE P_MSG P_TARGET P_DUP
NPROP=0

# already_filed — block-scoped cross-run dedup: an entry already exists in the
# target tracker with the same `- Location:` line AND the same command (BR6).
already_filed() { # <tracker> <location> <command>
  local f="$1" loc="$2" cmd="$3"
  [ -f "$f" ] || return 1
  [ -n "$loc" ] && [ "$loc" != "-" ] || return 1
  awk -v loc="- Location: $loc" -v cmd="$cmd" '
    function flush() { if (seen && (cmd == "" || cmdseen)) found = 1 }
    /^### [0-9]+\./ { flush(); seen = 0; cmdseen = 0; next }
    { if ($0 == loc) seen = 1; if (cmd != "" && index($0, cmd) > 0) cmdseen = 1 }
    END { flush(); exit (found ? 0 : 1) }
  ' "$f"
}

add_proposal() {
  local sev="$1" scope="$2" loc="$3" cmd="$4" ec="$5" loop="$6" id="$7" phase="$8" msg="$9"
  local override="${10:-}"
  if [ -z "$scope" ]; then scope="$(classify_scope "$loc" "$cmd" "$msg")"; fi
  local key="$scope|$loc|$cmd"
  [ -n "${SEEN[$key]:-}" ] && return
  SEEN[$key]=1
  local target
  if [ -n "$override" ]; then target="$override"
  elif [ "$scope" = "global" ]; then target="$GLOBAL_FILE"; else target="$PROJECT_FILE"; fi
  local dup="no"
  if already_filed "$target" "$loc" "$cmd"; then
    dup="yes"
  fi
  P_SCOPE+=("$scope"); P_SEV+=("$sev"); P_LOC+=("$loc"); P_CMD+=("$cmd")
  P_EC+=("$ec"); P_LOOP+=("$loop"); P_ID+=("$id"); P_PHASE+=("$phase")
  P_MSG+=("$msg"); P_TARGET+=("$target"); P_DUP+=("$dup")
  NPROP=$((NPROP+1))
}

if [ -n "$FROM" ]; then
  if [ ! -f "$FROM" ]; then echo "loop-error-triage: --from file not found: $FROM" >&2; exit 3; fi
  while IFS=$'\t' read -r c_scope c_sev c_target c_loc c_cmd c_ec c_loop c_id c_phase c_msg; do
    [ -n "${c_scope:-}" ] || continue
    case "$c_scope" in \#*) continue ;; esac
    add_proposal "$c_sev" "$c_scope" "$c_loc" "$c_cmd" "$c_ec" "$c_loop" "$c_id" "$c_phase" "$c_msg" "$c_target"
  done < "$FROM"
else
  while IFS=$'\t' read -r sev scope loc cmd ec loop id phase msg; do
    [ -n "${sev:-}" ] || continue
    sev="$(de "$sev")"; scope="$(de "$scope")"; loc="$(de "$loc")"
    cmd="$(de "$cmd")"; ec="$(de "$ec")"; loop="$(de "$loop")"
    id="$(de "$id")"; phase="$(de "$phase")"; msg="$(de "$msg")"
    [ "$(sev_num "$sev")" -ge "$MIN_NUM" ] || continue
    add_proposal "$sev" "$scope" "$loc" "$cmd" "$ec" "$loop" "$id" "$phase" "$msg"
  done < <(entries)
fi

# --- write proposals TSV (scope, severity, target, location, command, exit_code, loop, id, phase, message) ---
{
  printf '#scope\tseverity\ttarget\tlocation\tcommand\texit_code\tloop\tid\tphase\tmessage\n'
  i=0
  while [ "$i" -lt "$NPROP" ]; do
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "${P_SCOPE[$i]}" "${P_SEV[$i]}" "${P_TARGET[$i]}" "${P_LOC[$i]}" \
      "${P_CMD[$i]}" "${P_EC[$i]}" "${P_LOOP[$i]}" "${P_ID[$i]}" "${P_PHASE[$i]}" "${P_MSG[$i]}"
    i=$((i+1))
  done
} > "$PROPOSALS"

# --- write digest ---
{
  echo "# Loop error triage — $LABEL"
  echo ""
  echo "Journals: ${JOURNALS[*]}"
  echo "Min severity: $MIN_SEV | Proposals: $NPROP | Mode: $MODE"
  echo ""
  if [ "$NPROP" -eq 0 ]; then
    echo "_No actionable errors._"
  else
    echo "| # | scope | severity | already filed | target | location | command | message |"
    echo "|---|-------|----------|---------------|--------|----------|---------|---------|"
    i=0
    while [ "$i" -lt "$NPROP" ]; do
      printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
        "$((i+1))" "${P_SCOPE[$i]}" "${P_SEV[$i]}" "${P_DUP[$i]}" \
        "$(short "${P_TARGET[$i]}")" "$(short "${P_LOC[$i]}")" \
        "$(short "${P_CMD[$i]}")" "$(short "${P_MSG[$i]}")"
      i=$((i+1))
    done
  fi
} > "$DIGEST"

echo "[loop-error-triage] digests: $DIGEST"
echo "[loop-error-triage] proposals: $PROPOSALS ($NPROP)"

if [ "$MODE" != "apply" ]; then
  exit 0
fi

# --- apply ---
FILED=0; SKIPPED=0; COUNT=0
i=0
while [ "$i" -lt "$NPROP" ]; do
  scope="${P_SCOPE[$i]}"; sev="${P_SEV[$i]}"; loc="${P_LOC[$i]}"
  cmd="${P_CMD[$i]}"; ec="${P_EC[$i]}"; loop="${P_LOOP[$i]}"; id="${P_ID[$i]}"
  phase="${P_PHASE[$i]}"; msg="${P_MSG[$i]}"; target="${P_TARGET[$i]}"

  if [ "${P_DUP[$i]}" = "yes" ]; then
    echo "[loop-error-triage] skip (already filed): $loc"
    SKIPPED=$((SKIPPED+1)); i=$((i+1)); continue
  fi
  if [ "$COUNT" -ge "$MAX" ]; then
    echo "[loop-error-triage] --max $MAX reached; remaining proposals left unfiled"
    break
  fi
  COUNT=$((COUNT+1))

  # Ensure the target tracker exists before append-issue.sh validates it, and
  # route the write to exactly that target (global OR project) via the override,
  # so `--project-tracker` and the `<workspace>/known_issues.md` fallback are
  # honored (not silently re-resolved from cwd).
  if [ ! -f "$target" ]; then
    mkdir -p "$(dirname "$target")"
    printf '# Known issues\n' > "$target"
  fi

  title="Loop error: $(short "$msg")"
  desc="Erro capturado no loop ${loop}#${id} (phase ${phase}). Comando: ${cmd}. Exit code: ${ec}. Local: ${loc}. Mensagem: ${msg}."
  impact="Erros de loop nao rastreados geram correcao ad-hoc e reincidencia; este registro transforma a falha em trabalho rastreavel no tracker ${scope}."
  tests="1. Reproduzir o erro registrado no journal (${loop}#${id}, phase ${phase}): ${cmd} -> ${msg}\n2. Corrigir em ${loc} e reexecutar o loop -> nenhum novo evento com a mesma location+command e registrado.\n3. Confirmar que a issue criada some do proximo --plan (dedup por Location)."
  prio="$sev"
  if [ -z "$msg" ]; then title="Loop error: ${loc} (${loop}#${id})"; fi

  if OCF_ISSUES_FILE="$target" "$SCRIPTS_DIR/append-issue.sh" \
      --id "$(next_id "$target")" \
      --title "$title" --type bug --severity "$sev" --priority "$prio" \
      --location "$loc" --description "$desc" --impact "$impact" \
      --tests "$tests" --status backlog --reviewers "1 (backend)" \
      --report "loop-error-reviewer" >/dev/null; then
    echo "[loop-error-triage] filed ${scope}: $title"
    FILED=$((FILED+1))
  fi
  i=$((i+1))
done

echo "[loop-error-triage] applied: filed=$FILED skipped=$SKIPPED"
