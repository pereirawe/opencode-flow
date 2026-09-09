#!/usr/bin/env bash
# Tests for the deterministic Excalidraw converter (issue #227):
# scripts/shared/convert-excalidraw.sh + convert-excalidraw.py.
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_convert_excalidraw"

SHARED_DIR="$SCRIPT_DIR/../shared"
CONVERT="$SHARED_DIR/convert-excalidraw.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1x1 transparent PNG as data: URI (image pass-through fixture)
PNG_1x1="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

# --- fixture: closed v1 subset (rectangle, arrow, text, image) ---
cat > "$TMP/sample.json" <<JSONEOF
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    {"type":"rectangle","x":0,"y":0,"width":200,"height":100,
     "strokeColor":"#1e1e1e","backgroundColor":"#a5d8ff","fillStyle":"solid",
     "strokeWidth":2,"angle":0},
    {"type":"arrow","x":220,"y":50,"width":0,"height":0,
     "points":[[0,0],[100,0]],"strokeColor":"#e03131","strokeWidth":2},
    {"type":"text","x":0,"y":130,"text":"Hello","fontSize":24,"fontFamily":2,
     "strokeColor":"#1e1e1e"},
    {"type":"image","x":0,"y":170,"width":60,"height":60,
     "dataURI":"data:image/png;base64,${PNG_1x1}"}
  ],
  "appState": {"viewBackgroundColor":"#ffffff"}
}
JSONEOF

# --- fixture with an out-of-subset element (frame) ---
cat > "$TMP/with-frame.json" <<JSONEOF
{
  "type": "excalidraw",
  "version": 2,
  "elements": [
    {"type":"rectangle","x":0,"y":0,"width":200,"height":100,
     "strokeColor":"#1e1e1e","backgroundColor":"#a5d8ff","fillStyle":"solid",
     "strokeWidth":2,"angle":0},
    {"type":"frame","x":0,"y":120,"width":120,"height":80,
     "strokeColor":"#1e1e1e","name":"frame-1"}
  ],
  "appState": {"viewBackgroundColor":"#ffffff"}
}
JSONEOF

# --- structural ---
assert_eq "1" "$(test -x "$CONVERT" && echo 1 || echo 0)" "convert-excalidraw.sh is executable"

# --- usage / invalid input (exit 2, no artifact) ---
set +e
bash "$CONVERT" "$TMP/missing.json" "$TMP/out.html" >/dev/null 2>&1
rc_missing=$?
set -e
assert_eq "2" "$rc_missing" "exits 2 when the input JSON is missing"
assert_eq "0" "$(test -e "$TMP/out.html" && echo 1 || echo 0)" \
  "leaves no artifact on missing input"

set +e
bash "$CONVERT" "$TMP/sample.json" "$TMP/out.png" >/dev/null 2>&1
rc_ext=$?
set -e
assert_eq "2" "$rc_ext" "exits 2 on unsupported output format (.png)"

# broken JSON -> exit 2 (BR 11)
printf '{ not valid json' > "$TMP/broken.json"
set +e
bash "$CONVERT" "$TMP/broken.json" "$TMP/broken.html" >/dev/null 2>&1
rc_broken=$?
set -e
assert_eq "2" "$rc_broken" "exits 2 on broken JSON (schema violation)"
assert_eq "0" "$(test -e "$TMP/broken.html" && echo 1 || echo 0)" \
  "leaves no artifact on broken JSON"

# JSON without an elements array -> exit 2
printf '{"type":"excalidraw","appState":{}}' > "$TMP/noelements.json"
set +e
bash "$CONVERT" "$TMP/noelements.json" "$TMP/noel.html" >/dev/null 2>&1
rc_noel=$?
set -e
assert_eq "2" "$rc_noel" "exits 2 when the JSON has no elements array"
assert_eq "0" "$(test -e "$TMP/noel.html" && echo 1 || echo 0)" \
  "leaves no artifact when the schema is invalid"

printf 'ok\x00invalid' > "$TMP/nul.json"
set +e
bash "$CONVERT" "$TMP/nul.json" "$TMP/nul.html" >/dev/null 2>&1
rc_nul=$?
set -e
assert_eq "2" "$rc_nul" "exits 2 on NUL-byte input (encoding gate)"
assert_eq "0" "$(test -e "$TMP/nul.html" && echo 1 || echo 0)" \
  "leaves no artifact on encoding failure"

# --- HTML conversion ---
set +e
bash "$CONVERT" "$TMP/sample.json" "$TMP/out.html" >/dev/null 2>&1
rc_html=$?
set -e
assert_eq "0" "$rc_html" "converts .json -> .html"
assert_eq "1" "$(test -s "$TMP/out.html" && echo 1 || echo 0)" "html is non-empty"
assert_contains "$TMP/out.html" "<svg" "html contains an inline SVG"
assert_contains "$TMP/out.html" "<rect" "rectangle element rendered"
assert_contains "$TMP/out.html" "<polyline" "arrow element rendered"
assert_contains "$TMP/out.html" "<text" "text element rendered"
assert_contains "$TMP/out.html" "Hello" "text content present"
assert_contains "$TMP/out.html" "<image" "image element rendered"
assert_contains "$TMP/out.html" "data:image/png;base64" "image data: URI passed through"

