#!/usr/bin/env bash
set -euo pipefail

# format.sh — run the project's formatter (Prettier when configured, otherwise
# the default formatter for the project's stack) before commit/committer.
#
# Usage:
#   format.sh [--staged | --all] [--check]
#
#   --staged   format only staged files (default; used by scripts/pre_commit.sh)
#   --all      format every tracked file (git ls-files)
#   --check    do not write; exit non-zero when formatting is needed
#
# Detection (first matching formatter per file group, all groups are run):
#   - Prettier: available as `prettier` or `npx --no-install prettier`, applied
#     to js/jsx/ts/tsx/mjs/cjs/json/css/scss/less/md/yml/yaml/html/vue/svelte.
#     A project `.prettierrc*`/`prettier.config.*` is honoured automatically.
#   - Go:   `gofmt` on *.go
#   - Shell: `shfmt` on *.sh/*.bash
#   - Python: `ruff format` (preferred) or `black` on *.py
#
# Missing formatter binaries never fail the run: the group is skipped with a
# message and the script exits 0. Nothing is ever installed. node_modules/,
# vendor/, dist/, build/ and .git/ are never formatted.

usage() { echo "Usage: format.sh [--staged | --all] [--check]" >&2; }

MODE="staged"
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --staged) MODE="staged" ;;
    --all)    MODE="all" ;;
    --check)  CHECK=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; echo "[format] unknown flag: $1" >&2; exit 3 ;;
  esac
  shift
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[format] not a git repository — skipping"
  exit 0
fi
cd "$(git rev-parse --show-toplevel)"

if [ "$MODE" = "all" ]; then
  FILES="$(git ls-files 2>/dev/null || true)"
else
  FILES="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
fi

if [ -z "$FILES" ]; then
  echo "[format] no ${MODE} files — skipping"
  exit 0
fi

EXCLUDE_RE='(^|/)(node_modules|vendor|dist|build|\.git)/'

# select_ext "<space separated extensions>" — echoes candidate files.
select_ext() {
  local exts="$1" f ext e
  printf '%s\n' "$FILES" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    printf '%s' "$f" | grep -Eq "$EXCLUDE_RE" && continue
    ext="${f##*.}"
    for e in $exts; do
      if [ "$ext" = "$e" ]; then
        printf '%s\n' "$f"
        break
      fi
    done
  done
}

RAN=0
NEEDS=0

# --- Prettier ---------------------------------------------------------------
prettier_cmd=""
if command -v prettier >/dev/null 2>&1; then
  prettier_cmd="prettier"
elif command -v npx >/dev/null 2>&1 && npx --no-install prettier --version >/dev/null 2>&1; then
  prettier_cmd="npx --no-install prettier"
fi
if [ -n "$prettier_cmd" ]; then
  PF=()
  while IFS= read -r line; do [ -n "$line" ] && PF+=("$line"); done \
    < <(select_ext "js jsx ts tsx mjs cjs json css scss less md markdown yml yaml html htm vue svelte")
  if [ "${#PF[@]}" -gt 0 ]; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] prettier --check (${#PF[@]} file(s))"
      $prettier_cmd --check "${PF[@]}" || NEEDS=1
    else
      echo "[format] prettier --write (${#PF[@]} file(s))"
      $prettier_cmd --write "${PF[@]}" >/dev/null || echo "[format] prettier reported an error (continuing)"
    fi
  fi
fi

# --- Go (gofmt) -------------------------------------------------------------
if command -v gofmt >/dev/null 2>&1; then
  GF=()
  while IFS= read -r line; do [ -n "$line" ] && GF+=("$line"); done < <(select_ext "go")
  if [ "${#GF[@]}" -gt 0 ]; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] gofmt -l (${#GF[@]} file(s))"
      out="$(gofmt -l "${GF[@]}")" || true
      if [ -n "$out" ]; then NEEDS=1; printf '%s\n' "$out"; fi
    else
      echo "[format] gofmt -w (${#GF[@]} file(s))"
      gofmt -w "${GF[@]}"
    fi
  fi
fi

# --- Shell (shfmt) ----------------------------------------------------------
if command -v shfmt >/dev/null 2>&1; then
  SF=()
  while IFS= read -r line; do [ -n "$line" ] && SF+=("$line"); done < <(select_ext "sh bash")
  if [ "${#SF[@]}" -gt 0 ]; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] shfmt -d (${#SF[@]} file(s))"
      shfmt -d "${SF[@]}" >/dev/null 2>&1 || NEEDS=1
    else
      echo "[format] shfmt -w (${#SF[@]} file(s))"
      shfmt -w "${SF[@]}"
    fi
  fi
fi

# --- Python (ruff format, else black) ---------------------------------------
PY_FILES=()
while IFS= read -r line; do [ -n "$line" ] && PY_FILES+=("$line"); done < <(select_ext "py")
if [ "${#PY_FILES[@]}" -gt 0 ]; then
  if command -v ruff >/dev/null 2>&1; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] ruff format --check (${#PY_FILES[@]} file(s))"
      ruff format --check "${PY_FILES[@]}" >/dev/null 2>&1 || NEEDS=1
    else
      echo "[format] ruff format (${#PY_FILES[@]} file(s))"
      ruff format "${PY_FILES[@]}" >/dev/null
    fi
  elif command -v black >/dev/null 2>&1; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] black --check (${#PY_FILES[@]} file(s))"
      black --check "${PY_FILES[@]}" >/dev/null 2>&1 || NEEDS=1
    else
      echo "[format] black (${#PY_FILES[@]} file(s))"
      black "${PY_FILES[@]}" >/dev/null
    fi
  fi
fi

if [ "$RAN" -eq 0 ]; then
  echo "[format] no supported formatter found for ${MODE} files — skipping"
  exit 0
fi

if [ "$CHECK" -eq 1 ] && [ "$NEEDS" -eq 1 ]; then
  echo "[format] formatting changes needed — run scripts/format.sh --staged"
  exit 1
fi

echo "[format] ok"
exit 0
