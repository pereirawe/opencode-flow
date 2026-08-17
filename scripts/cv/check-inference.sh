#!/usr/bin/env bash
# Gate: ensure the final shareable resume artifact (HTML/PDF) contains no
# [INFERIDO] markers or the bare word "inferido" (case-insensitive).
#
# Internal analysis files (hub.json, analise-perfil.md, gap-analysis.md,
# inferences.md) MAY keep [INFERIDO]. The final HTML/PDF MUST NOT.
#
# Usage: check-inference.sh <file> [<file> ...]
#   - HTML: strips HTML/CSS comments (non-rendered, not part of the
#     shareable artifact) then greps the visible content for "inferido"
#     (case-insensitive).
#   - PDF: extracts text via pdftotext when available (best-effort); if
#     pdftotext is missing, the HTML gate is authoritative.
#
# Exit codes:
#   0  clean — no [INFERIDO] occurrences
#   1  blocked — occurrences found (listed to stderr)
#   2  usage/input error
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: check-inference.sh <file> [<file> ...]" >&2
  exit 2
fi

declare -a FILES=("$@")
OCCURRENCES=0

scan_text() {
  # $1 = file label, $2 = text to scan
  local label="$1" text="$2" matches
  if [[ -z "$text" ]]; then
    return 0
  fi
  matches="$(printf '%s\n' "$text" | grep -in "inferido" || true)"
  if [[ -n "$matches" ]]; then
    OCCURRENCES=$((OCCURRENCES + 1))
    echo "error: [INFERIDO] marker found in $label" >&2
    printf '%s\n' "$matches" | sed 's/^/  /' >&2
  fi
}

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "error: file not found: $f" >&2
    exit 2
  fi
  case "$f" in
    *.pdf|*.PDF)
      if command -v pdftotext >/dev/null 2>&1; then
        scan_text "$f" "$(pdftotext "$f" - 2>/dev/null || true)"
      fi
      ;;
    *)
      # Strip HTML and CSS comments: they are not rendered and must not trip
      # the gate (e.g. the template guard comment references the marker).
      scan_text "$f" "$(perl -0pe 's/<!--.*?-->//gs; s{/\*.*?\*/}{}gs' "$f" 2>/dev/null || cat "$f")"
      ;;
  esac
done

if [[ "$OCCURRENCES" -gt 0 ]]; then
  echo "error: [INFERIDO] blocked in $OCCURRENCES file(s) — remove/rephrase or get candidate approval before sharing" >&2
  exit 1
fi

echo "ok: no [INFERIDO] markers in the final artifact"
