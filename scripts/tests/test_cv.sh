#!/usr/bin/env bash
# Tests for the career CV scripts: scripts/cv/validate.py, scripts/cv/pdf.sh,
# the scripts/cv/check-inferido.sh gate, and scripts/cv/migrate-schema.py.
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_cv"

CV_DIR="$SCRIPT_DIR/../cv"
VALIDATOR="$CV_DIR/validate.py"
PDF_SH="$CV_DIR/pdf.sh"
CHECK_INFERIDO="$CV_DIR/check-inferido.sh"
MIGRATE="$CV_DIR/migrate-schema.py"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- validate.py ---
TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-valid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "personal_info": {"name": "Test"},
  "summary": "summary",
  "experience": [{"company": "Acme", "title": "Dev"}],
  "education": [{"institution": "USP", "course": "CS"}],
  "skills": [{"name": "Python"}],
  "certifications": [{"name": "AWS"}],
  "projects": [{"name": "proj"}],
  "languages": [{"language": "English"}],
  "links": [{"name": "GH", "url": "https://github.com/x"}]
}
json.dump(hub, open(os.path.join(tmp, "hub-valid.json"), "w"))
EOF

TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-invalid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "personal_info": {"name": "Test"},
  "summary": "summary",
  "experience": [{"company": "Acme"}],  # missing title
  "education": [],
  "skills": [],
  "certifications": [],
  "projects": [],
  "languages": [],
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
assert_eq "1" "$rc_invalid" "validate.py rejects a hub.json with a missing required field"
assert_eq "2" "$(python3 "$VALIDATOR" 2>/dev/null; echo $?)" "validate.py returns 2 without arguments"
assert_eq "2" "$(python3 "$VALIDATOR" "$TMP/nope.json" 2>/dev/null; echo $?)" "validate.py returns 2 for a missing file"

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

  # Non-ASCII output path (e.g. ~/career/joão-silva/) must render content,
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

# pdf.sh should fail cleanly (exit 2) when the input file is missing
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

# validate.py must reject non-object personal_info and non-string summary
TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-badtypes.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "personal_info": "not-an-object",
  "summary": 123,
  "experience": [], "education": [], "skills": [], "certifications": [],
  "projects": [], "languages": [], "links": []
}
json.dump(hub, open(os.path.join(tmp, "hub-badtypes.json"), "w"))
EOF

set +e
python3 "$VALIDATOR" "$TMP/hub-badtypes.json" >/dev/null 2>&1
rc_badtypes=$?
set -e
assert_eq "1" "$rc_badtypes" "validate.py rejects non-object personal_info and non-string summary"

# validate.py must handle a directory argument cleanly (exit 2, no traceback)
set +e
python3 "$VALIDATOR" "$TMP" >/dev/null 2>&1
rc_dir=$?
set -e
assert_eq "2" "$rc_dir" "validate.py exits 2 (not a traceback) for a directory argument"

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

# --- check-inferido.sh gate ---
# The gate blocks [INFERIDO] markers (case-insensitive) in the FINAL HTML/PDF.
# Internal artifacts (hub.json, gap-analysis.md, inferencias.md) keep them.

# 1. HTML with uppercase [INFERIDO] -> exit 1, occurrence listed
cat > "$TMP/inferido-upper.html" <<'HTMLEOF'
<!DOCTYPE html><html><body><h1>Dev</h1><p>English level [INFERIDO]</p></body></html>
HTMLEOF
set +e
CHECK_OUT="$(bash "$CHECK_INFERIDO" "$TMP/inferido-upper.html" 2>&1)"
rc_gate_upper=$?
set -e
assert_eq "1" "$rc_gate_upper" "gate exits 1 when HTML contains [INFERIDO]"
if [[ "$CHECK_OUT" == *"[INFERIDO]"* ]]; then
  t_ok "gate error message lists the occurrence"
else
  t_fail "gate error message does not list the occurrence: $CHECK_OUT"
fi

# 2. HTML with lowercase [inferido] -> exit 1
cat > "$TMP/inferido-lower.html" <<'HTMLEOF'
<!DOCTYPE html><html><body><h1>Dev</h1><p>Course [inferido]</p></body></html>
HTMLEOF
set +e
bash "$CHECK_INFERIDO" "$TMP/inferido-lower.html" >/dev/null 2>&1
rc_gate_lower=$?
set -e
assert_eq "1" "$rc_gate_lower" "gate exits 1 for lowercase [inferido]"

