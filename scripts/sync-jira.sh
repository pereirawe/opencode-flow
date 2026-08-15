#!/usr/bin/env bash
# sync-jira.sh — Jira Cloud sync for the issue pipeline (issue #48).
#
# Mirrors the opencode issue tracker (`known_issues.md`) into Jira Cloud via
# the REST v3 API: creates cards, transitions them through the project
# workflow, adds comments, and reconciles the whole tracker in one run.
# `known_issues.md` is the single source of truth — Jira is a mirror and the
# local status always wins.
#
# Non-blocking by design (BR 8): network/API/auth failures log a warning and
# return a non-zero exit, but pipeline scripts hooking this never abort on it.
# Transition map is configurable per-project (`statusMap` in jira.json), with
# documented defaults (BR 6). Idempotent (BR 5): a card is never created twice
# and re-running a sync for an unchanged status is a no-op.
#
# Configuration (see config.sh jira_config_load):
#   .opencode/jira.json  or env vars  + JIRA_API_TOKEN (env only, never logged)
#
# Usage:
#   sync-jira.sh config                 — print resolved config (no secrets)
#   sync-jira.sh ensure-card <file> <id>  — create card if Jira: - (idempotent)
#   sync-jira.sh transition <file> <id>   — move card to the mapped status
#   sync-jira.sh add-comment <file> <id> [text|stdin]
#   sync-jira.sh sync [file]              — reconcile every issue with a card

set -euo pipefail
source "$(dirname "$0")/config.sh"

# Single temp dir for the whole run; cleaned on exit so SIGINT/SIGTERM never
# leak mktemp files (reviewer nit).
JIRA_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$JIRA_TMPDIR"' EXIT

# --- auth ---------------------------------------------------------------------

auth_header() {
  if [[ "$JIRA_AUTH_MODE" == "bearer" ]]; then
    printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN"
  else
    local cred
    cred="$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64 | tr -d '\n')"
    printf 'Authorization: Basic %s\n' "$cred"
  fi
}

# jira_http <method> <path> [json-data] — curl wrapper.
# Prints the response body on success; logs a warning and returns 1 otherwise.
# Never prints the token: auth goes in the Authorization header only (AC 9).
# Hard network timeouts enforce the BR 8 non-blocking guarantee even for
# black-holed/DNS-stalled hosts (reviewer HIGH finding): a hung curl would
# otherwise freeze the pipeline hooks that call this synchronously.
jira_http() {
  local method="$1" path="$2" data="${3:-}"
  local url="${JIRA_BASE_URL%/}$path"
  local hdr
  hdr="$(auth_header)"
  local tmp_body tmp_code tmp_err
  tmp_body="$JIRA_TMPDIR/body.$$"; tmp_code="$JIRA_TMPDIR/code.$$"; tmp_err="$JIRA_TMPDIR/err.$$"
  local rc=0
  local ctimeout="${JIRA_CURL_TIMEOUT:-5}" mtimeout="${JIRA_CURL_MAXTIME:-30}"
  if [[ -n "$data" ]]; then
    curl -sS --connect-timeout "$ctimeout" --max-time "$mtimeout" \
      -X "$method" -H "$hdr" -H "Content-Type: application/json" \
      -o "$tmp_body" -w '%{http_code}' -d "$data" "$url" >"$tmp_code" 2>"$tmp_err" || rc=$?
  else
    curl -sS --connect-timeout "$ctimeout" --max-time "$mtimeout" \
      -X "$method" -H "$hdr" -H "Content-Type: application/json" \
      -o "$tmp_body" -w '%{http_code}' "$url" >"$tmp_code" 2>"$tmp_err" || rc=$?
  fi
  local code body err
  code="$(cat "$tmp_code" 2>/dev/null || echo "000")"
  body="$(cat "$tmp_body" 2>/dev/null || true)"
  err="$(head -c 300 "$tmp_err" 2>/dev/null || true)"
  rm -f "$tmp_body" "$tmp_code" "$tmp_err"
  if [[ "$rc" -ne 0 ]]; then
    echo "[jira] WARNING: curl failed (rc=$rc) for $method $path — sync skipped (non-blocking): $err" >&2
    return 1
  fi
  # sanitize before arithmetic: a non-numeric code would be evaluated as an
  # arithmetic expression under set -u (reviewer finding) — pin to digits
  code="${code//[^0-9]/}"
  [[ -z "$code" ]] && code="000"
  if [[ "$code" -ge 400 ]]; then
    echo "[jira] WARNING: Jira API HTTP $code for $method $path — $(printf '%s' "$body" | head -c 300) (non-blocking)" >&2
    return 1
  fi
  printf '%s' "$body"
  return 0
}

