#!/usr/bin/env bash
set -euo pipefail

# run-ci-workflow.sh — CI-native engine for the `@aibot:develop` trigger
# (issue #40). Executed inside the opencode-flow Docker image by the GitHub
# Actions workflow (.github/workflows/aibot-develop.yml); also runnable locally
# to simulate the CI behavior (same gates, same messages).
#
# Flow (mirrors aibot-watcher.sh handle_comment, CI variant):
#   1. author gate  — aibot/bot authors never trigger (BR 15 / AC 12)
#   2. token gate   — standalone `@aibot:develop` outside code fences (BR 1/AC 9)
#   3. allowlist    — repo must be in AIBOT_ALLOWLIST or aibot-repos.json (BR 2)
#   4. tracker gate — issue must be tracked locally with Remote: #id (BR 3/AC 5)
#   5. status gate  — in-progress → already-in-progress; resolved → already-resolved (BR 5/AC 6)
#   6. develop      — `opencode run --command "ocf:develop" <id> --auto` HEADLESS
#                     (BR 4/BR 13 — SPIKE passed: no --attach needed)
#   7. result       — in-publish + PR → success w/ MR link; else cannot-develop (BR 5/6/7)
#
# Exactly ONE standardized message per trigger (BR 7), via gh/glab using the
# templates in standards/aibot-messages.md.
#
# Usage (env):
#   AIBOT_TOKEN          token to match (default: @aibot:develop)
#   AIBOT_ALLOWLIST      comma/space separated allowlist (e.g. "owner/repo1 owner/repo2")
#   AIBOT_MODEL          model id (default: opencode-go/deepseek-v4-flash — qualified!)
#   AIBOT_AUTHORS        extra author logins excluded from triggering
#   OPENCODE_API_KEY     model API key for the opencode-go provider
#   GH_TOKEN / GL_TOKEN  provider token for gh/glab (set the one that applies)
#   CI_DRY_RUN=1         print actions instead of executing (for tests/simulation)
#
# Args:
#   --workspace <dir>   repo checkout (default: /workspace)
#   --issue <remote-id> remote issue number that was commented
#   --author <login>    comment author
#   --body <text>       comment body (or via COMMENT_BODY env)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/remote.sh"

CONFIG_ROOT="${AIBOT_CONFIG_DIR:-$CONFIG_DIR}"
AIBOT_REPOS_FILE="${AIBOT_REPOS_FILE:-$CONFIG_ROOT/aibot-repos.json}"
AIBOT_TOKEN="${AIBOT_TOKEN:-@aibot:develop}"
AIBOT_MODEL="${AIBOT_MODEL:-opencode-go/deepseek-v4-flash}"
AIBOT_AUTHORS="${AIBOT_AUTHORS:-}"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"
WORKSPACE="/workspace"
ISSUE=""
AUTHOR=""
BODY=""
DRY_RUN="${CI_DRY_RUN:-0}"

log() { printf '[run-ci-workflow] %s %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$*" >&2; }
fail() { log "ERROR: $*"; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE="${2:?--workspace requires a value}"; shift 2 ;;
    --issue) ISSUE="${2:?--issue requires a value}"; shift 2 ;;
    --author) AUTHOR="${2:?--author requires a value}"; shift 2 ;;
    --body) BODY="${2:?--body requires a value}"; shift 2 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[[ -n "$ISSUE" ]] || fail "--issue is required"
BODY="${BODY:-${COMMENT_BODY:-}}"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

