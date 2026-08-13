#!/usr/bin/env bash
# Tests for the career CV scripts: scripts/cv/validate.py and scripts/cv/pdf.sh.
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_cv"

CV_DIR="$SCRIPT_DIR/../cv"
VALIDATOR="$CV_DIR/validate.py"
PDF_SH="$CV_DIR/pdf.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- validate.py ---
TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-valid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "dados_pessoais": {"nome": "Teste"},
  "resumo": "resumo",
  "experiencia": [{"empresa": "Acme", "cargo": "Dev"}],
  "educacao": [{"instituicao": "USP", "curso": "CC"}],
  "skills": [{"nome": "Python"}],
  "certificacoes": [{"nome": "AWS"}],
  "projetos": [{"nome": "proj"}],
  "idiomas": [{"idioma": "Inglês"}],
  "links": [{"nome": "GH", "url": "https://github.com/x"}]
}
json.dump(hub, open(os.path.join(tmp, "hub-valid.json"), "w"))
EOF

TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-invalid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "dados_pessoais": {"nome": "Teste"},
  "resumo": "resumo",
  "experiencia": [{"empresa": "Acme"}],  # missing cargo
  "educacao": [],
  "skills": [],
  "certificacoes": [],
  "projetos": [],
  "idiomas": [],
  "links": []
}
json.dump(hub, open(os.path.join(tmp, "hub-invalid.json"), "w"))
EOF

set +e
python3 "$VALIDATOR" "$TMP/hub-valid.json" >/dev/null 2>&1
rc_valid=$?
python3 "$VALIDATOR" "$TMP/hub-invalid.json" >/dev/null 2>&1
rc_invalid=$?
set -e

assert_eq "0" "$rc_valid" "validate.py accepts a valid hub.json"
assert_eq "1" "$rc_invalid" "validate.py rejects a hub.json with missing required field"
assert_eq "2" "$(python3 "$VALIDATOR" 2>/dev/null; echo $?)" "validate.py returns 2 without arguments"
assert_eq "2" "$(python3 "$VALIDATOR" "$TMP/nope.json" 2>/dev/null; echo $?)" "validate.py returns 2 for missing file"

# --- pdf.sh ---
cat > "$TMP/resume.html" <<'HTMLEOF'
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<style>@page { size: A4; margin: 16mm; } body { font-family: sans-serif; }</style>
</head><body><h1>Test Resume</h1><p>ATS-friendly text.</p></body></html>
HTMLEOF

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)"
if [[ -n "$CHROME" ]]; then
  set +e
  bash "$PDF_SH" "$TMP/resume.html" "$TMP/resume.pdf" chrome >/dev/null 2>&1
  rc_pdf=$?
  set -e
  assert_eq "0" "$rc_pdf" "pdf.sh produces a PDF via Chrome headless"
  assert_eq "1" "$(test -s "$TMP/resume.pdf" && echo 1 || echo 0)" "generated PDF is non-empty"
  # ATS-extractable text
  if command -v pdftotext >/dev/null 2>&1; then
    EXTRACTED="$(pdftotext "$TMP/resume.pdf" - 2>/dev/null || true)"
    if [[ "$EXTRACTED" == *"Test Resume"* ]]; then
      t_ok "generated PDF is ATS-extractable (text readable)"
    else
      t_fail "generated PDF text not extractable (expected 'Test Resume')"
    fi
  fi
else
  echo "skip - chrome not installed; pdf.sh chrome path not exercised"
fi

# pdf.sh should fail cleanly (exit 2) when input file is missing
set +e
bash "$PDF_SH" "$TMP/missing.html" "$TMP/out.pdf" >/dev/null 2>&1
rc_missing=$?
set -e
assert_eq "2" "$rc_missing" "pdf.sh exits 2 when the input HTML is missing"

t_finish
