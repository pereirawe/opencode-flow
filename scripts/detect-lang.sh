#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: detect-lang.sh [location]
#
# Replaces the develop-router agent for language routing. Mirrors
# agents/development/devs/REGISTRY.md matching (detect files > extensions >
# paths) and prints the subagent type to implement an issue:
#   development/devs/golang | development/devs/python | development/developer
#
# Optional [location] narrows the search to that path (e.g. issue Location:).

LOC="${1:-}"
REPO_ROOT="$(dirname "$PROJECT_ISSUES_DIR")"
cd "$REPO_ROOT" 2>/dev/null || true

score_golang=0
score_python=0

# --- Detect files (strongest) ---
[[ -f go.mod ]] && score_golang=$((score_golang+3))
[[ -f pyproject.toml || -f requirements.txt || -f setup.py || -f setup.cfg ]] && score_python=$((score_python+3))

# --- Detect extensions / paths via git ls-files (fallback to fs glob) ---
files_golang=0
files_python=0
if git rev-parse --git-dir >/dev/null 2>&1; then
  if [[ -n "$LOC" ]]; then
    files_golang=$(git ls-files -- "$LOC" 2>/dev/null | grep -cE '\.go$' || true)
    files_python=$(git ls-files -- "$LOC" 2>/dev/null | grep -cE '\.py$|\.pyi$' || true)
  else
    files_golang=$(git ls-files 2>/dev/null | grep -cE '\.go$' || true)
    files_python=$(git ls-files 2>/dev/null | grep -cE '\.py$|\.pyi$' || true)
  fi
else
  if [[ -n "$LOC" ]]; then
    files_golang=$(find "$LOC" -name '*.go' 2>/dev/null | wc -l || true)
    files_python=$(find "$LOC" -name '*.py' -o -name '*.pyi' 2>/dev/null | wc -l || true)
  fi
fi

score_golang=$((score_golang + files_golang))
score_python=$((score_python + files_python))

# --- Detect paths ---
case "$LOC" in
  cmd/*|internal/*) score_golang=$((score_golang+2)) ;;
  src/*|app/*|tests/*) score_python=$((score_python+2)) ;;
esac

if [[ -d cmd || -d internal ]]; then score_golang=$((score_golang+1)); fi
if [[ -d src || -d app || -d tests ]]; then score_python=$((score_python+1)); fi

if [[ $score_golang -ge $score_python && $score_golang -gt 0 ]]; then
  echo "development/devs/golang"
elif [[ $score_python -gt 0 ]]; then
  echo "development/devs/python"
else
  echo "development/developer"
fi
