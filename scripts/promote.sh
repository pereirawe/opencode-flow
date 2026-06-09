#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: $SCRIPTS_DIR/promote.sh <local_issue_id>
# Reads Base branch, Reviewers, and Remote from known_issues.md
# backlog → ready: just status change (no branch, Tech Lead creates remote separately)
# ready → in-progress: reads Base branch, creates feature branch, no user interaction

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: promote.sh <id>"
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
REMOTE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Remote:/ {print $2; exit}')
BASE_BRANCH=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Base branch:/ {print $2; exit}')

# --- Mode 1: backlog → ready ---
if [[ "$STATUS" == "backlog" ]]; then
  awk -v id="$ID" '
    BEGIN{found=0}
    /^### [0-9]+\./ {
      if (found == 1 && $0 !~ "^### " id "\\.") { found=0 }
    }
    $0 ~ "^### " id "\\." {found=1}
    {
      if (found == 1 && $0 ~ /^- Status:/) { print "- Status: ready"; next }
      print
    }
  ' "$ISS_FILE" > "$ISS_FILE.tmp" && mv "$ISS_FILE.tmp" "$ISS_FILE"

  echo "[promote] Issue $ID promoted from backlog to ready"
  echo "[promote] Tech Lead should now create remote issue via create_issue.sh"
  exit 0
fi

# --- Mode 2: ready → in-progress ---
if [[ "$STATUS" == "ready" ]]; then
  # Validate Remote is populated
  if [[ -z "$REMOTE" || "$REMOTE" == "-" ]]; then
    echo "[promote] ERROR: Issue $ID has Remote: - but must be populated before promotion to in-progress"
    echo "[promote] Run create_issue.sh first, or set Remote: #<id> manually."
    exit 1
  fi

  if [[ "$REMOTE" == error:* ]]; then
    echo "[promote] ERROR: Issue $ID has Remote: $REMOTE — remote creation failed previously."
    echo "[promote] Re-run create_issue.sh before promoting."
    exit 1
  fi

  # Read Base branch from field, with fallback
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
      echo "[promote] ERROR: could not detect base branch and no Base branch field in issue"
      exit 1
    fi
    echo "[promote] Base branch: $BASE_BRANCH (detected)"
  else
    echo "[promote] Base branch: $BASE_BRANCH (from issue field)"
  fi

  # Update status to in-progress (do NOT reset Remote)
  awk -v id="$ID" '
    BEGIN{found=0}
    /^### [0-9]+\./ {
      if (found == 1 && $0 !~ "^### " id "\\.") { found=0 }
    }
    $0 ~ "^### " id "\\." {found=1}
    {
      if (found == 1 && $0 ~ /^- Status:/) { print "- Status: in-progress"; next }
      print
    }
  ' "$ISS_FILE" > "$ISS_FILE.tmp" && mv "$ISS_FILE.tmp" "$ISS_FILE"

  echo "[promote] Issue $ID promoted from ready to in-progress"
  echo "[promote] Title: $TITLE"
  echo "[promote] Remote: $REMOTE"

  # --- Branch creation ---
  if ! command -v git &>/dev/null; then
    echo "[promote] git not found, skipping branch creation"
    exit 0
  fi
  if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    echo "[promote] not a git repository, skipping branch creation"
    exit 0
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
  exit 0
fi

echo "Issue $ID cannot be promoted from status '$STATUS'"
exit 1
