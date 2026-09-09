#!/usr/bin/env bash
# Deterministic Mermaid -> SVG/HTML/PDF converter (issue #227).
# Renders offline via Chrome headless over a LOCAL harness that embeds the
# vendored, checksum-pinned mermaid bundle (scripts/shared/assets/mermaid.min.js
# + .sha256, BR 10) and the diagram ESCAPED AS DATA — never as an executable
# <script> (BR 8). The SVG is extracted from the rendered DOM and validated
# (non-empty, contains <svg>) before being written (BR 10). No LLM, no
# network, byte-identical output for identical input (BR 1).
#
# Contract (stable):
#   CLI:  convert-mermaid.sh <input.mmd> <output.svg|output.html|output.pdf> [--check]
#   Exit: 0 = success (artifact written)
#         1 = runtime failure or missing dependency (listed on stderr)
#         2 = usage error or invalid input (missing file, bad format,
#             encoding gate failure)
#   Guarantees: UTF-8/NUL gate before any processing (BR 6); --check validates
#   Chrome + the vendored asset/checksum before ANY file is created (BR 7);
#   zero partial artifact (temp + atomic rename, BR 5); the diagram is always
#   embedded as escaped data in the harness (BR 8); the extracted SVG is
#   validated before publish (BR 10); PDF goes exclusively through the shared
#   #226 engine (BR 3). The intermediate HTML (with the rendered SVG inline)
#   is ALWAYS generated and preserved (BR 2).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/convert-lib.sh"

ASSET="$SCRIPT_DIR/assets/mermaid.min.js"
SIDE="$SCRIPT_DIR/assets/mermaid.min.js.sha256"

INPUT="${1:-}"
OUTPUT="${2:-}"
MODE="${3:-}"

usage() {
  echo "Usage: convert-mermaid.sh <input.mmd> <output.svg|output.html|output.pdf> [--check]" >&2
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
  svg|html|pdf) ;;
  *)
    echo "error: unsupported output format: .$EXT (expected .svg, .html or .pdf)" >&2
    exit 2
    ;;
esac
if [[ ! -f "$INPUT" ]]; then
  echo "error: input mermaid not found: $INPUT" >&2
  exit 2
fi
convert_encoding_gate "$INPUT"   # BR 6

# --- dependency preflight (BR 7) ---
# Each probe is EXECUTED (not just `command -v`) so a binary that exists but
# cannot run is correctly reported as missing.
deps_check() {
  local missing=() chrome
  chrome="$(convert_find_chrome)"
  if [[ -z "$chrome" ]] || ! "$chrome" --version >/dev/null 2>&1; then
    missing+=("chrome (headless render)")
  fi
  if ! convert_check_asset "$ASSET" "$SIDE" >/dev/null 2>&1; then
    missing+=("mermaid asset/checksum ($ASSET)")
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
    echo "convert-mermaid: all dependencies present"
    exit 0
  fi
  exit 1
fi
deps_check || exit 1
convert_check_asset "$ASSET" "$SIDE" || exit 1   # loud, with checksum detail

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

CHROME="$(convert_find_chrome)"

# --- build the local harness: diagram embedded as ESCAPED DATA (BR 8) ---
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# html.escape(..., quote=True) — the diagram becomes inert text inside the
# <div class="mermaid">; mermaid reads it back as textContent. It can never be
# executed as markup or script, regardless of its content. Written to a FILE
# (not a variable) so `$`/backticks in the diagram can never be re-expanded
# while the harness is assembled.
python3 -c 'import html,sys; sys.stdout.write(html.escape(sys.stdin.read(), quote=True))' \
  < "$INPUT_ABS" > "$TMP/diagram.txt"

{
  printf '%s\n' '<!DOCTYPE html>'
  printf '%s\n' '<html lang="en"><head><meta charset="utf-8">'
  printf '%s\n' '<style>'
  printf '%s\n' '  body { margin: 0; background: #fff; }'
  printf '%s\n' '  .mermaid { display: flex; justify-content: center; padding: 16px; }'
  printf '%s\n' '  svg { max-width: 100%; height: auto; }'
  printf '%s\n' '</style>'
  printf '%s\n' '</head><body>'
  printf '%s\n' '<div class="mermaid">'
  cat "$TMP/diagram.txt"
  printf '%s\n' '</div>'
  printf '%s\n' "<script src=\"$(convert_file_url "$ASSET")\"></script>"
  printf '%s\n' '<script>'
  printf '%s\n' "  mermaid.initialize({ startOnLoad: false, theme: 'neutral', securityLevel: 'strict' });"
  printf '%s\n' "  window.addEventListener('load', function () {"
  printf '%s\n' "    var el = document.querySelector('.mermaid');"
  printf '%s\n' "    mermaid.render('mmd', el.textContent.trim()).then(function (r) {"
  printf '%s\n' "      document.getElementById('svgout').textContent = r.svg;"
  printf '%s\n' "    }).catch(function (e) {"
  printf '%s\n' "      document.getElementById('svgout').textContent ="
  printf '%s\n' "        'MERMAID_ERROR: ' + (e && e.message ? e.message : String(e));"
  printf '%s\n' "    });"
  printf '%s\n' '  });'
  printf '%s\n' '</script>'
  printf '%s\n' '<pre id="svgout" style="display:none"></pre>'
  printf '%s\n' '</body></html>'
} > "$TMP/harness.html"

# --- render offline: Chrome dump-dom with virtual time so the async render
# --- settles; only the local harness + vendored asset are ever executed.
if ! "$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --disable-dev-shm-usage \
  --dump-dom \
  --virtual-time-budget=15000 \
  "$(convert_file_url "$TMP/harness.html")" > "$TMP/dump.html" 2>/dev/null; then
  echo "error: Chrome failed to render the mermaid harness" >&2
  exit 1
fi

# --- extract + validate the SVG (BR 10: non-empty, contains <svg>) ---
if ! python3 - "$TMP/dump.html" "$TMP/svg.out" <<'PY'
import html as h
import re
import sys

dump = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'<pre id="svgout"[^>]*>(.*?)</pre>', dump, re.S)
if not m:
    sys.stderr.write("error: harness output marker not found in the rendered DOM\n")
    sys.exit(1)
