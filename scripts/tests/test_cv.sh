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

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
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
    if [[ "$EXTRACTED" == *"file://"* ]]; then
      t_fail "generated PDF contains a browser header (file:// URL leaked)"
    else
      t_ok "generated PDF has no browser header/footer"
    fi
  fi

  # Non-ASCII output path (e.g. ~/carreira/joão-silva/) must render content,
  # not Chrome's error page (regression for file_url UTF-8 encoding).
  mkdir -p "$TMP/joão-silva"
  cp "$TMP/resume.html" "$TMP/joão-silva/index.html"
  set +e
  bash "$PDF_SH" "$TMP/joão-silva/index.html" "$TMP/joão-silva/curriculo.pdf" chrome >/dev/null 2>&1
  rc_accent=$?
  set -e
  assert_eq "0" "$rc_accent" "pdf.sh handles a non-ASCII output path"
  if command -v pdftotext >/dev/null 2>&1 && [[ -s "$TMP/joão-silva/curriculo.pdf" ]]; then
    ACCENTED="$(pdftotext "$TMP/joão-silva/curriculo.pdf" - 2>/dev/null || true)"
    if [[ "$ACCENTED" == *"Test Resume"* ]]; then
      t_ok "non-ASCII path renders the real content (not a Chrome error page)"
    else
      t_fail "non-ASCII path produced Chrome's error page instead of content"
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

# pdf.sh should create the output dir when missing (regression for M1/M2)
set +e
bash "$PDF_SH" "$TMP/resume.html" "$TMP/deep/nested/out.pdf" chrome >/dev/null 2>&1
rc_deep=$?
set -e
assert_eq "0" "$rc_deep" "pdf.sh creates a missing output directory"
assert_eq "1" "$(test -s "$TMP/deep/nested/out.pdf" && echo 1 || echo 0)" "PDF written into created output dir"

# validate.py must reject non-object dados_pessoais and non-string resumo
TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-badtypes.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "dados_pessoais": "not-an-object",
  "resumo": 123,
  "experiencia": [], "educacao": [], "skills": [], "certificacoes": [],
  "projetos": [], "idiomas": [], "links": []
}
json.dump(hub, open(os.path.join(tmp, "hub-badtypes.json"), "w"))
EOF

set +e
python3 "$VALIDATOR" "$TMP/hub-badtypes.json" >/dev/null 2>&1
rc_badtypes=$?
set -e
assert_eq "1" "$rc_badtypes" "validate.py rejects non-object dados_pessoais and non-string resumo"

# validate.py must handle a directory argument cleanly (exit 2, no traceback)
set +e
python3 "$VALIDATOR" "$TMP" >/dev/null 2>&1
rc_dir=$?
set -e
assert_eq "2" "$rc_dir" "validate.py exits 2 (not traceback) for a directory argument"

# --- LibreOffice fallback (mocked) ---
# Mock libreoffice in PATH: it writes <outdir>/<stem>.pdf from the HTML copy in
# outdir, then pdf.sh must move it to OUTPUT_ABS. Regression for the fallback
# path when input and output are in different directories (review H1).
MOCK_DIR="$TMP/mockbin"
mkdir -p "$MOCK_DIR"
cat > "$MOCK_DIR/libreoffice" <<'EOF'
#!/usr/bin/env bash
# Mock: emulate `libreoffice --headless --convert-to pdf --outdir OUT IN`
outdir=""; input=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --outdir) outdir="$2"; shift 2 ;;
    --convert-to) shift 2 ;;
    *) input="$1"; shift ;;
  esac
done
if [[ -z "$outdir" || -z "$input" ]]; then exit 1; fi
stem="${input%.*}"; stem="$(basename "$stem")"
# produce a real PDF so the -s check passes
printf '%%PDF-1.4\n%%\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[]/Count 0>>endobj\nxref\n0 3\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \ntrailer<</Size 3/Root 1 0 R>>\nstartxref\n97\n%%%%EOF\n' > "$outdir/$stem.pdf"
EOF
chmod +x "$MOCK_DIR/libreoffice"

