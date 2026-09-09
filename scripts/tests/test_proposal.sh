#!/usr/bin/env bash
# Tests for the proposal scripts: scripts/proposal/brand-resolve.sh and
# scripts/proposal/pdf.sh (Proposal Design Standard).
# Self-contained: generates its own fixtures under a temp dir, no network,
# no TTY. PDF-engine assertions are skipped when the engine (Chrome and/or
# LibreOffice) is absent; HOME is isolated per invocation so the suite never
# reads the real ~/.config/opencode/assets.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_proposal"

PROPOSAL_DIR="$SCRIPT_DIR/../proposal"
BRAND_RESOLVE="$PROPOSAL_DIR/brand-resolve.sh"
PDF_SH="$PROPOSAL_DIR/pdf.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── brand-resolve.sh: no brand anywhere ────────────────────────────────
EMPTY="$TMP/empty"
mkdir -p "$EMPTY"
set +e
HOME="$TMP/home0" bash "$BRAND_RESOLVE" --project-dir "$EMPTY" > "$TMP/nobrand.out"
rc_nobrand=$?
set -e
assert_eq "1" "$rc_nobrand" "brand-resolve.sh exits 1 with no brand"
assert_contains "$TMP/nobrand.out" "brand=none" "no-brand output reports brand=none"

# ── brand-resolve.sh: project brand (logo + company.json) ─────────────
PROJ="$TMP/proj"
mkdir -p "$PROJ/docs/assets"
printf 'png-bytes' > "$PROJ/docs/assets/logo.png"
printf '{"name":"Acme SRL"}' > "$PROJ/docs/assets/company.json"
set +e
HOME="$TMP/home1" bash "$BRAND_RESOLVE" --project-dir "$PROJ" > "$TMP/full.out"
rc_full=$?
set -e
assert_eq "0" "$rc_full" "brand-resolve.sh exits 0 with a full project brand"
assert_contains "$TMP/full.out" "source=project" "full brand source is project"
assert_contains "$TMP/full.out" "brand=full" "full brand reports brand=full"
assert_contains "$TMP/full.out" "logo=$PROJ/docs/assets/logo.png" "logo resolves to the project path"
assert_contains "$TMP/full.out" "company_json=$PROJ/docs/assets/company.json" "company.json resolves to the project path"

# ── brand-resolve.sh: logo-only project MUST NOT cross-join a populated
#    global company.json (whole-tier fallback — the project tier wins and
#    stays logo-only; never pair another company's data with this logo).
LOGO_ONLY="$TMP/logo-only"
GLOB_HOME="$TMP/globhome"
mkdir -p "$LOGO_ONLY/docs/assets" "$GLOB_HOME/.config/opencode/assets"
printf 'png-bytes' > "$LOGO_ONLY/docs/assets/logo.svg"
printf '{"name":"Global Co"}' > "$GLOB_HOME/.config/opencode/assets/company.json"
set +e
HOME="$GLOB_HOME" bash "$BRAND_RESOLVE" --project-dir "$LOGO_ONLY" > "$TMP/logo_only.out"
rc_logo_only=$?
set -e
assert_eq "0" "$rc_logo_only" "brand-resolve.sh exits 0 with a logo-only brand"
assert_contains "$TMP/logo_only.out" "brand=logo-only" "logo-only reports brand=logo-only"
assert_contains "$TMP/logo_only.out" "company_json=-" "logo-only project does NOT cross-join global company.json"

# ── brand-resolve.sh: global tier fallback when the project has nothing ─
#    Global dir = $HOME/.config/opencode/assets (per the script).
NOPROJ="$TMP/noproj"
GLOB_HOME="$TMP/globhome"
mkdir -p "$NOPROJ/docs/assets" "$GLOB_HOME/.config/opencode/assets"
printf '{"name":"Global Co"}' > "$GLOB_HOME/.config/opencode/assets/company.json"
printf 'png-bytes' > "$GLOB_HOME/.config/opencode/assets/logo.jpg"
set +e
HOME="$GLOB_HOME" bash "$BRAND_RESOLVE" --project-dir "$NOPROJ" > "$TMP/global.out"
rc_global=$?
set -e
assert_eq "0" "$rc_global" "brand-resolve.sh exits 0 via the global tier when project is empty"
assert_contains "$TMP/global.out" "source=global" "empty-project fallback reports source=global"
assert_contains "$TMP/global.out" "brand=full" "global tier with logo+company reports brand=full"

# ── brand-resolve.sh: legacy spec-local logo fallback ─────────────────
LEGACY="$TMP/legacy"
mkdir -p "$LEGACY/docs/specs/demo/assets"
printf 'png-bytes' > "$LEGACY/docs/specs/demo/assets/logo.jpg"
set +e
HOME="$TMP/home3" bash "$BRAND_RESOLVE" --project-dir "$LEGACY" > "$TMP/legacy.out"
rc_legacy=$?
set -e
assert_eq "0" "$rc_legacy" "brand-resolve.sh exits 0 with a legacy spec-local logo"
assert_contains "$TMP/legacy.out" "source=legacy-spec" "legacy fallback reports source=legacy-spec"

