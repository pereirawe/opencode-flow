#!/usr/bin/env bash
# Tests for the career CV scripts: scripts/cv/validate.py, scripts/cv/pdf.sh,
# the scripts/cv/check-inference.sh gate, and scripts/cv/migrate-schema.py.
# Self-contained: generates its own fixtures under a temp dir, no network, no TTY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_cv"

CV_DIR="$SCRIPT_DIR/../cv"
VALIDATOR="$CV_DIR/validate.py"
PDF_SH="$CV_DIR/pdf.sh"
CHECK_INFERIDO="$CV_DIR/check-inference.sh"
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

# --- check-inference.sh gate ---
# The gate blocks [INFERIDO] markers (case-insensitive) in the FINAL HTML/PDF.
# Internal artifacts (hub.json, gap-analysis.md, inferences.md) keep them.

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
  assert_contains "$TAILOR_SKILL" "check-inference.sh" \
    "cv-tailor skill mandates the check-inference.sh gate"
  # and the human-decision flow via inferences.md
  assert_contains "$TAILOR_SKILL" "inferences.md" \
    "cv-tailor skill documents the inferences.md human-decision flow"
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
  assert_contains "$TAILOR_AGENT" "check-inference.sh" \
    "cv-tailor agent invokes the check-inference.sh gate"
  assert_contains "$TAILOR_AGENT" "inferences.md" \
    "cv-tailor agent documents the inferences.md human-decision flow"
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
  assert_contains "$OPT_SKILL" "profile-analysis.md" "cv-optimizer skill defines report output"
  assert_contains "$OPT_SKILL" "profile-analysis.pdf" "cv-optimizer skill defines PDF output"
  assert_contains "$OPT_SKILL" "NO metadata header" "cv-optimizer skill forbids metadata header"
  assert_contains "$OPT_SKILL" "since" "cv-optimizer skill uses the English since field"
  assert_contains "$OPT_SKILL" "current year − \`since\`" "cv-optimizer skill computes skill years dynamically"
  assert_not_contains "$OPT_SKILL" "\`desde\`" "cv-optimizer skill has no legacy desde field"
else
  t_fail "cv-optimizer skill missing at $OPT_SKILL"
fi

# --- cv-cover-letter contract (issue #66) ---
CL_SKILL="$SCRIPT_DIR/../../skills/career/cv-cover-letter/SKILL.md"
if [[ -f "$CL_SKILL" ]]; then
  # English schema keys (issue #64) — no legacy Portuguese keys
  assert_not_contains "$CL_SKILL" "resumo_i18n" \
    "cv-cover-letter skill has no legacy resumo_i18n key"
  assert_contains "$CL_SKILL" "summary_i18n" \
    "cv-cover-letter skill references the English summary_i18n key"
  # mandatory [INFERIDO] gate before the PDF + design/analysis standards
  assert_contains "$CL_SKILL" "check-inference.sh" \
    "cv-cover-letter skill mandates the check-inference.sh gate"
  assert_contains "$CL_SKILL" "standards/cv-design.md" \
    "cv-cover-letter skill mandates standards/cv-design.md"
  assert_contains "$CL_SKILL" "standards/cv-analysis.md" \
    "cv-cover-letter skill references standards/cv-analysis.md"
  assert_contains "$CL_SKILL" "templates/resume.html" \
    "cv-cover-letter skill references the reference template"
  # output structure per BR 8 (cartas/<slug>/carta-apresentacao.pdf + index.html)
  assert_contains "$CL_SKILL" "cartas/<job-slug>" \
    "cv-cover-letter skill defines the cartas/<job-slug> output directory"
  assert_contains "$CL_SKILL" "carta-apresentacao.pdf" \
    "cv-cover-letter skill defines carta-apresentacao.pdf output"
  assert_contains "$CL_SKILL" "NEVER invent" \
    "cv-cover-letter skill forbids fabrication (BR 5)"
  assert_contains "$CL_SKILL" "inferences.md" \
    "cv-cover-letter skill documents the inferences.md human-decision flow"
else
  t_fail "cv-cover-letter skill missing at $CL_SKILL"
fi

CL_AGENT="$SCRIPT_DIR/../../agents/career/cv-cover-letter.md"
if [[ -f "$CL_AGENT" ]]; then
  assert_contains "$CL_AGENT" "check-inference.sh" \
    "cv-cover-letter agent invokes the check-inference.sh gate"
  assert_contains "$CL_AGENT" "~/career/**" \
    "cv-cover-letter agent restricts edits to ~/career/** (BR 11)"
  assert_contains "$CL_AGENT" "validate.py" \
    "cv-cover-letter agent validates the hub (BR 2)"
  assert_contains "$CL_AGENT" "carta-apresentacao.pdf" \
    "cv-cover-letter agent produces carta-apresentacao.pdf"
else
  t_fail "cv-cover-letter agent missing at $CL_AGENT"
fi

CL_CMD="$SCRIPT_DIR/../../commands/ocf:cv-cover-letter.md"
if [[ -f "$CL_CMD" ]]; then
  assert_contains "$CL_CMD" "templates/resume.html" \
    "ocf:cv-cover-letter command references the reference template"
  assert_contains "$CL_CMD" "standards/cv-design.md" \
    "ocf:cv-cover-letter command mandates standards/cv-design.md"
  assert_contains "$CL_CMD" "carta-apresentacao.pdf" \
    "ocf:cv-cover-letter command documents the PDF output path"
else
  t_fail "ocf:cv-cover-letter command missing at $CL_CMD"
fi

# opencode.json registers the command and the skill allow (BR 12 / AC 4)
OP_CONFIG="$SCRIPT_DIR/../../opencode.json"
if [[ -f "$OP_CONFIG" ]]; then
  python3 - "$OP_CONFIG" <<'PYEOF' || t_fail "opencode.json cv-cover-letter registration invalid"
import json, sys
cfg = json.load(open(sys.argv[1]))
assert "ocf:cv-cover-letter" in cfg.get("command", {}), "command ocf:cv-cover-letter not registered"
assert cfg["permission"]["skill"].get("cv-cover-letter") == "allow", "skill cv-cover-letter not allow"
PYEOF
  t_ok "opencode.json registers ocf:cv-cover-letter command + skill allow"
else
  t_fail "opencode.json missing at $OP_CONFIG"
fi

