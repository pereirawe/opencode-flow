#!/usr/bin/env bash
# Tests for scripts/marketing/slide-compose.sh + carousel-pdf.sh (issue #225 —
# deterministic 1080x1080 composition and deck.pdf assembly).
#
# Render assertions require Chrome + Pillow; they are skipped with a clear
# message when Chrome is unavailable (repo precedent: test_cv.sh guards).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_carousel_compose"

COMPOSE="$SCRIPT_DIR/../marketing/slide-compose.sh"
CAROUSEL_PDF="$SCRIPT_DIR/../marketing/carousel-pdf.sh"
CONVERT_LIB="$SCRIPT_DIR/../shared/convert-lib.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# CHROME detection via the shared lib (same source the scripts use).
CHROME="$(bash -c 'source "$1"; convert_find_chrome' _ "$CONVERT_LIB" || true)"
if [[ -z "$CHROME" ]]; then
  echo "skip - Chrome not available; slide compose/render assertions skipped"
fi

# --- fixtures ----------------------------------------------------------------
mkdir -p "$TMP/proj/docs/assets"
# Real logo PNG (Pillow) so the overlay path is exercised.
python3 - "$TMP/proj/docs/assets/logo.png" <<'PY'
from PIL import Image
import sys
Image.new("RGB", (200, 80), (0, 119, 182)).save(sys.argv[1], "PNG")
PY
# A non-square background to prove object-fit: cover normalization (540x540).
python3 - "$TMP/bg-small.png" <<'PY'
from PIL import Image
import sys
Image.new("RGB", (540, 540), (230, 57, 70)).save(sys.argv[1], "PNG")
PY
# A 64x64 "wrong dimension" PNG for the PDF gate failure test.
python3 - "$TMP/bg-tiny.png" <<'PY'
from PIL import Image
import sys
Image.new("RGB", (64, 64), (0, 0, 0)).save(sys.argv[1], "PNG")
PY

cat > "$TMP/proj/docs/assets/person.json" <<'JSON'
{
  "schema": "linkedin-carousel-person-v1",
  "name": "Maria Silva",
  "headline": "Engenheira de dados | transformo dados em decisoes",
  "handle": "in/maria-silva",
  "cta_text": "Salve este post",
  "logo_path": "logo.png"
}
JSON

DECK="$TMP/proj/docs/carousel/meudeck/deck.json"
mkdir -p "$(dirname "$DECK")"
cat > "$DECK" <<'JSON'
{
  "schema": "linkedin-carousel-deck-v1",
  "slug": "meudeck",
  "topic": "Arquitetura limpa na pratica",
  "locale": "pt",
  "n_slides": 3,
  "created": "2026-09-09T13:27:00Z",
  "open_questions": [],
  "slides": [
    {
      "index": 1,
      "type": "cover",
      "design_prompt": "Design a bold editorial background, dark and minimal, square 1080x1080, no text.",
      "text": {"TITULO": "Arquitetura limpa", "SUBTITULO": "7 pontos para codigo sustentavel", "RODAPE": "Maria Silva · in/maria-silva"},
      "sources": []
    },
    {
      "index": 2,
      "type": "content",
      "design_prompt": "Design a calm abstract background, dark blue tones, square 1080x1080, no text.",
      "text": {"TAG": "Principio 1", "HEADLINE": "Dependencias explicitas", "BULLETS": ["Injete as dependencias", "Nada de globais"], "DETALHE": "Fonte: clean-architecture.org"},
      "sources": [{"url": "https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html", "accessed": "2026-09-09", "note": "principio de dependencias"}]
    },
    {
      "index": 3,
      "type": "cta",
      "design_prompt": "Design a minimal final background, red accent, square 1080x1080, no text.",
      "text": {"HEADLINE": "Gostou?", "SUBHEADLINE": "Siga para mais conteudo", "CTA": "Salve este post", "RODAPE": "Maria Silva · in/maria-silva"},
      "sources": []
    }
  ]
}
JSON