# ── brand-resolve.sh: usage errors ────────────────────────────────────
set +e
HOME="$TMP/home4" bash "$BRAND_RESOLVE" --project-dir "$TMP/does-not-exist" >/dev/null 2>&1
rc_baddir=$?
set -e
assert_eq "2" "$rc_baddir" "brand-resolve.sh exits 2 for a missing project dir"
set +e
HOME="$TMP/home5" bash "$BRAND_RESOLVE" --project-dir >/dev/null 2>&1
rc_noval=$?
set -e
assert_eq "2" "$rc_noval" "brand-resolve.sh exits 2 when --project-dir has no value"

# ── pdf.sh ─────────────────────────────────────────────────────────────
cat > "$TMP/proposal.html" <<'HTMLEOF'
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<style>@page { size: A4; margin: 14mm 16mm; } body { font-family: sans-serif; }
</style></head><body><h1>Commercial Proposal</h1><p>Branded PDF text.</p></body></html>
HTMLEOF

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
if [[ -n "$CHROME" ]]; then
  set +e
  bash "$PDF_SH" "$TMP/proposal.html" "$TMP/proposal.pdf" chrome >/dev/null 2>&1
  rc_pdf=$?
  set -e
  assert_eq "0" "$rc_pdf" "proposal pdf.sh produces a PDF via Chrome headless"
  assert_eq "1" "$(test -s "$TMP/proposal.pdf" && echo 1 || echo 0)" "proposal PDF is non-empty"
  if command -v pdftotext >/dev/null 2>&1; then
    EXTRACTED="$(pdftotext "$TMP/proposal.pdf" - 2>/dev/null || true)"
    if [[ "$EXTRACTED" == *"Commercial Proposal"* ]]; then
      t_ok "proposal PDF is text-extractable"
    else
      t_fail "proposal PDF text not extractable (expected 'Commercial Proposal')"
    fi
    if [[ "$EXTRACTED" == *"file://"* ]]; then
      t_fail "proposal PDF contains a browser header (file:// URL leaked)"
    else
      t_ok "proposal PDF has no browser header/footer"
    fi
  fi
else
  echo "skip - chrome not installed; proposal pdf.sh chrome path not exercised"
fi

# pdf.sh fails cleanly (exit 2) when input is missing; creates output dir
set +e
bash "$PDF_SH" "$TMP/missing.html" "$TMP/out.pdf" >/dev/null 2>&1
rc_missing=$?
set -e
assert_eq "2" "$rc_missing" "proposal pdf.sh exits 2 when the input HTML is missing"

if [[ -n "$CHROME" ]]; then
  set +e
  bash "$PDF_SH" "$TMP/proposal.html" "$TMP/deep/nested/out.pdf" chrome >/dev/null 2>&1
  rc_deep=$?
  set -e
  assert_eq "0" "$rc_deep" "proposal pdf.sh creates a missing output directory"
  assert_eq "1" "$(test -s "$TMP/deep/nested/out.pdf" && echo 1 || echo 0)" "proposal PDF written into created dir"
fi

# ── pdf.sh: LibreOffice fallback warns about page numbers ─────────────
if command -v libreoffice >/dev/null 2>&1 || command -v soffice >/dev/null 2>&1; then
  set +e
  bash "$PDF_SH" "$TMP/proposal.html" "$TMP/proposal-lo.pdf" libreoffice > "$TMP/lo.out" 2> "$TMP/lo.err"
  rc_lo=$?
  set -e
  assert_eq "0" "$rc_lo" "proposal pdf.sh produces a PDF via the LibreOffice fallback"
  assert_eq "1" "$(test -s "$TMP/proposal-lo.pdf" && echo 1 || echo 0)" "LibreOffice proposal PDF is non-empty"
  assert_contains "$TMP/lo.err" "LibreOffice fallback" "proposal pdf.sh warns on the LibreOffice fallback (page-number footer caveat)"
else
  echo "skip - libreoffice not installed; proposal pdf.sh fallback path not exercised"
fi

# ── Reference template sanity (static, no render) ─────────────────────
TPL="$(cd "$SCRIPT_DIR/../.." && pwd)/skills/business-ops/proposal-writer/templates/proposal.html"
if [[ -f "$TPL" ]]; then
  assert_contains "$TPL" "@page" "proposal template declares @page (A4)"
  assert_contains "$TPL" "brand-header" "proposal template has a brand header block"
  assert_contains "$TPL" "{{PROPOSAL_BODY}}" "proposal template keeps a body placeholder"
  assert_contains "$TPL" "proposal-section" "proposal template uses the .proposal-section class (standard §2.4)"
  assert_contains "$TPL" "{{DOC_LANG}}" "proposal template parametrizes the html lang attribute"
else
  t_fail "proposal reference template missing: $TPL"
fi

t_finish