# --- cv-linkedin contract (issue #67) ---
LI_SKILL="$SCRIPT_DIR/../../skills/career/cv-linkedin/SKILL.md"
if [[ -f "$LI_SKILL" ]]; then
  # English schema keys (issue #64) — no legacy Portuguese keys
  assert_not_contains "$LI_SKILL" "resumo_i18n" \
    "cv-linkedin skill has no legacy resumo_i18n key"
  assert_contains "$LI_SKILL" "summary_i18n" \
    "cv-linkedin skill references the English summary_i18n key"
  # analysis standard + LinkedIn character limits (BR 9 / AC 9)
  assert_contains "$LI_SKILL" "standards/cv-analysis.md" \
    "cv-linkedin skill references standards/cv-analysis.md (BR 12)"
  assert_contains "$LI_SKILL" "220" \
    "cv-linkedin skill mandates the 220-char headline limit"
  assert_contains "$LI_SKILL" "2600" \
    "cv-linkedin skill mandates the 2600-char about limit"
  assert_contains "$LI_SKILL" "top 50" \
    "cv-linkedin skill caps the skills ranking at top 50"
  # output file (BR 5) + fabrication rule (BR 6)
  assert_contains "$LI_SKILL" "linkedin-optimization.md" \
    "cv-linkedin skill defines the linkedin-optimization.md output (BR 5)"
  assert_contains "$LI_SKILL" "NEVER invent" \
    "cv-linkedin skill forbids fabrication (BR 6)"
  # no [INFERIDO]-in-output instruction + no LinkedIn scraping (BR 4/BR 7)
  assert_contains "$LI_SKILL" "NO \`[INFERIDO]\`" \
    "cv-linkedin skill forbids [INFERIDO] in the output file (BR 7)"
  assert_not_contains "$LI_SKILL" "curl" \
    "cv-linkedin skill has no curl/URL-fetching instructions (BR 4)"
  assert_contains "$LI_SKILL" "never scraped" \
    "cv-linkedin skill explicitly forbids scraping (BR 4)"
else
  t_fail "cv-linkedin skill missing at $LI_SKILL"
fi

LI_AGENT="$SCRIPT_DIR/../../agents/career/cv-linkedin.md"
if [[ -f "$LI_AGENT" ]]; then
  assert_contains "$LI_AGENT" "~/career/**" \
    "cv-linkedin agent restricts edits to ~/career/** (BR 10 / AC 11)"
  assert_contains "$LI_AGENT" "validate.py" \
    "cv-linkedin agent validates the hub (BR 8)"
  assert_contains "$LI_AGENT" "linkedin-optimization.md" \
    "cv-linkedin agent produces linkedin-optimization.md (BR 5)"
  assert_not_contains "$LI_AGENT" '"curl -L*": allow' \
    "cv-linkedin agent grants no curl -L permission (BR 4)"
else
  t_fail "cv-linkedin agent missing at $LI_AGENT"
fi

LI_CMD="$SCRIPT_DIR/../../commands/ocf:cv-linkedin.md"
if [[ -f "$LI_CMD" ]]; then
  assert_contains "$LI_CMD" "linkedin-optimization.md" \
    "ocf:cv-linkedin command documents the linkedin-optimization.md output"
  assert_contains "$LI_CMD" "standards/cv-analysis.md" \
    "ocf:cv-linkedin command references standards/cv-analysis.md (BR 12)"
else
  t_fail "ocf:cv-linkedin command missing at $LI_CMD"
fi

# opencode.json registers the command and the skill allow (BR 11 / AC 4)
if [[ -f "$OP_CONFIG" ]]; then
  python3 - "$OP_CONFIG" <<'PYEOF' || t_fail "opencode.json cv-linkedin registration invalid"
import json, sys
cfg = json.load(open(sys.argv[1]))
assert "ocf:cv-linkedin" in cfg.get("command", {}), "command ocf:cv-linkedin not registered"
assert cfg["permission"]["skill"].get("cv-linkedin") == "allow", "skill cv-linkedin not allow"
PYEOF
  t_ok "opencode.json registers ocf:cv-linkedin command + skill allow"
else
  t_fail "opencode.json missing at $OP_CONFIG"
fi

# --- cv-interview-prep contract (issue #68) ---
# frontmatter helper: file starts with '---' and has a closing '---' line
frontmatter_ok() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  head -n1 "$f" | grep -q '^---$' || return 1
  awk 'NR>1 && /^---$/ { found=1; exit } END { exit !found }' "$f"
}

IP_SKILL="$SCRIPT_DIR/../../skills/career/cv-interview-prep/SKILL.md"
if [[ -f "$IP_SKILL" ]]; then
  frontmatter_ok "$IP_SKILL" \
    && t_ok "cv-interview-prep skill has valid YAML frontmatter" \
    || t_fail "cv-interview-prep skill frontmatter invalid (expected '---' delimiters)"
  # English schema keys (issue #64) — no legacy Portuguese keys
  assert_not_contains "$IP_SKILL" "resumo_i18n" \
    "cv-interview-prep skill has no legacy resumo_i18n key"
  assert_contains "$IP_SKILL" "summary_i18n" \
    "cv-interview-prep skill references the English summary_i18n key"
  # analysis standard + user's communication language (BR 11 / AC 8)
  assert_contains "$IP_SKILL" "standards/cv-analysis.md" \
    "cv-interview-prep skill references standards/cv-analysis.md (BR 11)"
  assert_contains "$IP_SKILL" "communication language" \
    "cv-interview-prep skill mandates the user's communication language (AC 8)"
  # output file (BR 5) + kit components (BR 2)
  assert_contains "$IP_SKILL" "interview-preparation.md" \
    "cv-interview-prep skill defines the interview-preparation.md output (BR 5)"
  assert_contains "$IP_SKILL" "Likely interview questions" \
    "cv-interview-prep skill covers likely interview questions (BR 2)"
  assert_contains "$IP_SKILL" "Suggested STAR answers" \
    "cv-interview-prep skill covers STAR answers (BR 2)"
  assert_contains "$IP_SKILL" "Questions to ask the interviewer" \
    "cv-interview-prep skill covers questions to ask (BR 2)"
  assert_contains "$IP_SKILL" "Technical topics to review" \
    "cv-interview-prep skill covers technical topics (BR 2)"
  # STAR answers map to real hub entries (BR 3) + gaps flagged (BR 8)
  assert_contains "$IP_SKILL" "NEVER invent" \
    "cv-interview-prep skill forbids fabrication (BR 3)"
  assert_contains "$IP_SKILL" "preparation gap" \
    "cv-interview-prep skill flags preparation gaps (BR 8)"
  # no [INFERIDO]-in-output instruction + no URL fetching (BR 6)
  assert_contains "$IP_SKILL" "NO \`[INFERIDO]\`" \
    "cv-interview-prep skill forbids [INFERIDO] in the output file (BR 6)"
  assert_not_contains "$IP_SKILL" "curl" \
    "cv-interview-prep skill has no curl/URL-fetching instructions"
else
  t_fail "cv-interview-prep skill missing at $IP_SKILL"
fi

