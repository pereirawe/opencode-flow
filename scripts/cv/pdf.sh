#!/usr/bin/env bash
# Backward-compat wrapper: delegates to the shared HTML->PDF core.
#
# The rendering logic lives in scripts/shared/html-to-pdf.sh (issue #226).
# This wrapper exists solely so career consumers (cv-tailor, cv-cover-letter,
# cv-optimizer skills/commands) keep calling scripts/cv/pdf.sh unchanged.
# It adds NO logic: same CLI, same stdout, same exit codes (0/1/2) — it just
# forwards every argument and replicates the child's exit status.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$SCRIPT_DIR/../shared/html-to-pdf.sh"

if [[ ! -x "$CORE" ]]; then
  if [[ -f "$CORE" ]]; then
    bash "$CORE" "$@"
    exit $?
  fi
  echo "error: shared HTML->PDF core not found: $CORE" >&2
  exit 1
fi

exec "$CORE" "$@"