# --- JSON helpers (python3 first, grep best-effort fallback) ------------------

# json_get <json> <key...> — nested lookup; prints "" on missing
json_get() {
  local j="$1"; shift
  if command -v python3 >/dev/null 2>&1; then
    J="$j" python3 -c '
import json, os, sys
try:
    d = json.loads(os.environ["J"])
except Exception:
    sys.exit(1)
for k in sys.argv[1:]:
    if isinstance(d, dict):
        d = d.get(k)
    else:
        d = None
    if d is None:
        break
print(d if isinstance(d, str) else json.dumps(d))' "$@" 2>/dev/null || true
  else
    echo "$j" | sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
  fi
}

# build_json <typename> <text> — ADF document with the given body text
build_json() {
  local type="$1" text="$2"
  if command -v python3 >/dev/null 2>&1; then
    T="$type" TEXT="$text" python3 -c '
import json, os
def para(t):
    return {"type":"paragraph","content":[{"type":"text","text":t}]}
lines = [ln for ln in os.environ["TEXT"].split("\n")]
paras = [para(ln) for ln in lines] if any(lines) else [para("")]
print(json.dumps({"type":"doc","version":1,"content":paras}))'
  else
    local e
    e="$(printf '%s' "$text" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"%s"}]}]}' "$e"
  fi
}

# --- tracker helpers -----------------------------------------------------------

# issue_section <file> <id> — prints the issue entry block
issue_section() {
  awk -v id="$2" '
    $0 ~ "^### " id "\\." {found=1}
    found {
      if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") { exit }
      print
    }
  ' "$1"
}

# field_value <section> <name> — value of "- <name>:" ("" when absent)
field_value() {
  printf '%s\n' "$1" | awk -F': ' -v f="$2" '$0 ~ "^\\- " f ":" {print $2; exit}'
}

# set_jira_field <file> <id> <value> — replace `- Jira:` or insert it right
# after `- Remote:` (fallback: append at the end of the entry). Idempotent:
# re-running replaces, never duplicates.
set_jira_field() {
  local file="$1" id="$2" val="$3"
  awk -v id="$id" -v val="$val" '
  /^### [0-9]+\./ {
    if (collecting) { flush_section(); collecting = 0; n = 0 }
    if ($0 ~ "^### " id "\\.") collecting = 1
  }
  {
    if (collecting) buf[n++] = $0; else print
  }
  END { if (collecting) flush_section() }
  function flush_section(   i, done) {
    done = 0
    for (i = 0; i < n; i++) {
      if (buf[i] ~ /^- Jira:/) {
        # the Jira line is the anchor for replacement/insertion: write it once
        if (!done) { print "- Jira: " val; done = 1 }
        continue
      }
      print buf[i]
      if (!done && buf[i] ~ /^- Remote:/) { print "- Jira: " val; done = 1 }
    }
    if (!done) print "- Jira: " val
  }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# --- status mapping (BR 6) ------------------------------------------------------

default_status_map() {
  case "$1" in
    backlog|ready)   echo "To Do" ;;
    in-progress)     echo "In Progress" ;;
    in-review)       echo "In Review" ;;
    in-qa)           echo "QA/Testing" ;;
    in-publish)      echo "Ready for Release" ;;
    resolved)        echo "Done" ;;
    *)               echo "" ;;
  esac
}

# map_status <local_status> — Jira status name from statusMap or defaults
map_status() {
  local s="$1"
  if [[ -n "$JIRA_STATUS_MAP" ]] && command -v python3 >/dev/null 2>&1; then
    local m
    m="$(M="$JIRA_STATUS_MAP" S="$s" python3 -c '
import json, os, sys
try:
    d = json.loads(os.environ["M"])
except Exception:
    sys.exit(1)
print(d.get(os.environ["S"], ""))' 2>/dev/null || true)"
    if [[ -n "$m" ]]; then echo "$m"; return; fi
  fi
  default_status_map "$s"
}

# --- Jira API operations --------------------------------------------------------

# card_status <key> — current workflow status name of the card
card_status() {
  local key="$1"
  local resp
  resp="$(jira_http GET "/rest/api/3/issue/$key?fields=status")" || return 1
  json_get "$resp" fields status name
}