IP_AGENT="$SCRIPT_DIR/../../agents/career/cv-interview-prep.md"
if [[ -f "$IP_AGENT" ]]; then
  frontmatter_ok "$IP_AGENT" \
    && t_ok "cv-interview-prep agent has valid YAML frontmatter" \
    || t_fail "cv-interview-prep agent frontmatter invalid (expected '---' delimiters)"
  assert_contains "$IP_AGENT" "~/career/**" \
    "cv-interview-prep agent restricts edits to ~/career/** (BR 9 / AC 11)"
  assert_contains "$IP_AGENT" "temperature: 0.2" \
    "cv-interview-prep agent runs at temperature 0.2 (BR 9)"
  assert_contains "$IP_AGENT" "validate.py" \
    "cv-interview-prep agent validates the hub (BR 7)"
  assert_contains "$IP_AGENT" "interview-preparation.md" \
    "cv-interview-prep agent produces interview-preparation.md (BR 5)"
  assert_not_contains "$IP_AGENT" '"curl -L*": allow' \
    "cv-interview-prep agent grants no curl -L permission"
else
  t_fail "cv-interview-prep agent missing at $IP_AGENT"
fi

IP_CMD="$SCRIPT_DIR/../../commands/ocf:cv-interview-prep.md"
if [[ -f "$IP_CMD" ]]; then
  assert_contains "$IP_CMD" "interview-preparation.md" \
    "ocf:cv-interview-prep command documents the interview-preparation.md output"
  assert_contains "$IP_CMD" "standards/cv-analysis.md" \
    "ocf:cv-interview-prep command references standards/cv-analysis.md (BR 11)"
  assert_contains "$IP_CMD" "<candidate-directory> <job>" \
    "ocf:cv-interview-prep command documents the <candidate-directory> <job> signature (BR 1)"
else
  t_fail "ocf:cv-interview-prep command missing at $IP_CMD"
fi

# opencode.json registers the command and the skill allow (BR 10 / AC 4)
if [[ -f "$OP_CONFIG" ]]; then
  python3 - "$OP_CONFIG" <<'PYEOF' || t_fail "opencode.json cv-interview-prep registration invalid"
import json, sys
cfg = json.load(open(sys.argv[1]))
assert "ocf:cv-interview-prep" in cfg.get("command", {}), "command ocf:cv-interview-prep not registered"
assert cfg["permission"]["skill"].get("cv-interview-prep") == "allow", "skill cv-interview-prep not allow"
PYEOF
  t_ok "opencode.json registers ocf:cv-interview-prep command + skill allow"
else
  t_fail "opencode.json missing at $OP_CONFIG"
fi

# --- cv-ats-score contract (issue #69) ---
ATS_SKILL="$SCRIPT_DIR/../../skills/career/cv-ats-score/SKILL.md"
if [[ -f "$ATS_SKILL" ]]; then
  frontmatter_ok "$ATS_SKILL" \
    && t_ok "cv-ats-score skill has valid YAML frontmatter" \
    || t_fail "cv-ats-score skill frontmatter invalid (expected '---' delimiters)"
  # English schema keys (issue #64) — no legacy Portuguese keys
  assert_not_contains "$ATS_SKILL" "resumo_i18n" \
    "cv-ats-score skill has no legacy resumo_i18n key"
  # analysis standard + user's communication language (BR 10 / AC 8)
  assert_contains "$ATS_SKILL" "standards/cv-analysis.md" \
    "cv-ats-score skill references standards/cv-analysis.md (BR 10)"
  assert_contains "$ATS_SKILL" "communication language" \
    "cv-ats-score skill mandates the user's communication language (AC 8)"
  # output file (BR 5) + score breakdown weights (BR 4 / AC 5)
  assert_contains "$ATS_SKILL" "ats-score.md" \
    "cv-ats-score skill defines the ats-score.md output (BR 5)"
  assert_contains "$ATS_SKILL" "40%" \
    "cv-ats-score skill defines the keyword_match weight (40%, BR 4)"
  assert_contains "$ATS_SKILL" "30%" \
    "cv-ats-score skill defines the section/format weights (30%, BR 4)"
  assert_contains "$ATS_SKILL" "0-100" \
    "cv-ats-score skill defines the 0-100 score range (AC 5)"
  # coverage (BR 3 / AC 6): keyword density + red flags + section detection
  assert_contains "$ATS_SKILL" "keyword density" \
    "cv-ats-score skill covers keyword density (BR 3)"
  assert_contains "$ATS_SKILL" "multi-column" \
    "cv-ats-score skill detects multi-column layouts (BR 3)"
  assert_contains "$ATS_SKILL" "images as text" \
    "cv-ats-score skill detects images as text (BR 3)"
  assert_contains "$ATS_SKILL" "missing standard sections" \
    "cv-ats-score skill detects missing standard sections (BR 3)"
  assert_contains "$ATS_SKILL" "section_completeness" \
    "cv-ats-score skill covers section detection (BR 3)"
  # pdftotext best-effort (BR 2) + no URL fetching
  assert_contains "$ATS_SKILL" "pdftotext" \
    "cv-ats-score skill extracts text via pdftotext (BR 2)"
  assert_contains "$ATS_SKILL" "cannot-analyze" \
    "cv-ats-score skill handles the no-text-source case honestly"
  assert_not_contains "$ATS_SKILL" "curl" \
    "cv-ats-score skill has no curl/URL-fetching instructions"
  # report structure rules (AC 9): one H1, no metadata header, canonical table
  assert_contains "$ATS_SKILL" "exactly one H1" \
    "cv-ats-score skill mandates exactly one H1 (AC 9)"
  assert_contains "$ATS_SKILL" "NO metadata header" \
    "cv-ats-score skill forbids metadata header (AC 9)"
  # [INFERIDO] allowed inline in the internal report (std §5), never in resume
  assert_contains "$ATS_SKILL" "[INFERIDO]" \
    "cv-ats-score skill keeps [INFERIDO] inline in the internal report (std §5)"
  assert_contains "$ATS_SKILL" "NEVER fabricate" \
    "cv-ats-score skill forbids fabrication of counts/scores"
else
  t_fail "cv-ats-score skill missing at $ATS_SKILL"
fi

ATS_AGENT="$SCRIPT_DIR/../../agents/career/cv-ats-score.md"
if [[ -f "$ATS_AGENT" ]]; then
  frontmatter_ok "$ATS_AGENT" \
    && t_ok "cv-ats-score agent has valid YAML frontmatter" \
    || t_fail "cv-ats-score agent frontmatter invalid (expected '---' delimiters)"
  assert_contains "$ATS_AGENT" "~/career/**" \
    "cv-ats-score agent restricts edits to ~/career/** (BR 8 / AC 10)"
  assert_contains "$ATS_AGENT" "temperature: 0.2" \
    "cv-ats-score agent runs at temperature 0.2"
  assert_contains "$ATS_AGENT" '"pdftotext *": allow' \
    "cv-ats-score agent grants the pdftotext bash permission (BR 6)"
  assert_contains "$ATS_AGENT" "ats-score.md" \
    "cv-ats-score agent produces ats-score.md (BR 5)"
  assert_contains "$ATS_AGENT" "read-only" \
    "cv-ats-score agent is read-only besides the report (BR 8 / AC 10)"
  assert_not_contains "$ATS_AGENT" '"curl -L*": allow' \
    "cv-ats-score agent grants no curl -L permission"
