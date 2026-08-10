#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "[scan-issues] Running static scan..."

PATTERN="TODO|FIXME|HACK|XXX|SECURITY|BUG|WORKAROUND"
TARGETS=()
for glob in ./src ./cmd ./internal ./scripts ./*.go ./*.py ./*.js ./*.ts ./*.rs; do
  [ -e "$glob" ] || [ -L "$glob" ] && TARGETS+=("$glob")
done

if [ -f ".opencode/scan-patterns" ]; then
  echo "[scan-issues] Loading custom scan patterns from .opencode/scan-patterns"
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    for glob in $line; do
      [ -e "$glob" ] || [ -L "$glob" ] && TARGETS+=("$glob")
    done
  done < ".opencode/scan-patterns"
fi

echo "[scan-issues] Searching risky patterns..."

if command -v rg >/dev/null 2>&1; then
  rg -n "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true
elif command -v grep >/dev/null 2>&1; then
  grep -RInE "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true
else
  echo "[scan-issues] no text search tool available"
fi

echo "[scan-issues] Done. Run /ocf:scan-issues in the assistant to update $PROJECT_ISSUES_FILE"
