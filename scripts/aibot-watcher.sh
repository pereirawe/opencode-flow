#!/usr/bin/env bash
set -euo pipefail

# aibot-watcher.sh — Poll remote issue comments for `@aibot:develop` triggers.
#
# For each allowlisted repo in ~/.config/opencode/aibot-repos.json:
#   - fetch NEW issue comments since the per-repo cursor (issue comments only,
#     never PR comments / merge states — BR 14 / BR 18). On FIRST run the
#     cursor is initialized to the newest comment so historical comments
#     (including stale triggers) never fire after install (Security M2).
#   - for each comment containing the standalone token `@aibot:develop`
#     (BR 3, outside fenced code blocks — R-M2), not authored by the aibot
#     itself (BR 17), and on a REAL issue (not a PR — R-M1/S-M1):
#       * find the matching locally-tracked issue (`Remote: #<id>` in the
#         workspace tracker) — BR 4
#       * re-check the issue status inside the per-repo flock — BR 5
#       * trigger `opencode run --attach ... --command "ocf:develop" <id>`
#         (BR 7 — NO `--` separator; see opencode_run) capped per tick
#         (MAX_TRIGGERS_PER_TICK — Security M3)
#       * post the standardized result message via `ocf:aibot-notify` (BR 8-10)
#
# Run via systemd timer (aibot-watcher.timer, OnCalendar=*:0/2) under the
# opencode user — BR 12. The web server health-check happens first and the
# tick exits cleanly when it is down (BR 12 / AC 9).
#
# State (cursor + per-repo lock + develop logs) lives in
# ~/.config/opencode/state/aibot/ (BR 15, mode 0700). The cursor persists
# across restarts so comments are never re-processed (BR 2 / AC 8 / AC 13).
#
# Security boundary (BR 13 / AC 19): allowlist of repos in aibot-repos.json +
# locally-tracked-issue gate + explicit deny rules in opencode.json AND in the
# agent configs (development/developer, devs/*, aibot, develop-router). The
# `--auto` flag only auto-approves permissions that are not explicitly denied.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
# config.sh redefines SCRIPT_DIR from $0 — recompute so remote.sh resolves
# correctly even when this file is sourced (tests) rather than executed.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/remote.sh"

# --- configuration (env-overridable) ---
CONFIG_ROOT="${AIBOT_CONFIG_DIR:-$CONFIG_DIR}"
AIBOT_REPOS_FILE="${AIBOT_REPOS_FILE:-$CONFIG_ROOT/aibot-repos.json}"
AIBOT_STATE_DIR="${AIBOT_STATE_DIR:-$CONFIG_ROOT/state/aibot}"
# 127.0.0.1, not localhost — avoids localhost→::1 resolution mismatch (BR 12)
AIBOT_WEB_URL="${AIBOT_WEB_URL:-http://127.0.0.1:4096}"
# Qualified provider/model id — the server rejects the bare id with
# ProviderModelNotFoundError (R-B2).
AIBOT_MODEL="${AIBOT_MODEL:-opencode-go/deepseek-v4-flash}"
AIBOT_TOKEN="${AIBOT_TOKEN:-@aibot:develop}"
# Comma-separated list of extra authors to exclude (beyond the local identity)
AIBOT_AUTHORS="${AIBOT_AUTHORS:-}"
# Auth is passed to `opencode run` via OPENCODE_SERVER_* env vars, never argv
# (a --password would show up in `ps`) — Security M4.
AIBOT_SERVER_USERNAME="${AIBOT_SERVER_USERNAME:-}"
AIBOT_SERVER_PASSWORD="${AIBOT_SERVER_PASSWORD:-}"
# Cap of actual develop pipeline spawns per repo per tick (Security M3)
MAX_TRIGGERS_PER_TICK="${MAX_TRIGGERS_PER_TICK:-1}"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"