else
  t_fail "cv-ats-score agent missing at $ATS_AGENT"
fi

ATS_CMD="$SCRIPT_DIR/../../commands/ocf:cv-ats-score.md"
if [[ -f "$ATS_CMD" ]]; then
  assert_contains "$ATS_CMD" "ats-score.md" \
    "ocf:cv-ats-score command documents the ats-score.md output"
  assert_contains "$ATS_CMD" "standards/cv-analysis.md" \
    "ocf:cv-ats-score command references standards/cv-analysis.md (BR 10)"
  assert_contains "$ATS_CMD" "<candidate-directory> <job-slug>" \
    "ocf:cv-ats-score command documents the <candidate-directory> <job-slug> signature (BR 1)"
  assert_contains "$ATS_CMD" "40%" \
    "ocf:cv-ats-score command documents the 40/30/30 breakdown (BR 4)"
else
  t_fail "ocf:cv-ats-score command missing at $ATS_CMD"
fi

# opencode.json registers the command and the skill allow (BR 6/7 / AC 4)
if [[ -f "$OP_CONFIG" ]]; then
  python3 - "$OP_CONFIG" <<'PYEOF' || t_fail "opencode.json cv-ats-score registration invalid"
import json, sys
cfg = json.load(open(sys.argv[1]))
assert "ocf:cv-ats-score" in cfg.get("command", {}), "command ocf:cv-ats-score not registered"
assert cfg["permission"]["skill"].get("cv-ats-score") == "allow", "skill cv-ats-score not allow"
PYEOF
  t_ok "opencode.json registers ocf:cv-ats-score command + skill allow"
else
  t_fail "opencode.json missing at $OP_CONFIG"
fi

# ats-score.md structure rules (AC 9): exactly one H1, NO metadata header —
# the fixture mirrors the mandated report shape (H1 title first, then H2s).
cat > "$TMP/ats-score-fixture.md" <<'MDEOF'
# ATS Score — backend-engineer-remote

## Job context

Backend Engineer — Acme, senior, English.

## ATS score

| Section | Score (0-100) | Justification |
| --- | --- | --- |
| keyword_match | 80 | 8 of 10 job keywords found |
| section_completeness | 100 | all standard sections detected |
| format_compliance | 75 | single-column, one red flag |
| Global | 85 | weighted total |

## Keyword density

- Kubernetes — 2x in the job, 0x in the resume

## ATS red flags

- None detected

## Recommendations

- Add "Kubernetes" to the skills section — it appears 2x in the job but 0x in your resume.
MDEOF
if [[ "$(head -n1 "$TMP/ats-score-fixture.md")" == "# ATS Score"* ]]; then
  t_ok "ats-score.md starts directly with the H1 title (no metadata header)"
else
  t_fail "ats-score.md does not start with the H1 title (metadata header present)"
fi
H1_COUNT="$(grep -c '^# ' "$TMP/ats-score-fixture.md" || true)"
assert_eq "1" "$H1_COUNT" "ats-score.md fixture has exactly one H1 title"
if grep -qE '^(Generated on:|Source:|Tool:|Note:)' "$TMP/ats-score-fixture.md" 2>/dev/null; then
  t_fail "ats-score.md fixture contains a metadata header line"
else
  t_ok "ats-score.md fixture has no metadata header lines"
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

# --- issue #72: validate.py format + summary_i18n + cross-field checks ---
# Both the jsonschema path (default) and the hand-rolled fallback
# (CV_VALIDATE_FALLBACK=1) MUST agree on every shared semantic check.
run_both() {
  local expected="$1" label="$2" file="$3"
  set +e
  python3 "$VALIDATOR" "$file" >/dev/null 2>&1; rc_p=$?
  CV_VALIDATE_FALLBACK=1 python3 "$VALIDATOR" "$file" >/dev/null 2>&1; rc_f=$?
  set -e
  assert_eq "$expected" "$rc_p" "$label (jsonschema path)"
  assert_eq "$expected" "$rc_f" "$label (hand-rolled fallback)"
}

TMP_ENV="$TMP" python3 - <<'EOF'
import json, os, time
tmp = os.environ["TMP_ENV"]

def base():
    return {
        "personal_info": {"name": "Test"},
        "summary": "summary",
        "experience": [{"company": "Acme", "title": "Dev"}],
        "education": [{"institution": "USP", "course": "CS"}],
        "skills": [{"name": "Python"}],
        "certifications": [{"name": "AWS"}],
        "projects": [{"name": "proj"}],
        "languages": [{"language": "English"}],
        "links": [{"name": "GH", "url": "https://github.com/x"}],
    }

def write(name, hub):
    json.dump(hub, open(os.path.join(tmp, name), "w"))

write("hub-bad-email.json",
      {**base(), "personal_info": {**base()["personal_info"], "email": "not-an-email"}})
write("hub-bad-url.json",
      {**base(), "links": [{"name": "GH", "url": "not-a-url"}]})
write("hub-bad-i18n-key.json",
      {**base(), "summary_i18n": {"fr": "bonjour"}})
write("hub-bad-i18n-type.json",
      {**base(), "summary_i18n": {"pt": 123}})
write("hub-bad-range.json",
      {**base(), "experience": [{"company": "Acme", "title": "Dev",
                                 "start_date": "2023-06", "end_date": "2021-01"}]})
write("hub-good-range.json",
      {**base(), "experience": [{"company": "Acme", "title": "Dev",
                                 "start_date": "2021-01", "end_date": "present"}]})
write("hub-good-range-atual.json",
      {**base(), "experience": [{"company": "Acme", "title": "Dev",
                                 "start_date": "2020", "end_date": "atual"}]})
write("hub-educ-range.json",
      {**base(), "education": [{"institution": "USP", "course": "CS",
                                "start_date": "2023-01", "end_date": "2019-12"}]})
write("hub-cert-future.json",
      {**base(), "certifications": [{"name": "AWS",
                                     "year": str(int(time.strftime("%Y")) + 1)}]})
write("hub-cert-expiry.json",
      {**base(), "certifications": [{"name": "AWS",
                                     "year": "2023", "expiry_date": "2020-01"}]})
write("hub-unknown-key.json",
      {**base(), "bogus_section": []})