# has_token <body> — 0 when the standalone token appears as a whole line
# (trimmed) OUTSIDE fenced code blocks / HTML <pre>/<code> (BR 1 / AC 9).
has_token() {
  local body="$1"
  printf '%s\n' "$body" | awk -v tok="$AIBOT_TOKEN" '
    /^[[:space:]]*(```|~~~)/                  { in_fence = !in_fence; next }
    /^[[:space:]]*<\/?(pre|code).*>[[:space:]]*$/ { in_fence = !in_fence; next }
    !in_fence {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if ($0 == tok) { found = 1 }
    }
    END { exit (found == 1) ? 0 : 1 }
  '
}

# is_aibot_author <login> — 0 when the commenter is the aibot itself (BR 15).
is_aibot_author() {
  local author="${1:-}"
  [[ -z "$author" ]] && return 1
  [[ "$author" == *"[bot]" ]] && return 0
  if [[ -n "$AIBOT_AUTHORS" ]] \
    && printf '%s\n' "$AIBOT_AUTHORS" | tr ',' '\n' | grep -qxF "$author"; then
    return 0
  fi
  # The local identity that posts as the aibot (gh user / glab user)
  case "$(detect_provider "$WORKSPACE")" in
    github) [[ "$author" == "$(gh api user --jq .login 2>/dev/null || echo '')" ]] && return 0 ;;
    gitlab) [[ "$author" == "$(glab api user --jq .username 2>/dev/null || echo '')" ]] && return 0 ;;
  esac
  return 1
}

# repo_in_allowlist <repo> — 0 when the repo is in AIBOT_ALLOWLIST env or in
# the aibot-repos.json keys (BR 2).
repo_in_allowlist() {
  local repo="${1:-}"
  [[ -z "$repo" ]] && return 1
  if [[ -n "$AIBOT_ALLOWLIST" ]]; then
    printf '%s\n' "$AIBOT_ALLOWLIST" | tr ',[:space:]' '\n\n\n' | grep -qxF "$repo" && return 0
  fi
  if [[ -f "$AIBOT_REPOS_FILE" ]] && command -v jq >/dev/null 2>&1; then
    jq -e --arg r "$repo" 'has($r)' "$AIBOT_REPOS_FILE" >/dev/null 2>&1 && return 0
  fi
  return 1
}

# resolve_tracker — prefer workspace .opencode tracker with real entries,
# falling back to workspace root tracker (CWD quirk, issue 39 note 1).
has_entries() { grep -qE '^### [0-9]+\.' "$1" 2>/dev/null; }
resolve_tracker() {
  local local_tracker="$WORKSPACE/.opencode/known_issues.md"
  local root_tracker="$WORKSPACE/known_issues.md"
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

# find_tracked_issue <tracker> <remote_id> — local id whose `Remote:` == #<id>
find_tracked_issue() {
  local tracker="$1" rid="#$2"
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

# get_field <tracker> <local_id> <Field>
get_field() {
  local tracker="$1" id="$2" field="$3"
  awk -v id="$id" -v f="^- $field:" '
    $0 ~ "^### " id "\\." { found=1; next }
    found && $0 ~ /^### [0-9]+\./ { exit }
    found && $0 ~ f { sub(/^[^:]*: /, ""); print; exit }
  ' "$tracker"
}

# message_template <key> — the body of the `### <key>` section from
# standards/aibot-messages.md
message_template() {
  local key="$1" file="$CONFIG_ROOT/standards/aibot-messages.md"
  [[ -f "$file" ]] || fail "standards/aibot-messages.md not found ($file)"
  awk -v key="$key" '
    $0 ~ "^### " key "$" { in_msg = 1; next }
    in_msg && /^### / { exit }
    in_msg { print }
  ' "$file"
}

# post_message <remote-id> <key> [pr-number] — post exactly ONE standardized
# message via gh/glab (BR 7). Failures are logged, never fatal (matches the
# aibot agent tolerance).
post_message() {
  local remote_id="$1" key="$2" pr="${3:-}"
  local msg mr_link provider
  msg="$(message_template "$key")"
  msg="${msg//\{issue_id\}/$remote_id}"
  if [[ "$key" == "success" && -n "$pr" ]]; then
    provider="$(detect_provider "$WORKSPACE")"
    case "$provider" in
      github)
        mr_link="$(gh pr view "$pr" --json url --jq .url 2>/dev/null \
          || printf 'https://github.com/%s/pull/%s' "$(parse_remote "$WORKSPACE" | cut -d' ' -f2)" "$pr")"
        ;;
      gitlab)
        mr_link="$(glab mr view "$pr" --json web_url --jq .web_url 2>/dev/null \
          || printf 'https://gitlab.com/%s/-/merge_requests/%s' "$(parse_remote "$WORKSPACE" | cut -d' ' -f2)" "$pr")"
        ;;
      *) mr_link="PR #$pr" ;;
    esac
    msg="${msg//\{mr_link\}/$mr_link}"
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[dry-run] would post message '$key' to issue #$remote_id:"
    printf '%s\n' "$msg" >&2
    return 0
  fi
  case "$(detect_provider "$WORKSPACE")" in
    github)
      printf '%s\n' "$msg" | gh issue comment "$remote_id" --body-file - \
        || log "warning: failed to post '$key' to #$remote_id (gh)"
      ;;
    gitlab)
      glab issue comment "$remote_id" --message "$(printf '%s' "$msg")" \
        || log "warning: failed to post '$key' to #$remote_id (glab)"
      ;;
    *) log "warning: unknown provider — message '$key' for #$remote_id not posted" ;;
  esac
}

