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
    /^### Status/ {exit}
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
  awk -v id="$INPUT" -v rid="$REMOTE_VAL" -v ns="$NEW_STATUS" '
  BEGIN{found=0}
  /^### [0-9]+\./{
    if(found==1 && $0 !~ "^### "id"\\."){found=0}
  }
  $0 ~ "^### "id"\."{found=1}
  {
    if(found==1 && $0 ~ /^- Status:/){print "- Status: "ns; next}
    if(found==1 && $0 ~ /^- Remote:/){print "- Remote: "rid; next}
    print
  }' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
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