write("hub-day-start-coarse-end.json",
      {**base(), "experience": [{"company": "Acme", "title": "Dev",
                                 "start_date": "2021-12-31", "end_date": "2021-12"}]})
write("hub-equal-month.json",
      {**base(), "experience": [{"company": "Acme", "title": "Dev",
                                 "start_date": "2021-06", "end_date": "2021-06"}]})
EOF

run_both "1" "validate.py rejects an invalid email address" "$TMP/hub-bad-email.json"
run_both "1" "validate.py rejects an invalid URL" "$TMP/hub-bad-url.json"
run_both "1" "validate.py rejects an invalid summary_i18n locale key" "$TMP/hub-bad-i18n-key.json"
run_both "1" "validate.py rejects a non-string summary_i18n value" "$TMP/hub-bad-i18n-type.json"
run_both "1" "validate.py rejects experience end before start" "$TMP/hub-bad-range.json"
run_both "0" "validate.py accepts experience with an open-ended 'present' end" "$TMP/hub-good-range.json"
run_both "0" "validate.py accepts experience with an open-ended 'atual' end" "$TMP/hub-good-range-atual.json"
run_both "1" "validate.py rejects education end before start" "$TMP/hub-educ-range.json"
run_both "1" "validate.py rejects a future certification year" "$TMP/hub-cert-future.json"
run_both "1" "validate.py rejects a certification year after expiry" "$TMP/hub-cert-expiry.json"
run_both "0" "validate.py accepts a day-level start with a coarse month end (M1)" "$TMP/hub-day-start-coarse-end.json"
run_both "0" "validate.py accepts start equal to end (same month)" "$TMP/hub-equal-month.json"

# unknown-key rejection is jsonschema-only (schema additionalProperties: false);
# the hand-rolled fallback is intentionally lenient on unknown keys (documented).
set +e
python3 "$VALIDATOR" "$TMP/hub-unknown-key.json" >/dev/null 2>&1; rc_unknown_p=$?
CV_VALIDATE_FALLBACK=1 python3 "$VALIDATOR" "$TMP/hub-unknown-key.json" >/dev/null 2>&1; rc_unknown_f=$?
set -e
if python3 -c "import jsonschema" >/dev/null 2>&1; then
  assert_eq "1" "$rc_unknown_p" "jsonschema path rejects unknown root keys (additionalProperties)"
else
  assert_eq "0" "$rc_unknown_p" "primary path (fallback, no jsonschema) accepts unknown root keys"
fi
assert_eq "0" "$rc_unknown_f" "hand-rolled fallback accepts unknown root keys (documented leniency)"

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

# --- cv-hub-update contract (issue #70) ---
HUB_UPDATE_CMD="$SCRIPT_DIR/../../commands/ocf:cv-hub-update.md"
HUB_SKILL="$SCRIPT_DIR/../../skills/career/cv-hub/SKILL.md"
EXTRACTOR_AGENT="$SCRIPT_DIR/../../agents/career/cv-extractor.md"

# 1. Command exists with the <candidate-directory> signature (BR 1 / AC 1)
if [[ -f "$HUB_UPDATE_CMD" ]]; then
  # command docs use the "## /ocf:... " title + --- description frontmatter --- pattern
  grep -q '^## /ocf:cv-hub-update <candidate-directory>$' "$HUB_UPDATE_CMD" \
    && t_ok "ocf:cv-hub-update command title carries the <candidate-directory> signature (BR 1)" \
    || t_fail "ocf:cv-hub-update command title missing the <candidate-directory> signature (BR 1)"
  grep -q '^description: ' "$HUB_UPDATE_CMD" \
    && t_ok "ocf:cv-hub-update command has a description frontmatter field" \
    || t_fail "ocf:cv-hub-update command missing the description frontmatter field"
  # never recreates the hub (BR 1) and never builds when hub.json is missing (BR 5 / AC 7)
  assert_contains "$HUB_UPDATE_CMD" "NEVER recreates" \
    "ocf:cv-hub-update command forbids recreating hub.json from scratch (BR 1)"
  assert_contains "$HUB_UPDATE_CMD" "run \`/ocf:cv-hub\` first" \
    "ocf:cv-hub-update command tells the user to run ocf:cv-hub first when hub.json is missing (BR 5 / AC 7)"
  # accepted input forms (BR 2 / AC 2)
  assert_contains "$HUB_UPDATE_CMD" "Pasted text" \
    "ocf:cv-hub-update command accepts pasted text (BR 2)"
  assert_contains "$HUB_UPDATE_CMD" "New PDF" \
    "ocf:cv-hub-update command accepts a new PDF (BR 2)"
  assert_contains "$HUB_UPDATE_CMD" "New file" \
    "ocf:cv-hub-update command accepts a new file (BR 2)"
  assert_contains "$HUB_UPDATE_CMD" "Manual key-value edits" \
    "ocf:cv-hub-update command accepts manual key-value edits (BR 2)"
  # validate + README regeneration (BR 4 / AC 6) and diff/summary (BR 10 / AC 8)
  assert_contains "$HUB_UPDATE_CMD" "validate.py" \
    "ocf:cv-hub-update command re-validates with validate.py (BR 4 / AC 6)"
  assert_contains "$HUB_UPDATE_CMD" "Regenerate \`README.md\`" \
    "ocf:cv-hub-update command regenerates README.md (BR 4 / AC 6)"
  assert_contains "$HUB_UPDATE_CMD" "diff/summary" \
    "ocf:cv-hub-update command reports a diff/summary of changes (BR 10 / AC 8)"
  # agent invocation + update mode (BR 8 / AC 9)
  assert_contains "$HUB_UPDATE_CMD" "career/cv-extractor" \
    "ocf:cv-hub-update command invokes the career/cv-extractor subagent (BR 8)"
  assert_contains "$HUB_UPDATE_CMD" "update-mode" \
    "ocf:cv-hub-update command passes the update-mode instruction to the agent"
else
  t_fail "ocf:cv-hub-update command missing at $HUB_UPDATE_CMD"
fi