# 3. HTML without markers -> exit 0 (PDF generation may proceed)
cat > "$TMP/inferido-clean.html" <<'HTMLEOF'
<!DOCTYPE html><html><body><h1>Dev</h1><p>English course — advanced level.</p></body></html>
HTMLEOF
set +e
bash "$CHECK_INFERIDO" "$TMP/inferido-clean.html" >/dev/null 2>&1
rc_gate_clean=$?
set -e
assert_eq "0" "$rc_gate_clean" "gate exits 0 for a clean HTML without markers"

# 4. Gate usage error without arguments -> exit 2
set +e
bash "$CHECK_INFERIDO" >/dev/null 2>&1
rc_gate_usage=$?
set -e
assert_eq "2" "$rc_gate_usage" "gate exits 2 without arguments"

# 5. Missing file -> exit 2
set +e
bash "$CHECK_INFERIDO" "$TMP/nope.html" >/dev/null 2>&1
rc_gate_missing=$?
set -e
assert_eq "2" "$rc_gate_missing" "gate exits 2 for a missing file"

# 6. PDF input scanned via pdftotext when available (best-effort)
if command -v pdftotext >/dev/null 2>&1; then
  if [[ -s "$TMP/resume.pdf" ]]; then
    set +e
    bash "$CHECK_INFERIDO" "$TMP/resume.pdf" >/dev/null 2>&1
    rc_gate_pdf=$?
    set -e
    assert_eq "0" "$rc_gate_pdf" "gate exits 0 for a clean PDF (pdftotext path)"
  fi
fi

# 7. PDF containing [INFERIDO] text must be BLOCKED via pdftotext (BR 10)
if command -v pdftotext >/dev/null 2>&1 && [[ -n "$CHROME" ]]; then
  printf '<!DOCTYPE html><html><body><h1>Dev</h1><p>English level [INFERIDO]</p></body></html>\n' > "$TMP/inferido-pdf.html"
  set +e
  bash "$PDF_SH" "$TMP/inferido-pdf.html" "$TMP/inferido-pdf.pdf" chrome >/dev/null 2>&1
  rc_make_pdf=$?
  set -e
  if [[ "$rc_make_pdf" -eq 0 && -s "$TMP/inferido-pdf.pdf" ]]; then
    set +e
    bash "$CHECK_INFERIDO" "$TMP/inferido-pdf.pdf" >/dev/null 2>&1
    rc_gate_pdf_block=$?
    set -e
    assert_eq "1" "$rc_gate_pdf_block" "gate blocks a PDF whose text contains [INFERIDO]"
  else
    echo "skip - could not render [INFERIDO] PDF fixture; blocking-PDF path not exercised"
  fi
fi

# --- migrate-schema.py (issue #64: pt -> en hub.json migration) ---
MIGRATE_SCRIPT="$CV_DIR/migrate-schema.py"
if [[ -f "$MIGRATE_SCRIPT" ]]; then
  # 1. A legacy Portuguese-keyed hub is rejected by validate.py (English schema)
  cat > "$TMP/hub-pt.json" <<'EOF'
{
  "dados_pessoais": {"nome": "Maria Silva", "titulo_profissional": "Data Engineer", "cidade": "São Paulo", "pretensao_salarial": "R$ 15k"},
  "resumo": "executive summary",
  "resumo_i18n": {"pt": "...", "en": "..."},
  "experiencia": [{"empresa": "Acme", "cargo": "Dev", "inicio": "2021-03", "fim": "atual", "atual": true, "tipo": "CLT", "resumo": "r", "conquistas": ["x"], "tecnologias": ["Python"]}],
  "educacao": [{"instituicao": "USP", "curso": "CS", "tipo": "Graduação", "status": "Concluído"}],
  "skills": [{"nome": "Python", "categoria": "linguagem", "nivel": "avancado", "desde": "2018", "anos_experiencia": 6, "importancia": "principal"}],
  "certificacoes": [{"nome": "AWS", "emissor": "AWS", "ano": "2023"}],
  "projetos": [{"nome": "p", "descricao": "d", "relevancia": "alta"}],
  "idiomas": [{"idioma": "English", "nivel": "fluente", "nota_escala": "C1"}],
  "links": [{"nome": "GH", "url": "https://github.com/x"}],
  "fontes": ["curriculo.pdf"],
  "data_geracao": "2026-08-15"
}
EOF
  set +e
  python3 "$VALIDATOR" "$TMP/hub-pt.json" >/dev/null 2>&1
  rc_pt_unmigrated=$?
  set -e
  assert_eq "1" "$rc_pt_unmigrated" "validate.py rejects a legacy Portuguese-keyed hub"

  # 2. Migration produces an English hub that passes validation
  set +e
  python3 "$MIGRATE_SCRIPT" "$TMP/hub-pt.json" --output "$TMP/hub-migrated.json" --validate "$VALIDATOR" >/dev/null 2>&1
  rc_migrate=$?
  set -e
  assert_eq "0" "$rc_migrate" "migrate-schema.py converts a Portuguese hub successfully"
  assert_eq "1" "$(test -s "$TMP/hub-migrated.json" && echo 1 || echo 0)" "migrated hub file written"
  python3 "$VALIDATOR" "$TMP/hub-migrated.json" >/dev/null 2>&1 || {
    t_fail "migrated hub is not valid against the English schema"
  }
  python3 - <<EOF
