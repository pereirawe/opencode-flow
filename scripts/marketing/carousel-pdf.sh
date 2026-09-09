#!/usr/bin/env bash
# carousel-pdf.sh — assemble the LinkedIn carousel deck.pdf from the N validated
# slide PNGs (issue #225). Each 1080x1080 slide becomes one square PDF page.
#
#   carousel-pdf.sh --deck <deck.json> --images <dir> --out <deck.pdf>
#
# Contract (shared with the deterministic converters, issue #227):
#   Exit 0 = success (non-empty PDF with one square page per slide)
#          1 = runtime failure (Chrome/PDF engine missing, invalid slide image,
#              empty/partial PDF produced)
#          2 = usage error or invalid input (bad flags, invalid deck.json,
#              missing slide files)
#   Guarantees (BR 9): deck.pdf is ONLY assembled when ALL N slide images pass
#   the magic-byte + 1080x1080 dimension validation; zero partial artifact at
#   the destination (temp file published atomically after validation).
#
# PDF path: THE convert-lib bridge (scripts/shared/html-to-pdf.sh, issue #226)
# — never a direct Chrome --print-to-pdf call in this family.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../shared/convert-lib.sh
source "$SCRIPT_DIR/../shared/convert-lib.sh"

CANVAS_W=1080
CANVAS_H=1080

usage() { # fd 1=stdout, 2=stderr
  local fd="${1:-1}"
  cat >&"$fd" <<'EOF'
Usage:
  carousel-pdf.sh --deck <deck.json> --images <dir> --out <deck.pdf>

  --deck    FILE   deck.json (canonical carousel spec — n_slides/slides).
  --images  DIR    directory containing slide-01.png .. slide-0N.png.
  --out     FILE   output deck.pdf (N square 1080x1080 pages).

Requires the shared HTML->PDF engine (Chrome headless or LibreOffice, issue
#226) + python3 with Pillow for the dimension gate. Exit codes: 0 success,
1 runtime failure, 2 usage/invalid input.
EOF
}

DECK=""; IMAGES=""; OUT=""
parse_args() {
  local i=0
  local -a args=("$@")
  local n=$#
  while (( i < n )); do
    case "${args[$i]}" in
      --deck)   DECK="${args[$((i+1))]:-}";   i=$((i+2)) ;;
      --images) IMAGES="${args[$((i+1))]:-}"; i=$((i+2)) ;;
      --out)    OUT="${args[$((i+1))]:-}";    i=$((i+2)) ;;
      --help|-h) usage; exit 0 ;;
      *) usage 2; exit 2 ;;
    esac
  done
}

img_dims() {
  python3 - "$1" <<'PY'
from PIL import Image
import sys
try:
    im = Image.open(sys.argv[1])
    print(f"{im.width}x{im.height}")
except Exception:
    pass
PY
}

img_magic() {
  head -c 8 "$1" | od -An -tx1 | tr -d ' \n' || true
}

parse_args "$@"
if [[ -z "$DECK" || -z "$IMAGES" || -z "$OUT" ]]; then
  usage 2
  exit 2
fi
[[ -f "$DECK" ]]   || { echo "error: deck file not found: $DECK" >&2; exit 2; }
[[ -d "$IMAGES" ]] || { echo "error: images directory not found: $IMAGES" >&2; exit 2; }

if ! python3 -c 'import PIL' >/dev/null 2>&1; then
  echo "error: python3 Pillow not found (needed for the 1080x1080 dimension gate)" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve the ordered slide file list from the deck (exit 2 on invalid deck,
# exit 1 when a slide image is missing or fails the magic/dimension gate).
# ---------------------------------------------------------------------------
SLIDE_FILES="$(python3 - "$DECK" "$IMAGES" <<'PY'
import json
import os
import sys

deck_path, images_dir = sys.argv[1], sys.argv[2]
deck = json.load(open(deck_path, encoding="utf-8"))
if deck.get("schema") != "linkedin-carousel-deck-v1":
    sys.exit("error: deck.json has an unsupported schema (expected linkedin-carousel-deck-v1)")
slides = deck.get("slides") or []
n = deck.get("n_slides")
if not isinstance(n, int) or n != len(slides):
    sys.exit("error: deck.json n_slides must equal the number of slides")
if n < 3 or n > 20:
    sys.exit("error: deck.json must have 3..20 slides (BR 4), got %d" % n)
for i in range(1, n + 1):
    path = os.path.join(images_dir, "slide-%02d.png" % i)
    if not os.path.isfile(path):
        sys.exit("error: missing slide image: %s" % path)
    print(path)
PY
)" || { echo "$SLIDE_FILES" >&2; exit 2; }

mapfile -t FILES <<< "$SLIDE_FILES"
for f in "${FILES[@]}"; do
  [[ -n "$f" ]] || continue
  if [[ "$(img_magic "$f")" != "89504e470d0a1a0a" ]]; then
    echo "error: slide image is not a valid PNG (magic mismatch): $f" >&2
    exit 1
  fi
  dims="$(img_dims "$f")"
  if [[ "$dims" != "${CANVAS_W}x${CANVAS_H}" ]]; then
    echo "error: slide image has dimension $dims, expected ${CANVAS_W}x${CANVAS_H}: $f" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Build the deck HTML: one 1080x1080 .page div per slide (full-bleed image).
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HTML_TMP="$TMP/deck.html"
PDF_TMP="$TMP/deck.pdf"

python3 - "$HTML_TMP" "${FILES[@]}" <<'PY'
import sys
import urllib.parse

out_html = sys.argv[1]
files = sys.argv[2:]
pages = "".join(
    '<div class="page"><img src="file://%s" alt=""></div>' % urllib.parse.quote(f, safe="/_.~-")
    for f in files
)
html_doc = """<!DOCTYPE html>
<html lang="pt">
<head>
<meta charset="utf-8">
<style>
@page { size: 1080px 1080px; margin: 0; }
html, body { margin: 0; padding: 0; }
.page { width: 1080px; height: 1080px; page-break-after: always; }
.page:last-child { page-break-after: auto; }
.page img { width: 1080px; height: 1080px; object-fit: fill; display: block; }
</style>
</head>
<body>
%s
</body>
</html>
""" % pages
with open(out_html, "w", encoding="utf-8") as fh:
    fh.write(html_doc)
PY

# ---------------------------------------------------------------------------
# THE PDF path: the shared #226 engine via the convert-lib bridge (BR 3).
# ---------------------------------------------------------------------------
if ! convert_html_to_pdf "$HTML_TMP" "$PDF_TMP"; then
  echo "error: failed to assemble deck.pdf (HTML->PDF engine failure)" >&2
  exit 1
fi
if [[ ! -s "$PDF_TMP" ]] || [[ "$(head -c 4 "$PDF_TMP")" != "%PDF" ]]; then
  echo "error: deck.pdf output is empty or not a valid PDF" >&2
  exit 1
fi

if ! convert_atomic_publish "$PDF_TMP" "$OUT"; then
  echo "error: failed to publish deck.pdf" >&2
  exit 1
fi
echo "Deck PDF generated: $OUT"