# 2. The cv-hub skill EXTENDS (not replaces) the build flow with update mode (BR 9)
if [[ -f "$HUB_SKILL" ]]; then
  # build-mode instructions preserved (extend, not replace)
  assert_contains "$HUB_SKILL" "## Extraction process" \
    "cv-hub skill keeps the build-mode extraction process (BR 9 — extend, not replace)"
  assert_contains "$HUB_SKILL" "## Update mode" \
    "cv-hub skill has an update-mode section (BR 9)"
  # duplicate detection + merge keys (BR 6 / AC 4)
  assert_contains "$HUB_SKILL" "same \`company\` + \`title\` + \`start_date\`" \
    "cv-hub skill defines the experience duplicate key (BR 6 / AC 4)"
  assert_contains "$HUB_SKILL" "same \`name\`" \
    "cv-hub skill defines the name duplicate key for skills/certifications/projects (BR 6 / AC 4)"
  # never-delete rule (BR 3 / AC 3)
  assert_contains "$HUB_SKILL" "NEVER delete" \
    "cv-hub skill forbids deleting entries without explicit confirmation (BR 3 / AC 3)"
  # [INFERIDO] preservation (BR 7 / AC 5)
  assert_contains "$HUB_SKILL" "Preserve existing \`[INFERIDO]\` markers" \
    "cv-hub skill mandates preserving existing [INFERIDO] markers (BR 7 / AC 5)"
  # update mode validates + regenerates README (BR 4 / AC 6)
  assert_contains "$HUB_SKILL" "validate.py" \
    "cv-hub skill update mode re-validates with validate.py (BR 4 / AC 6)"
  assert_contains "$HUB_SKILL" "Regenerate \`README.md\`" \
    "cv-hub skill update mode regenerates README.md (BR 4 / AC 6)"
  # update mode reports the diff/summary (BR 10 / AC 8)
  assert_contains "$HUB_SKILL" "Report the diff/summary" \
    "cv-hub skill update mode reports a diff/summary (BR 10 / AC 8)"
else
  t_fail "cv-hub skill missing at $HUB_SKILL"
fi

# 3. The cv-extractor agent has update-mode responsibilities + hub.json edit allow
#    (BR 8 / AC 9 — unlike cv-optimizer which denies hub.json edits)
if [[ -f "$EXTRACTOR_AGENT" ]]; then
  assert_contains "$EXTRACTOR_AGENT" "Update mode" \
    "cv-extractor agent has an update-mode section"
  assert_contains "$EXTRACTOR_AGENT" '"~/career/**/hub.json": allow' \
    "cv-extractor agent explicitly allows hub.json edits (BR 8 / AC 9)"
  assert_contains "$EXTRACTOR_AGENT" "NEVER delete" \
    "cv-extractor agent forbids deleting existing entries without confirmation (BR 3)"
  assert_contains "$EXTRACTOR_AGENT" "[INFERIDO]" \
    "cv-extractor agent preserves [INFERIDO] markers (BR 7)"
  assert_contains "$EXTRACTOR_AGENT" "validate.py" \
    "cv-extractor agent re-validates with validate.py (BR 4)"
else
  t_fail "cv-extractor agent missing at $EXTRACTOR_AGENT"
fi

# cv-optimizer STILL denies hub.json edits (regression — AC 9 contrast)
OPT_AGENT="$SCRIPT_DIR/../../agents/career/cv-optimizer.md"
if [[ -f "$OPT_AGENT" ]]; then
  assert_contains "$OPT_AGENT" '"~/career/**/hub.json": deny' \
    "cv-optimizer agent still denies hub.json edits (regression, AC 9 contrast)"
else
  t_fail "cv-optimizer agent missing at $OPT_AGENT"
fi

# 4. opencode.json registers the command (BR 8 / AC 9) and the skill stays allowed
if [[ -f "$OP_CONFIG" ]]; then
  python3 - "$OP_CONFIG" <<'PYEOF' || t_fail "opencode.json cv-hub-update registration invalid"
import json, sys
cfg = json.load(open(sys.argv[1]))
assert "ocf:cv-hub-update" in cfg.get("command", {}), "command ocf:cv-hub-update not registered"
assert cfg["permission"]["skill"].get("cv-hub") == "allow", "skill cv-hub not allow"
assert "career/cv-extractor" in cfg["command"]["ocf:cv-hub-update"]["template"], \
    "cv-hub-update template does not invoke the cv-extractor agent"
assert "validate.py" in cfg["command"]["ocf:cv-hub-update"]["template"], \
    "cv-hub-update template does not mandate validate.py"
assert "update-mode" in cfg["command"]["ocf:cv-hub-update"]["template"], \
    "cv-hub-update template does not pass the update-mode instruction"
PYEOF
  t_ok "opencode.json registers ocf:cv-hub-update command + cv-hub skill allow"
else
  t_fail "opencode.json missing at $OP_CONFIG"
fi

# --- cv-tailor gap-analysis metrics contract (issue #71) ---
# The gap analysis must carry: weighted match percentage (mandatory 2x,
# desirable 1x), keyword density map, and coverage summary by section — all
# computed on the FINAL resume text, per standards/cv-analysis.md §3.2/§4.5-§4.7.
CV_ANALYSIS_STD="$SCRIPT_DIR/../../standards/cv-analysis.md"
if [[ -f "$CV_ANALYSIS_STD" ]]; then
  # §3.2 mandates the new gap-analysis sections (BR 6 / AC 5)
  assert_contains "$CV_ANALYSIS_STD" "4. Match percentage" \
    "cv-analysis standard §3.2 mandates the match percentage section (BR 1)"
  assert_contains "$CV_ANALYSIS_STD" "5. Keyword density & coverage" \
    "cv-analysis standard §3.2 mandates the keyword density & coverage section (BR 2/3)"
  # canonical tables §4.5-§4.7 (AC 5)
  assert_contains "$CV_ANALYSIS_STD" "### 4.5 Match percentage" \
    "cv-analysis standard defines the weighted match table (BR 4)"
  assert_contains "$CV_ANALYSIS_STD" "### 4.6 Keyword density map" \
    "cv-analysis standard defines the keyword density table (BR 2)"
  assert_contains "$CV_ANALYSIS_STD" "### 4.7 Coverage summary by section" \
    "cv-analysis standard defines the coverage table (BR 3)"
  assert_contains "$CV_ANALYSIS_STD" "\`2x\` for mandatory requirements" \
    "cv-analysis standard documents the 2x mandatory weight (BR 4)"
  assert_contains "$CV_ANALYSIS_STD" "strip the HTML tags" \
    "cv-analysis standard computes counts on the final resume text from index.html (BR 5)"
  assert_contains "$CV_ANALYSIS_STD" "pdftotext" \
    "cv-analysis standard computes counts from the PDF via pdftotext (BR 5)"
else
  t_fail "cv-analysis standard missing at $CV_ANALYSIS_STD"
fi

