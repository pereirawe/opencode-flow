#!/usr/bin/env bash
# Tests for the deterministic Mermaid converter (issue #227):
# scripts/shared/convert-mermaid.sh + vendored assets/mermaid.min.js(.sha256).
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_convert_mermaid"

SHARED_DIR="$SCRIPT_DIR/../shared"
CONVERT="$SHARED_DIR/convert-mermaid.sh"
ASSET="$SHARED_DIR/assets/mermaid.min.js"
SIDE="$SHARED_DIR/assets/mermaid.min.js.sha256"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- vendored asset: pinned, checksummed, metadata sidecar (BR 10) ---
assert_eq "1" "$(test -f "$ASSET" && echo 1 || echo 0)" "vendored mermaid asset exists"
assert_eq "1" "$(test -f "$SIDE" && echo 1 || echo 0)" "checksum sidecar exists"
assert_contains "$SIDE" "mermaid.min.js" "sidecar names the pinned file"
assert_contains "$SIDE" "version=" "sidecar records the exact version"
assert_contains "$SIDE" "url=" "sidecar records the origin URL"
assert_contains "$SIDE" "license=MIT" "sidecar records the MIT license"

# sidecar first line must be a 64-hex checksum matching the asset
expected_sha="$(awk 'NR==1{print $1}' "$SIDE")"
if [[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]]; then
  actual_sha="$(sha256sum "$ASSET" | awk '{print $1}')"
  assert_eq "$expected_sha" "$actual_sha" "asset SHA-256 matches the versioned sidecar"
else
  t_fail "sidecar first line is not a 64-hex SHA-256 (got '$expected_sha')"
fi

# --- fixture ---
cat > "$TMP/flow.mmd" <<'MMDEOF'
graph TD
    A[Início] --> B{Decide}
    B -->|sim| C[OK]
    B -->|não| D[Fim]
MMDEOF

# --- usage / invalid input (exit 2, no artifact) ---
set +e
bash "$CONVERT" "$TMP/missing.mmd" "$TMP/out.svg" >/dev/null 2>&1
rc_missing=$?
set -e
assert_eq "2" "$rc_missing" "exits 2 when the input file is missing"
assert_eq "0" "$(test -e "$TMP/out.svg" && echo 1 || echo 0)" \
  "leaves no artifact on missing input"

set +e
bash "$CONVERT" "$TMP/flow.mmd" "$TMP/out.txt" >/dev/null 2>&1
rc_ext=$?
set -e
assert_eq "2" "$rc_ext" "exits 2 on unsupported output format (.txt)"

printf 'ok\x00invalid' > "$TMP/nul.mmd"
set +e
bash "$CONVERT" "$TMP/nul.mmd" "$TMP/nul.svg" >/dev/null 2>&1
rc_nul=$?
set -e
assert_eq "2" "$rc_nul" "exits 2 on NUL-byte input (encoding gate)"
assert_eq "0" "$(test -e "$TMP/nul.svg" && echo 1 || echo 0)" \
  "leaves no artifact on encoding failure"

# --- --check with Chrome missing (mocked PATH) -> exit 1, no artifact ---
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
PATH="$NOCHROME_DIR:$PATH" bash "$CONVERT" "$TMP/flow.mmd" "$TMP/nc.svg" --check >/dev/null 2>&1
rc_nc=$?
set -e
assert_eq "1" "$rc_nc" "--check exits 1 listing missing chrome"
assert_eq "0" "$(test -e "$TMP/nc.svg" && echo 1 || echo 0)" \
  "--check leaves no artifact when chrome is missing"

# --- HTML/SVG conversion (guarded by Chrome: mermaid renders in Chrome) ---
CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
if [[ -n "$CHROME" ]]; then
  set +e
  bash "$CONVERT" "$TMP/flow.mmd" "$TMP/out.html" >/dev/null 2>&1
  rc_html=$?
  set -e
  assert_eq "0" "$rc_html" "converts .mmd -> .html (offline Chrome render)"
  assert_eq "1" "$(test -s "$TMP/out.html" && echo 1 || echo 0)" "html is non-empty"
  assert_contains "$TMP/out.html" "<svg" "html contains the rendered SVG"
  assert_contains "$TMP/out.html" "Início" "svg contains a diagram node label"
  assert_contains "$TMP/out.html" "mermaid-source" \
    "original diagram is preserved as escaped data in the html (BR 8)"
  assert_not_contains "$TMP/out.html" "<script" \
    "no executable script remains in the preserved html"

  set +e
  bash "$CONVERT" "$TMP/flow.mmd" "$TMP/out.svg" >/dev/null 2>&1
  rc_svg=$?
  set -e
  assert_eq "0" "$rc_svg" "converts .mmd -> .svg"
  assert_eq "1" "$(test -s "$TMP/out.svg" && echo 1 || echo 0)" "svg is non-empty"
  assert_contains "$TMP/out.svg" "<svg" "svg artifact contains <svg> (BR 10)"
  assert_eq "1" "$(test -s "$TMP/out.html" && echo 1 || echo 0)" \
    "intermediate HTML is preserved next to the SVG (BR 2)"

  # --- determinism (BR 1): byte-identical second run ---
  bash "$CONVERT" "$TMP/flow.mmd" "$TMP/out2.svg" >/dev/null 2>&1
  assert_eq "$(sha256sum "$TMP/out.svg" | awk '{print $1}')" \
            "$(sha256sum "$TMP/out2.svg" | awk '{print $1}')" \
            "identical input -> identical SVG hash (determinism)"

  # --- PDF path (guarded by a PDF engine) ---
  if command -v google-chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1 \
     || command -v libreoffice >/dev/null 2>&1 || command -v soffice >/dev/null 2>&1; then
    set +e
    bash "$CONVERT" "$TMP/flow.mmd" "$TMP/out.pdf" >/dev/null 2>&1
    rc_pdf=$?
    set -e
    assert_eq "0" "$rc_pdf" "converts .mmd -> .pdf via the shared #226 engine"
    assert_eq "1" "$(test -s "$TMP/out.pdf" && echo 1 || echo 0)" "pdf is non-empty"
    assert_contains "$TMP/out.pdf" "%PDF" "pdf has a valid magic header"
  else
    echo "skip - no PDF engine; mermaid->pdf path not exercised"
  fi
else
  echo "skip - chrome not installed; mermaid render paths not exercised"
fi

t_finish
