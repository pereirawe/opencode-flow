#!/usr/bin/env bash
# Deterministic Excalidraw -> SVG/HTML/JPEG/PDF converter (issue #227).
# Renders the closed v1 element subset with an in-repo python3-stdlib renderer
# (scripts/shared/convert-excalidraw.py, BR 11) — no LLM, no network, fully
# offline and deterministic (BR 1). Elements outside the subset warn and are
# skipped (exit 0); JSON outside the elements v1/v2 schema exits 2.
#
# JPEG path (BR 12): Chrome headless screenshot of the intermediate HTML at the
# original canvas size -> PNG -> JPEG via Pillow (preferred) or convert/cjpeg
# fallback; white background (JPEG has no alpha) + fixed quality 90. When no
# PNG->JPEG converter exists, --check exits 1 BEFORE any file is created.
# PDF is produced EXCLUSIVELY by the shared #226 engine (BR 3). The
# intermediate HTML (SVG inline) is ALWAYS generated and preserved (BR 2).
#
# Contract (stable):
#   CLI:  convert-excalidraw.sh <input.json> <output.svg|output.html|output.jpeg|output.pdf> [--check]
#   Exit: 0 = success (artifact written)
#         1 = runtime failure or missing dependency (listed on stderr)
#         2 = usage error or invalid input (missing file, bad format,
#             schema violation, encoding gate failure)
#   Guarantees: UTF-8/NUL gate before any processing (BR 6); --check validates
#   dependencies before ANY file is created (BR 7); zero partial artifact
#   (temp + atomic rename, BR 5).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/convert-lib.sh"

INPUT="${1:-}"
OUTPUT="${2:-}"
MODE="${3:-}"

usage() {
  echo "Usage: convert-excalidraw.sh <input.json> <output.svg|output.html|output.jpeg|output.pdf> [--check]" >&2
  exit 2
}

# --- usage / input validation (exit 2, nothing created) ---
if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
fi
case "$MODE" in
  ""|--check) ;;
  *) usage ;;
esac
EXT="${OUTPUT##*.}"
case "$EXT" in
  svg|html|jpeg|pdf) ;;
  *)
    echo "error: unsupported output format: .$EXT (expected .svg, .html, .jpeg or .pdf)" >&2
    exit 2
    ;;
esac
if [[ ! -f "$INPUT" ]]; then
  echo "error: input excalidraw JSON not found: $INPUT" >&2
  exit 2
fi
convert_encoding_gate "$INPUT"   # BR 6

# --- dependency preflight (BR 7) ---
# Each probe is EXECUTED (not just `command -v`) so a binary that exists but
# cannot run is correctly reported as missing.
deps_check() {
  local missing=() chrome
  if ! command -v python3 >/dev/null 2>&1 || ! python3 --version >/dev/null 2>&1; then
    missing+=("python3")
  fi
  if [[ "$EXT" == "jpeg" ]]; then
    chrome="$(convert_find_chrome)"
    if [[ -z "$chrome" ]] || ! "$chrome" --version >/dev/null 2>&1; then
      missing+=("chrome (screenshot)")
    fi
    if ! convert_find_png2jpeg >/dev/null 2>&1; then
      missing+=("png2jpeg (pillow/convert/cjpeg)")
    fi
  fi
  if [[ "$EXT" == "pdf" ]]; then
    if [[ ! -f "$CONVERT_LIB_DIR/html-to-pdf.sh" ]]; then
      missing+=("html-to-pdf.sh (issue #226 engine)")
    fi
    if ! convert_have_pdf_engine; then
      missing+=("chrome-or-libreoffice (PDF engine)")
    fi
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "error: missing dependencies: ${missing[*]}" >&2
    return 1
  fi
  return 0
}
if [[ "$MODE" == "--check" ]]; then
  if deps_check; then
    echo "convert-excalidraw: all dependencies present"
    exit 0
  fi
  exit 1
fi
deps_check || exit 1

# --- output path resolution ---
OUT_RAW_DIR="$(dirname "$OUTPUT")"
if [[ ! -d "$OUT_RAW_DIR" ]]; then
  mkdir -p "$OUT_RAW_DIR" || { echo "error: cannot create output directory: $OUT_RAW_DIR" >&2; exit 2; }
fi
OUT_DIR="$(realpath "$OUT_RAW_DIR")"
OUTPUT_ABS="$OUT_DIR/$(basename "$OUTPUT")"
INPUT_ABS="$(realpath "$INPUT")"
STEM="$(convert_stem "$OUTPUT")"
HTML_ABS="$OUT_DIR/$STEM.html"   # intermediate artifact, always preserved (BR 2)

# --- render (temp dir + atomic publish = zero partial artifact, BR 5) ---
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The renderer prints "<width>x<height>" on stdout and writes the HTML.
# rc 2 = schema/usage (message already on stderr); rc 1 = runtime failure.
set +e
DIMS="$(python3 "$SCRIPT_DIR/convert-excalidraw.py" "$INPUT_ABS" "$TMP/out.html" 2>"$TMP/render.err")"
rc_render=$?
set -e
if [[ $rc_render -ne 0 ]]; then
  cat "$TMP/render.err" >&2
  exit "$rc_render"
fi
# Forward out-of-subset warnings (BR 11) to our stderr on success too.
if [[ -s "$TMP/render.err" ]]; then
  cat "$TMP/render.err" >&2
fi
W="${DIMS%%x*}"
H="${DIMS##*x}"
if [[ ! "$W" =~ ^[0-9]+$ || ! "$H" =~ ^[0-9]+$ ]]; then
  echo "error: renderer returned invalid canvas dimensions: $DIMS" >&2
  exit 1
fi

case "$EXT" in
  svg)
    # Extract the <svg> from the intermediate HTML (single top-level <svg>).
    if ! python3 - "$TMP/out.html" "$TMP/out.svg" <<'PY'
import re
import sys

doc = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"<svg\b.*?</svg>", doc, re.S)
if not m:
    sys.stderr.write("error: no <svg> found in the rendered HTML\n")
    sys.exit(1)
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    fh.write(m.group(0) + "\n")
sys.exit(0)
PY
    then
      echo "error: could not extract the SVG from the rendered HTML" >&2
      exit 1
    fi
    convert_atomic_publish "$TMP/out.svg" "$OUTPUT_ABS" || exit 1
    convert_atomic_publish "$TMP/out.html" "$HTML_ABS" || exit 1
    echo "SVG generated: $OUTPUT_ABS"
    echo "HTML generated: $HTML_ABS"
    ;;
  html)
    convert_atomic_publish "$TMP/out.html" "$OUTPUT_ABS" || exit 1
    echo "HTML generated: $OUTPUT_ABS"
    ;;
  jpeg)
    convert_atomic_publish "$TMP/out.html" "$HTML_ABS" || exit 1
    if ! convert_screenshot "$HTML_ABS" "$TMP/shot.png" "$W" "$H"; then
      echo "error: Chrome screenshot failed (HTML->JPEG path)" >&2
      exit 1
    fi
    if ! convert_png_to_jpeg "$TMP/shot.png" "$OUTPUT_ABS" "$W" "$H"; then
      echo "error: PNG->JPEG conversion failed" >&2
      exit 1
    fi
    echo "HTML generated: $HTML_ABS"
    echo "JPEG generated: $OUTPUT_ABS"
    ;;
  pdf)
    convert_atomic_publish "$TMP/out.html" "$HTML_ABS" || exit 1
    convert_html_to_pdf "$HTML_ABS" "$OUTPUT_ABS" || exit 1
    echo "HTML generated: $HTML_ABS"
    ;;
esac