# find_transition_id <key> <target-name> — transition id by target status name;
# prints "" (with warning) when the workflow does not allow it (BR 9)
find_transition_id() {
  local key="$1" target="$2"
  local resp
  resp="$(jira_http GET "/rest/api/3/issue/$key/transitions")" || return 1
  if command -v python3 >/dev/null 2>&1; then
    local id
    id="$(B="$resp" TARGET="$target" python3 -c '
import json, os, sys
try:
    d = json.loads(os.environ["B"])
except Exception:
    sys.exit(1)
for t in d.get("transitions", []):
    if t.get("name") == os.environ["TARGET"]:
        print(t.get("id", ""))
        sys.exit(0)
sys.exit(1)' 2>/dev/null || true)"
    if [[ -n "$id" ]]; then echo "$id"; return 0; fi
  else
    local fallback
    fallback="$(echo "$resp" | tr '}' '\n' | grep -F "\"name\":\"$target\"" | head -1 \
      | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([0-9]*\)".*/\1/p' || true)"
    if [[ -n "$fallback" ]]; then echo "$fallback"; return 0; fi
  fi
  echo "[jira] WARNING: transition to '$target' is not allowed by the Jira workflow for $key — no-op (BR 9)" >&2
  return 1
}

# --- subcommands ----------------------------------------------------------------

cmd_config() {
  if jira_config_load; then
    # email is redacted (AC 9 / BR 12): the value is the Jira account login,
    # not needed for debugging; never echo it to logs/console
    printf 'enabled=yes\nbase_url=%s\nproject_key=%s\nemail=<set>\nauth_mode=%s\n' \
      "$JIRA_BASE_URL" "$JIRA_PROJECT_KEY" "$JIRA_AUTH_MODE"
    return 0
  fi
  echo "enabled=no"
  return 1
}

cmd_ensure_card() { # <file> <id> — create the card when Jira: - (BR 4/BR 5)
  local file="$1" id="$2"
  local sec
  sec="$(issue_section "$file" "$id")"
  if [[ -z "$sec" ]]; then
    echo "[jira] issue $id not found in $file" >&2
    return 1
  fi
  local cur
  cur="$(field_value "$sec" Jira)"
  if [[ -n "$cur" && "$cur" != "-" ]]; then
    echo "[jira] card already exists for issue $id ($cur) — skipping creation (BR 5)"
    return 0
  fi
  local title body payload resp key
  title="$(printf '%s\n' "$sec" | sed -n '1s/^### [0-9]*\. //p')"
  body="$(printf '%s\n' "$sec" | awk '
    NR == 1 { next }
    /^- (Status|Opened|Ready|Started|Remote|PR|Jira):/ { next }
    { print }
  ')"
  if ! command -v python3 >/dev/null 2>&1; then
    # No python3 → the JSON build cannot be done safely (the grep fallback
    # produced invalid JSON / raw newlines — reviewer finding). Fail loudly
    # and non-blocking instead of sending a malformed create to Jira.
    echo "[jira] WARNING: python3 is required to create the card for issue $id — skipped (non-blocking)" >&2
    return 1
  fi
  payload="$(build_json doc "$body")"
  payload="$(JIRA_TITLE="$title" JIRA_PROJ="$JIRA_PROJECT_KEY" JIRA_BODY="$payload" python3 -c '
import json, os
p = {"fields": {
  "project": {"key": os.environ["JIRA_PROJ"]},
  "summary": os.environ["JIRA_TITLE"],
  "issuetype": {"name": "Task"},
  "description": json.loads(os.environ["JIRA_BODY"]),
}}
print(json.dumps(p))' 2>/dev/null || true)"
  if [[ -z "$payload" ]]; then
    echo "[jira] WARNING: could not build the card payload for issue $id — skipped (non-blocking)" >&2
    return 1
  fi
  resp="$(jira_http POST /rest/api/3/issue "$payload")" || return 1
  key="$(json_get "$resp" key)"
  if [[ -z "$key" ]]; then
    echo "[jira] WARNING: no issue key in create response (non-blocking)" >&2
    return 1
  fi
  set_jira_field "$file" "$id" "$key"
  echo "[jira] card created: $key for issue $id"
}

