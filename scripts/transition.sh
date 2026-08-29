#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: $SCRIPTS_DIR/transition.sh <local_issue_id> <new_status>
#
# Single status-transition entrypoint for the delivery pipeline. Updates the
# issue status and stamps the corresponding per-stage completion timestamp
# (set-if-absent, idempotent). Agents call this instead of editing
# known_issues.md directly so each stage's completion is tracked.
#
# Status -> timestamp field mapping (issue #81 per-stage tracking):
#   in-progress  -> - Started:
#   in-review    -> - In review:
#   in-qa        -> - In QA:
#   in-publish   -> - In publish:
#   resolved     -> handled by close_issue.sh (also archives)
#   backlog/ready/open -> no timestamp stamped (start of lifecycle)
#
# The timestamp block order is canonical: Status < Opened < Ready < Started <
# In review < In QA < In publish (resolved lives only in the archive).

ID=${1:-}
NEW_STATUS=${2:-}
if [[ -z "$ID" || -z "$NEW_STATUS" ]]; then
  echo "Usage: transition.sh <id> <new_status>"
  exit 1
fi

VALID_STATUSES="backlog ready open in-progress in-review in-qa in-publish resolved"
if ! printf '%s\n' "$VALID_STATUSES" | tr ' ' '\n' | grep -qxF "$NEW_STATUS"; then
  echo "[transition] ERROR: invalid status '$NEW_STATUS'"
  echo "[transition] Valid statuses: $VALID_STATUSES"
  exit 1
fi

ISS_FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$ISS_FILE" ]]; then
  echo "known_issues.md not found"
  exit 1
fi

# Extract issue section
SECTION=$(awk -v id="$ID" '
  $0 ~ "^### " id "\\." {found=1}
  found {
    if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") {
      exit
    }
    print
  }
' "$ISS_FILE")

if [[ -z "$SECTION" ]]; then
  echo "Issue $ID not found"
  exit 1
fi

# Map status -> timestamp field ('' = none)
FIELD=""
case "$NEW_STATUS" in
  in-progress)  FIELD="Started" ;;
  in-review)    FIELD="In review" ;;
  in-qa)        FIELD="In QA" ;;
  in-publish)   FIELD="In publish" ;;
esac

TODAY=$(date +%Y-%m-%dT%H:%M)

# rewrite_entry — update the Status line and stamp FIELD (set-if-absent),
# rebuilding the canonical timestamp block Status < Opened < Ready < Started <
# In review < In QA < In publish. Existing values are never overwritten nor
# duplicated (idempotent — re-running a transition cannot corrupt fields).
rewrite_entry() { # <file> <id> <new_status> <field> <today>
  local file="$1" id="$2" ns="$3" field="$4" today="$5"
  awk -v id="$id" -v ns="$ns" -v field="$field" -v today="$today" '
  BEGIN { collecting = 0; n = 0 }
  /^### [0-9]+\./ {
    if (collecting) { flush_section(); collecting = 0; n = 0 }
    if ($0 ~ "^### " id "\\.") collecting = 1
  }
  {
    if (collecting) buf[n++] = $0; else print
  }
  END { if (collecting) flush_section() }
  function val(line,    p) {
    p = index(line, ":")
    if (p == 0) return ""
    return substr(line, p + 2)
  }
  function present(v) { return (v != "" && v != "-") }
  function flush_section(   i, status_idx, s, o, r, st, ir, iq, ip) {
    status_idx = -1
    o = ""; r = ""; st = ""; ir = ""; iq = ""; ip = ""
    for (i = 0; i < n; i++) {
      if (buf[i] ~ /^- Status:/ && status_idx < 0) status_idx = i
      if (buf[i] ~ /^- Opened:/)     o  = val(buf[i])
      if (buf[i] ~ /^- Ready:/)      r  = val(buf[i])
      if (buf[i] ~ /^- Started:/)    st = val(buf[i])
      if (buf[i] ~ /^- In review:/)  ir = val(buf[i])
      if (buf[i] ~ /^- In QA:/)      iq = val(buf[i])
      if (buf[i] ~ /^- In publish:/) ip = val(buf[i])
    }
    if (status_idx < 0) status_idx = 0
    # set-if-absent: existing values win; stamp only the missing target field
    if (field == "Started"    && !present(st)) st = today
    if (field == "In review"  && !present(ir)) ir = today
    if (field == "In QA"      && !present(iq)) iq = today
    if (field == "In publish" && !present(ip)) ip = today
    for (i = 0; i < n; i++) {
      if (i == status_idx) {
        print "- Status: " ns
        if (present(o))  print "- Opened: "  o
        if (present(r))  print "- Ready: "   r
        if (present(st)) print "- Started: " st
        if (present(ir)) print "- In review: "  ir
        if (present(iq)) print "- In QA: "      iq
        if (present(ip)) print "- In publish: " ip
      } else if (buf[i] ~ /^- (Status|Opened|Ready|Started|In review|In QA|In publish):/) {
        continue
      } else {
        print buf[i]
      }
    }
  }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

rewrite_entry "$ISS_FILE" "$ID" "$NEW_STATUS" "$FIELD" "$TODAY"

# Jira Cloud sync (issue #48): reflect the status transition on the card when
# Jira is configured. Non-blocking (BR 8): failures never fail.
if "$SCRIPTS_DIR/sync-jira.sh" config >/dev/null 2>&1; then
  "$SCRIPTS_DIR/sync-jira.sh" transition "$ISS_FILE" "$ID" \
    || echo "[jira] Warning: status sync failed for issue $ID (non-blocking)"
fi

if [[ -n "$FIELD" ]]; then
  echo "[transition] Issue $ID -> $NEW_STATUS ($FIELD: $TODAY)"
else
  echo "[transition] Issue $ID -> $NEW_STATUS (no timestamp field)"
fi
