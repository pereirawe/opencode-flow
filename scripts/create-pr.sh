#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: create-pr.sh <local_issue_id>
#
# Creates the merge/pull request for an issue and records `- PR: #<n>` in
# known_issues.md. Replaces the publish-requester agent: the PR body is built
# mechanically from the issue fields (no agent judgment needed). The Committer
# gate (in-publish) must already have passed before calling this.
#
# Remote detection: gh for github.com, glab for gitlab.

ID=${1:-}
if [[ -z "$ID" ]]; then echo "Usage: create-pr.sh <id>"; exit 3; fi

FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then echo "known_issues.md not found"; exit 3; fi

SECTION=$(awk -v id="$ID" '
  $0 ~ "^### " id "\\." {found=1}
  found { if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit; print }
' "$FILE")
if [[ -z "$SECTION" ]]; then echo "create-pr: issue $ID not found"; exit 2; fi

STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
TYPE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Type:/ {print $2; exit}')
TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
REMOTE_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Remote:/ {print $2; exit}')
REMOTE_ID=${REMOTE_REF#\#}
BASE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Base branch:/ {print $2; exit}')
DESC=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Description:/ {print $2; exit}')
BUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Business rules:/ {print $2; exit}')
ACCEPT=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Acceptance criteria:/ {print $2; exit}')
TESTS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Tests:/ {print $2; exit}')
LOCATION=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Location:/ {print $2; exit}')

if [[ "$STATUS" != "in-publish" ]]; then
  echo "create-pr: issue $ID status '$STATUS' (expected in-publish)"
  exit 1
fi

REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
PR_TITLE="$TYPE: $TITLE (#$ID)"

BODY=$(cat <<EOF
## Summary
${DESC:-}

## Business rules
${BUS:-}

## Acceptance criteria
${ACCEPT:-}

## Tests
${TESTS:-}

## Location
${LOCATION:-}

Closes #$REMOTE_ID
EOF
)

PR=""
if [[ "$REMOTE_URL" == *"github.com"* ]]; then
  PR=$(gh pr create --title "$PR_TITLE" --body "$BODY" --base "$BASE" --json number --jq '.number' 2>/dev/null) \
    || { echo "create-pr: gh pr create failed"; exit 1; }
elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
  URL=$(glab mr create --title "$PR_TITLE" --description "$BODY" --target-branch "$BASE" 2>/dev/null) \
    || { echo "create-pr: glab mr create failed"; exit 1; }
  PR=$(printf '%s' "$URL" | grep -oE '[0-9]+' | tail -1)
else
  echo "create-pr: unknown remote host — cannot create MR"; exit 1
fi

if [[ -z "$PR" ]]; then echo "create-pr: could not parse PR number"; exit 1; fi

# Record - PR: #<n>
awk -v id="$ID" -v pr="$PR" '
  $0 ~ "^### " id "\\." {f=1}
  f && $0 ~ /^- PR:/ {print "- PR: #" pr; next}
  f && $0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\." {f=0}
  {print}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

echo "[create-pr] PR #$PR created for issue $ID (base=$BASE)"