# A deck with an unescaped-injection title (HTML-escaping test).
DECK_XSS="$TMP/deck-xss.json"
python3 - "$DECK" "$DECK_XSS" <<'PY'
import json, sys
deck = json.load(open(sys.argv[1], encoding="utf-8"))
deck["slides"][0]["text"]["TITULO"] = "<script>alert(1)</script> & <b>bold</b>"
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    json.dump(deck, fh, ensure_ascii=False, indent=2)
PY

# Deck with only 2 slides (BR 4 violation).
DECK_SHORT="$TMP/deck-short.json"
python3 - "$DECK" "$DECK_SHORT" <<'PY'
import json, sys
deck = json.load(open(sys.argv[1], encoding="utf-8"))
deck["n_slides"] = 2
deck["slides"] = deck["slides"][:2]
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    json.dump(deck, fh, ensure_ascii=False, indent=2)
PY

# run helper
COMP_OUT=""; COMP_RC=""
run_compose() {
  set +e
  COMP_OUT="$(bash "$COMPOSE" "$@" 2>&1)"
  COMP_RC=$?
  set -e
}
PDF_OUT=""; PDF_RC=""
run_pdf() {
  set +e
  PDF_OUT="$(bash "$CAROUSEL_PDF" "$@" 2>&1)"
  PDF_RC=$?
  set -e
}
img_dims() { python3 - "$1" <<'PY'
from PIL import Image
import sys
try:
    im = Image.open(sys.argv[1]); print(f"{im.width}x{im.height}")
except Exception: pass
PY
}
png_magic() { head -c 8 "$1" | od -An -tx1 | tr -d ' \n' || true; }

# --- syntax -------------------------------------------------------------------
set +e
bash -n "$COMPOSE"; rc1=$?
bash -n "$CAROUSEL_PDF"; rc2=$?
set -e
assert_eq "0" "$rc1" "slide-compose.sh passes bash -n"
assert_eq "0" "$rc2" "carousel-pdf.sh passes bash -n"

# --- compose: usage / input validation -----------------------------------------
run_compose
assert_eq "2" "$COMP_RC" "compose without args -> exit 2 (usage)"

run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 1
assert_eq "2" "$COMP_RC" "compose without --out -> exit 2"

run_compose --deck "$TMP/nope.json" --person "$TMP/proj/docs/assets/person.json" --slide 1 --out "$TMP/o.png"
assert_eq "2" "$COMP_RC" "compose with missing deck -> exit 2"

run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 99 --out "$TMP/o.png"
assert_eq "2" "$COMP_RC" "compose with unknown slide index -> exit 2"
if [[ "$COMP_OUT" == *"not found in deck"* ]]; then
  t_ok "unknown slide error message is clear"
else
  t_fail "unknown slide message not clear: $COMP_OUT"
fi

