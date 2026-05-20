#!/usr/bin/env bash
set -euo pipefail

# Usage: .config/opencode/scripts/promote.sh <local_issue_id>

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: promote.sh <id>"
  exit 1
fi

ISS_FILE=".config/opencode/known_issues.md"

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

STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')

if [[ "$STATUS" != "backlog" && "$STATUS" != "ready" ]]; then
  echo "Issue $ID cannot be promoted from status '$STATUS'"
  exit 1
fi

awk -v id="$ID" '
  BEGIN{found=0}
  /^### [0-9]+\./ {
    if (found == 1 && $0 !~ "^### " id "\\.") {
      found=0
    }
  }
  $0 ~ "^### " id "\\." {found=1}
  {
    if (found == 1 && $0 ~ /^- Status:/) {
      print "- Status: open"
      next
    }
    if (found == 1 && $0 ~ /^- Remote:/) {
      print "- Remote: -"
      next
    }
    print
  }
' "$ISS_FILE" > "$ISS_FILE.tmp" && mv "$ISS_FILE.tmp" "$ISS_FILE"

echo "[promote] Issue $ID promoted from $STATUS to open"
echo "[promote] Remote reset to - until create_issue.sh assigns the remote id"
echo "[promote] Title: $TITLE"