# run_develop <local-id> — headless full pipeline (BR 4/BR 13).
# NO `--` separator before the args (issue 39 R-B1: breaks on opencode 1.18.7).
run_develop() {
  local local_id="$1"
  log "disparando headless: $OPENCODE_BIN run --auto --dir $WORKSPACE --model $AIBOT_MODEL --command ocf:develop $local_id"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[dry-run] opencode run --auto --dir $WORKSPACE --model $AIBOT_MODEL --command \"ocf:develop\" $local_id"
    return 0
  fi
  "$OPENCODE_BIN" run --auto --dir "$WORKSPACE" --model "$AIBOT_MODEL" \
    --command "ocf:develop" "$local_id" < /dev/null
}

# ---------------------------------------------------------------------------
# gates
# ---------------------------------------------------------------------------

PROVIDER="$(detect_provider "$WORKSPACE")"
REPO="$(parse_remote "$WORKSPACE" | cut -d' ' -f2)"
log "provider=$PROVIDER repo=$REPO issue=#$ISSUE author=$AUTHOR"

# 1. author gate (BR 15 / AC 12)
if is_aibot_author "$AUTHOR"; then
  log "comment ignored — aibot author '$AUTHOR' (self-trigger prevention)"
  exit 0
fi

# 2. token gate (BR 1 / AC 9)
if ! has_token "$BODY"; then
  log "comment without standalone token '$AIBOT_TOKEN' — ignored (no pipeline, no message)"
  exit 0
fi
  log "TOKEN detected — issue #$ISSUE (author: $AUTHOR)"

# 3. allowlist (BR 2)
if ! repo_in_allowlist "$REPO"; then
  log "repo '$REPO' not in allowlist — refusing with standard message"
  post_message "$ISSUE" "cannot-develop"  # inline recusa (issue 40 note 6)
  exit 0
fi

# 4. tracker gate (BR 3 / AC 5)
TRACKER="$(resolve_tracker)"
LOCAL_ID="$(find_tracked_issue "$TRACKER" "$ISSUE")"
if [[ -z "$LOCAL_ID" ]]; then
  log "remote issue #$ISSUE not tracked locally — posting not-tracked"
  post_message "$ISSUE" "not-tracked"
  exit 0
fi
  log "issue #$ISSUE matched local #$LOCAL_ID (tracker: $TRACKER)"

# 5. status gate (BR 5 / AC 6)
STATUS="$(get_field "$TRACKER" "$LOCAL_ID" "Status")"
case "$STATUS" in
  in-progress|in-review|in-qa|in-publish)
    log "status=$STATUS — already in progress"
    post_message "$ISSUE" "already-in-progress"
    exit 0
    ;;
  resolved)
    log "status=$STATUS — already resolved"
    post_message "$ISSUE" "already-resolved"
    exit 0
    ;;
esac

# 6. develop headless (BR 4/BR 13)
if ! run_develop "$LOCAL_ID"; then
  log "ocf:develop #$LOCAL_ID failed — posting cannot-develop (no MR)"
  post_message "$ISSUE" "cannot-develop"
  exit 0
fi

# 7. result (BR 5/6/7) — re-read status after the pipeline
NEW_STATUS="$(get_field "$TRACKER" "$LOCAL_ID" "Status")"
PR_NUM="$(get_field "$TRACKER" "$LOCAL_ID" "PR")"
PR_NUM="${PR_NUM#\#}"
if [[ "$NEW_STATUS" == "in-publish" && -n "$PR_NUM" ]]; then
  log "success: status=$NEW_STATUS PR=#$PR_NUM — posting success"
  post_message "$ISSUE" "success" "$PR_NUM"
else
  log "pipeline ended without MR (status=$NEW_STATUS PR=$PR_NUM) — posting cannot-develop"
  post_message "$ISSUE" "cannot-develop"
fi
exit 0