import json
hub = json.load(open("$TMP/hub-migrated.json"))
assert "personal_info" in hub and hub["personal_info"]["name"] == "Maria Silva"
assert hub["summary"] == "executive summary"
assert hub["experience"][0]["company"] == "Acme" and hub["experience"][0]["title"] == "Dev"
assert hub["experience"][0]["end_date"] == "present" and hub["experience"][0]["current"] is True
assert hub["experience"][0]["type"] == "CLT"
assert hub["education"][0]["status"] == "completed"
assert hub["education"][0]["type"] == "Bachelor's degree"
assert hub["skills"][0]["since"] == "2018" and hub["skills"][0]["level"] == "advanced"
assert hub["skills"][0]["importance"] == "primary" and hub["skills"][0]["category"] == "language"
assert hub["languages"][0]["language"] == "English" and hub["languages"][0]["level"] == "fluent"
assert hub["languages"][0]["scale_note"] == "C1"
assert hub["certifications"][0]["issuer"] == "AWS"
assert hub["sources"] == ["curriculo.pdf"] and hub["version"] == 2
EOF
  t_ok "migrated hub has English keys, translated enums, and schema version 2"

  # 3. Idempotency: re-running on an already-English hub is a no-op
  set +e
  python3 "$MIGRATE_SCRIPT" "$TMP/hub-migrated.json" --output "$TMP/hub-migrated2.json" >/dev/null 2>&1
  rc_migrate_idem=$?
  set -e
  assert_eq "0" "$rc_migrate_idem" "migrate-schema.py is idempotent on an English hub"
  if diff -q "$TMP/hub-migrated.json" "$TMP/hub-migrated2.json" >/dev/null 2>&1; then
    t_ok "idempotent migration produces identical output"
  else
    t_fail "idempotent migration changed the already-English hub"
  fi

  # 4. Missing file -> exit 1, clear error
  set +e
  python3 "$MIGRATE_SCRIPT" "$TMP/nope-hub.json" >/dev/null 2>&1
  rc_migrate_missing=$?
  set -e
  assert_eq "1" "$rc_migrate_missing" "migrate-schema.py exits 1 for a missing file"
else
  t_fail "migrate-schema.py missing at $MIGRATE_SCRIPT"
fi

# --- cv-tailor / cv-optimizer contract (issue #62) ---
TAILOR_SKILL="$SCRIPT_DIR/../../skills/career/cv-tailor/SKILL.md"
if [[ -f "$TAILOR_SKILL" ]]; then
  # skill cv-tailor must NOT instruct marking [INFERIDO] in the HTML/PDF final
  assert_not_contains "$TAILOR_SKILL" "marcado \`[INFERIDO]\` no HTML/PDF" \
    "cv-tailor skill no longer instructs marking [INFERIDO] in the HTML/PDF"
  assert_not_contains "$TAILOR_SKILL" "marcar \`[INFERIDO]\`" \
    "cv-tailor skill has no 'mark [INFERIDO]' instruction"
  # it MUST document the mandatory gate before the PDF
  assert_contains "$TAILOR_SKILL" "check-inferido.sh" \
    "cv-tailor skill mandates the check-inferido.sh gate"
  # and the human-decision flow via inferencias.md
  assert_contains "$TAILOR_SKILL" "inferencias.md" \
    "cv-tailor skill documents the inferencias.md human-decision flow"
  # issue #64: the skill MUST use the English schema keys
  assert_contains "$TAILOR_SKILL" "summary_i18n" \
    "cv-tailor skill references the English summary_i18n key"
  assert_not_contains "$TAILOR_SKILL" "resumo_i18n" \
    "cv-tailor skill has no legacy resumo_i18n key"