# --- compose: deterministic renders --------------------------------------------
if [[ -n "$CHROME" ]]; then
  OUT_COVER="$TMP/slides/slide-01.png"
  mkdir -p "$(dirname "$OUT_COVER")"
  run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 1 --out "$OUT_COVER"
  assert_eq "0" "$COMP_RC" "cover compose (no bg) succeeds"
  if [[ -s "$OUT_COVER" ]]; then
    assert_eq "89504e470d0a1a0a" "$(png_magic "$OUT_COVER")" "cover PNG magic bytes"
    assert_eq "1080x1080" "$(img_dims "$OUT_COVER")" "cover PNG is exactly 1080x1080 (BR 5)"
  else
    t_fail "cover PNG missing or empty"
  fi

  # Determinism: same input -> byte-identical output.
  OUT_COVER2="$TMP/slides/slide-01b.png"
  run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 1 --out "$OUT_COVER2"
  assert_eq "0" "$COMP_RC" "cover compose second run succeeds"
  if [[ -s "$OUT_COVER2" ]] && cmp -s "$OUT_COVER" "$OUT_COVER2"; then
    t_ok "compose is deterministic (byte-identical PNG)"
  else
    t_fail "compose is NOT byte-deterministic across runs"
  fi

  # Content slide with a NON-square background -> object-fit: cover normalizes.
  OUT_CONTENT="$TMP/slides/slide-02.png"
  run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 2 \
    --bg "$TMP/bg-small.png" --out "$OUT_CONTENT"
  assert_eq "0" "$COMP_RC" "content compose with 540x540 bg succeeds"
  assert_eq "1080x1080" "$(img_dims "$OUT_CONTENT")" "content PNG normalized to exactly 1080x1080"
  if [[ -f "$TMP/slides/slide-02.html" ]]; then
    assert_contains "$TMP/slides/slide-02.html" "object-fit:cover" "composed HTML uses object-fit: cover for the bg"
    assert_contains "$TMP/slides/slide-02.html" "bg-small.png" "composed HTML references the background URL"
  else
    t_fail "composed HTML sibling not written"
  fi

  # Logo overlay: the composed HTML must embed the validated logo (bottom-right).
  if [[ -f "$TMP/slides/slide-01.html" ]]; then
    assert_contains "$TMP/slides/slide-01.html" "logo.png" "composed HTML embeds the logo overlay"
  else
    t_fail "cover HTML sibling missing (logo assertion)"
  fi

  # CTA slide.
  OUT_CTA="$TMP/slides/slide-03.png"
  run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 3 \
    --bg "$TMP/bg-small.png" --out "$OUT_CTA"
  assert_eq "0" "$COMP_RC" "cta compose with bg succeeds"
  assert_eq "1080x1080" "$(img_dims "$OUT_CTA")" "cta PNG is exactly 1080x1080"

  # HTML escaping: raw <script> must NEVER reach the HTML; the copy is escaped.
  OUT_XSS="$TMP/slides/xss.png"
  run_compose --deck "$DECK_XSS" --person "$TMP/proj/docs/assets/person.json" --slide 1 --out "$OUT_XSS"
  assert_eq "0" "$COMP_RC" "compose with <script> in TITULO still succeeds"
  if [[ -f "$TMP/slides/xss.html" ]]; then
    assert_not_contains "$TMP/slides/xss.html" "<script>alert(1)</script>" "raw <script> never reaches the HTML"
    assert_contains "$TMP/slides/xss.html" "&lt;script&gt;" "TITULO is HTML-escaped (&lt;script&gt;)"
  else
    t_fail "xss HTML sibling missing (escaping assertion)"
  fi

  # Background magic gate: a non-image --bg is rejected BEFORE any render.
  printf 'definitely not an image' > "$TMP/fake-bg.txt"
  run_compose --deck "$DECK" --person "$TMP/proj/docs/assets/person.json" --slide 1 \
    --bg "$TMP/fake-bg.txt" --out "$TMP/slides/fake.png"
  assert_eq "2" "$COMP_RC" "non-image background -> exit 2 (magic gate)"
  assert_eq "0" "$(test -f "$TMP/slides/fake.png" && echo 1 || echo 0)" "non-image bg leaves NO PNG"
else
  echo "skip - compose render assertions (no Chrome)"
fi

# --- carousel-pdf ---------------------------------------------------------------
run_pdf
assert_eq "2" "$PDF_RC" "carousel-pdf without args -> exit 2 (usage)"

run_pdf --deck "$TMP/nope.json" --images "$TMP" --out "$TMP/deck.pdf"
assert_eq "2" "$PDF_RC" "carousel-pdf with missing deck -> exit 2"

run_pdf --deck "$DECK_SHORT" --images "$TMP" --out "$TMP/deck.pdf"
assert_eq "2" "$PDF_RC" "carousel-pdf with N<3 deck -> exit 2 (BR 4)"