# Input in one dir, output in another — fallback must land at OUTPUT_ABS.
mkdir -p "$TMP/in" "$TMP/out"
cp "$TMP/resume.html" "$TMP/in/resume.html"
set +e
PATH="$MOCK_DIR:$PATH" bash "$PDF_SH" "$TMP/in/resume.html" "$TMP/out/curriculo.pdf" libreoffice >/dev/null 2>&1
rc_lo=$?
set -e
assert_eq "0" "$rc_lo" "LibreOffice fallback succeeds with input and output in different dirs"
assert_eq "1" "$(test -s "$TMP/out/curriculo.pdf" && echo 1 || echo 0)" "fallback PDF moved to OUTPUT_ABS (not stranded in input dir)"

# Same-dir invocation (the documented flow: pdf.sh index.html curriculo.pdf)
# must also work — cp/mv "same file" guard (regression CRITICAL-1).
mkdir -p "$TMP/samedir"
cp "$TMP/resume.html" "$TMP/samedir/index.html"
set +e
PATH="$MOCK_DIR:$PATH" bash "$PDF_SH" "$TMP/samedir/index.html" "$TMP/samedir/curriculo.pdf" libreoffice >/dev/null 2>&1
rc_samedir=$?
set -e
assert_eq "0" "$rc_samedir" "LibreOffice fallback succeeds in the same-dir invocation"
assert_eq "1" "$(test -s "$TMP/samedir/curriculo.pdf" && echo 1 || echo 0)" "same-dir fallback PDF written"

# --- cv-optimizer contract ---
# The skill/agent must not modify hub.json. Verify the skill file references
# validate.py and mandates [INFERIDO] + never-modify-hub rules.
OPT_SKILL="$SCRIPT_DIR/../../skills/career/cv-optimizer/SKILL.md"
if [[ -f "$OPT_SKILL" ]]; then
  assert_contains "$OPT_SKILL" "[INFERIDO]" "cv-optimizer skill mandates [INFERIDO] markers"
  assert_contains "$OPT_SKILL" "NUNCA modificar \`hub.json\`" "cv-optimizer skill forbids hub.json edits"
  assert_contains "$OPT_SKILL" "validate.py" "cv-optimizer skill references hub validation"
  assert_contains "$OPT_SKILL" "analise-perfil.md" "cv-optimizer skill defines report output"
  assert_contains "$OPT_SKILL" "analise-perfil.pdf" "cv-optimizer skill defines PDF output"
  assert_contains "$OPT_SKILL" "NENHUM cabeçalho de metadados" "cv-optimizer skill forbids metadata header"
  assert_contains "$OPT_SKILL" "desde" "cv-optimizer skill uses skill desde field"
  assert_contains "$OPT_SKILL" "ano atual − \`desde\`" "cv-optimizer skill computes skill years dynamically"
else
  t_fail "cv-optimizer skill missing at $OPT_SKILL"
fi

# validate.py must accept a valid 'desde' year and reject malformed ones
TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-desde-valid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "dados_pessoais": {"nome": "T"}, "resumo": "r",
  "experiencia": [], "educacao": [], "certificacoes": [], "projetos": [],
  "idiomas": [], "links": [],
  "skills": [{"nome": "Python", "desde": "2018"}]
}
json.dump(hub, open(os.path.join(tmp, "hub-desde-valid.json"), "w"))
EOF

TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-desde-invalid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "dados_pessoais": {"nome": "T"}, "resumo": "r",
  "experiencia": [], "educacao": [], "certificacoes": [], "projetos": [],
  "idiomas": [], "links": [],
  "skills": [{"nome": "Python", "desde": "20a8"}]
}
json.dump(hub, open(os.path.join(tmp, "hub-desde-invalid.json"), "w"))
EOF

set +e
python3 "$VALIDATOR" "$TMP/hub-desde-valid.json" >/dev/null 2>&1
rc_desde_ok=$?
python3 "$VALIDATOR" "$TMP/hub-desde-invalid.json" >/dev/null 2>&1
rc_desde_bad=$?
set -e
assert_eq "0" "$rc_desde_ok" "validate.py accepts a skill with valid desde (YYYY)"
assert_eq "1" "$rc_desde_bad" "validate.py rejects a skill with malformed desde"

t_finish