cmd_transition() { # <file> <id> [--terminal] — move the card to the mapped status (BR 6)
  local file="$1" id="$2" terminal=0
  if [[ "${3:-}" == "--terminal" ]]; then
    terminal=1
  fi
  local sec
  sec="$(issue_section "$file" "$id")"
  if [[ -z "$sec" ]]; then
    echo "[jira] issue $id not found in $file" >&2
    return 1
  fi
  local key status target cur tid resp
  key="$(field_value "$sec" Jira)"
  if [[ -z "$key" || "$key" == "-" ]]; then
    echo "[jira] no card for issue $id (Jira: ${key:-none}) — transition skipped"
    return 0
  fi
  if ! [[ "$key" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
    echo "[jira] WARNING: malformed Jira key '$key' for issue $id — skipped (non-blocking)" >&2
    return 1
  fi
  # --terminal forces the resolved/terminal mapping (close path): the entry is
  # archived right after, so the card must reach Done regardless of whether the
  # local status was in-publish or resolved (reviewer finding).
  status="$(field_value "$sec" Status)"
  if [[ "$terminal" == "1" ]]; then
    status="resolved"
  fi
  target="$(map_status "$status")"
  if [[ -z "$target" ]]; then
    echo "[jira] no mapped Jira status for local status '$status' — skipped"
    return 0
  fi
  cur="$(card_status "$key")" || return 1
  if [[ -n "$cur" && "$cur" == "$target" ]]; then
    echo "[jira] card $key already in '$target' — no transition"
    return 0
  fi
  tid="$(find_transition_id "$key" "$target")" || return 0
  if ! [[ "$tid" =~ ^[0-9]+$ ]]; then
    echo "[jira] WARNING: non-numeric transition id for $key — skipped (non-blocking)" >&2
    return 1
  fi
  resp="$(jira_http POST "/rest/api/3/issue/$key/transitions" \
    "{\"transition\":{\"id\":\"$tid\"}}")" || return 1
  echo "[jira] card $key transitioned to '$target' (id $tid)"
}

cmd_add_comment() { # <file> <id> [text] — text from argv or stdin (BR 10)
  local file="$1" id="$2" text="${3:-}"
  if [[ -z "$text" ]]; then
    text="$(cat)"
  fi
  local sec key payload
  sec="$(issue_section "$file" "$id")"
  [[ -n "$sec" ]] || { echo "[jira] issue $id not found in $file" >&2; return 1; }
  key="$(field_value "$sec" Jira)"
  if [[ -z "$key" || "$key" == "-" ]]; then
    echo "[jira] no card for issue $id (Jira: ${key:-none}) — comment skipped"
    return 0
  fi
  if ! [[ "$key" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
    echo "[jira] WARNING: malformed Jira key '$key' for issue $id — skipped (non-blocking)" >&2
    return 1
  fi
  local doc
  doc="$(build_json doc "$text")"
  payload="$(printf '{"body":%s}' "$doc")"
  jira_http POST "/rest/api/3/issue/$key/comment" "$payload" || return 1
  echo "[jira] comment added to card $key"
}

cmd_sync() { # [file] — reconcile every issue that has a card (AC 5)
  local file="${1:-$PROJECT_ISSUES_FILE}"
  if [[ ! -f "$file" ]]; then
    echo "[jira] tracker not found: $file" >&2
    return 1
  fi
  local ids id sec key out
  ids="$(awk '/^### [0-9]+\./ { gsub(/\.$/,"",$2); print $2 }' "$file")"
  local synced=0 skipped=0 failed=0
  for id in $ids; do
    sec="$(issue_section "$file" "$id")"
    key="$(field_value "$sec" Jira)"
    if [[ -z "$key" || "$key" == "-" ]]; then
      skipped=$((skipped + 1))
      continue
    fi
    out="$(cmd_transition "$file" "$id" 2>&1)" && {
      synced=$((synced + 1))
      echo "[jira] $out"
    } || {
      failed=$((failed + 1))
      echo "[jira] WARNING: sync failed for issue $id — continuing (non-blocking): $out"
    }
  done
  echo "[jira] sync done: $synced synced, $skipped without card, $failed failed"
  # a reconcile where every transition failed must not report success (BR 8 /
  # CI observability — reviewer finding)
  [[ "$failed" -eq 0 ]]
}

# --- main ------------------------------------------------------------------------

CMD="${1:-}"
shift || true

case "$CMD" in
  config)
    cmd_config
    ;;
  ensure-card|transition|add-comment|sync)
    if ! jira_config_load; then
      echo "[jira] sync disabled — no valid Jira config (jira.json or env + JIRA_API_TOKEN)" >&2
      exit 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
      # JSON building/parsing requires python3; the sed/grep fallbacks produced
      # invalid JSON / wrong nested lookups (reviewer finding). Fail loudly,
      # non-blocking — the pipeline hooks tolerate the exit code.
      echo "[jira] WARNING: python3 is required for Jira sync — skipped (non-blocking)" >&2
      exit 1
    fi
    case "$CMD" in
      ensure-card) cmd_ensure_card "$@" ;;
      transition)  cmd_transition "$@" ;;
      add-comment) cmd_add_comment "$@" ;;
      sync)        cmd_sync "$@" ;;
    esac
    ;;
  *)
    echo "Usage: sync-jira.sh {config|ensure-card <file> <id>|transition <file> <id> [--terminal]|add-comment <file> <id> [text]|sync [file]}" >&2
    exit 2
    ;;
esac
