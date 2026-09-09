#!/usr/bin/env bash
# convert-lib.sh — shared library for the deterministic format converters
# (issue #227): convert-md.sh, convert-mermaid.sh, convert-excalidraw.sh.
#
# Sourced by each converter, never executed directly:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/convert-lib.sh"
#
# Provided helpers (all deterministic, offline, no LLM):
#   convert_find_chrome          -> echoes a Chrome binary path, or empty
#   convert_have_pdf_engine      -> 0 when Chrome or LibreOffice is available
#   convert_find_png2jpeg        -> echoes "pillow"|"convert"|"cjpeg", or 1
#   convert_encoding_gate <file> -> exit 2 on invalid UTF-8 / NUL bytes (BR 6)
#   convert_file_url <path>      -> echoes a percent-encoded file:// URL
#   convert_stem <path>          -> echoes basename without final extension
#   convert_atomic_publish <tmp> <dest> -> mkdir -p + atomic mv (zero partial
#                                  artifact, BR 5); exit 1 on failure
#   convert_check_asset <asset> <sidecar> -> verifies SHA-256 (BR 10); exit 1
#   convert_screenshot <html> <png> <w> <h> -> Chrome headless screenshot;
#                                  exit 1 when Chrome missing or PNG empty
#   convert_png_to_jpeg <png> <jpeg> <w> <h> -> white background + quality 90,
#                                  exact WxH (BR 12); exit 1 when no converter
#   convert_html_to_pdf <html> <pdf> -> delegates to the shared #226 engine
#                                  (scripts/shared/html-to-pdf.sh); exit 1 on
#                                  failure — the ONLY PDF path (BR 3)
#   convert_warn <msg>           -> "warning: ..." to stderr
#
# Exit-code contract (BR 5, shared with every converter):
#   0 = success; 1 = runtime/dependency failure; 2 = usage or invalid input.
# The library never creates files itself — callers own their temp/atomic flow.

# Directory of this library (resolved at source time): used to locate the
# shared #226 PDF engine (html-to-pdf.sh) regardless of the caller's location.
CONVERT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

convert_find_chrome() {
  command -v google-chrome 2>/dev/null \
    || command -v google-chrome-stable 2>/dev/null \
    || command -v chromium 2>/dev/null \
    || command -v chromium-browser 2>/dev/null \
    || true
}

# convert_have_pdf_engine — 0 when at least one PDF engine (Chrome headless or
# LibreOffice) exists on PATH. The shared #226 engine falls back Chrome->LO,
# so the converters only need "at least one" to be runnable.
convert_have_pdf_engine() {
  if [[ -n "$(convert_find_chrome)" ]]; then
    return 0
  fi
  command -v libreoffice >/dev/null 2>&1 && return 0
  command -v soffice >/dev/null 2>&1 && return 0
  return 1
}

# convert_find_png2jpeg — echoes the PNG->JPEG strategy: "pillow" (Python PIL,
# preferred), "convert" (ImageMagick), "cjpeg" (netpbm + libjpeg fallback).
# Returns 1 when none is available.
convert_find_png2jpeg() {
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' >/dev/null 2>&1; then
    printf 'pillow\n'
    return 0
  fi
  if command -v convert >/dev/null 2>&1; then
    printf 'convert\n'
    return 0
  fi
  if command -v cjpeg >/dev/null 2>&1 && command -v pngtopnm >/dev/null 2>&1; then
    printf 'cjpeg\n'
    return 0
  fi
  return 1
}

# convert_encoding_gate <file> — reject corrupted input BEFORE any processing
# (BR 6): invalid UTF-8 sequences or NUL bytes -> exit 2 with no artifact.
convert_encoding_gate() {
  local f="$1"
  if ! iconv -f UTF-8 -t UTF-8 "$f" >/dev/null 2>&1; then
    echo "error: input is not valid UTF-8 (corrupted byte sequences) — fix the encoding before converting" >&2
    exit 2
  fi
  if perl -0777 -ne 'exit 1 if /\x00/' "$f"; then
    return 0
  fi
  echo "error: input contains NUL bytes (corrupted characters) — fix before converting" >&2
  exit 2
}

