#!/usr/bin/env bash
# Deterministic Markdown -> HTML/PDF converter (issue #227).
# Renders markdown with an in-repo python3-stdlib renderer (scripts/shared/
# convert-md.py) — no LLM, no network, fully offline and deterministic
# (BR 1). PDF is produced EXCLUSIVELY by the shared #226 engine
# (scripts/shared/html-to-pdf.sh, BR 3). HTML is ALWAYS the intermediate
# artifact, generated and preserved on every conversion (BR 2).
#
# Contract (stable):
#   CLI:  convert-md.sh <input.md> <output.html|output.pdf> [--check]
#   Exit: 0 = success (artifact written)
#         1 = runtime failure or missing dependency (listed on stderr)
#         2 = usage error or invalid input (missing file, bad format,
#             encoding gate failure)
#   Guarantees: UTF-8/NUL gate runs BEFORE any processing (BR 6); --check
#   validates dependencies before ANY file is created (BR 7); zero partial
#   artifact on any failure path (temp + atomic rename, BR 5); raw HTML in
#   the input is always escaped (BR 8); local images become data: URIs up to
#   512 KiB (BR 9).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/convert-lib.sh"

INPUT="${1:-}"
OUTPUT="${2:-}"
MODE="${3:-}"

usage() {
  echo "Usage: convert-md.sh <input.md> <output.html|output.pdf> [--check]" >&2
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
  html|pdf) ;;
  *)
    echo "error: unsupported output format: .$EXT (expected .html or .pdf)" >&2
    exit 2
    ;;
esac
if [[ ! -f "$INPUT" ]]; then
  echo "error: input markdown not found: $INPUT" >&2
  exit 2
fi
convert_encoding_gate "$INPUT"   # BR 6: exits 2 on NUL / invalid UTF-8

# --- dependency preflight (BR 7: before ANY file is created) ---
# Each probe is EXECUTED (not just `command -v`) so a binary that exists but
# cannot run is correctly reported as missing.
deps_check() {
  local missing=()
  if ! command -v python3 >/dev/null 2>&1 || ! python3 --version >/dev/null 2>&1; then
    missing+=("python3")
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
    echo "convert-md: all dependencies present"
    exit 0
  fi
  exit 1
fi
deps_check || exit 1

# --- output path resolution (mkdir before realpath, #226 pattern) ---
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

if ! python3 "$SCRIPT_DIR/convert-md.py" "$INPUT_ABS" "$TMP/out.html"; then
  echo "error: markdown rendering failed" >&2
  exit 1
fi

if [[ "$EXT" == "html" ]]; then
  convert_atomic_publish "$TMP/out.html" "$OUTPUT_ABS" || exit 1
  echo "HTML generated: $OUTPUT_ABS"
else
  # PDF: HTML intermediate is preserved next to the PDF, then delegated (BR 3).
  convert_atomic_publish "$TMP/out.html" "$HTML_ABS" || exit 1
  convert_html_to_pdf "$HTML_ABS" "$OUTPUT_ABS" || exit 1
  echo "HTML generated: $HTML_ABS"
fi
