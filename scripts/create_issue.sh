#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage:
# $SCRIPTS_DIR/create_issue.sh "Issue Title" "Issue Body"
# $SCRIPTS_DIR/create_issue.sh <local_issue_number>

INPUT=${1:-}
TITLE=""
BODY=""

# If only a number is provided, fetch from known_issues
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  FILE="$PROJECT_ISSUES_FILE"
  if [[ ! -f "$FILE" ]]; then
    echo "known_issues.md not found"
    exit 1
  fi
  SECTION=$(awk -v id="$INPUT" '
    $0 ~ "^### " id "\\." {found=1}
    found {
      if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") {
        exit
      }
      print
    }
  ' "$FILE")

  if [[ -z "$SECTION" ]]; then
    echo "Issue $INPUT not found"
    exit 1
  fi

  STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
  REMOTE_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Remote:/ {print $2; exit}')

  if [[ "$STATUS" != "ready" && "$STATUS" != "open" ]]; then
    echo "Issue $INPUT cannot create remote issue from status '$STATUS'"
    exit 1
  fi

  if [[ "$REMOTE_REF" != "-" ]]; then
    echo "Issue $INPUT already has remote reference '$REMOTE_REF'"
    exit 1
  fi

  TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
  BODY=$(printf '%s\n' "$SECTION" | awk 'NR == 1 {next} $0 !~ /^- Remote:/ {print}')
else
  TITLE=${1:-}
  BODY=${2:-}
fi

if [[ -z "$TITLE" || -z "$BODY" ]]; then
  echo "Usage: create_issue.sh \"title\" \"body\""
  exit 1
fi

REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
echo "[issue] Remote: ${REMOTE_URL:-none}"

CREATE_REMOTE=true
if [[ -z "$REMOTE_URL" ]]; then
  echo "[issue] No remote configured — skipping remote issue creation"
  CREATE_REMOTE=false
elif [[ "$REMOTE_URL" == *"github.com"* ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "[issue] GitHub CLI (gh) not installed — skipping remote creation"
    CREATE_REMOTE=false
  fi
elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
  if ! command -v glab >/dev/null 2>&1; then
    echo "[issue] GitLab CLI (glab) not installed — skipping remote creation"
    CREATE_REMOTE=false
  fi
else
  echo "[issue] Unsupported or no remote — skipping remote issue creation"
  CREATE_REMOTE=false
fi

ISSUE_ID=""
ERROR_MSG=""
if $CREATE_REMOTE; then
  if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    ISSUE_URL=$(gh issue create --title "$TITLE" --body "$BODY" 2>/tmp/gh_error || true)
    if [[ -z "$ISSUE_URL" ]]; then
      ERROR_MSG=$(head -1 /tmp/gh_error 2>/dev/null || echo "unknown error")
      echo "[issue] FAILED: $ERROR_MSG"
    else
      ISSUE_ID=$(basename "$ISSUE_URL")
      echo "[issue] Created: $ISSUE_URL"
    fi
  elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
    ISSUE_URL=$(glab issue create --title "$TITLE" --description "$BODY" --yes 2>/tmp/gl_error | grep -Eo 'https?://[^ ]+' || true)
    if [[ -z "$ISSUE_URL" ]]; then
      ERROR_MSG=$(head -1 /tmp/gl_error 2>/dev/null || echo "unknown error")
      echo "[issue] FAILED: $ERROR_MSG"
    else
      ISSUE_ID=$(basename "$ISSUE_URL")
      echo "[issue] Created: $ISSUE_URL"
    fi
  fi
else
  echo "[issue] Local-only issue (no remote)"
fi

# rewrite_entry — rewrite the issue entry in the tracker file:
#   - replace the Status line (when new_status is non-empty)
#   - replace the Remote line (when remote is non-empty)
#   - rebuild the canonical timestamp block (Opened, Ready, Started) right after
#     the Status line, preserving field order Status < Opened < Ready < Started
#   - set-if-absent: existing timestamp values are never overwritten and never
#     duplicated (idempotent — re-running a script cannot corrupt fields)
# Issue #57: timestamp stamping is done here (pipeline scripts), NOT via
# pre_commit.sh trailer parsing (issue #24).
rewrite_entry() { # <file> <id> <new_status|''> <opened|''> <ready|''> <started|''> <remote|''>
  local file="$1" id="$2" ns="$3" opened="$4" ready="$5" started="$6" remote="$7"
  awk -v id="$id" -v ns="$ns" -v opened="$opened" -v ready="$ready" \
      -v started="$started" -v remote="$remote" '
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
  function flush_section(   i, status_idx, opened_v, ready_v, started_v) {
    status_idx = -1
    opened_v = ""; ready_v = ""; started_v = ""
    for (i = 0; i < n; i++) {
      if (buf[i] ~ /^- Status:/ && status_idx < 0) status_idx = i
      if (buf[i] ~ /^- Opened:/)  opened_v  = val(buf[i])
      if (buf[i] ~ /^- Ready:/)   ready_v   = val(buf[i])
      if (buf[i] ~ /^- Started:/) started_v = val(buf[i])
    }
    if (status_idx < 0) status_idx = 0
    # set-if-absent: existing values win; stamp only missing fields
    if (opened  != "" && !present(opened_v))  opened_v  = opened
    if (ready   != "" && !present(ready_v))   ready_v   = ready
    if (started != "" && !present(started_v)) started_v = started
    for (i = 0; i < n; i++) {
      if (buf[i] ~ /^- (Opened|Ready|Started):/) continue
      if (i == status_idx) {
        if (ns != "") print "- Status: " ns; else print buf[i]
        if (present(opened_v))  print "- Opened: "  opened_v
        if (present(ready_v))   print "- Ready: "   ready_v
        if (present(started_v)) print "- Started: " started_v
      } else if (remote != "" && buf[i] ~ /^- Remote:/) {
        print "- Remote: " remote
      } else {
        print buf[i]
      }
    }
  }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Update known_issues with Remote ID and status
FILE="$PROJECT_ISSUES_FILE"
if [[ -f "$FILE" && "$INPUT" =~ ^[0-9]+$ ]]; then
  NEW_STATUS="in-progress"
  if [[ "$STATUS" == "ready" ]]; then
    NEW_STATUS="ready"
  fi
  if [[ -n "$ERROR_MSG" ]]; then
    REMOTE_VAL="error:$ERROR_MSG"
  elif [[ -n "$ISSUE_ID" ]]; then
    REMOTE_VAL="#$ISSUE_ID"
  else
    REMOTE_VAL="-"
  fi
  # Stamp `- Opened:` ONLY on remote creation success (BR 3/BR 8), set-if-absent
  OPENED_DATE=""
  if [[ -n "$ISSUE_ID" ]]; then
    OPENED_DATE=$(date +%Y-%m-%d)
  fi
  rewrite_entry "$FILE" "$INPUT" "$NEW_STATUS" "$OPENED_DATE" "" "" "$REMOTE_VAL"
fi

# Create branch (only for legacy open status, ready uses promote.sh)
if [[ "$STATUS" == "open" ]]; then
  SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9 ' | tr ' ' '-')
  BRANCH="issue-${ISSUE_ID}-${SLUG}"
  if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    git checkout "$BRANCH"
  else
    git checkout -b "$BRANCH" 2>/dev/null || true
  fi
  echo "[issue] Branch: $BRANCH"
fi
echo "$ISSUE_ID"
