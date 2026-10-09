#!/usr/bin/env bash
set -euo pipefail

# format.sh — run the project's formatter (Prettier when the project configures
# it, otherwise the default formatter for the project's stack) before
# commit/committer.
#
# Usage:
#   format.sh [--staged | --all | --diff <range>] [--check]
#
#   --staged        format only staged files (default; used by pre_commit.sh)
#   --all           format every tracked file (git ls-files)
#   --diff <range>  format files changed in a git range, e.g. main...HEAD
#   --check         do not write; exit non-zero when formatting is needed
#
# Detection (each group runs only when its tool is available):
#   - Prettier: only when the project opts in (.prettierrc*, prettier.config.*,
#     or a `prettier` key/dependency in package.json). Prefers the project-local
#     `npx --no-install prettier`, falling back to a `prettier` on PATH.
#   - Go:   `gofmt` on *.go
#   - Shell: `shfmt` on *.sh/*.bash
#   - Python: `ruff format` (preferred) or `black` on *.py
#
# Missing formatter binaries never fail the run: the group is skipped with a
# message and the script exits 0. Nothing is ever installed. node_modules/,
# vendor/, dist/, build/ and .git/ are never formatted.

usage() { echo "Usage: format.sh [--staged | --all | --diff <range>] [--check]" >&2; }

MODE="staged"
RANGE=""
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --staged) MODE="staged" ;;
    --all)    MODE="all" ;;
    --diff)
      [ $# -ge 2 ] || { usage; echo "[format] --diff requires a range" >&2; exit 3; }
      MODE="diff"; RANGE="$2"; shift ;;
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

case "$MODE" in
  all)  FILES="$(git ls-files 2>/dev/null || true)" ;;
  diff) FILES="$(git diff --name-only --diff-filter=ACMR "$RANGE" 2>/dev/null || true)" ;;
  *)    FILES="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)" ;;
esac

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

# has_prettier_config — true when the project opts into Prettier.
has_prettier_config() {
  compgen -G ".prettierrc*" >/dev/null 2>&1 && return 0
  compgen -G "prettier.config.*" >/dev/null 2>&1 && return 0
  [ -f package.json ] && grep -Eq '"prettier"' package.json && return 0
  return 1
}

RAN=0
NEEDS=0
HAVE_TOOL=0

# --- Prettier ---------------------------------------------------------------
prettier_cmd=""
if has_prettier_config; then
  if command -v npx >/dev/null 2>&1 && npx --no-install prettier --version >/dev/null 2>&1; then
    prettier_cmd="npx --no-install prettier"
  elif command -v prettier >/dev/null 2>&1; then
    prettier_cmd="prettier"
  fi
fi
if [ -n "$prettier_cmd" ]; then
  HAVE_TOOL=1
  PF=()
  while IFS= read -r line; do [ -n "$line" ] && PF+=("$line"); done \
    < <(select_ext "js jsx ts tsx mjs cjs json css scss less md markdown yml yaml html htm vue svelte")
  if [ "${#PF[@]}" -gt 0 ]; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] prettier --check (${#PF[@]} file(s))"
      rc=0; $prettier_cmd --check "${PF[@]}" >/dev/null 2>&1 || rc=$?
      if [ "$rc" -eq 1 ]; then NEEDS=1
      elif [ "$rc" -ne 0 ]; then echo "[format] prettier skipped (no matching files)"; fi
    else
      echo "[format] prettier --write (${#PF[@]} file(s))"
      $prettier_cmd --write "${PF[@]}" >/dev/null || echo "[format] prettier reported an error (continuing)"
    fi
  fi
fi

# --- Go (gofmt) -------------------------------------------------------------
if command -v gofmt >/dev/null 2>&1; then
  HAVE_TOOL=1
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
      gofmt -w "${GF[@]}" || echo "[format] gofmt reported an error (continuing)"
    fi
  fi
fi

# --- Shell (shfmt) ----------------------------------------------------------
if command -v shfmt >/dev/null 2>&1; then
  HAVE_TOOL=1
  SF=()
  while IFS= read -r line; do [ -n "$line" ] && SF+=("$line"); done < <(select_ext "sh bash")
  if [ "${#SF[@]}" -gt 0 ]; then
    RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] shfmt -d (${#SF[@]} file(s))"
      shfmt -d "${SF[@]}" >/dev/null 2>&1 || NEEDS=1
    else
      echo "[format] shfmt -w (${#SF[@]} file(s))"
      shfmt -w "${SF[@]}" || echo "[format] shfmt reported an error (continuing)"
    fi
  fi
fi

# --- Python (ruff format, else black) ---------------------------------------
PY_FILES=()
while IFS= read -r line; do [ -n "$line" ] && PY_FILES+=("$line"); done < <(select_ext "py")
if [ "${#PY_FILES[@]}" -gt 0 ]; then
  if command -v ruff >/dev/null 2>&1; then
    HAVE_TOOL=1; RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] ruff format --check (${#PY_FILES[@]} file(s))"
      ruff format --check "${PY_FILES[@]}" >/dev/null 2>&1 || NEEDS=1
    else
      echo "[format] ruff format (${#PY_FILES[@]} file(s))"
      ruff format "${PY_FILES[@]}" >/dev/null || echo "[format] ruff reported an error (continuing)"
    fi
  elif command -v black >/dev/null 2>&1; then
    HAVE_TOOL=1; RAN=1
    if [ "$CHECK" -eq 1 ]; then
      echo "[format] black --check (${#PY_FILES[@]} file(s))"
      black --check "${PY_FILES[@]}" >/dev/null 2>&1 || NEEDS=1
    else
      echo "[format] black (${#PY_FILES[@]} file(s))"
      black "${PY_FILES[@]}" >/dev/null || echo "[format] black reported an error (continuing)"
    fi
  fi
fi

if [ "$RAN" -eq 0 ]; then
  if [ "$HAVE_TOOL" -eq 1 ]; then
    echo "[format] no eligible ${MODE} files for the available formatter(s) — skipping"
  else
    echo "[format] no supported formatter found for ${MODE} files — skipping"
  fi
  exit 0
fi

if [ "$CHECK" -eq 1 ] && [ "$NEEDS" -eq 1 ]; then
  echo "[format] formatting changes needed — run scripts/format.sh --staged"
  exit 1
fi

echo "[format] ok"
exit 0
