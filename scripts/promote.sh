#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: $SCRIPTS_DIR/promote.sh <local_issue_id> [base_branch]

ID=${1:-}
BASE_BRANCH=${2:-}
if [[ -z "$ID" ]]; then
  echo "Usage: promote.sh <id> [base_branch]"
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

# --- Branch creation ---
if ! command -v git &>/dev/null; then
  echo "[promote] git not found, skipping branch creation"
  exit 0
fi

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
  echo "[promote] not a git repository, skipping branch creation"
  exit 0
fi

# Detect default branch if base branch not provided
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#refs/remotes/origin/##')
  if [[ -z "$BASE_BRANCH" ]]; then
    for candidate in main master; do
      if git show-ref --verify refs/heads/"$candidate" &>/dev/null 2>&1; then
        BASE_BRANCH="$candidate"
        break
      fi
    done
  fi
  if [[ -z "$BASE_BRANCH" ]]; then
    echo "[promote] could not detect base branch"
    exit 0
  fi
  echo "[promote] Base branch: $BASE_BRANCH (detected)"
else
  echo "[promote] Base branch: $BASE_BRANCH (specified)"
fi

# Generate slug from title
SLUG=$(printf '%s\n' "$TITLE" \
  | iconv -t ascii//TRANSLIT 2>/dev/null \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/--*/-/g' \
  | sed 's/^-//;s/-$//')

if [[ -z "$SLUG" ]]; then
  SLUG="issue-$ID"
fi

BRANCH="issue-$ID-$SLUG"

# Checkout base branch and pull
git fetch origin "$BASE_BRANCH" 2>/dev/null || git fetch origin 2>/dev/null || true
if git show-ref --verify refs/heads/"$BASE_BRANCH" &>/dev/null 2>&1; then
  git checkout "$BASE_BRANCH" 2>/dev/null
else
  git checkout -b "$BASE_BRANCH" origin/"$BASE_BRANCH" 2>/dev/null || true
fi
git pull origin "$BASE_BRANCH" 2>/dev/null || true

# Create feature branch
if git show-ref --verify refs/heads/"$BRANCH" &>/dev/null 2>&1; then
  echo "[promote] Branch '$BRANCH' already exists, checking it out"
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
  echo "[promote] Branch '$BRANCH' created from '$BASE_BRANCH'"
fi