log() { printf '[aibot-watcher] %s %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$*" >&2; }

fail() { log "ERROR: $*"; exit 1; }

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

# web_healthy — 0 when the opencode web server answers on $AIBOT_WEB_URL (BR 12).
# -f: any 4xx/5xx response counts as unhealthy (Runtime m1).
web_healthy() {
  if ! command -v curl >/dev/null 2>&1; then
    log "curl not available — assuming web server is down"
    return 1
  fi
  curl -fsS -o /dev/null --max-time 5 "$AIBOT_WEB_URL" 2>/dev/null
}

# list_repos — print "key<TAB>workspace" for every allowlisted repo entry.
# Top-level keys starting with "_" are treated as documentation and skipped.
list_repos() {
  if [[ ! -f "$AIBOT_REPOS_FILE" ]]; then
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    fail "jq is required to parse $AIBOT_REPOS_FILE"
  fi
  local out="" err
  err="$(mktemp)"
  out="$(jq -r 'to_entries[] | select(.key | startswith("_") | not) |
         [.key, (.value.workspace // "")] | @tsv' "$AIBOT_REPOS_FILE" 2>"$err")" \
    || { log "AVISO: falha ao parsear $AIBOT_REPOS_FILE (JSON malformado?): $(head -c 200 "$err" 2>/dev/null)"; rm -f "$err"; return 0; }
  rm -f "$err"
  printf '%s\n' "$out"
}

# expand_path — expand ~ and $HOME prefixes (no command substitution is safe)
expand_path() {
  local p="$1"
  if [[ "$p" == "~"* ]]; then
    p="$HOME${p:1}"
  elif [[ "$p" == '$HOME'* ]]; then
    p="$HOME${p:5}"
  fi
  printf '%s' "$p"
}

# --- state files (BR 15) ---
slug() { printf '%s' "$1" | tr '/:' '__'; }
cursor_file() { printf '%s/%s.cursor\n' "$AIBOT_STATE_DIR" "$(slug "$1")"; }
lock_file()  { printf '%s/%s.lock\n'  "$AIBOT_STATE_DIR" "$(slug "$1")"; }

read_cursor() {
  local f
  f="$(cursor_file "$1")"
  if [[ -f "$f" ]]; then
    cat "$f"
  fi
  return 0
}

write_cursor() {
  local f
  f="$(cursor_file "$1")"
  printf '%s\n' "$2" > "$f"
}

# resolve_tracker <workspace> — BR 4: prefer the workspace .opencode tracker,
# falling back to the workspace root tracker when the .opencode one has no
# real entries (e.g. the opencode config repo ships an empty template).
has_entries() { grep -qE '^### [0-9]+\.' "$1" 2>/dev/null; }

resolve_tracker() {
  local workspace="$1"
  local local_tracker="$workspace/.opencode/known_issues.md"
  local root_tracker="$workspace/known_issues.md"
  if [[ -f "$local_tracker" ]] && has_entries "$local_tracker"; then
    printf '%s\n' "$local_tracker"; return 0
  fi
  if [[ -f "$root_tracker" ]] && has_entries "$root_tracker"; then
    printf '%s\n' "$root_tracker"; return 0
  fi
  if [[ -f "$local_tracker" ]]; then printf '%s\n' "$local_tracker"; return 0; fi
  if [[ -f "$root_tracker" ]]; then printf '%s\n' "$root_tracker"; return 0; fi
  printf '%s\n' ""
}

# find_tracked_issue <tracker> <remote_id> — echo the local id of the entry
# whose `Remote:` equals `#<remote_id>`, or empty when not tracked (BR 4).
# Note: `exit` inside awk still runs the END rule, so the match is guarded by
# a `found` flag to avoid double printing.
find_tracked_issue() {
  local tracker="$1"
  local rid="#$2"
  [[ -f "$tracker" ]] || { printf '%s\n' ""; return 0; }
  awk -v rid="$rid" '
    /^### [0-9]+\./ {
      if (in_section && remote == rid) { found = 1; print current_id; exit }
      current_id = $2; sub(/\.$/, "", current_id)
      remote = ""; in_section = 1
      next
    }
    in_section && /^- Remote:/ {
      remote = substr($0, index($0, ":")+2)
      sub(/[[:space:]]+$/, "", remote)
    }
    END { if (found != 1 && in_section && remote == rid) print current_id }
  ' "$tracker"
}

# get_field <tracker> <local_id> <Field> — echo the field value (Status/PR/...)
get_field() {
  local tracker="$1" id="$2" field="$3"
  awk -v id="$id" -v f="^- $field:" '
    $0 ~ "^### " id "\\." { found=1; next }
    found && $0 ~ /^### [0-9]+\./ { exit }
    found && $0 ~ f { sub(/^[^:]*: /, ""); print; exit }
  ' "$tracker"
}

# has_token <body> — 0 when the standalone token appears as a whole line
# (trimmed) OUTSIDE fenced code blocks. Token inside code fences (``` or ~~~),
# quoted replies, inline code or linked text does not match (R-M2 / AC 15).
has_token() {
  local body="$1"
  printf '%s\n' "$body" | awk -v tok="$AIBOT_TOKEN" '
    /^[[:space:]]*(```|~~~)/ { in_fence = !in_fence; next }
    !in_fence {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if ($0 == tok) { found = 1 }
    }
    END { exit (found == 1) ? 0 : 1 }
  '
}

# get_local_identity <provider> <workspace> — the local user the aibot posts
# as (used for self-trigger prevention, BR 17).
get_local_identity() {
  local provider="$1"
  case "$provider" in
    github) gh api user --jq '.login' 2>/dev/null || echo "" ;;
    gitlab) glab api user --jq '.username' 2>/dev/null || echo "" ;;
    *) echo "" ;;
  esac
}

# is_aibot_author <author> [identity] — 0 when the comment author is the aibot
# itself (local identity, explicit AIBOT_AUTHORS list, or a GitHub *[bot]
# account). The local identity comes from get_local_identity (the account the
# aibot posts as) — BR 17 self-trigger prevention.
is_aibot_author() {
  local author="$1"
  local identity="${2:-}"
  [[ -z "$author" ]] && return 1
  [[ "$author" == *"[bot]" ]] && return 0
  if [[ -n "$AIBOT_AUTHORS" ]] \
    && printf '%s\n' "$AIBOT_AUTHORS" | tr ',' '\n' | grep -qxF "$author"; then
    return 0
  fi
  if [[ -n "$identity" ]] && [[ "$author" == "$identity" ]]; then
    return 0
  fi
  return 1
}

# fetch_issue_numbers <provider> <owner/repo> — real issue numbers only.
# GitHub's /issues endpoint also returns pull requests (they carry a
# `pull_request` key) — they are excluded here so PR conversation comments can
# be filtered out of the comment stream (R-M1/S-M1, BR 18 / AC 16).
fetch_issue_numbers() {
  local provider="$1" path="$2" enc out err rc=0
  case "$provider" in
    github)
      err="$(mktemp)"
      # state=all: closed issues are still real issues (BR 18 / BR 5 —
      # "already-resolved" path). PRs are excluded via .pull_request == null.
      out="$(gh api "repos/$path/issues?state=all" --paginate \
        --jq '.[] | select(.pull_request == null) | .number' \
        < /dev/null 2>"$err")" || rc=$?
      if [[ "$rc" -ne 0 ]]; then
        log "aviso: gh fetch de issues falhou para $path: $(head -c 200 "$err" 2>/dev/null)"
      fi
      rm -f "$err"
      printf '%s\n' "$out"
      return "$rc"
      ;;
    gitlab)
      enc="$(printf '%s' "$path" | sed 's#/#%2F#g')"
      err="$(mktemp)"
      out="$(glab api "projects/$enc/issues?state=all&per_page=100" --paginate \
        --jq '.[].iid' < /dev/null 2>"$err")" || rc=$?
      if [[ "$rc" -ne 0 ]]; then
        log "aviso: glab fetch de issues falhou para $path: $(head -c 200 "$err" 2>/dev/null)"
      fi
      rm -f "$err"
      printf '%s\n' "$out"
      return "$rc"
      ;;
    *) return 0 ;;
  esac
}

# fetch_comments <provider> <owner/repo> — print one JSON object per issue
# comment, shape: {id, author, issue, body}. GitLab filters noteable_type ==
# "Issue" (PR/review comments never come through); GitHub PR-comment filtering
# is done by the caller against fetch_issue_numbers (BR 18).
fetch_comments() {
  local provider="$1" path="$2" enc out notes err rc=0
  case "$provider" in
    github)
      err="$(mktemp)"
      out="$(gh api "repos/$path/issues/comments" --paginate \
        --jq '.[] | {id: .id, author: .user.login, issue: (.issue_url | capture("issues/(?<n>[0-9]+)$") | .n), body: .body}' \
        < /dev/null 2>"$err")" || rc=$?
      if [[ "$rc" -ne 0 ]]; then
        log "aviso: gh fetch de comentários falhou para $path: $(head -c 200 "$err" 2>/dev/null)"
      fi
      rm -f "$err"
      printf '%s\n' "$out"
      ;;
    gitlab)
      enc="$(printf '%s' "$path" | sed 's#/#%2F#g')"
      # Aggregate project notes endpoint; falls back to per-issue polling when
      # the host restricts it (some GitLab instances 403/404 the aggregate).
      err="$(mktemp)"
      notes="$(glab api "projects/$enc/notes?sort=asc&per_page=100" --paginate \
        --jq '.[] | select(.noteable_type == "Issue") | {id: .id, author: .author.username, issue: .noteable_iid, body: .body}' \
        < /dev/null 2>"$err")" || rc=$?
      if [[ "$rc" -ne 0 ]]; then
        log "aviso: glab fetch de notas falhou para $path (agregado): $(head -c 200 "$err" 2>/dev/null) — tentando por issue"
      fi
      rm -f "$err"
      if [[ -z "$notes" ]]; then
        local iid
        while IFS= read -r iid; do
          [[ -z "$iid" ]] && continue
          glab api "projects/$enc/issues/$iid/notes?sort=asc&per_page=100" --paginate \
            --jq '.[] | select(.noteable_type == "Issue") | {id: .id, author: .author.username, issue: .noteable_iid, body: .body}' \
            < /dev/null 2>/dev/null || true
        done < <(glab api "projects/$enc/issues?per_page=100" --paginate --jq '.[].iid' < /dev/null 2>/dev/null || true)
      else
        printf '%s\n' "$notes"
      fi
      ;;
    *) return 0 ;;
  esac
}

# opencode_run <workspace> <args...> — invoke `opencode run --attach` against the
# web server. Auth is passed via OPENCODE_SERVER_* env vars (never argv — a
# `--password` would be visible in `ps`, Security M4). NOTE: the BR 7 command
# form has NO `--` separator before the args — on opencode 1.18.7 the
# `--command <cmd> -- <arg>` form crashes with "G.includes is not a function"
# (R-B1); args must follow the --command value directly.
opencode_run() {
  local workspace="$1"
  shift
  local -a run_env=(env)
  if [[ -n "$AIBOT_SERVER_USERNAME" ]]; then
    run_env+=(OPENCODE_SERVER_USERNAME="$AIBOT_SERVER_USERNAME")
  fi
  if [[ -n "$AIBOT_SERVER_PASSWORD" ]]; then
    run_env+=(OPENCODE_SERVER_PASSWORD="$AIBOT_SERVER_PASSWORD")
  fi
  if ! command -v "$OPENCODE_BIN" >/dev/null 2>&1; then
    log "opencode binary '$OPENCODE_BIN' não encontrado (set OPENCODE_BIN)"
    return 127
  fi
  # BR 13: --auto auto-approves everything NOT explicitly denied; the explicit
  # deny rules in opencode.json + agent configs still hold (security review).
  "${run_env[@]}" "$OPENCODE_BIN" run --attach "$AIBOT_WEB_URL" --auto \
    --dir "$workspace" --model "$AIBOT_MODEL" "$@"
}

# run_develop <workspace> <local_id> — run the full continuous pipeline
# (promote → develop → senior review → QA → committer → MR) on the web server.
# Output streams to a per-run log file (never buffered in memory — Runtime m3);
# on failure the tail of the log is emitted to stderr. Returns the opencode
# run exit code (BR 7).
run_develop() {
  local workspace="$1" local_id="$2" rc=0
  local logf logdir
  logdir="$AIBOT_STATE_DIR/logs"
  mkdir -p -m 700 "$logdir" 2>/dev/null || true
  logf="$logdir/develop-$(date +%Y%m%d-%H%M%S)-#$local_id.log"
  log "disparando: opencode run --attach $AIBOT_WEB_URL --auto --dir $workspace --model $AIBOT_MODEL --command ocf:develop $local_id (log: $logf)"
  # < /dev/null: never let the develop run consume the comment stream that the
  # calling while/read loop feeds from (process substitution stdin inheritance).
  opencode_run "$workspace" --command "ocf:develop" "$local_id" \
    < /dev/null >"$logf" 2>&1 || rc=$?
  rc="${rc:-0}"
  log "ocf:develop #$local_id exit=$rc"
  if [[ "$rc" -ne 0 ]]; then
    tail -n 15 "$logf" >&2
  fi
  return "$rc"
}

# notify_issue <workspace> <remote_id> <message_key> [pr_number] — post exactly
# one standardized aibot message to the remote issue via ocf:aibot-notify
# (BR 10). Non-blocking.
notify_issue() {
  local workspace="$1" remote_id="$2" msg_key="$3" pr_number="${4:-}"
  if ! command -v "$OPENCODE_BIN" >/dev/null 2>&1; then
    log "aviso: opencode binary não encontrado — mensagem '$msg_key' para #$remote_id não postada"
    return 0
  fi
  log "notificando: ocf:aibot-notify #$remote_id '$msg_key'${pr_number:+ (PR $pr_number)}"
  local args=(--command "ocf:aibot-notify" "$remote_id" "$msg_key")
  [[ -n "$pr_number" ]] && args+=("$pr_number")
  opencode_run "$workspace" "${args[@]}" < /dev/null >/dev/null 2>&1 \
    || log "aviso: falha ao postar mensagem '$msg_key' para #$remote_id"
}

# ---------------------------------------------------------------------------
# comment handling
# ---------------------------------------------------------------------------

# handle_comment <ctx...> — decide and act on one trigger comment.
# Args: workspace tracker provider path cid cauthor cissue cjson aibot_identity
# Returns: 1 when a develop pipeline was actually spawned (used by the
# MAX_TRIGGERS_PER_TICK cap), 0 otherwise.
handle_comment() {
  local workspace="$1" tracker="$2" provider="$3" path="$4"
  local cid="$5" cauthor="$6" cissue="$7" cjson="$8" identity="$9"

  # BR 17 / AC 14: comments authored by the aibot never trigger
  if is_aibot_author "$cauthor" "$identity"; then
    log "comentário $cid ignorado (autor aibot '$cauthor') — self-trigger prevention"
    return 0
  fi

  local body=""
  body="$(jq -r '.body' <<<"$cjson" 2>/dev/null || echo "")"

  # BR 3 / AC 15: only comments with the standalone token trigger; others are
  # ignored (the cursor still advances in process_repo).
  if ! has_token "$body"; then
    log "comentário $cid sem token standalone '$AIBOT_TOKEN' — ignorado (cursor avança)"
    return 0
  fi

  log "TOKEN detectado: comentário $cid da issue remota #$cissue (autor: $cauthor)"

  # BR 4 / AC 3: the commented issue must be tracked locally with matching Remote:
  local local_id=""
  local_id="$(find_tracked_issue "$tracker" "$cissue")"
  if [[ -z "$local_id" ]]; then
    log "issue remota #$cissue não rastreada localmente — postando mensagem padrão"
    notify_issue "$workspace" "$cissue" "not-tracked" ""
    return 0
  fi
  log "issue remota #$cissue → issue local #$local_id"

  # BR 5 / AC 4 / AC 5: status re-check inside the flock
  local status="" pr=""
  status="$(get_field "$tracker" "$local_id" "Status")"
  pr="$(get_field "$tracker" "$local_id" "PR")"
  case "$status" in
    in-progress|in-review|in-qa|in-publish)
      log "issue #$local_id status '$status' — já em andamento; sem novo develop"
      notify_issue "$workspace" "$cissue" "already-in-progress" ""
      return 0
      ;;
    resolved)
      log "issue #$local_id status 'resolved' — já resolvida"
      notify_issue "$workspace" "$cissue" "already-resolved" ""
      return 0
      ;;
    ""|-)
      log "issue #$local_id sem Status — não dispara"
      return 0
      ;;
  esac

  # BR 7 / AC 2: trigger the full continuous pipeline
  if run_develop "$workspace" "$local_id"; then
    local new_status="" new_pr=""
    new_status="$(get_field "$tracker" "$local_id" "Status")"
    new_pr="$(get_field "$tracker" "$local_id" "PR")"
    if [[ "$new_status" == "in-publish" && -n "$new_pr" && "$new_pr" != "-" ]]; then
      # BR 8 / AC 2 / AC 10: success → standardized message with MR link
      log "develop concluído: issue #$local_id in-publish, PR $new_pr"
      notify_issue "$workspace" "$cissue" "success" "${new_pr#\#}"
    else
      # BR 9 / AC 11: finished but no MR → cannot-develop
      log "develop terminou sem MR (status=$new_status pr=$new_pr) — cannot-develop"
      notify_issue "$workspace" "$cissue" "cannot-develop" ""
    fi
  else
    # BR 9 / AC 11: blocked develop → cannot-develop
    log "develop falhou para issue #$local_id — cannot-develop"
    notify_issue "$workspace" "$cissue" "cannot-develop" ""
  fi
  return 1
}

# process_repo <key> <workspace> — full per-repo pipeline under flock (BR 1, 6).
process_repo() {
  local key="$1" workspace="$2"
  workspace="$(expand_path "$workspace")"
  log "=== repo '$key' workspace '$workspace' ==="

  # AC 17: empty / nonexistent workspace → refuse with standard message, clean exit
  if [[ -z "$workspace" || ! -d "$workspace" ]]; then
    log "recusando: workspace de '$key' vazio ou inexistente ('$workspace') — mensagem padrão"
    return 0
  fi
  if ! git -C "$workspace" rev-parse --git-dir >/dev/null 2>&1; then
    log "recusando: workspace '$workspace' não é um repositório git"
    return 0
  fi

  # BR 1 / AC 18: allowlist gate — provider from remote.origin.url (remote.sh),
  # and the parsed owner/repo must match the allowlisted key.
  local provider="" path="" ai_bot_identity=""
  read -r provider path <<<"$(parse_remote "$workspace")"
  if [[ "$provider" != "github" && "$provider" != "gitlab" ]]; then
    log "recusando: provider '$provider' (remote.origin.url) não suportado — AC 18"
    return 0
  fi
  if [[ "$path" != "$key" ]]; then
    log "recusando: remote path '$path' não corresponde à chave allowlist '$key' — BR 1"
    return 0
  fi

  # BR 15 / BR 6: per-repo lock, held for the WHOLE run (including develop).
  # Non-blocking: a second trigger on a locked repo is deferred to the next tick.
  # NOTE: `exec {var}>file` applies redirections persistently to the current
  # shell — never append e.g. `2>/dev/null` here or the watcher's own stderr
  # (all logging) would be silenced for the rest of this repo's processing.
  local lock="" lockfd=""
  lock="$(lock_file "$key")"
  exec {lockfd}>"$lock" || { log "falha ao abrir lock $lock"; return 0; }
  if ! flock -n "$lockfd"; then
    log "repo '$key' já sendo processado (flock) — deferido para o próximo tick"
    exec {lockfd}>&-
    return 0
  fi
  log "lock adquirido para '$key'"

  local cursor="" tracker="" cjson="" cid="" cauthor="" cissue="" processed=0
  local triggers=0
  cursor="$(read_cursor "$key")"
  tracker="$(resolve_tracker "$workspace")"

  # Security M2: on FIRST run (no cursor yet), initialize the cursor to the
  # newest comment id so historical comments — including stale @aibot:develop
  # triggers — never fire after install. New comments posted after the first
  # tick are processed normally.
  if [[ -z "$cursor" ]]; then
    local newest=""
    newest="$(fetch_comments "$provider" "$path" \
      | jq -sr '[.[] | .id] | max // empty' 2>/dev/null || true)"
    if [[ -n "$newest" ]]; then
      log "primeiro run: cursor inicializado para $newest (comentário mais recente) — sem replay de comentários históricos"
      write_cursor "$key" "$newest"
      cursor="$newest"
    fi
  fi
  log "cursor atual '$key': ${cursor:-nenhum}"
  log "tracker: $tracker"

  # R-M1/S-M1 (BR 18 / AC 16): GitHub PR conversation comments are excluded by
  # checking each comment's issue number against the real issue list. GitLab
  # comments are already filtered to noteable_type == "Issue", but the same
  # uniform check is harmless there. If the issue-list fetch FAILS (rate limit,
  # network), valid_issues is empty and rc != 0 — defer the whole tick WITHOUT
  # advancing the cursor so real triggers are retried when the list recovers
  # (runtime N1: never silently drop a real trigger by cursor advance).
  local valid_issues="" fetch_rc=0
  valid_issues="$(fetch_issue_numbers "$provider" "$path")" || fetch_rc=$?
  if [[ "$fetch_rc" -ne 0 || -z "$valid_issues" ]]; then
    log "aviso: lista de issues indisponível para $path (rc=$fetch_rc) — comentários deferidos, cursor não avança"
    return 0
  fi

  ai_bot_identity="$(get_local_identity "$provider")"

  # Fetch issue comments (ascending by id), process only those after the cursor.
  # `jq -sc` keeps each comment on a single line for the while/read loop.
  local stream=""
  stream="$(fetch_comments "$provider" "$path" | jq -sc 'sort_by(.id)[]' 2>/dev/null || true)"
  while IFS= read -r cjson; do
    [[ -z "$cjson" ]] && continue
    cid="$(jq -r '.id' <<<"$cjson" 2>/dev/null || echo "")"
    cauthor="$(jq -r '.author' <<<"$cjson" 2>/dev/null || echo "")"
    cissue="$(jq -r '.issue' <<<"$cjson" 2>/dev/null || echo "")"
    [[ -z "$cid" || -z "$cissue" ]] && continue

    # BR 2 / AC 8 / AC 13: every comment processed at most once (cursor gate)
    if [[ -n "$cursor" ]] && [[ "$cid" -le "$cursor" ]] 2>/dev/null; then
      continue
    fi
    # BR 18 / AC 16: skip comments that are not on a real issue (PR comments)
    if ! printf '%s\n' "$valid_issues" | grep -qxF "$cissue" 2>/dev/null; then
      log "comentário $cid ignorado (issue #$cissue não é uma issue real — provável comentário de PR)"
      write_cursor "$key" "$cid"
      continue
    fi
    processed=$((processed + 1))
    # Security M3: bound parallel pipeline spawns per repo per tick
    if [[ "$triggers" -ge "$MAX_TRIGGERS_PER_TICK" ]]; then
      log "limite de triggers por tick atingido ($MAX_TRIGGERS_PER_TICK) — comentário $cid (issue #$cissue) pulado, cursor avança"
      write_cursor "$key" "$cid"
      continue
    fi
    if ! handle_comment "$workspace" "$tracker" "$provider" "$path" \
      "$cid" "$cauthor" "$cissue" "$cjson" "$ai_bot_identity"; then
      triggers=$((triggers + 1))
    fi
    # BR 3: cursor advances for EVERY comment, even non-triggering ones
    write_cursor "$key" "$cid"
  done <<< "$stream"

  log "repo '$key': $processed comentário(s) novo(s) processados, $triggers trigger(s)"
  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&-
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

main() {
  log "=== aibot-watcher tick ==="

  # BR 12 / AC 9: health-check the web server first; skip + log when down
  if ! web_healthy; then
    log "web server ($AIBOT_WEB_URL) indisponível — tick pulado (BR 12 / AC 9)"
    exit 0
  fi

  if [[ ! -f "$AIBOT_REPOS_FILE" ]]; then
    log "sem allowlist ($AIBOT_REPOS_FILE) — nada a fazer"
    exit 0
  fi

  # State (cursor + lock) is private — 0700 (Security nit)
  mkdir -p -m 700 "$AIBOT_STATE_DIR"

  # BR 6: repos run in parallel (backgrounded); a second trigger on a locked
  # repo is deferred to the next tick by the per-repo flock.
  local pids=() key="" workspace=""
  while IFS=$'\t' read -r key workspace; do
    [[ -z "$key" ]] && continue
    process_repo "$key" "$workspace" &
    pids+=("$!")
  done < <(list_repos)

  if [[ ${#pids[@]} -gt 0 ]]; then
    local failed=0 pid=""
    for pid in "${pids[@]}"; do
      wait "$pid" || failed=1
    done
    log "tick concluído (failed=$failed)"
    exit "$failed"
  fi
  log "tick concluído (nenhum repo allowlisted)"
  exit 0
}

# Only execute when run as a script; when sourced (tests), just define helpers.
if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
  main "$@"
fi
