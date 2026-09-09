#!/usr/bin/env bash
# slide-compose.sh — deterministic slide composition for the LinkedIn carousel
# (issue #225): HTML/CSS typographic layer -> 1080x1080 PNG via Chrome headless.
#
# The text layer (exact copy + logo overlay) is ALWAYS composed
# deterministically here — the image model contributes only the background
# art (BR 6). Same inputs -> same output (no randomness, no network).
#
#   slide-compose.sh --deck <deck.json> --person <person.json> --slide <N> \
#                    [--bg <background.png|jpg|webp>] --out <slide.png>
#
# Contract (shared with scripts/cv/banner-gen.sh and scripts/shared/convert-lib.sh):
#   Exit 0 = success (valid 1080x1080 PNG published, plus the <name>.html source)
#          1 = runtime failure (missing Chrome/Pillow, invalid rendered PNG, ...)
#          2 = usage error or invalid input (bad flags, missing/unknown slide,
#              invalid deck/person JSON, missing required text fields)
#   Guarantees: zero partial artifact (temp file published only after magic-byte
#   + dimension validation), HTML-escaped copy (no injection), logo only when
#   present and readable.
#
# Dependencies: bash + python3 (stdlib + Pillow for dimension validation) +
# Google Chrome/Chromium headless.
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
  slide-compose.sh --deck <deck.json> --person <person.json> --slide <N>
                   [--bg <background.png|jpg|webp>] --out <slide.png>

  --deck    FILE  deck.json (canonical carousel spec — slides/text blocks).
  --person  FILE  docs/assets/person.json (validated identity: name/handle/logo).
  --slide   N     slide index (1-based, must exist in deck.json).
  --bg      FILE  optional background art (magic-byte validated; normalized to
                  1080x1080 via object-fit: cover — text layer is deterministic).
  --out     FILE  output PNG (1080x1080). A sibling <name>.html is written with
                  the exact HTML/CSS used for the render.

Requires Chrome/Chromium headless + python3 with Pillow. Exit codes: 0 success,
1 runtime failure, 2 usage/invalid input.
EOF
}

DECK=""; PERSON=""; SLIDE=""; BG=""; OUT=""
parse_args() {
  local i=0
  local -a args=("$@")
  local n=$#
  while (( i < n )); do
    case "${args[$i]}" in
      --deck)   DECK="${args[$((i+1))]:-}";   i=$((i+2)) ;;
      --person) PERSON="${args[$((i+1))]:-}"; i=$((i+2)) ;;
      --slide)  SLIDE="${args[$((i+1))]:-}";  i=$((i+2)) ;;
      --bg)     BG="${args[$((i+1))]:-}";     i=$((i+2)) ;;
      --out)    OUT="${args[$((i+1))]:-}";    i=$((i+2)) ;;
      --help|-h) usage; exit 0 ;;
      *) usage 2; exit 2 ;;
    esac
  done
}

# img_dims <file> -> "WxH" (Pillow) or empty on failure
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

# img_magic <file> -> 8 hex bytes of the magic header (lowercase, no spaces)
img_magic() {
  head -c 8 "$1" | od -An -tx1 | tr -d ' \n' || true
}

magic_is_image() { # PNG/JPEG/WebP are the accepted background formats
  case "$1" in
    89504e470d0a1a0a|ffd8ff*|52494646*) return 0 ;;
    *) return 1 ;;
  esac
}

parse_args "$@"
if [[ -z "$DECK" || -z "$PERSON" || -z "$SLIDE" || -z "$OUT" ]]; then
  usage 2
  exit 2
fi
[[ -f "$DECK" ]]   || { echo "error: deck file not found: $DECK" >&2; exit 2; }
[[ -f "$PERSON" ]] || { echo "error: person file not found: $PERSON" >&2; exit 2; }
[[ "$SLIDE" =~ ^[0-9]+$ ]] || { echo "error: --slide must be a positive integer, got '$SLIDE'" >&2; exit 2; }

