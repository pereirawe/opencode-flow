#!/usr/bin/env bash
# Tests for the deterministic Markdown converter (issue #227):
# scripts/shared/convert-md.sh + convert-md.py.
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_convert_md"

SHARED_DIR="$SCRIPT_DIR/../shared"
CONVERT="$SHARED_DIR/convert-md.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- fixture ---
cat > "$TMP/sample.md" <<'MDEOF'
# Title

A paragraph with **bold**, *italic* and `code`.

- item one
- item two
  - nested item
- item three

1. first
2. second

> a quote

```python
print("hi")
```

| Name | Qty |
|------|----:|
| A    |   1 |
| B    |   2 |

[link](https://example.com)

<div>raw html must be escaped</div>

![missing-local.png](missing-local.png)
MDEOF

# --- structural ---
assert_eq "1" "$(test -x "$CONVERT" && echo 1 || echo 0)" "convert-md.sh is executable"
assert_contains "$CONVERT" "convert-md.sh <input.md> <output.html|output.pdf>" \
  "script documents the generic CLI"

# --- usage / invalid input (exit 2, no artifact) ---
set +e
bash "$CONVERT" "$TMP/missing.md" "$TMP/out.html" >/dev/null 2>&1
rc_missing=$?
set -e
assert_eq "2" "$rc_missing" "exits 2 when the input markdown is missing"
assert_eq "0" "$(test -e "$TMP/out.html" && echo 1 || echo 0)" \
  "leaves no artifact on missing input"

set +e
bash "$CONVERT" "$TMP/sample.md" "$TMP/out.txt" >/dev/null 2>&1
rc_ext=$?
set -e
assert_eq "2" "$rc_ext" "exits 2 on unsupported output format (.txt)"

printf 'ok\x00invalid' > "$TMP/nul.md"
set +e
bash "$CONVERT" "$TMP/nul.md" "$TMP/nul.html" >/dev/null 2>&1
rc_nul=$?
set -e
assert_eq "2" "$rc_nul" "exits 2 on NUL-byte input (encoding gate)"
assert_eq "0" "$(test -e "$TMP/nul.html" && echo 1 || echo 0)" \
  "leaves no artifact on encoding failure"

# --- HTML conversion ---
set +e
bash "$CONVERT" "$TMP/sample.md" "$TMP/out.html" >/dev/null 2>&1
rc_html=$?
set -e
assert_eq "0" "$rc_html" "converts .md -> .html"
assert_eq "1" "$(test -s "$TMP/out.html" && echo 1 || echo 0)" "html is non-empty"
assert_contains "$TMP/out.html" "<h1>Title</h1>" "ATX heading rendered"
assert_contains "$TMP/out.html" "<strong>bold</strong>" "bold rendered"
assert_contains "$TMP/out.html" "<em>italic</em>" "italic rendered"
assert_contains "$TMP/out.html" "<code>code</code>" "inline code rendered"
assert_contains "$TMP/out.html" "<ul>" "unordered list rendered"
assert_contains "$TMP/out.html" "<ol>" "ordered list rendered"
assert_contains "$TMP/out.html" "item one" "list item one rendered"
assert_contains "$TMP/out.html" "item two" "list item two rendered (parent preserved)"
assert_contains "$TMP/out.html" "nested item" "nested list item rendered (no content loss)"
assert_contains "$TMP/out.html" "item three" "sibling item after a nested list rendered (Q1 regression)"
assert_contains "$TMP/out.html" "<blockquote>" "blockquote rendered"
assert_contains "$TMP/out.html" 'class="language-python"' "fenced code keeps the language"
assert_contains "$TMP/out.html" "<table>" "GFM pipe table rendered"
assert_contains "$TMP/out.html" '<a href="https://example.com">link</a>' "link rendered"
assert_contains "$TMP/out.html" "&lt;div&gt;raw html must be escaped&lt;/div&gt;" \
  "raw HTML is escaped (BR 8), never active markup"
assert_not_contains "$TMP/out.html" "<div>raw html" \
  "raw HTML is not interpreted as a tag"

# --- determinism (BR 1): byte-identical second run ---
bash "$CONVERT" "$TMP/sample.md" "$TMP/out2.html" >/dev/null 2>&1
assert_eq "$(sha256sum "$TMP/out.html" | awk '{print $1}')" \
          "$(sha256sum "$TMP/out2.html" | awk '{print $1}')" \
          "identical input -> identical HTML hash (determinism)"

# --- --check ---
set +e
bash "$CONVERT" "$TMP/sample.md" "$TMP/check.html" --check >/dev/null 2>&1
rc_check2=$?
set -e
assert_eq "0" "$rc_check2" "--check passes when python3 is present"
assert_eq "0" "$(test -e "$TMP/check.html" && echo 1 || echo 0)" \
  "--check creates no artifact"

# --- --check with python3 missing (mocked PATH) -> exit 1, no artifact ---
NOPY_DIR="$TMP/nopy"
mkdir -p "$NOPY_DIR"
for e in python3 python; do
  cat > "$NOPY_DIR/$e" <<'EOF'
#!/usr/bin/env bash
exit 127
EOF
  chmod +x "$NOPY_DIR/$e"
done
set +e
PATH="$NOPY_DIR:$PATH" bash "$CONVERT" "$TMP/sample.md" "$TMP/nopy.html" --check >/dev/null 2>&1
rc_nopy=$?
set -e
assert_eq "1" "$rc_nopy" "--check exits 1 listing missing python3"
assert_eq "0" "$(test -e "$TMP/nopy.html" && echo 1 || echo 0)" \
  "--check leaves no artifact when a dependency is missing"

# --- PDF path (guarded by a PDF engine) ---
if command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1 \
   || command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1 \
   || command -v libreoffice >/dev/null 2>&1 || command -v soffice >/dev/null 2>&1; then
  set +e
  bash "$CONVERT" "$TMP/sample.md" "$TMP/out.pdf" >/dev/null 2>&1
  rc_pdf=$?
  set -e
  assert_eq "0" "$rc_pdf" "converts .md -> .pdf via the shared #226 engine"
  assert_eq "1" "$(test -s "$TMP/out.pdf" && echo 1 || echo 0)" "pdf is non-empty"
  assert_contains "$TMP/out.pdf" "%PDF" "pdf has a valid magic header"
  assert_eq "1" "$(test -s "$TMP/out.html" && echo 1 || echo 0)" \
    "intermediate HTML is preserved next to the PDF (BR 2)"
else
  echo "skip - no PDF engine; md->pdf path not exercised"
fi

t_finish