if [[ -f "$TAILOR_SKILL" ]]; then
  # BR 1/4 — weighted match percentage (mandatory 2x, desirable 1x)
  assert_contains "$TAILOR_SKILL" "match percentage" \
    "cv-tailor skill computes the match percentage (BR 1)"
  assert_contains "$TAILOR_SKILL" "mandatory requirements weigh 2x" \
    "cv-tailor skill documents the 2x mandatory / 1x desirable weights (BR 4)"
  # BR 2/3/5 — keyword density + coverage on the FINAL resume text
  assert_contains "$TAILOR_SKILL" "Keyword density map" \
    "cv-tailor skill computes the keyword density map (BR 2)"
  assert_contains "$TAILOR_SKILL" "Coverage summary by section" \
    "cv-tailor skill computes the coverage summary by section (BR 3)"
  assert_contains "$TAILOR_SKILL" "pdftotext" \
    "cv-tailor skill extracts the final resume text via pdftotext (BR 5)"
  assert_contains "$TAILOR_SKILL" "strip the HTML tags" \
    "cv-tailor skill extracts the final resume text from index.html (BR 5)"
  # BR 6 — canonical structure of standards/cv-analysis.md
  assert_contains "$TAILOR_SKILL" "standards/cv-analysis.md" \
    "cv-tailor skill references standards/cv-analysis.md (BR 6)"
else
  t_fail "cv-tailor skill missing at $TAILOR_SKILL"
fi

if [[ -f "$TAILOR_AGENT" ]]; then
  assert_contains "$TAILOR_AGENT" "match percentage" \
    "cv-tailor agent computes the weighted match percentage (BR 1/4)"
  assert_contains "$TAILOR_AGENT" "keyword density map" \
    "cv-tailor agent computes the keyword density map (BR 2)"
  assert_contains "$TAILOR_AGENT" "coverage summary" \
    "cv-tailor agent computes the coverage summary by section (BR 3)"
  assert_contains "$TAILOR_AGENT" "pdftotext" \
    "cv-tailor agent extracts the final resume text via pdftotext (BR 5)"
else
  t_fail "cv-tailor agent missing at $TAILOR_AGENT"
fi

if [[ -f "$TAILOR_CMD" ]]; then
  assert_contains "$TAILOR_CMD" "match percentage" \
    "ocf:cv-tailor command documents the match percentage (BR 1)"
  assert_contains "$TAILOR_CMD" "keyword density map" \
    "ocf:cv-tailor command documents the keyword density map (BR 2)"
  assert_contains "$TAILOR_CMD" "coverage summary" \
    "ocf:cv-tailor command documents the coverage summary (BR 3)"
else
  t_fail "ocf:cv-tailor command missing at $TAILOR_CMD"
fi

# fixture: gap-analysis.md with the match-percentage table must follow the
# report structure rules of the standard (exactly one H1, NO metadata header,
# H2 sections in the mandated order) — mirrors the ats-score fixture checks.
# The fixture exercises the documented 70% example (Tests: 1 of issue #71):
# 4 mandatory + 2 desirable requirements, 3 mandatory + 1 desirable met →
# (3×2 + 1×1) / (4×2 + 2×1) × 100 = 70%.
cat > "$TMP/gap-analysis-fixture.md" <<'MDEOF'
# Gap Analysis — senior-backend-engineer

## Job context

Backend Engineer — Acme, senior, English.

## Requirements

### Required

- Kubernetes
- Go
- Docker
- AWS ECS

### Desirable

- Kafka
- gRPC

## Gap analysis

| Requirement | Match | Evidence in hub |
| --- | --- | --- |
| Kubernetes | atendido | skills: Kubernetes (level: advanced) |
| Go | atendido | skills: Go (level: advanced) |
| Docker | atendido | skills: Docker (level: advanced) |
| AWS ECS | not_met | not found in hub |
| Kafka | atendido | skills: Kafka (level: intermediate) |
| gRPC | not_met | not found in hub |

## Match percentage

| Metric | Weight | Met | Total | Weighted |
| --- | --- | --- | --- | --- |
| Mandatory | 2x | 3 | 4 | 6/8 |
| Desirable | 1x | 1 | 2 | 1/2 |

Match: 70%

## Keyword density & coverage

| Keyword | Count in resume |
| --- | --- |
| Kubernetes | 3 |
| Docker | 2 |
| Go | 2 |
| Kafka | 1 |
| AWS ECS | 0 |
| gRPC | 0 |

| Resume section | Job keywords found | Count |
| --- | --- | --- |
| Skills | Kubernetes, Go | 4 |
| Experience | Kubernetes | 2 |
| Summary | Docker | 1 |
MDEOF

# partial-match fixture (Tests: 4 of issue #71): one mandatory requirement
# classified `parcial` counts as 0.5 met → weighted total reflects 0.5.
cat > "$TMP/gap-analysis-parcial-fixture.md" <<'MDEOF'
# Gap Analysis — partial-match example

## Match percentage

| Metric | Weight | Met | Total | Weighted |
| --- | --- | --- | --- | --- |
| Mandatory | 2x | 0.5 | 1 | 1/2 |

Match: 50%
MDEOF
if [[ "$(head -n1 "$TMP/gap-analysis-fixture.md")" == "# Gap Analysis"* ]]; then
  t_ok "gap-analysis.md starts directly with the H1 title (no metadata header)"
else
  t_fail "gap-analysis.md does not start with the H1 title (metadata header present)"
fi
H1_COUNT_GA="$(grep -c '^# ' "$TMP/gap-analysis-fixture.md" || true)"
assert_eq "1" "$H1_COUNT_GA" "gap-analysis.md fixture has exactly one H1 title"
if grep -qE '^(Generated on:|Source:|Tool:|Note:)' "$TMP/gap-analysis-fixture.md" 2>/dev/null; then
  t_fail "gap-analysis.md fixture contains a metadata header line"
else
  t_ok "gap-analysis.md fixture has no metadata header lines"
fi

# --- issue #71 review-correction assertions (senior QA findings F1-F8) ---

# F1 — the documented 70% example is exercised and pinned (Tests: 1)
assert_contains "$TMP/gap-analysis-fixture.md" "Match: 70%" \
  "fixture computes the documented 70% weighted match (Tests: 1)"
assert_contains "$TMP/gap-analysis-fixture.md" "| Mandatory | 2x | 3 | 4 | 6/8 |" \
  "fixture weighted row: 3 mandatory met × 2 = 6/8 (Tests: 1)"
assert_contains "$TMP/gap-analysis-fixture.md" "| Desirable | 1x | 1 | 2 | 1/2 |" \
  "fixture weighted row: 1 desirable met × 1 = 1/2 (Tests: 1)"
assert_contains "$TAILOR_SKILL" "(3×2 + 1×1)" \
  "cv-tailor skill documents the 70% example (3×2 + 1×1) (Tests: 1)"

# F2 — coverage table ranks Skills and Experience at the top (Tests: 3)
assert_contains "$TMP/gap-analysis-fixture.md" "| Experience | Kubernetes | 2 |" \
  "coverage fixture has an Experience row ranking at the top (Tests: 3)"