# Optional background: must exist and look like an image (magic-byte gate
# before any render — a corrupt/half download can never reach the composition).
if [[ -n "$BG" ]]; then
  [[ -f "$BG" ]] || { echo "error: background image not found: $BG" >&2; exit 2; }
  if ! magic_is_image "$(img_magic "$BG")"; then
    echo "error: background file is not a valid PNG/JPEG/WebP image (magic mismatch): $BG" >&2
    exit 2
  fi
fi

# Runtime dependencies (exit 1 — environment, not usage).
if [[ -z "$(convert_find_chrome)" ]]; then
  echo "error: Google Chrome not found (needed for the deterministic 1080x1080 slide render)" >&2
  exit 1
fi
if ! python3 -c 'import PIL' >/dev/null 2>&1; then
  echo "error: python3 Pillow not found (needed for 1080x1080 dimension validation)" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HTML_TMP="$TMP/slide.html"
PNG_TMP="$TMP/slide.png"

# ---------------------------------------------------------------------------
# Generate the deterministic HTML: HTML-escaped copy, canonical palette/fonts,
# per-type layout (cover/content/cta), optional logo overlay bottom-right.
# ---------------------------------------------------------------------------
BG_URL=""
if [[ -n "$BG" ]]; then
  BG_URL="$(python3 - "$BG" <<'PY'
import sys, urllib.parse
print("file://" + urllib.parse.quote(sys.argv[1], safe="/_.~-"))
PY
)"
fi

if ! python3 - "$DECK" "$PERSON" "$SLIDE" "$BG_URL" "$HTML_TMP" <<'PY' 2>&1
import html
import json
import sys

deck_path, person_path, slide_idx, bg_url, out_html = sys.argv[1:6]
slide_idx = int(slide_idx)

deck = json.load(open(deck_path, encoding="utf-8"))
if deck.get("schema") != "linkedin-carousel-deck-v1":
    sys.exit("error: deck.json has an unsupported schema (expected linkedin-carousel-deck-v1)")
person = json.load(open(person_path, encoding="utf-8"))

slide = next((s for s in deck.get("slides", []) if s.get("index") == slide_idx), None)
if slide is None:
    sys.exit(f"error: slide {slide_idx} not found in deck.json (slides: {[s.get('index') for s in deck.get('slides', [])]})")
stype = slide.get("type")
if stype not in ("cover", "content", "cta"):
    sys.exit(f"error: slide {slide_idx} has an unknown type {stype!r} (expected cover|content|cta)")
text = slide.get("text") or {}

e = html.escape

# --- Validate the per-type text block (canonical template, BR 3) -----------
errors = []
if stype == "cover":
    if not isinstance(text.get("TITULO"), str) or not text["TITULO"].strip():
        errors.append("cover slide text.TITULO is required")
elif stype == "content":
    if not isinstance(text.get("HEADLINE"), str) or not text["HEADLINE"].strip():
        errors.append("content slide text.HEADLINE is required")
    bullets = text.get("BULLETS")
    if not isinstance(bullets, list) or not any(
        isinstance(b, str) and b.strip() for b in bullets
    ):
        errors.append("content slide text.BULLETS must be a non-empty array of strings")
else:  # cta
    if not isinstance(text.get("HEADLINE"), str) or not text["HEADLINE"].strip():
        errors.append("cta slide text.HEADLINE is required")
    if not isinstance(text.get("CTA"), str) or not text["CTA"].strip():
        errors.append("cta slide text.CTA is required")
if errors:
    sys.exit("error: " + "; ".join(errors))


def render(key, class_name):
    """Render a slide text field as a div when it is a non-empty string."""
    v = text.get(key, "")
    if isinstance(v, str) and v.strip():
        return f'<div class="{class_name}">{e(v)}</div>'
    return ""


