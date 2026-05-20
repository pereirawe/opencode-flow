#!/usr/bin/env bash
set -euo pipefail

# Usage: .config/opencode/scripts/close_issue.sh <local_issue_id>

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: close_issue.sh <id>"
  exit 1
fi

FILE=".config/opencode/known_issues.md"
if [[ ! -f "$FILE" ]]; then
  echo "known_issues.md not found"
  exit 1
fi

SECTION=$(awk -v id="$ID" '
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
REMOTE_URL=$(git config --get remote.origin.url)

if [[ "$STATUS" != "open" && "$STATUS" != "in-progress" ]]; then
  echo "Issue $ID cannot be closed from status '$STATUS'"
  exit 1
fi

if [[ -n "$REMOTE_ID" && "$REMOTE_ID" != "-" ]]; then
  if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    gh issue close "$REMOTE_ID" || true
  elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
    glab issue close "$REMOTE_ID" || true
  fi
fi

# Mark as resolved locally
awk -v id="$ID" '
BEGIN{found=0}
/^### [0-9]+\./{
  if(found==1 && $0 !~ "^### "id"\\."){found=0}
}
$0 ~ "^### "id"\."{found=1}
{
  if(found==1 && $0 ~ /^- Status:/){print "- Status: resolved"; next}
  print
}' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

echo "[issue] closed $ID"
