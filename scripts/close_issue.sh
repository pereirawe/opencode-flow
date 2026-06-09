#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: $SCRIPTS_DIR/close_issue.sh <local_issue_id>

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: close_issue.sh <id>"
  exit 1
fi

FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then
  echo "known_issues.md not found"
  exit 1
fi

SECTION=$(awk -v id="$ID" '
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
  echo "Issue $ID not found"
  exit 1
fi

STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
REMOTE_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Remote:/ {print $2; exit}')
REMOTE_ID=${REMOTE_REF#\#}
PR_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- PR:/ {print $2; exit}')
PR_ID=${PR_REF#\#}
REMOTE_URL=$(git config --get remote.origin.url)

if [[ "$STATUS" != "ready" && "$STATUS" != "open" && "$STATUS" != "in-progress" && "$STATUS" != "in-publish" && "$STATUS" != "resolved" ]]; then
  echo "Issue $ID cannot be closed from status '$STATUS'"
  exit 1
fi

# Auto-detect merged PR when status is in-publish
if [[ "$STATUS" == "in-publish" && -n "$PR_ID" && "$PR_ID" != "-" ]]; then
  if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    PR_STATE=$(gh pr view "$PR_ID" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
    if [[ "$PR_STATE" == "MERGED" ]]; then
      echo "[pr] PR #$PR_ID merged — closing issue"
    else
      echo "[pr] PR #$PR_ID not merged yet (state: $PR_STATE). Skipping remote close."
    fi
  fi
fi

if [[ -n "$REMOTE_ID" && "$REMOTE_ID" != "-" ]]; then
  if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    gh issue close "$REMOTE_ID" || true
  elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
    glab issue close "$REMOTE_ID" || true
  fi
fi

# Extract fields for archive
TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
TYPE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Type:/ {print $2; exit}')
SEVERITY=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Severity:/ {print $2; exit}')
REPORTED_BY=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Report:/ {print $2; exit}')
REVIEWERS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Reviewers:/ {print $2; exit}')
# Strip profiles, keep only count for archive (BR11)
REVIEWER_COUNT=$(printf '%s\n' "$REVIEWERS" | grep -o '^[0-9]*' || echo "1")
DESC=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Description:/ {print $2; exit}')
SUGGESTED=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Suggested fix:/ {print $2; exit}')
RESOLVED_DATE=$(date +%Y-%m-%d)
SUMMARY="${DESC:-no description}${SUGGESTED:+ — ${SUGGESTED}}"

# Ensure resolved archive exists with header
if [[ ! -f "$RESOLVED_FILE" ]]; then
  echo "# Resolved Issues" > "$RESOLVED_FILE"
  echo "" >> "$RESOLVED_FILE"
  echo "Issues resolved from \`known_issues.md\`. See \`standards/resolved-issue.md\` for format." >> "$RESOLVED_FILE"
  echo "" >> "$RESOLVED_FILE"
fi

# Prepend to resolved archive (newest first)
TMP_ARCHIVE=$(mktemp)
printf '%s\n' "" > "$TMP_ARCHIVE"
printf '### %s. %s\n' "$ID" "$TITLE" >> "$TMP_ARCHIVE"
printf -- '- Resolved: %s\n' "$RESOLVED_DATE" >> "$TMP_ARCHIVE"
printf -- '- Type: %s\n' "${TYPE:-chore}" >> "$TMP_ARCHIVE"
printf -- '- Report: %s\n' "${REPORTED_BY:-unknown}" >> "$TMP_ARCHIVE"
printf -- '- Reviewers: %s\n' "${REVIEWER_COUNT:-1}" >> "$TMP_ARCHIVE"
printf -- '- Remote: %s\n' "${REMOTE_REF:--}" >> "$TMP_ARCHIVE"
printf -- '- Severity: %s\n' "${SEVERITY:-medium}" >> "$TMP_ARCHIVE"
printf -- '- Summary: %s\n' "$SUMMARY" >> "$TMP_ARCHIVE"
# Append existing content after header (lines 4+)
tail -n +4 "$RESOLVED_FILE" >> "$TMP_ARCHIVE"
mv "$TMP_ARCHIVE" "$RESOLVED_FILE"
echo "[archive] Appended to $RESOLVED_FILE"

# Remove entry from known_issues.md
awk -v id="$ID" '
BEGIN{skip=0}
$0 ~ "^### " id "\\." {skip=1; next}
skip == 1 && $0 ~ /^### [0-9]+\./ {skip=0}
skip == 0 {print}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

echo "[issue] closed $ID, archived to resolved_issues.md"