# --- determinism (BR 1): byte-identical second run ---
bash "$CONVERT" "$TMP/sample.json" "$TMP/out2.html" >/dev/null 2>&1
assert_eq "$(sha256sum "$TMP/out.html" | awk '{print $1}')" \
          "$(sha256sum "$TMP/out2.html" | awk '{print $1}')" \
          "identical input -> identical HTML hash (determinism)"

# --- out-of-subset element: warning on stderr, exit 0, valid artifact (BR 11) ---
set +e
bash "$CONVERT" "$TMP/with-frame.json" "$TMP/frame.html" >"$TMP/frame.out" 2>"$TMP/frame.err"
rc_frame=$?
set -e
assert_eq "0" "$rc_frame" "out-of-subset element does not abort (exit 0)"
if grep -qi "frame" "$TMP/frame.err"; then
  t_ok "stderr warning names the out-of-subset element (frame)"
else
  t_fail "stderr warning names the out-of-subset element (frame)"
fi
assert_eq "1" "$(test -s "$TMP/frame.html" && echo 1 || echo 0)" \
  "valid artifact still generated with an out-of-subset element"

# --- SVG conversion ---
set +e
bash "$CONVERT" "$TMP/sample.json" "$TMP/out.svg" >/dev/null 2>&1
rc_svg=$?
set -e
assert_eq "0" "$rc_svg" "converts .json -> .svg"
assert_eq "1" "$(test -s "$TMP/out.svg" && echo 1 || echo 0)" "svg is non-empty"
assert_contains "$TMP/out.svg" "<svg" "svg artifact contains <svg>"
assert_eq "1" "$(test -s "$TMP/out.html" && echo 1 || echo 0)" \
  "intermediate HTML is preserved next to the SVG (BR 2)"

# --- --check: chrome missing for jpeg -> exit 1, no artifact ---
NOCHROME_DIR="$TMP/nochrome"
mkdir -p "$NOCHROME_DIR"
for e in google-chrome google-chrome-stable chromium chromium-browser; do
  cat > "$NOCHROME_DIR/$e" <<'EOF'
#!/usr/bin/env bash
exit 127
EOF
  chmod +x "$NOCHROME_DIR/$e"
done
set +e
PATH="$NOCHROME_DIR:$PATH" bash "$CONVERT" "$TMP/sample.json" "$TMP/nc.jpeg" --check >/dev/null 2>&1
rc_nc=$?
set -e
assert_eq "1" "$rc_nc" "--check exits 1 for jpeg when chrome is missing"
assert_eq "0" "$(test -e "$TMP/nc.jpeg" && echo 1 || echo 0)" \
  "--check leaves no artifact when a dependency is missing"

# --- JPEG path (guarded by Chrome + a PNG->JPEG converter) ---
CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
HAVE_JPEG=0
if command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' >/dev/null 2>&1; then
  HAVE_JPEG=1
elif command -v convert >/dev/null 2>&1; then
  HAVE_JPEG=1
elif command -v cjpeg >/dev/null 2>&1 && command -v pngtopnm >/dev/null 2>&1; then
  HAVE_JPEG=1
fi
if [[ -n "$CHROME" && "$HAVE_JPEG" == "1" ]]; then
  set +e
  bash "$CONVERT" "$TMP/sample.json" "$TMP/out.jpeg" >/dev/null 2>&1
  rc_jpeg=$?
  set -e
  assert_eq "0" "$rc_jpeg" "converts .json -> .jpeg"
  assert_eq "1" "$(test -s "$TMP/out.jpeg" && echo 1 || echo 0)" "jpeg is non-empty"
  assert_eq "$(printf '\xff\xd8' | od -An -tx1 | tr -d ' \n')" \
            "$(od -An -tx1 -N2 "$TMP/out.jpeg" | tr -d ' \n')" \
            "jpeg has a valid FFD8 magic header"
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' >/dev/null 2>&1; then
    dims="$(python3 -c 'from PIL import Image; print("x".join(map(str, Image.open("'"$TMP/out.jpeg"'").size)))')"
    # canvas = elements bounding box (0..320 x 0..230) + 2*20 padding => 360x270
    assert_eq "360x270" "$dims" "jpeg dimensions equal the original canvas (BR 12)"
  fi
else
  echo "skip - chrome or png->jpeg converter missing; jpeg path not exercised"
fi

# --- PDF path (guarded by a PDF engine) ---
if command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1 \
   || command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1 \
   || command -v libreoffice >/dev/null 2>&1 || command -v soffice >/dev/null 2>&1; then
  set +e
  bash "$CONVERT" "$TMP/sample.json" "$TMP/out.pdf" >/dev/null 2>&1
  rc_pdf=$?
  set -e
  assert_eq "0" "$rc_pdf" "converts .json -> .pdf via the shared #226 engine"
  assert_eq "1" "$(test -s "$TMP/out.pdf" && echo 1 || echo 0)" "pdf is non-empty"
  assert_contains "$TMP/out.pdf" "%PDF" "pdf has a valid magic header"
else
  echo "skip - no PDF engine; excalidraw->pdf path not exercised"
fi

t_finish