else
  t_fail "cv-tailor skill missing at $TAILOR_SKILL"
fi

TAILOR_AGENT="$SCRIPT_DIR/../../agents/career/cv-tailor.md"
if [[ -f "$TAILOR_AGENT" ]]; then
  assert_not_contains "$TAILOR_AGENT" "marcado \`[INFERIDO]\` no HTML/PDF" \
    "cv-tailor agent no longer instructs marking [INFERIDO] in the HTML/PDF"
  assert_contains "$TAILOR_AGENT" "check-inferido.sh" \
    "cv-tailor agent invokes the check-inferido.sh gate"
  assert_contains "$TAILOR_AGENT" "inferencias.md" \
    "cv-tailor agent documents the inferencias.md human-decision flow"
else
  t_fail "cv-tailor agent missing at $TAILOR_AGENT"
fi

# cv-hub / cv-optimizer KEEP [INFERIDO] in internal artifacts (regression zero)
OPT_SKILL="$SCRIPT_DIR/../../skills/career/cv-optimizer/SKILL.md"
if [[ -f "$OPT_SKILL" ]]; then
  assert_contains "$OPT_SKILL" "[INFERIDO]" \
    "cv-optimizer skill keeps [INFERIDO] markers in internal artifacts (regression)"
fi

# --- cv-optimizer contract ---
# The skill/agent must not modify hub.json. Verify the skill file references
# validate.py and mandates [INFERIDO] + never-modify-hub rules (English).
if [[ -f "$OPT_SKILL" ]]; then
  assert_contains "$OPT_SKILL" "[INFERIDO]" "cv-optimizer skill mandates [INFERIDO] markers"
  assert_contains "$OPT_SKILL" "NEVER modify \`hub.json\`" "cv-optimizer skill forbids hub.json edits"
  assert_contains "$OPT_SKILL" "validate.py" "cv-optimizer skill references hub validation"
  assert_contains "$OPT_SKILL" "analise-perfil.md" "cv-optimizer skill defines report output"
  assert_contains "$OPT_SKILL" "analise-perfil.pdf" "cv-optimizer skill defines PDF output"
  assert_contains "$OPT_SKILL" "NO metadata header" "cv-optimizer skill forbids metadata header"
  assert_contains "$OPT_SKILL" "since" "cv-optimizer skill uses the English since field"
  assert_contains "$OPT_SKILL" "current year − \`since\`" "cv-optimizer skill computes skill years dynamically"
  assert_not_contains "$OPT_SKILL" "\`desde\`" "cv-optimizer skill has no legacy desde field"
else
  t_fail "cv-optimizer skill missing at $OPT_SKILL"
fi

# validate.py must accept a valid 'since' year and reject malformed ones
TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-since-valid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "personal_info": {"name": "T"}, "summary": "r",
  "experience": [], "education": [], "certifications": [], "projects": [],
  "languages": [], "links": [],
  "skills": [{"name": "Python", "since": "2018"}]
}
json.dump(hub, open(os.path.join(tmp, "hub-since-valid.json"), "w"))
EOF

TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-since-invalid.json"
import json, os
tmp = os.environ["TMP_ENV"]
hub = {
  "personal_info": {"name": "T"}, "summary": "r",
  "experience": [], "education": [], "certifications": [], "projects": [],
  "languages": [], "links": [],
  "skills": [{"name": "Python", "since": "20a8"}]
}
json.dump(hub, open(os.path.join(tmp, "hub-since-invalid.json"), "w"))
EOF

TMP_ENV="$TMP" python3 - <<'EOF' > "$TMP/hub-since-future.json"
import json, os, time
tmp = os.environ["TMP_ENV"]
hub = {
  "personal_info": {"name": "T"}, "summary": "r",
  "experience": [], "education": [], "certifications": [], "projects": [],
  "languages": [], "links": [],
  "skills": [{"name": "Python", "since": str(int(time.strftime("%Y")) + 5)}]
}
json.dump(hub, open(os.path.join(tmp, "hub-since-future.json"), "w"))
EOF

