#!/usr/bin/env bash
# spec-init.sh — bootstrap a tech-spec workspace under docs/specs/<slug>/
#
# Usage:
#   scripts/spec-init.sh <slug>
#
# Creates:
#   docs/specs/<slug>/
#   docs/specs/<slug>/assets/
#   docs/specs/<slug>/assets/logo.<ext>   (copied from first available source)
#
# Logo resolution order:
#   1) $PWD/docs/assets/logo.{svg,png,jpg,jpeg,webp}
#   2) ~/.config/opencode/assets/logo.{svg,png,jpg,jpeg,webp}
#
# If no logo is found, writes a placeholder text file and exits 0 with a
# warning — the agent decides how to proceed.

set -euo pipefail

SLUG="${1:-}"
if [[ -z "$SLUG" ]]; then
  echo "usage: spec-init.sh <slug>" >&2
  exit 2
fi

# Sanitize slug: lowercase, alnum + dash only
SLUG_CLEAN="$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')"
if [[ -z "$SLUG_CLEAN" ]]; then
  echo "error: slug produced empty string after sanitization" >&2
  exit 2
fi

TARGET_DIR="docs/specs/${SLUG_CLEAN}"
ASSETS_DIR="${TARGET_DIR}/assets"

mkdir -p "$ASSETS_DIR"

find_logo() {
  local base
  for base in "docs/assets" "$HOME/.config/opencode/assets"; do
    for ext in svg png jpg jpeg webp; do
      if [[ -f "$base/logo.$ext" ]]; then
        echo "$base/logo.$ext"
        return 0
      fi
    done
  done
  return 1
}

if LOGO_SRC="$(find_logo)"; then
  LOGO_EXT="${LOGO_SRC##*.}"
  LOGO_DEST="${ASSETS_DIR}/logo.${LOGO_EXT}"
  cp "$LOGO_SRC" "$LOGO_DEST"
  echo "logo: copied $LOGO_SRC -> $LOGO_DEST"
  echo "relative: ./assets/logo.${LOGO_EXT}"
else
  PLACEHOLDER="${ASSETS_DIR}/LOGO_MISSING.txt"
  cat > "$PLACEHOLDER" <<EOF
No logo was found. Place your company logo at one of:

  docs/assets/logo.{svg,png,jpg,jpeg,webp}
  ~/.config/opencode/assets/logo.{svg,png,jpg,jpeg,webp}

Then re-run: scripts/spec-init.sh ${SLUG_CLEAN}
EOF
  echo "warning: no logo found — placeholder written to $PLACEHOLDER" >&2
  echo "relative: (missing)"
fi

echo "target: $TARGET_DIR"
