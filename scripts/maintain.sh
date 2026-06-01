#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "[maintain] Scanning $PROJECT_ISSUES_FILE..."
echo ""

if [[ ! -f "$PROJECT_ISSUES_FILE" ]]; then
  echo "[maintain] No known_issues.md found at $PROJECT_ISSUES_FILE"
  exit 1
fi

# Parse all issues
TOTAL=0
LOCAL=0
REMOTE=0
STALE=0
MATCH=0
declare -a ISSUE_IDS
declare -a ISSUE_TITLES
declare -a ISSUE_STATUSES
declare -a ISSUE_REMOTES

while IFS= read -r line; do
  if [[ "$line" =~ ^###[[:space:]]([0-9]+)\.(.*) ]]; then
    TOTAL=$((TOTAL + 1))
    ISSUE_IDS+=("${BASH_REMATCH[1]}")
    ISSUE_TITLES+=("${BASH_REMATCH[2]}")
    ISSUE_STATUSES+=("")
    ISSUE_REMOTES+=("")
  elif [[ "$line" =~ ^-[[:space:]]Status:[[:space:]](.*) ]]; then
    ISSUE_STATUSES[$((TOTAL - 1))]="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^-[[:space:]]Remote:[[:space:]](.*) ]]; then
    ISSUE_REMOTES[$((TOTAL - 1))]="${BASH_REMATCH[1]}"
  fi
done < "$PROJECT_ISSUES_FILE"

echo "[maintain] Found $TOTAL issue(s)"
echo ""

REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

for ((i = 0; i < TOTAL; i++)); do
  id="${ISSUE_IDS[$i]}"
  title="${ISSUE_TITLES[$i]}"
  status="${ISSUE_STATUSES[$i]}"
  remote="${ISSUE_REMOTES[$i]}"

  echo "--- Issue #$id:${title} ---"
  echo "  Status: ${status:-unknown}"
  echo "  Remote: ${remote:--}"

  if [[ "$remote" == "-" || -z "$remote" ]]; then
    LOCAL=$((LOCAL + 1))
    echo "  → Local only, no remote check needed"
  else
    REMOTE=$((REMOTE + 1))
    REMOTE_ID="${remote#\#}"
    echo "  Remote ID: $REMOTE_ID"

    REMOTE_STATE=""
    if [[ "$REMOTE_URL" == *"github.com"* ]] && command -v gh >/dev/null 2>&1; then
      REMOTE_STATE=$(gh issue view "$REMOTE_ID" --json state --jq '.state' 2>/dev/null || echo "unknown")
    elif [[ "$REMOTE_URL" == *"gitlab"* ]] && command -v glab >/dev/null 2>&1; then
      REMOTE_STATE=$(glab issue view "$REMOTE_ID" 2>/dev/null | grep -E '^State:' | awk '{print $2}' || echo "unknown")
    else
      REMOTE_STATE="unreachable"
    fi

    echo "  Remote state: $REMOTE_STATE"

    if [[ "$status" == "in-progress" && "$REMOTE_STATE" == "CLOSED" ]]; then
      echo "  ⚠️  STALE: local is 'in-progress' but remote is CLOSED"
      STALE=$((STALE + 1))
    elif [[ "$REMOTE_STATE" == "OPEN" || "$REMOTE_STATE" == "opened" ]]; then
      echo "  ✓ Sync OK: local=$status, remote=OPEN"
      MATCH=$((MATCH + 1))
    elif [[ "$status" == "resolved" ]]; then
      echo "  ✓ Already resolved locally"
    fi
  fi
  echo ""
done

OPEN_NO_REMOTE=0
for ((i = 0; i < TOTAL; i++)); do
  status="${ISSUE_STATUSES[$i]}"
  remote="${ISSUE_REMOTES[$i]}"
  if [[ "$status" == "open" && "$remote" == "-" ]]; then
    OPEN_NO_REMOTE=$((OPEN_NO_REMOTE + 1))
    echo "  ⚠️  OPEN WITHOUT REMOTE: Issue #${ISSUE_IDS[$i]} — create remote issue before development"
  fi
done

echo ""
echo "=== Summary ==="
echo "  Total issues:        $TOTAL"
echo "  Local only:          $LOCAL"
echo "  With remote:         $REMOTE"
echo "  Remote synced:       $MATCH"
echo "  Stale:               $STALE"
echo "  Open without remote: $OPEN_NO_REMOTE"
echo ""
echo "[maintain] Done. Run /ocf:maintain in the assistant to review and archive."