# --- Identity (validated by carousel-gen.sh preflight; compose only READS) --
# logo_path resolves relative to person.json's directory (docs/assets/) — the
# canonical location per issue #225 BR 1 — or as an absolute path when given.
import os
import urllib.parse

logo_html = ""
logo_path = person.get("logo_path") or ""
if logo_path:
    if not os.path.isabs(logo_path):
        logo_path = os.path.join(os.path.dirname(os.path.abspath(person_path)), logo_path)
    if os.path.isfile(logo_path):
        logo_html = (
            '<div class="logo"><img src="file://'
            + urllib.parse.quote(logo_path, safe="/_.~-")
            + '" alt=""></div>'
        )

# --- Background layer: model art (cover, deterministic) or CSS-only --------
# A scrim gradient guarantees text contrast over any art (BR 5/6).
if bg_url:
    bg_layer = (
        f'<div class="bgimg"><img src="{e(bg_url, quote=True)}" alt=""></div>'
        '<div class="scrim"></div>'
    )
else:
    bg_layer = '<div class="cssbg"></div>'

# --- Per-type body ----------------------------------------------------------
if stype == "cover":
    body = (
        '<div class="cover">'
        f'<div class="title">{e(text.get("TITULO", ""))}</div>'
        '<div class="rule"></div>'
        f'{render("SUBTITULO", "subtitle")}'
        f'{render("RODAPE", "rodape")}'
        '</div>'
    )
elif stype == "content":
    bullets_html = "".join(
        f"<li>{e(b)}</li>"
        for b in text.get("BULLETS", [])
        if isinstance(b, str) and b.strip()
    )
    body = (
        '<div class="content">'
        f'{render("TAG", "tag")}'
        f'<div class="headline">{e(text.get("HEADLINE", ""))}</div>'
        f"<ul>{bullets_html}</ul>"
        f'{render("DETALHE", "detail")}'
        '</div>'
    )
else:  # cta
    body = (
        '<div class="cta">'
        f'<div class="headline">{e(text.get("HEADLINE", ""))}</div>'
        f'{render("SUBHEADLINE", "subheadline")}'
        f'<div class="cta-box">{e(text.get("CTA", ""))}</div>'
        f'{render("RODAPE", "rodape")}'
        '</div>'
    )

