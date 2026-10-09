#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# loop-journal.sh — structured per-loop event journal (issue #244).
#
# Records error/lifecycle events emitted while a discovery or delivery loop
# runs, as newline-delimited JSON (JSONL). The loop-error-reviewer agent reads
# this journal at the end of a loop and turns actionable errors into canonical
# issues, in the global opencode tracker or in the target project tracker.
#
# Storage:
#   Default file = <PROJECT_ISSUES_DIR>/loop-journal/loop-<loop>-<id>.jsonl
#   Override the base directory with OCF_LOOP_JOURNAL_DIR.
#   Override the file entirely with --journal.
#
# Usage:
#   loop-journal.sh path   [--loop <name>] [--id <n>] [--journal <file>]
#   loop-journal.sh append --message <m> [--severity <s>] [--phase <p>]
#                          [--scope global|project] [--location <l>]
#                          [--command <c>] [--exit-code <n>]
#                          [--loop <name>] [--id <n>] [--journal <file>]
#   loop-journal.sh list   [--journal <file>] [--format jsonl|md]
#   loop-journal.sh clear  [--journal <file>]
#
# Event fields: ts (UTC ISO-8601), loop, id, phase, severity
# (low|medium|high|critical), scope (global|project|""), location, command,
# exit_code, message.
#
# Exit codes: 0 ok, 3 usage error.

JOURNAL=""
LOOP="loop"
ID="batch"
FORMAT="jsonl"

CMD="${1:-}"
if [ -n "$CMD" ]; then shift; fi

MESSAGE=""; SEVERITY="medium"; PHASE="-"; SCOPE=""
LOCATION="-"; COMMAND="-"; EXIT_CODE="-"

while [ $# -gt 0 ]; do
  case "$1" in
    --journal)   JOURNAL="$2"; shift 2 ;;
    --loop)      LOOP="$2"; shift 2 ;;
    --id)        ID="$2"; shift 2 ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --message)   MESSAGE="$2"; shift 2 ;;
    --severity)  SEVERITY="$2"; shift 2 ;;
    --phase)     PHASE="$2"; shift 2 ;;
    --scope)     SCOPE="$2"; shift 2 ;;
    --location)  LOCATION="$2"; shift 2 ;;
    --command)   COMMAND="$2"; shift 2 ;;
    --exit-code) EXIT_CODE="$2"; shift 2 ;;
    *) echo "loop-journal: unknown flag '$1'" >&2; exit 3 ;;
  esac
done

sanitize() { printf '%s' "${1:-}" | LC_ALL=C tr -c 'A-Za-z0-9._-' '-' | sed 's/^-\{1,\}//;s/-\{1,\}$//'; }

resolve_journal() {
  if [ -n "$JOURNAL" ]; then printf '%s' "$JOURNAL"; return; fi
  local base="${OCF_LOOP_JOURNAL_DIR:-$(pwd -P)/.opencode/loop-journal}"
  printf '%s/loop-%s-%s.jsonl' "$base" "$(sanitize "$LOOP")" "$(sanitize "$ID")"
}

# json_escape — escape a value for a double-quoted JSON string.
json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# jget — awk helper (single-quoted JSON object line): read a top-level string value.
# Backslash escapes are preserved verbatim (we only need scope/severity/location/
# command/message round-tripping, not full JSON unescaping).
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

case "$CMD" in
  path)
    J="$(resolve_journal)"
    mkdir -p "$(dirname "$J")"
    printf '%s\n' "$J"
    ;;
  append)
    if [ -z "$MESSAGE" ]; then echo "loop-journal: --message required for append" >&2; exit 3; fi
    case "$SEVERITY" in low|medium|high|critical) ;; *) echo "loop-journal: invalid --severity '$SEVERITY'" >&2; exit 3 ;; esac
    case "$SCOPE" in ""|global|project) ;; *) echo "loop-journal: invalid --scope '$SCOPE'" >&2; exit 3 ;; esac
    J="$(resolve_journal)"
    mkdir -p "$(dirname "$J")"
    TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    {
      printf '{"ts":"%s","loop":"%s","id":"%s","phase":"%s","severity":"%s","scope":"%s","location":"%s","command":"%s","exit_code":"%s","message":"%s"}\n' \
        "$(json_escape "$TS")" "$(json_escape "$LOOP")" "$(json_escape "$ID")" \
        "$(json_escape "$PHASE")" "$(json_escape "$SEVERITY")" "$(json_escape "$SCOPE")" \
        "$(json_escape "$LOCATION")" "$(json_escape "$COMMAND")" "$(json_escape "$EXIT_CODE")" \
        "$(json_escape "$MESSAGE")"
    } >> "$J"
    printf '[loop-journal] appended to %s\n' "$J"
    ;;
  list)
    J="$(resolve_journal)"
    if [ ! -f "$J" ]; then exit 0; fi
    if [ "$FORMAT" = "jsonl" ]; then
      cat "$J"
    elif [ "$FORMAT" = "md" ]; then
      awk "$AWK_JGET"'
        /^\{/ {
          printf "%s  %-8s  %-7s  %s#%s  %s  %s  %s\n",
            jget($0,"ts"), jget($0,"severity"), jget($0,"scope"),
            jget($0,"loop"), jget($0,"id"), jget($0,"phase"),
            jget($0,"location"), jget($0,"message")
        }
      ' "$J"
    else
      echo "loop-journal: invalid --format '$FORMAT'" >&2; exit 3
    fi
    ;;
  clear)
    J="$(resolve_journal)"
    mkdir -p "$(dirname "$J")"
    : > "$J"
    printf '[loop-journal] cleared %s\n' "$J"
    ;;
  ""|help|-h|--help)
    sed -n '6,30p' "$0"
    exit 0
    ;;
  *)
    echo "loop-journal: unknown command '$CMD'" >&2; exit 3
    ;;
esac