# §4.7 — rows ordered by Count descending: Skills 4 > Experience 2 > Summary 1
COV_LINE_SKILLS="$(grep -n '^| Skills | Kubernetes, Go | 4 |' "$TMP/gap-analysis-fixture.md" | cut -d: -f1)"
COV_LINE_EXP="$(grep -n '^| Experience | Kubernetes | 2 |' "$TMP/gap-analysis-fixture.md" | cut -d: -f1)"
COV_LINE_SUM="$(grep -n '^| Summary | Docker | 1 |' "$TMP/gap-analysis-fixture.md" | cut -d: -f1)"
if [[ -n "$COV_LINE_SKILLS" && -n "$COV_LINE_EXP" && -n "$COV_LINE_SUM" \
      && "$COV_LINE_SKILLS" -lt "$COV_LINE_EXP" && "$COV_LINE_EXP" -lt "$COV_LINE_SUM" ]]; then
  t_ok "coverage table rows ordered by Count descending (Skills > Experience > Summary)"
else
  t_fail "coverage table rows not ordered by Count descending (Skills > Experience > Summary)"
fi

# §4.6 — density rows ordered by count descending; keywords with count 0 last
DENS_LINE_K8S="$(grep -n '^| Kubernetes | 3 |' "$TMP/gap-analysis-fixture.md" | cut -d: -f1)"
DENS_LINE_GRPC="$(grep -n '^| gRPC | 0 |' "$TMP/gap-analysis-fixture.md" | cut -d: -f1)"
if [[ -n "$DENS_LINE_K8S" && -n "$DENS_LINE_GRPC" && "$DENS_LINE_K8S" -lt "$DENS_LINE_GRPC" ]]; then
  t_ok "density rows ordered by count descending; count-0 keywords listed last"
else
  t_fail "density rows not ordered by count descending (count-0 keywords must be last)"
fi

# F3 — parcial counts as half (0.5) toward Met (new BR 9 / Tests: 4)
assert_contains "$TAILOR_SKILL" "as half (0.5)" \
  "cv-tailor skill documents parcial counts as half (BR 9)"
assert_contains "$CV_ANALYSIS_STD" "counts as 0.5 toward" \
  "cv-analysis standard §4.5 documents parcial as 0.5 toward Met (BR 9)"
assert_contains "$TMP/gap-analysis-parcial-fixture.md" "| Mandatory | 2x | 0.5 | 1 | 1/2 |" \
  "parcial match counts as 0.5 met in the weighted table (BR 9 / Tests: 4)"
assert_contains "$TMP/gap-analysis-parcial-fixture.md" "Match: 50%" \
  "parcial 0.5 met yields the weighted 50% match (BR 9 / Tests: 4)"

# F4 — case-insensitive keyword counting is documented and pinned
assert_contains "$CV_ANALYSIS_STD" "case-insensitive" \
  "cv-analysis standard §4.6 counts keywords case-insensitively"
assert_contains "$TAILOR_SKILL" "case-insensitive" \
  "cv-tailor skill counts keywords case-insensitively"

# F5 — missing-text-source limitation is documented (never invent counts)
assert_contains "$TAILOR_SKILL" "note the limitation" \
  "cv-tailor skill documents the missing-text-source limitation"
assert_contains "$TAILOR_AGENT" "invent counts: if no text source" \
  "cv-tailor agent forbids inventing counts"
assert_contains "$TAILOR_CMD" "Never invent counts" \
  "ocf:cv-tailor command forbids inventing counts"

# F6 — row-ordering rules are documented in the standard
assert_contains "$CV_ANALYSIS_STD" "Rows are ordered by" \
  "cv-analysis standard §4.6/§4.7 document the row-ordering rules"
assert_contains "$CV_ANALYSIS_STD" "listed last" \
  "cv-analysis standard §4.6 lists count-0 keywords last"

# F8 — the match_percentage formula block is pinned
assert_contains "$CV_ANALYSIS_STD" "match_percentage = round" \
  "cv-analysis standard documents the match_percentage formula"
assert_contains "$TAILOR_SKILL" "match_percentage = round" \
  "cv-tailor skill documents the match_percentage formula"

# --- issue #72: agents/career/README.md, README template, curl removal ---
# 1. agents/career/README.md exists and lists every career agent + command
CAREER_README="$SCRIPT_DIR/../../agents/career/README.md"
if [[ -f "$CAREER_README" ]]; then
  for agent in cv-extractor cv-optimizer cv-tailor cv-cover-letter cv-linkedin \
               cv-interview-prep cv-ats-score; do
    assert_contains "$CAREER_README" "$agent" \
      "agents/career/README.md lists the $agent agent (BR 3)"
  done
  for cmd in ocf:cv-hub ocf:cv-hub-update ocf:cv-optimize ocf:cv-tailor \
             ocf:cv-cover-letter ocf:cv-linkedin ocf:cv-interview-prep \
             ocf:cv-ats-score; do
    assert_contains "$CAREER_README" "$cmd" \
      "agents/career/README.md documents the $cmd command (BR 3)"
  done
else
  t_fail "agents/career/README.md missing at $CAREER_README"
fi

# 2. README.md template defined in the cv-hub skill (BR 4 / AC 4)
if [[ -f "$HUB_SKILL" ]]; then
  assert_contains "$HUB_SKILL" "## README.md template" \
    "cv-hub skill defines the README.md template section (BR 4)"
  for section in "## Contact" "## Summary" "## Experience" "## Education" \
                 "## Skills" "## Certifications" "## Projects" "## Languages" \
                 "## Links"; do
    assert_contains "$HUB_SKILL" "$section" \
      "README template covers the $section section (BR 4)"
  done
else
  t_fail "cv-hub skill missing at $HUB_SKILL"
fi

# 3. curl -L removed from cv-tailor (BR 5 / AC 5) — URLs are never fetched
assert_not_contains "$TAILOR_SKILL" "curl" \
  "cv-tailor skill has no curl/URL-fetching instructions (BR 5)"
assert_not_contains "$TAILOR_AGENT" '"curl -L*": allow' \
  "cv-tailor agent grants no curl -L bash permission (BR 5)"
assert_not_contains "$TAILOR_AGENT" "curl" \
  "cv-tailor agent has no curl/URL-fetching instructions (BR 5)"
assert_not_contains "$TAILOR_CMD" "curl" \
  "ocf:cv-tailor command has no curl/URL-fetching instructions (BR 5)"
if [[ -f "$OP_CONFIG" ]]; then
  python3 - "$OP_CONFIG" <<'PYEOF' || t_fail "ocf:cv-tailor template still references curl (BR 5)"
import json, sys
cfg = json.load(open(sys.argv[1]))
template = cfg["command"]["ocf:cv-tailor"]["template"]
assert "curl" not in template, "ocf:cv-tailor template must not mention curl"
PYEOF
  t_ok "ocf:cv-tailor command template has no curl instructions (BR 5)"
else
  t_fail "opencode.json missing at $OP_CONFIG"
fi

t_finish
