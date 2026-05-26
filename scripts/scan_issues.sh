#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "[scan-issues] Running static scan..."

# Basic heuristics — extend patterns for your project language
PATTERN="TODO|FIXME|HACK|XXX|SECURITY|TODO|BUG|WORKAROUND"
TARGETS=()
for glob in ./src ./cmd ./internal ./*.go ./*.py ./*.js ./*.ts ./*.rs; do
  [ -e "$glob" ] || [ -L "$glob" ] && TARGETS+=("$glob")
done

echo "[scan-issues] Searching risky patterns..."

if command -v rg >/dev/null 2>&1; then
  rg -n "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true
elif command -v grep >/dev/null 2>&1; then
  grep -RInE "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true
else
  echo "[scan-issues] no text search tool available"
fi

echo "[scan-issues] Done. Run /ocf:scan-issues in the assistant to update $PROJECT_ISSUES_FILE"
