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

# Ensure the output directory exists before resolving it (realpath fails on
# missing dirs, and Chrome won't create the parent).
OUTPUT_DIR_RAW="$(dirname "$OUTPUT")"
if [[ ! -d "$OUTPUT_DIR_RAW" ]]; then
  mkdir -p "$OUTPUT_DIR_RAW" || { echo "error: cannot create output directory: $OUTPUT_DIR_RAW" >&2; exit 2; }
fi
if ! OUTPUT_DIR="$(realpath "$OUTPUT_DIR_RAW")"; then
  echo "error: cannot resolve output directory: $OUTPUT_DIR_RAW" >&2
  exit 2
fi
OUTPUT_ABS="$OUTPUT_DIR/$(basename "$OUTPUT")"

# Build a URL-encoded file:// URL so paths with spaces / non-ASCII names work.
file_url() {
  local path="$1"
  local encoded=""
  local i c
  for ((i = 0; i < ${#path}; i++)); do
    c="${path:$i:1}"
    case "$c" in
      [a-zA-Z0-9/_.~-]) encoded+="$c" ;;
      *) printf -v esc '%%%02X' "'$c"; encoded+="$esc" ;;
    esac
  done
  printf 'file://%s' "$encoded"
}

render_chrome() {
  local chrome
  chrome="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
  if [[ -z "$chrome" ]]; then
    echo "error: Google Chrome not found (needed for HTML->PDF)" >&2
    return 1
  fi

  # Headless print-to-pdf: A4, no margins (content controls them via @page CSS),
  # prefer CSS page size when set.
  local url
  url="$(file_url "$INPUT_ABS")"
  "$chrome" \
    --headless=new \
    --disable-gpu \
    --no-sandbox \
    --disable-dev-shm-usage \
    --print-to-pdf="$OUTPUT_ABS" \
    --print-to-pdf-no-header \
    "$url" >/dev/null 2>&1

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

  local outdir stem generated
  outdir="$OUTPUT_DIR"
  mkdir -p "$outdir"
  stem="$(basename "$INPUT_ABS")"
  stem="${stem%.*}"

  # LibreOffice converts to PDF into the same dir as the source — convert into
  # a copy placed in the output dir so the generated PDF lands next to OUTPUT.
  cp "$INPUT_ABS" "$outdir/$stem.html"

  "$lo" --headless --convert-to pdf --outdir "$outdir" "$outdir/$stem.html" >/dev/null 2>&1

  generated="$outdir/$stem.pdf"
  if [[ -f "$generated" ]]; then
    mv -f "$generated" "$OUTPUT_ABS"
  fi
  rm -f "$outdir/$stem.html"
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
