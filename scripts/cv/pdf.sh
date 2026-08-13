#!/usr/bin/env bash
# Generate a PDF resume from an HTML file.
# Engine: Google Chrome headless --print-to-pdf (A4, margins).
# Fallback: LibreOffice (headless convert-to pdf) when Chrome is unavailable.
set -euo pipefail

# Usage: pdf.sh <input.html> <output.pdf> [<chrome|libreoffice>]
INPUT="${1:-}"
OUTPUT="${2:-}"
FORCE_ENGINE="${3:-}"

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Usage: pdf.sh <input.html> <output.pdf> [chrome|libreoffice]" >&2
  exit 2
fi

if [[ ! -f "$INPUT" ]]; then
  echo "error: input HTML not found: $INPUT" >&2
  exit 2
fi

INPUT_ABS="$(realpath "$INPUT")"
OUTPUT_ABS="$(realpath "$OUTPUT")"

render_chrome() {
  local chrome
  chrome="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
  if [[ -z "$chrome" ]]; then
    echo "error: Google Chrome not found (needed for HTML->PDF)" >&2
    return 1
  fi

  # Headless print-to-pdf: A4, no margins (content controls them via @page CSS),
  # prefer CSS page size when set.
  "$chrome" \
    --headless=new \
    --disable-gpu \
    --no-sandbox \
    --disable-dev-shm-usage \
    --print-to-pdf="$OUTPUT_ABS" \
    --print-to-pdf-no-header \
    --no-pdf-header-footer \
    "file://$INPUT_ABS" >/dev/null 2>&1

  if [[ ! -s "$OUTPUT_ABS" ]]; then
    echo "error: Chrome produced an empty PDF" >&2
    return 1
  fi
}

render_libreoffice() {
  local lo
  lo="$(command -v libreoffice || command -v soffice || true)"
  if [[ -z "$lo" ]]; then
    echo "error: LibreOffice not found (no fallback available)" >&2
    return 1
  fi

  local outdir
  outdir="$(dirname "$OUTPUT_ABS")"
  mkdir -p "$outdir"

  # LibreOffice converts to PDF into the same dir as the source.
  "$lo" --headless --convert-to pdf --outdir "$outdir" "$INPUT_ABS" >/dev/null 2>&1

  local generated="${INPUT_ABS%.html}.pdf"
  if [[ -f "$generated" ]]; then
    mv -f "$generated" "$OUTPUT_ABS"
  fi
  if [[ ! -s "$OUTPUT_ABS" ]]; then
    echo "error: LibreOffice produced an empty PDF" >&2
    return 1
  fi
}

if [[ "$FORCE_ENGINE" == "libreoffice" ]]; then
  render_libreoffice
elif [[ "$FORCE_ENGINE" == "chrome" ]]; then
  render_chrome
else
  if render_chrome; then
    :
  elif render_libreoffice; then
    :
  else
    echo "error: no PDF engine available" >&2
    exit 1
  fi
fi

echo "PDF generated: $OUTPUT_ABS"
