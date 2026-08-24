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

# Gate: reject corrupted input encoding BEFORE rendering. A NUL byte or an
# invalid UTF-8 sequence in the HTML renders as "�" (replacement char) in the
# PDF — e.g. the "·" separator (UTF-8 C2 B7) corrupted to "\x00b7" renders as
# "�b7". Refuse to render so the corruption can never silently ship.
check_encoding() {
  if ! iconv -f UTF-8 -t UTF-8 "$INPUT_ABS" >/dev/null 2>&1; then
    echo "error: input HTML is not valid UTF-8 (corrupted byte sequences) — fix the encoding before generating the PDF" >&2
    return 1
  fi
  if perl -0777 -ne 'exit 1 if /\x00/' "$INPUT_ABS"; then
    return 0
  fi
  echo "error: input HTML contains NUL bytes (corrupted characters, e.g. the '·' separator) — fix before generating the PDF" >&2
  perl -0777 -ne '$n = () = /\x00/g; print "  $n NUL byte(s) found\n"' "$INPUT_ABS" >&2
  return 1
}
check_encoding || exit 1

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
# LC_ALL=C makes ${#path} and substring indexing operate on BYTES, so each
# byte of a UTF-8 char is percent-encoded (%C3%A9), not the Unicode codepoint
# (%E9) — Chrome requires the former.
file_url() {
  local LC_ALL=C
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
    --no-pdf-header-footer \
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
  # Guard the copy/move: when the input already lives in the output dir (the
  # documented same-dir invocation) or basenames collide, `cp`/`mv` would fail
  # with "same file".
  local src_in_outdir=""
  if [[ "$INPUT_ABS" == "$outdir/$stem.html" ]]; then
    src_in_outdir=1
  fi
  if [[ -z "$src_in_outdir" ]]; then
    cp "$INPUT_ABS" "$outdir/$stem.html"
  fi

  "$lo" --headless --convert-to pdf --outdir "$outdir" "$outdir/$stem.html" >/dev/null 2>&1

  generated="$outdir/$stem.pdf"
  if [[ -f "$generated" ]]; then
    if [[ "$generated" != "$OUTPUT_ABS" ]]; then
      mv -f "$generated" "$OUTPUT_ABS"
    fi
  fi
  if [[ -z "$src_in_outdir" ]]; then
    rm -f "$outdir/$stem.html"
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
