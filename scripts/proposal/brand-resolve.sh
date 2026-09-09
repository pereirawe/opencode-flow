#!/usr/bin/env bash
# brand-resolve.sh — resolve the proposing company's brand assets (logo +
# company.json) for the Proposal Design Standard (standards/proposal-design.md).
#
# Resolution order (MUST, per the standard) — WHOLE-TIER fallback, never
# cross-joined piece by piece (mixing tiers could pair one company's logo with
# another company's company.json):
#   1) <project>/docs/assets/ (logo.* + company.json)
#   2) ~/.config/opencode/assets/ (logo.* + company.json)
#   3) legacy compat: docs/specs/<slug>/assets/logo.* (spec-local copy) — never
#      primary; reported only when the first two are absent.
#
# Usage:
#   scripts/proposal/brand-resolve.sh [--project-dir <dir>]
#   (default project dir = $PWD)
#
# Output (absolute paths, `key=value` lines):
#   logo=<abs path or ->
#   company_json=<abs path or ->
#   source=<project|global|legacy-spec|none>
#   brand=<full|logo-only|company-only|none>
#
# Exit code:
#   0 — brand found (logo and/or company.json)
#   1 — no brand anywhere
set -euo pipefail

PROJECT_DIR="${PWD}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      if [[ $# -lt 2 ]]; then
        echo "error: --project-dir requires a value" >&2
        echo "Usage: brand-resolve.sh [--project-dir <dir>]" >&2
        exit 2
      fi
      PROJECT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: brand-resolve.sh [--project-dir <dir>]"
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "error: project dir not found: $PROJECT_DIR" >&2
  exit 2
fi

GLOBAL_DIR="$HOME/.config/opencode/assets"

find_logo() { # <base_dir>
  local base="$1" ext f
  for ext in svg png jpg jpeg webp; do
    f="$base/logo.$ext"
    if [[ -f "$f" ]]; then
      printf '%s' "$f"
      return 0
    fi
  done
  return 1
}

find_company_json() { # <base_dir>
  local base="$1" f
  f="$base/company.json"
  if [[ -f "$f" ]]; then
    printf '%s' "$f"
    return 0
  fi
  return 1
}

LOGO=""
COMPANY=""
SOURCE="none"

# Tier model (whole-tier fallback — NEVER cross-join tiers): resolve assets
# from the FIRST tier that contributes anything. A project that only has a
# logo does NOT pull the global company.json in: mixing tiers could pair one
# company's logo with another company's data.
resolve_tier() { # <label> <base_dir>  — fills LOGO/COMPANY/SOURCE if tier yields anything
  local label="$1" base="$2" l c
  l="$(find_logo "$base" || true)"
  c="$(find_company_json "$base" || true)"
  if [[ -n "$l" || -n "$c" ]]; then
    LOGO="$l"
    COMPANY="$c"
    SOURCE="$label"
    return 0
  fi
  return 1
}

# 1) project brand (preferred)
resolve_tier "project" "$PROJECT_DIR/docs/assets" \
  || resolve_tier "global" "$GLOBAL_DIR" \
  || {
       # 3) legacy spec-local logo (last resort)
       LEGACY="$(find "$PROJECT_DIR/docs/specs" -path '*/assets/logo.*' 2>/dev/null | head -n 1 || true)"
       if [[ -n "$LEGACY" ]]; then
         LOGO="$LEGACY"
         SOURCE="legacy-spec"
       fi
     }

if [[ -n "$LOGO" && -n "$COMPANY" ]]; then
  BRAND="full"
elif [[ -n "$LOGO" ]]; then
  BRAND="logo-only"
elif [[ -n "$COMPANY" ]]; then
  BRAND="company-only"
else
  BRAND="none"
  SOURCE="none"
fi

printf 'logo=%s\n' "${LOGO:--}"
printf 'company_json=%s\n' "${COMPANY:--}"
printf 'source=%s\n' "$SOURCE"
printf 'brand=%s\n' "$BRAND"

if [[ "$BRAND" == "none" ]]; then
  exit 1
fi
exit 0