if [[ -n "$CHROME" ]]; then
  # Happy path: all slides valid -> deck.pdf with one square page per slide.
  IMG_OK="$TMP/imgs-ok"
  mkdir -p "$IMG_OK"
  cp "$TMP/slides/slide-01.png" "$IMG_OK/slide-01.png"
  cp "$TMP/slides/slide-02.png" "$IMG_OK/slide-02.png"
  cp "$TMP/slides/slide-03.png" "$IMG_OK/slide-03.png"
  run_pdf --deck "$DECK" --images "$IMG_OK" --out "$TMP/out-ok/deck.pdf"
  assert_eq "0" "$PDF_RC" "carousel-pdf with 3 valid slides succeeds"
  if [[ -s "$TMP/out-ok/deck.pdf" ]]; then
    assert_eq "%PDF" "$(head -c 4 "$TMP/out-ok/deck.pdf")" "deck.pdf has PDF magic"
    if command -v pdfinfo >/dev/null 2>&1; then
      PAGES="$(pdfinfo "$TMP/out-ok/deck.pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')" || PAGES="0"
      assert_eq "3" "$PAGES" "deck.pdf has 3 pages (one per slide)"
      # Square pages (BR 5): width == height in the pdfinfo box report.
      # Matches both "Page size: 810 x 810 pts" and "Page    1 size: 810 x 810 pts".
      BOX="$(pdfinfo -box "$TMP/out-ok/deck.pdf" 2>/dev/null | awk '/size:/{for(i=1;i<=NF;i++){if($i=="x"){print $(i-1), $(i+1); exit}}}')" || BOX=""
      if [[ -n "$BOX" ]]; then
        W="${BOX%% *}"; H="${BOX##* }"
        if [[ "$W" == "$H" ]]; then
          t_ok "deck.pdf pages are square ($W x $H)"
        else
          t_fail "deck.pdf pages not square: $BOX"
        fi
      else
        t_fail "pdfinfo -box produced no page size"
      fi
    else
      echo "skip - pdfinfo not available; page count/square assertions skipped"
    fi
  else
    t_fail "deck.pdf missing or empty"
  fi

  # Missing slide image -> exit 2 (input error).
  IMG_MISSING="$TMP/imgs-missing"
  mkdir -p "$IMG_MISSING"
  cp "$IMG_OK/slide-01.png" "$IMG_MISSING/slide-01.png"
  run_pdf --deck "$DECK" --images "$IMG_MISSING" --out "$TMP/out-missing/deck.pdf"
  assert_eq "2" "$PDF_RC" "missing slide image -> exit 2"
  assert_eq "0" "$(test -f "$TMP/out-missing/deck.pdf" && echo 1 || echo 0)" "missing slide leaves NO deck.pdf"

  # Invalid dimension -> exit 1 (validation gate), NO deck.pdf.
  IMG_BAD="$TMP/imgs-bad"
  mkdir -p "$IMG_BAD"
  cp "$IMG_OK/slide-01.png" "$IMG_BAD/slide-01.png"
  cp "$TMP/bg-tiny.png" "$IMG_BAD/slide-02.png"
  cp "$IMG_OK/slide-03.png" "$IMG_BAD/slide-03.png"
  run_pdf --deck "$DECK" --images "$IMG_BAD" --out "$TMP/out-bad/deck.pdf"
  assert_eq "1" "$PDF_RC" "slide with wrong dimension -> exit 1 (gate)"
  if [[ "$PDF_OUT" == *"1080x1080"* ]]; then
    t_ok "dimension gate error message mentions the expected size"
  else
    t_fail "dimension gate message not clear: $PDF_OUT"
  fi
  assert_eq "0" "$(test -f "$TMP/out-bad/deck.pdf" && echo 1 || echo 0)" "invalid dimension leaves NO deck.pdf"
else
  echo "skip - carousel-pdf assertions (no Chrome)"
fi

t_finish