content = h.unescape(m.group(1))
if content.startswith("MERMAID_ERROR"):
    sys.stderr.write("error: mermaid render failed: %s\n" % content)
    sys.exit(1)
if not content.strip() or "<svg" not in content:
    sys.stderr.write("error: mermaid produced no valid SVG (empty or missing <svg>)\n")
    sys.exit(1)
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    fh.write(content + "\n")
sys.exit(0)
PY
then
  echo "error: could not extract a valid SVG from the rendered harness" >&2
  exit 1
fi

# --- assemble the final intermediate HTML: rendered SVG inline + the original
# --- diagram preserved as escaped data (BR 2, BR 8). Diagram comes from the
# --- file so `$`/backticks in it are never re-expanded.
{
  printf '%s\n' '<!DOCTYPE html>'
  printf '%s\n' '<html lang="en"><head><meta charset="utf-8">'
  printf '%s\n' "<title>${STEM}</title>"
  printf '%s\n' '<style>'
  printf '%s\n' '  body { margin: 0; background: #fff; }'
  printf '%s\n' '  .mermaid { display: flex; justify-content: center; padding: 16px; }'
  printf '%s\n' '  svg { max-width: 100%; height: auto; }'
  printf '%s\n' '</style>'
  printf '%s\n' '</head><body>'
  printf '%s\n' '<pre class="mermaid-source" style="display:none">'
  cat "$TMP/diagram.txt"
  printf '%s\n' '</pre>'
  printf '%s\n' '<div class="mermaid">'
  cat "$TMP/svg.out"
  printf '%s\n' '</div>'
  printf '%s\n' '</body></html>'
} > "$TMP/final.html"

case "$EXT" in
  svg)
    convert_atomic_publish "$TMP/svg.out" "$OUTPUT_ABS" || exit 1
    convert_atomic_publish "$TMP/final.html" "$HTML_ABS" || exit 1
    echo "SVG generated: $OUTPUT_ABS"
    echo "HTML generated: $HTML_ABS"
    ;;
  html)
    convert_atomic_publish "$TMP/final.html" "$OUTPUT_ABS" || exit 1
    echo "HTML generated: $OUTPUT_ABS"
    ;;
  pdf)
    convert_atomic_publish "$TMP/final.html" "$HTML_ABS" || exit 1
    convert_html_to_pdf "$HTML_ABS" "$OUTPUT_ABS" || exit 1
    echo "HTML generated: $HTML_ABS"
    ;;
esac
