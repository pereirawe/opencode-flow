#!/usr/bin/env bash
set -euo pipefail

echo "[scan-issues] Running static scan..."

# Basic heuristics — extend patterns for your project language
PATTERN="TODO|FIXME|HACK|XXX|SECURITY|TODO|BUG|WORKAROUND"
TARGETS=(./src ./cmd ./internal ./.config ./*.go ./*.py ./*.js ./*.ts ./*.rs 2>/dev/null || true)

echo "[scan-issues] Searching risky patterns..."

if command -v rg >/dev/null 2>&1; then
  rg -n "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true
elif command -v grep >/dev/null 2>&1; then
  grep -RInE "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true
else
  echo "[scan-issues] no text search tool available"
fi

echo "[scan-issues] Done. Run /scan-issues in the assistant to update .config/opencode/known_issues.md"
