#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# sync_github_issues.sh — Synchronize resolved known_issues with GitHub/GitLab
#
# Scans known_issues.md for issues with Status: resolved or in-publish where
# the remote issue (#<id>) is still open on GitHub/GitLab, and closes them.
#
# Usage:
#   sync_github_issues.sh                    # checks project issues (CWD)
#   sync_github_issues.sh --global           # checks global issues instead
#   sync_github_issues.sh --dry-run          # preview only, no changes
#   sync_github_issues.sh --all              # check both global and project

DRY_RUN=false
CHECK_GLOBAL=false
CHECK_PROJECT=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --global) CHECK_GLOBAL=true; CHECK_PROJECT=false ;;
    --all) CHECK_GLOBAL=true ;;
  esac
done

REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [[ -z "$REMOTE_URL" ]]; then
  echo "[!] No git remote found in CWD"
fi

check_file() {
  local file="$1"
  local label="$2"

  if [[ ! -f "$file" ]]; then
    echo "[skip] $label: file not found ($file)"
    return
  fi

  echo "=== Scanning $label: $file ==="

  # Parse each issue section
  awk '
  BEGIN { id=""; remote=""; pr=""; status=""; title="" }
  /^### / {
    if (id != "" && remote != "" && remote != "-") {
      print id, remote, status, pr, title
    }
    id = $2
    sub(/\\.$/, "", id)
    title = substr($0, index($0, " ")+1)
    sub(/^[^ ]+ +/, "", title)
    remote = ""
    pr = ""
    status = ""
  }
  /^- Remote:/ { remote = substr($0, index($0, ":")+2) }
  /^- PR:/ { pr = substr($0, index($0, ":")+2) }
  /^- Status:/ { status = substr($0, index($0, ":")+2) }
  END {
    if (id != "" && remote != "" && remote != "-") {
      print id, remote, status, pr, title
    }
  }
  ' "$file" | while read -r id remote status pr title; do
    REMOTE_ID="${remote#\#}"
    PR_ID="${pr#\#}"

    echo ""
    echo "--- $id ($title) ---"
    echo "  Status: $status"
    echo "  Remote: $remote"
    echo "  PR:     $pr"

    # Determine if we should close the remote issue
    SHOULD_CLOSE=false
    REASON=""

    case "$status" in
      "resolved")
        if [[ -n "$REMOTE_ID" && "$REMOTE_ID" != "-" ]]; then
          if [[ "$REMOTE_URL" == *"github.com"* ]]; then
            ISSUE_STATE=$(gh issue view "$REMOTE_ID" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
            echo "  GitHub issue state: $ISSUE_STATE"
            if [[ "$ISSUE_STATE" == "OPEN" ]]; then
              SHOULD_CLOSE=true
              REASON="GitHub issue #$REMOTE_ID is OPEN but local status is resolved"
            fi
          elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
            ISSUE_STATE=$(glab issue view "$REMOTE_ID" 2>/dev/null | head -5 || echo "")
            echo "  GitLab issue state: $(echo "$ISSUE_STATE" | grep -i state || echo "unknown")"
          fi
        fi
        ;;
      "in-publish")
        if [[ -n "$REMOTE_ID" && "$REMOTE_ID" != "-" ]]; then
          # Only close if PR is merged
          PR_MERGED=false
          if [[ -n "$PR_ID" && "$PR_ID" != "-" ]]; then
            if [[ "$REMOTE_URL" == *"github.com"* ]]; then
              PR_STATE=$(gh pr view "$PR_ID" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
              echo "  PR #$PR_ID state: $PR_STATE"
              if [[ "$PR_STATE" == "MERGED" ]]; then
                PR_MERGED=true
              fi
            fi
          fi
          if $PR_MERGED; then
            ISSUE_STATE=$(gh issue view "$REMOTE_ID" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
            echo "  GitHub issue state: $ISSUE_STATE"
            if [[ "$ISSUE_STATE" == "OPEN" ]]; then
              SHOULD_CLOSE=true
              REASON="PR #$PR_ID merged, local status is in-publish, GitHub issue still OPEN"
            fi
          else
            echo "  PR not merged yet — skipping remote close"
          fi
        fi
        ;;
      *)
        echo "  Status '$status' — skipping"
        ;;
    esac

    if $SHOULD_CLOSE; then
      echo "  [action] $REASON"
      if $DRY_RUN; then
        echo "  [dry-run] Would close remote issue #$REMOTE_ID"
      else
        if [[ "$REMOTE_URL" == *"github.com"* ]]; then
          echo "  Closing GitHub issue #$REMOTE_ID..."
          gh issue close "$REMOTE_ID" && echo "  ✓ Closed #$REMOTE_ID" || echo "  ✗ Failed to close #$REMOTE_ID"
        elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
          echo "  Closing GitLab issue #$REMOTE_ID..."
          glab issue close "$REMOTE_ID" && echo "  ✓ Closed #$REMOTE_ID" || echo "  ✗ Failed to close #$REMOTE_ID"
        fi
      fi
    fi
  done

  echo ""
  echo "=== Done: $label ==="
}

if $CHECK_GLOBAL; then
  check_file "$ISSUES_FILE" "Global Config Issues"
fi

if $CHECK_PROJECT; then
  if [[ -f ".opencode/known_issues.md" ]]; then
    check_file "$(pwd -P)/.opencode/known_issues.md" "Project Issues ($(basename "$(pwd -P)"))"
  else
    echo "[skip] No project .opencode/known_issues.md found in CWD"
  fi
fi

echo ""
echo "Sync complete."