html_doc = f'''<!DOCTYPE html>
<html lang="pt">
<head>
<meta charset="utf-8">
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
html, body {{ width:1080px; height:1080px; }}
body {{
  font-family:'Inter','Space Grotesk',system-ui,-apple-system,'Segoe UI',Roboto,Arial,sans-serif;
  color:#FFFFFF; background:#000000; position:relative; overflow:hidden;
  -webkit-font-smoothing:antialiased;
}}
.bgimg {{ position:absolute; inset:0; }}
.bgimg img {{ width:1080px; height:1080px; object-fit:cover; display:block; }}
.scrim {{ position:absolute; inset:0;
  background:linear-gradient(168deg, rgba(0,0,0,0.10) 0%, rgba(0,0,0,0.45) 48%, rgba(0,0,0,0.88) 100%); }}
.cssbg {{ position:absolute; inset:0;
  background:radial-gradient(circle at 84% 12%, #0077B6 0%, rgba(0,119,182,0) 46%),
             linear-gradient(152deg, #000000 0%, #101010 58%, #1C0509 100%); }}
.cssbg::after {{ content:''; position:absolute; left:72px; top:0; width:14px; height:1080px; background:#E63946; }}
.logo {{ position:absolute; right:48px; bottom:44px; z-index:5; }}
.logo img {{ display:block; max-width:220px; max-height:96px; object-fit:contain; }}

.cover {{ position:absolute; inset:0; z-index:2; display:flex; flex-direction:column;
  justify-content:flex-end; padding:88px; }}
.cover .title {{ font-size:104px; font-weight:800; line-height:1.0; letter-spacing:-0.02em;
  text-transform:uppercase; max-width:880px; }}
.cover .rule {{ width:120px; height:12px; background:#E63946; margin:40px 0 32px; }}
.cover .subtitle {{ font-size:44px; font-weight:500; line-height:1.2; color:rgba(255,255,255,0.92); max-width:820px; }}
.cover .rodape {{ margin-top:72px; font-size:30px; font-weight:600; color:rgba(255,255,255,0.72); }}

.content {{ position:absolute; inset:0; z-index:2; display:flex; flex-direction:column;
  justify-content:center; padding:88px; }}
.content .tag {{ font-size:32px; font-weight:700; letter-spacing:0.22em; text-transform:uppercase;
  color:#E63946; margin-bottom:40px; }}
.content .headline {{ font-size:78px; font-weight:800; line-height:1.04; letter-spacing:-0.015em;
  max-width:900px; margin-bottom:48px; }}
.content ul {{ list-style:none; max-width:880px; }}
.content ul li {{ position:relative; font-size:40px; font-weight:500; line-height:1.32;
  padding-left:60px; margin-bottom:26px; }}
.content ul li::before {{ content:''; position:absolute; left:0; top:20px; width:30px; height:10px; background:#0077B6; }}
.content .detail {{ margin-top:56px; font-size:26px; line-height:1.4; color:rgba(255,255,255,0.66); max-width:860px; }}

.cta {{ position:absolute; inset:0; z-index:2; display:flex; flex-direction:column;
  justify-content:center; padding:88px; }}
.cta .headline {{ font-size:92px; font-weight:800; line-height:1.02; letter-spacing:-0.02em;
  text-transform:uppercase; max-width:900px; }}
.cta .subheadline {{ margin-top:32px; font-size:42px; font-weight:500; line-height:1.25;
  color:rgba(255,255,255,0.9); max-width:840px; }}
.cta .cta-box {{ margin-top:64px; align-self:flex-start; background:#E63946; color:#FFFFFF;
  font-size:40px; font-weight:700; letter-spacing:0.02em; padding:30px 56px; border-radius:9999px; }}
.cta .rodape {{ margin-top:auto; padding-top:48px; font-size:30px; font-weight:600;
  color:rgba(255,255,255,0.72); }}
</style>
</head>
<body>
{bg_layer}
{logo_html}
{body}
</body>
</html>'''

with open(out_html, "w", encoding="utf-8") as fh:
    fh.write(html_doc)
PY
then
  echo "error: failed to generate the slide HTML (see message above)" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Deterministic render: Chrome headless screenshot at exactly 1080x1080.
# ---------------------------------------------------------------------------
if ! convert_screenshot "$HTML_TMP" "$PNG_TMP" "$CANVAS_W" "$CANVAS_H"; then
  echo "error: Chrome failed to render slide $SLIDE (no PNG produced)" >&2
  exit 1
fi

MAGIC="$(img_magic "$PNG_TMP")"
if [[ "$MAGIC" != "89504e470d0a1a0a" ]]; then
  echo "error: rendered slide is not a valid PNG (magic mismatch: $MAGIC)" >&2
  exit 1
fi
DIMS="$(img_dims "$PNG_TMP")"
if [[ "$DIMS" != "${CANVAS_W}x${CANVAS_H}" ]]; then
  echo "error: rendered slide has dimension $DIMS, expected ${CANVAS_W}x${CANVAS_H} (BR 5)" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Atomic publish: PNG first (validated), then the HTML source sibling.
# ---------------------------------------------------------------------------
if ! convert_atomic_publish "$PNG_TMP" "$OUT"; then
  echo "error: failed to publish the slide PNG" >&2
  exit 1
fi
HTML_SIBLING="${OUT%.*}.html"
if [[ "$HTML_SIBLING" != "$OUT" ]]; then
  mv -f "$HTML_TMP" "$HTML_SIBLING"
fi
echo "Slide composed: $OUT"
