#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "[pre-commit] Running checks..."

# Run tests (detect language runner automatically)
if command -v go >/dev/null 2>&1 && [ -f go.mod ]; then
  go test ./... || { echo "Go tests failed"; exit 1; }
elif command -v cargo >/dev/null 2>&1 && [ -f Cargo.toml ]; then
  cargo test || { echo "Rust tests failed"; exit 1; }
elif command -v npm >/dev/null 2>&1 && [ -f package.json ]; then
  npm test 2>/dev/null || npm run test 2>/dev/null || echo "[pre-commit] No npm test script found"
elif command -v pytest >/dev/null 2>&1; then
  pytest || echo "[pre-commit] pytest not configured"
else
  echo "[pre-commit] No test runner detected — skipping tests"
fi

# Parse commit message for trailers
COMMIT_MSG_FILE="${1:-}"
if [[ -n "$COMMIT_MSG_FILE" && -f "$COMMIT_MSG_FILE" ]]; then
  COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
else
  COMMIT_MSG=$(git log -1 --pretty=format:"%B" 2>/dev/null || true)
fi

if [[ -n "$COMMIT_MSG" ]]; then
  echo "[pre-commit] Checking commit trailers..."

  STATUS_FLAG=$(printf '%s\n' "$COMMIT_MSG" | grep -E '^Status:\s*(in-progress|resolved)$' | head -1 || true)
  REMOTE_FLAG=$(printf '%s\n' "$COMMIT_MSG" | grep -E '^Remote:\s*#' | head -1 || true)
  CLOSES_FLAG=$(printf '%s\n' "$COMMIT_MSG" | grep -E '^Closes\s+#[0-9]+' | head -1 || true)
  ISSUE_REF=$(printf '%s\n' "$COMMIT_MSG" | grep -Eo '\(#[0-9]+\)' | grep -Eo '[0-9]+' | head -1 || true)

  if [[ -n "$ISSUE_REF" ]]; then
    echo "[pre-commit] Issue reference found: #${ISSUE_REF}"

    if [[ -n "$STATUS_FLAG" ]]; then
      STATUS_VAL=$(printf '%s\n' "$STATUS_FLAG" | awk '{print $2}')
      echo "[pre-commit] Status trailer: ${STATUS_VAL}"

      # Check if we have a known_issues.md to update
      if [[ -f "$PROJECT_ISSUES_FILE" ]]; then
        CURRENT_STATUS=$(awk -v id="$ISSUE_REF" '
          $0 ~ "^### " id "\\." {found=1}
          found && $0 ~ /^- Status:/ {print $2; exit}
        ' "$PROJECT_ISSUES_FILE" 2>/dev/null || echo "")

        if [[ -n "$CURRENT_STATUS" ]]; then
          echo "[pre-commit] Issue #${ISSUE_REF} current status: ${CURRENT_STATUS}"
        fi
      fi
    fi

    if [[ -n "$CLOSES_FLAG" ]]; then
      echo "[pre-commit] Closes flag detected — will archive issue #$(printf '%s\n' "$CLOSES_FLAG" | grep -Eo '[0-9]+')"
    fi
  else
    echo "[pre-commit] No issue reference found in commit message"
  fi
fi

# Check for issues without a remote issue
if [[ -f "$PROJECT_ISSUES_FILE" ]]; then
  MISSING_REMOTE=$(awk '
    /^### [0-9]+\./ {
      if ((status_open || status_ready) && remote_dash) print detected_id
      if ((status_open || status_ready) && remote_error) print detected_id " (error)"
      detected_id = $2; gsub(/\./, "", detected_id)
      status_open = 0; status_ready = 0; remote_dash = 0; remote_error = 0
    }
    detected_id != "" && /^- Status:/ {
      if ($3 == "open") status_open = 1
      if ($3 == "ready") status_ready = 1
    }
    detected_id != "" && /^- Remote:/ {
      if ($3 == "-") remote_dash = 1
      if ($3 ~ /^error:/) remote_error = 1
    }
    END {
      if ((status_open || status_ready) && remote_dash) print detected_id
      if ((status_open || status_ready) && remote_error) print detected_id " (error)"
    }
  ' "$PROJECT_ISSUES_FILE" 2>/dev/null || true)

  if [[ -n "$MISSING_REMOTE" ]]; then
    echo "[pre-commit] ⚠️  WARNING: Issue(s) with no valid Remote: $MISSING_REMOTE"
    echo "[pre-commit]   Create a remote issue before starting development."
  fi
fi

# Ensure known_issues was considered
if git diff --cached --name-only 2>/dev/null | grep -q "known_issues.md"; then
  echo "[pre-commit] $PROJECT_ISSUES_FILE was updated"
else
  echo "[pre-commit] WARNING: $PROJECT_ISSUES_FILE was not updated — update it if this change affects the project"
fi

echo "[pre-commit] OK"
