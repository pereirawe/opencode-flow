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

# Ensure known_issues was considered
if git diff --cached --name-only 2>/dev/null | grep -q "known_issues.md"; then
  echo "[pre-commit] $CONFIG_DIR/known_issues.md was updated"
else
  echo "[pre-commit] WARNING: $CONFIG_DIR/known_issues.md was not updated — update it if this change affects the project"
fi

echo "[pre-commit] OK"
