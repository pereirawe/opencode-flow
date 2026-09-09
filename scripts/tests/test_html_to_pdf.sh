#!/usr/bin/env bash
# Tests for the shared HTML->PDF core (issue #226): scripts/shared/html-to-pdf.sh
# and the backward-compat wrapper scripts/cv/pdf.sh.
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_html_to_pdf"

SHARED_DIR="$SCRIPT_DIR/../shared"
SHARED="$SHARED_DIR/html-to-pdf.sh"
WRAPPER="$SCRIPT_DIR/../cv/pdf.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- fixtures ---
cat > "$TMP/input.html" <<'HTMLEOF'
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<style>@page { size: A4; margin: 16mm; } body { font-family: sans-serif; }</style>
</head><body><h1>Shared Core</h1><p>Generic HTML->PDF text.</p></body></html>
HTMLEOF

# --- structural: shared script is executable and has the generic contract ---
assert_eq "1" "$(test -x "$SHARED" && echo 1 || echo 0)" "shared html-to-pdf.sh is executable"
assert_contains "$SHARED" "html-to-pdf.sh <input.html> <output.pdf>" \
  "shared script documents the generic CLI"
assert_not_contains "$SHARED" "resume" \
  "shared script has no career/cv vocabulary in its content"

# --- wrapper structural: zero duplication (delegates, has no render function) ---
assert_contains "$WRAPPER" "html-to-pdf.sh" \
  "wrapper references the shared core (delegation)"
assert_not_contains "$WRAPPER" "render_chrome" \
  "wrapper has NO Chrome render function (zero duplication)"
assert_not_contains "$WRAPPER" "--print-to-pdf" \
  "wrapper has NO direct Chrome --print-to-pdf call (zero duplication)"
assert_not_contains "$WRAPPER" "check_encoding" \
  "wrapper has NO encoding gate (logic lives in shared only)"
assert_eq "1" "$(test -x "$WRAPPER" && echo 1 || echo 0)" "wrapper cv/pdf.sh is executable"

# --- shared direct: Chrome path (guarded by Chrome presence) ---
CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
if [[ -n "$CHROME" ]]; then
  set +e
  bash "$SHARED" "$TMP/input.html" "$TMP/out.pdf" chrome >/dev/null 2>&1
  rc=$?
  set -e
  assert_eq "0" "$rc" "shared produces a PDF via Chrome headless (direct)"
  assert_eq "1" "$(test -s "$TMP/out.pdf" && echo 1 || echo 0)" "shared PDF is non-empty"
  assert_contains "$TMP/out.pdf" "%PDF" "shared PDF has a valid PDF magic header"

  # Non-ASCII output path (file:// percent-encoding)
  mkdir -p "$TMP/saída-joão"
  cp "$TMP/input.html" "$TMP/saída-joão/index.html"
  set +e
  bash "$SHARED" "$TMP/saída-joão/index.html" "$TMP/saída-joão/doc.pdf" chrome >/dev/null 2>&1
  rc_accent=$?
  set -e
  assert_eq "0" "$rc_accent" "shared handles a non-ASCII output path"

  # Missing output dir is created
  set +e
  bash "$SHARED" "$TMP/input.html" "$TMP/deep/nested/out.pdf" chrome >/dev/null 2>&1
  rc_deep=$?
  set -e
  assert_eq "0" "$rc_deep" "shared creates a missing output directory"
  assert_eq "1" "$(test -s "$TMP/deep/nested/out.pdf" && echo 1 || echo 0)" \
    "shared PDF written into created output dir"
else
  echo "skip - chrome not installed; shared chrome path not exercised"
fi

# --- shared direct: input missing -> exit 2, no artifact ---
set +e
bash "$SHARED" "$TMP/missing.html" "$TMP/nope.pdf" >/dev/null 2>&1
rc_missing=$?
set -e
assert_eq "2" "$rc_missing" "shared exits 2 when the input HTML is missing"
assert_eq "0" "$(test -e "$TMP/nope.pdf" && echo 1 || echo 0)" \
  "shared leaves no artifact on missing input"

# --- shared direct: corrupted input encoding -> non-zero, no artifact ---
printf 'ok\x00invalid' > "$TMP/nul.html"
set +e
bash "$SHARED" "$TMP/nul.html" "$TMP/nul.pdf" >/dev/null 2>&1
rc_nul=$?
set -e
if [[ "$rc_nul" -ne 0 ]]; then
  t_ok "shared rejects input with NUL bytes (exit != 0, got $rc_nul)"
else
  t_fail "shared rejects input with NUL bytes (expected non-zero, got 0)"
fi
assert_eq "0" "$(test -e "$TMP/nul.pdf" && echo 1 || echo 0)" \
  "shared leaves no artifact on encoding failure"

# --- shared direct: engines absent (mocked PATH prepend) -> exit 1, no artifact ---
# Mock: shadow chrome/libreoffice binaries with failing stubs, but KEEP the
# real PATH (coreutils must remain available to the script).
NOENGINE_DIR="$TMP/noengine"
mkdir -p "$NOENGINE_DIR"
for e in google-chrome google-chrome-stable chromium chromium-browser libreoffice soffice; do
  cat > "$NOENGINE_DIR/$e" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$NOENGINE_DIR/$e"
done
set +e
PATH="$NOENGINE_DIR:$PATH" bash "$SHARED" "$TMP/input.html" "$TMP/eng.pdf" >/dev/null 2>&1
rc_eng=$?
set -e
assert_eq "1" "$rc_eng" "shared exits 1 when no PDF engine is available"
assert_eq "0" "$(test -e "$TMP/eng.pdf" && echo 1 || echo 0)" \
  "shared leaves no artifact when no engine is available"

# --- wrapper: backward-compat delegation (same CLI contract) ---
set +e
bash "$WRAPPER" "$TMP/missing.html" "$TMP/wrap.pdf" >/dev/null 2>&1
rc_wrap_missing=$?
set -e
assert_eq "2" "$rc_wrap_missing" "wrapper preserves exit 2 on missing input"
assert_eq "0" "$(test -e "$TMP/wrap.pdf" && echo 1 || echo 0)" \
  "wrapper leaves no artifact on missing input"

if [[ -n "$CHROME" ]]; then
  set +e
  bash "$WRAPPER" "$TMP/input.html" "$TMP/wrap.pdf" chrome >/dev/null 2>&1
  rc_wrap=$?
  set -e
  assert_eq "0" "$rc_wrap" "wrapper produces a PDF via delegation (Chrome)"
  assert_eq "1" "$(test -s "$TMP/wrap.pdf" && echo 1 || echo 0)" \
    "wrapper-delegated PDF is non-empty"
fi

t_finish
