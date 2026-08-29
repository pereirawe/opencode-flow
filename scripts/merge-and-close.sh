#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: merge-and-close.sh <local_issue_id> [base_branch]
#
# Mechanical end-of-pipeline step for /ocf:develop-full (and /ocf:delivery after
# merge): once review + QA approved and the Committer gate passed (Status:
# in-publish), this script merges the MR, returns the local checkout to the
# updated base branch, and archives the issue via close_issue.sh.
#
# The orchestrating agent's only remaining value here is a short closing comment
# (optional, --comment or OCF_CLOSE_COMMENT). All heavy mechanics are scripted
# so no agent token budget is spent on merge/archive bookkeeping.
#
# Merge strategy: OCF_MERGE_STRATEGY (squash|merge|rebase), default squash.

ID=${1:-}
BASE_ARG=${2:-}
if [[ -z "$ID" ]]; then
  echo "Usage: merge-and-close.sh <id> [base_branch]"
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
    if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit
    print
  }
' "$FILE")
if [[ -z "$SECTION" ]]; then
  echo "Issue $ID not found"
  exit 1
fi

STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
PR_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- PR:/ {print $2; exit}')
PR_ID=${PR_REF#\#}
BASE_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Base branch:/ {print $2; exit}')
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

MERGE_STRATEGY="${OCF_MERGE_STRATEGY:-squash}"

if [[ "$STATUS" != "in-publish" ]]; then
  echo "Issue $ID status is '$STATUS' — expected 'in-publish' (approval gate passed)."
  echo "Refusing to merge/close an issue that has not been approved."
  exit 1
fi

BASE="$BASE_ARG"
if [[ -z "$BASE" && -n "$BASE_REF" && "$BASE_REF" != "-" ]]; then
  BASE="$BASE_REF"
fi
if [[ -z "$BASE" ]]; then
  BASE=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null \
      || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#.*/##' \
      || echo "main")
fi

if [[ -n "$PR_ID" && "$PR_ID" != "-" ]]; then
  echo "[merge] merging PR #$PR_ID (strategy=$MERGE_STRATEGY)"
  if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    gh pr merge "$PR_ID" --"$MERGE_STRATEGY" --delete-branch \
      || { echo "[merge] FAILED to merge PR #$PR_ID"; exit 1; }
  elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
    glab mr merge "$PR_ID" --"$MERGE_STRATEGY" --yes \
      || { echo "[merge] FAILED to merge MR #$PR_ID"; exit 1; }
  else
    echo "[merge] unknown remote host — cannot merge automatically"
    exit 1
  fi
else
  echo "[merge] no PR reference (PR: $PR_REF) — skipping merge"
fi

echo "[base] checking out $BASE and pulling origin"
git checkout "$BASE" >/dev/null 2>&1
git pull origin "$BASE"

echo "[close] archiving issue $ID (close_issue.sh)"
"$SCRIPTS_DIR/close_issue.sh" "$ID"

COMMENT="${OCF_CLOSE_COMMENT:-}"
if [[ -n "$COMMENT" ]]; then
  TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
  BODY="$(date +%Y-%m-%d) — merged & archived: ${TITLE} (#$ID)"
  if [[ "$REMOTE_URL" == *"github.com"* && -n "$PR_ID" && "$PR_ID" != "-" ]]; then
    gh pr comment "$PR_ID" --body "$BODY" 2>/dev/null \
      || gh issue comment "$PR_REF" --body "$BODY" 2>/dev/null \
      || echo "[comment] skipped (non-blocking)"
  elif [[ "$REMOTE_URL" == *"gitlab"* && -n "$PR_ID" && "$PR_ID" != "-" ]]; then
    glab mr note "$PR_ID" --message "$BODY" 2>/dev/null \
      || echo "[comment] skipped (non-blocking)"
  fi
fi

echo "[done] issue $ID merged, base synced, archived."