# convert_file_url <path> — build a percent-encoded file:// URL so paths with
# spaces / non-ASCII names work in Chrome. LC_ALL=C makes ${#path} operate on
# BYTES so each UTF-8 byte is encoded (%C3%A9), as Chrome requires (pattern of
# the shared #226 engine).
convert_file_url() {
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

convert_stem() {
  local b
  b="$(basename "$1")"
  printf '%s' "${b%.*}"
}

# convert_atomic_publish <tmpfile> <dest> — create the output directory and
# atomically move the finished artifact into place. No failure path can leave a
# truncated/partial file at <dest> (BR 5).
convert_atomic_publish() {
  local tmp="$1" dest="$2" d
  d="$(dirname "$dest")"
  if [[ ! -d "$d" ]]; then
    mkdir -p "$d" || { echo "error: cannot create output directory: $d" >&2; return 1; }
  fi
  if [[ ! -f "$tmp" ]]; then
    echo "error: internal error — temporary artifact missing: $tmp" >&2
    return 1
  fi
  mv -f "$tmp" "$dest"
}

# convert_check_asset <asset> <sidecar> — verify the vendored mermaid bundle
# against its versioned SHA-256 (BR 10). The sidecar's FIRST line is the
# checksum in `sha256sum` format; the following lines carry metadata.
convert_check_asset() {
  local asset="$1" sidecar="$2" expected actual
  if [[ ! -f "$asset" ]]; then
    echo "error: missing mermaid asset: $asset (vendor it once via scripts/shared/assets/)" >&2
    return 1
  fi
  if [[ ! -f "$sidecar" ]]; then
    echo "error: missing mermaid checksum sidecar: $sidecar" >&2
    return 1
  fi
  expected="$(awk 'NR==1{print $1}' "$sidecar")"
  actual="$(sha256sum "$asset" 2>/dev/null | awk '{print $1}')"
  if [[ -z "$expected" || -z "$actual" || "$expected" != "$actual" ]]; then
    echo "error: mermaid asset checksum mismatch — asset may be corrupted (expected $expected, got $actual)" >&2
    return 1
  fi
  return 0
}

# convert_screenshot <html_abs> <png_abs> <w> <h> — Chrome headless screenshot
# of the intermediate HTML at exactly WxH (device-scale 1). Offline: only the
# local file:// URL is loaded. Exit 1 on missing Chrome or empty PNG.
convert_screenshot() {
  local html="$1" png="$2" w="$3" h="$4" chrome
  chrome="$(convert_find_chrome)"
  if [[ -z "$chrome" ]]; then
    echo "error: Google Chrome not found (needed for the HTML->JPEG screenshot)" >&2
    return 1
  fi
  "$chrome" \
    --headless=new \
    --disable-gpu \
    --no-sandbox \
    --disable-dev-shm-usage \
    --hide-scrollbars \
    --force-device-scale-factor=1 \
    --window-size="${w},${h}" \
    --screenshot="$png" \
    "$(convert_file_url "$html")" >/dev/null 2>&1
  if [[ ! -s "$png" ]]; then
    echo "error: Chrome produced an empty screenshot" >&2
    return 1
  fi
  return 0
}

# convert_png_to_jpeg <png> <jpeg> <w> <h> — deterministic PNG->JPEG (BR 12):
# composed over a WHITE background (JPEG has no alpha), resized exactly to WxH,
# quality fixed at 90. Strategy: Pillow -> ImageMagick convert -> netpbm cjpeg.
convert_png_to_jpeg() {
  local png="$1" jpeg="$2" w="$3" h="$4" mode
  mode="$(convert_find_png2jpeg)" || {
    echo "error: no PNG->JPEG converter available (pillow, convert or cjpeg+pngtopnm)" >&2
    return 1
  }
  case "$mode" in
    pillow)
      python3 - "$png" "$jpeg" "$w" "$h" <<'PY'
import sys
from PIL import Image
png, jpeg, w, h = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
im = Image.open(png).convert('RGBA')
bg = Image.new('RGBA', im.size, (255, 255, 255, 255))
out = Image.alpha_composite(bg, im).convert('RGB')
if out.size != (w, h):
    out = out.resize((w, h), Image.LANCZOS)
out.save(jpeg, 'JPEG', quality=90)
PY
      ;;
    convert)
      convert "$png" -background white -flatten -resize "${w}x${h}!" -quality 90 "$jpeg"
      ;;
    cjpeg)
      if command -v pnmscale >/dev/null 2>&1; then
        pngtopnm "$png" 2>/dev/null | pnmscale -xsize "$w" -ysize "$h" 2>/dev/null \
          | cjpeg -quality 90 -outfile "$jpeg"
      else
        pngtopnm "$png" 2>/dev/null | cjpeg -quality 90 -outfile "$jpeg"
      fi
      ;;
  esac
  if [[ ! -s "$jpeg" ]]; then
    echo "error: PNG->JPEG conversion produced an empty file" >&2
    return 1
  fi
  return 0
}

# convert_html_to_pdf <html> <pdf> — THE only PDF path (BR 3): delegates to the
# shared engine from issue #226 (scripts/shared/html-to-pdf.sh). Converters
# never call Chrome --print-to-pdf directly and never reimplement a fallback.
convert_html_to_pdf() {
  local h2p="$CONVERT_LIB_DIR/html-to-pdf.sh"
  if [[ ! -f "$h2p" ]]; then
    echo "error: shared HTML->PDF engine not found: $h2p (issue #226 dependency)" >&2
    return 1
  fi
  bash "$h2p" "$1" "$2"
}

convert_warn() {
  echo "warning: $*" >&2
}
