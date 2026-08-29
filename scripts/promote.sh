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

# --- Mode 1: backlog → ready ---
if [[ "$STATUS" == "backlog" ]]; then
  TODAY=$(date +%Y-%m-%dT%H:%M)
  # Stamp `- Ready:` (today, set-if-absent) alongside the status change (BR 2)
  rewrite_entry "$ISS_FILE" "$ID" "ready" "" "$TODAY" "" ""

  echo "[promote] Issue $ID promoted from backlog to ready"
  echo "[promote] Remote issue will be created during promotion (PM step) or by the next promoter."

  # Jira Cloud sync (issue #48): reflect backlog→ready on the card when Jira is
  # configured and a card exists. Non-blocking (BR 8): failures never fail.
  if "$SCRIPTS_DIR/sync-jira.sh" config >/dev/null 2>&1; then
    "$SCRIPTS_DIR/sync-jira.sh" transition "$ISS_FILE" "$ID" \
      || echo "[jira] Warning: status sync failed for issue $ID (non-blocking)"
  fi
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

  if [[ "$REMOTE" == "#local" ]]; then
    echo "[promote] ERROR: Issue $ID has Remote: #local — remote creation was skipped."
    echo "[promote] Re-run create_issue.sh before promoting."
    exit 1
  fi

  # Validate reviewer profiles (BR2)
  REVIEWERS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Reviewers:/ {print $2; exit}')
  VALID_PROFILES="backend data devops frontend mobile performance qa runtime security ux-ui"
  if [[ -n "$REVIEWERS" ]]; then
    if printf '%s\n' "$REVIEWERS" | grep -q '('; then
      PROFILES=$(printf '%s\n' "$REVIEWERS" | sed 's/.*(\(.*\))/\1/')
      for p in $(printf '%s\n' "$PROFILES" | tr ',' ' '); do
        p=$(printf '%s\n' "$p" | xargs)
        if [[ -n "$p" ]] && ! printf '%s\n' "$VALID_PROFILES" | tr ' ' '\n' | grep -qxF "$p"; then
          echo "[promote] ⚠️  WARNING: Unknown reviewer profile '$p' in issue $ID"
          echo "[promote]   Valid profiles: $VALID_PROFILES"
        fi
      done
    fi
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

  # Update status to in-progress (do NOT reset Remote); stamp Started and
  # backfill Opened set-if-absent (BR 2/BR 3 — documented approximation when
  # the remote was auto-created during promotion and has no Opened stamp yet)
  TODAY=$(date +%Y-%m-%dT%H:%M)
  rewrite_entry "$ISS_FILE" "$ID" "in-progress" "$TODAY" "" "$TODAY" ""

  # Jira Cloud sync (issue #48): reflect ready→in-progress on the card when
  # Jira is configured and a card exists. Non-blocking (BR 8).
  if "$SCRIPTS_DIR/sync-jira.sh" config >/dev/null 2>&1; then
    "$SCRIPTS_DIR/sync-jira.sh" transition "$ISS_FILE" "$ID" \
      || echo "[jira] Warning: status sync failed for issue $ID (non-blocking)"
  fi

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
    | (command -v iconv &>/dev/null && iconv -t ascii//TRANSLIT || cat) 2>/dev/null \
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
    git checkout "$BASE_BRANCH"
  else
    git checkout -b "$BASE_BRANCH" origin/"$BASE_BRANCH"
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