set +e
python3 "$VALIDATOR" "$TMP/hub-since-valid.json" >/dev/null 2>&1
rc_since_ok=$?
python3 "$VALIDATOR" "$TMP/hub-since-invalid.json" >/dev/null 2>&1
rc_since_bad=$?
python3 "$VALIDATOR" "$TMP/hub-since-future.json" >/dev/null 2>&1
rc_since_future=$?
set -e
assert_eq "0" "$rc_since_ok" "validate.py accepts a skill with valid since (YYYY)"
assert_eq "1" "$rc_since_bad" "validate.py rejects a skill with malformed since"
assert_eq "1" "$rc_since_future" "validate.py rejects a skill with future since"

# --- cv-design standard + reference template (issue #63) ---
CV_DESIGN="$SCRIPT_DIR/../../standards/cv-design.md"
CV_TEMPLATE="$SCRIPT_DIR/../../skills/career/cv-pdf/templates/resume.html"
PDF_SKILL="$SCRIPT_DIR/../../skills/career/cv-pdf/SKILL.md"
TAILOR_CMD="$SCRIPT_DIR/../../commands/ocf:cv-tailor.md"

# 1. Reference template exists and declares @page A4 with 12-15mm margins
if [[ -f "$CV_TEMPLATE" ]]; then
  assert_contains "$CV_TEMPLATE" "@page" "cv-pdf template declares @page"
  assert_contains "$CV_TEMPLATE" "A4" "cv-pdf template uses A4 page size"
  assert_contains "$CV_TEMPLATE" "12mm" "cv-pdf template uses 12-15mm margins (12mm present)"
  # 5. No Google Fonts / emoji in the template (ATS + sober style)
  assert_not_contains "$CV_TEMPLATE" "fonts.googleapis.com" "cv-pdf template has no Google Fonts links"
  assert_not_contains "$CV_TEMPLATE" "fonts.gstatic.com" "cv-pdf template has no Google Fonts CDN"
  if LC_ALL=C grep -q $'\xF0\x9F' "$CV_TEMPLATE" 2>/dev/null; then
    t_fail "cv-pdf template contains emoji (4-byte UTF-8 sequence)"
  else
    t_ok "cv-pdf template contains no emoji"
  fi
else
  t_fail "cv-pdf template missing at $CV_TEMPLATE"
fi

# 2. cv-pdf skill mandates standards/cv-design.md and the reference template
if [[ -f "$PDF_SKILL" ]]; then
  assert_contains "$PDF_SKILL" "standards/cv-design.md" "cv-pdf skill mandates standards/cv-design.md"
  assert_contains "$PDF_SKILL" "templates/resume.html" "cv-pdf skill references the reference template"
  assert_contains "$PDF_SKILL" "12mm" "cv-pdf skill documents 12-15mm margins"
else
  t_fail "cv-pdf skill missing at $PDF_SKILL"
fi

# 3. cv-tailor skill references the reference template and the standard
if [[ -f "$TAILOR_SKILL" ]]; then
  assert_contains "$TAILOR_SKILL" "templates/resume.html" "cv-tailor skill references the reference template"
  assert_contains "$TAILOR_SKILL" "standards/cv-design.md" "cv-tailor skill mandates standards/cv-design.md"
else
  t_fail "cv-tailor skill missing at $TAILOR_SKILL"
fi

# 4. cv-tailor agent and command instruct template usage + conformity check (AC 4)
if [[ -f "$TAILOR_AGENT" ]]; then
  assert_contains "$TAILOR_AGENT" "templates/resume.html" "cv-tailor agent references the reference template"
  assert_contains "$TAILOR_AGENT" "standards/cv-design.md" "cv-tailor agent mandates standards/cv-design.md"
else
  t_fail "cv-tailor agent missing at $TAILOR_AGENT"
fi

if [[ -f "$TAILOR_CMD" ]]; then
  assert_contains "$TAILOR_CMD" "templates/resume.html" "ocf:cv-tailor command references the reference template"
  assert_contains "$TAILOR_CMD" "standards/cv-design.md" "ocf:cv-tailor command mandates standards/cv-design.md"
else
  t_fail "ocf:cv-tailor command missing at $TAILOR_CMD"
fi

# 5. Design standard exists with testable ATS/print/page rules (AC 1)
if [[ -f "$CV_DESIGN" ]]; then
  assert_contains "$CV_DESIGN" "WCAG AA" "cv-design standard documents the 4.5:1 contrast rule"
  assert_contains "$CV_DESIGN" "A4" "cv-design standard mandates A4"
  assert_contains "$CV_DESIGN" "12mm" "cv-design standard documents 12-15mm margins"
else
  t_fail "cv-design standard missing at $CV_DESIGN"
fi

t_finish
