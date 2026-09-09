#!/usr/bin/env bash
# test_issue_lint.sh — regression test for issue #224: issue-lint.sh SIGPIPE
# crash (exit 141) when parsing large multi-line fields under `set -o pipefail`.
#
# Root cause (fixed): val() used `field "$1" | head -1 | sed ...`. With a large
# multi-line field (e.g. a canonical feat entry with 13+ Business rules), the
# awk producer in field() keeps writing to the pipe after head -1 exits →
# EPIPE → SIGPIPE → awk dies → `set -euo pipefail` (line 2) aborts the whole
# script with exit 141 and NO verdict (neither PASS nor FAIL). Deterministic
# with big blocks; short fields never trigger it.
# Fix: `sed -n 1p` — same first-line semantics as head -1, but it drains the
# full pipe, so the producer never sees EPIPE (AC 1/2/3).
#
# Coverage (Tests 1-3):
#   t01 — large multi-line entry (25+ Business rules lines) → exit 0 + PASS
#         verdict emitted (no silent 141 crash)
#   t02 — short canonical entry (chore, Tests: -) → exit 0 (no regression)
#   t03 — schema-invalid entry (missing Reviewers) → exit 2 + FAIL verdict
#         (no regression — lint still reports blocking findings)
#   t04 — sed -n 1p ≡ head -1 on a single line (semantic equivalence)
#   t05 — sed -n 1p ≡ head -1 on multi-line input (both yield the 1st line)
#   t06 — issue-lint.sh parses clean (bash -n) after the fix
#
# Self-contained: mktemp + trap; the script under test resolves its issues
# file via config.sh from the CWD (`.opencode/known_issues.md`), so each case
# runs with `cd` into an isolated fixture dir.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_issue_lint"

LINT="$HERE/../issue-lint.sh"
[[ -f "$LINT" ]] || { t_fail "issue-lint.sh not found at $LINT"; t_finish; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RUN_OUT="$TMP/run.out"

# run_lint <dir> <id> [--strict] — runs issue-lint.sh with CWD = <dir> so
# config.sh resolves PROJECT_ISSUES_FILE to <dir>/.opencode/known_issues.md;
# echoes the exit code, stdout+stderr captured in $RUN_OUT.
run_lint() {
  local dir="$1" id="$2"; shift 2
  local rc=0
  ( cd "$dir" && bash "$LINT" "$id" "$@" ) >"$RUN_OUT" 2>&1 || rc=$?
  echo "$rc"
}

# ===========================================================================
# t01 — large multi-line entry: Business rules com 25 linhas (valor na 1a linha
# + bloco de continuação), --strict → PASS (0). Antes do fix isto abortava
# deterministicamente com exit 141 e saída vazia (SIGPIPE no awk do field()
# quando o head -1 saía cedo).
# ===========================================================================
big="$TMP/big"; mkdir -p "$big/.opencode"
{
  printf '## Known Issues\n\n'
  printf '### 1. Entry with a large multi-line Business rules block\n'
  printf -- '- Status: ready\n- Opened: 2026-09-09\n- Type: feat\n- Severity: medium\n- Priority: high\n'
  printf -- '- Base branch: main\n- Reviewers: 1 (backend)\n- Remote: -\n- Jira: -\n- PR: -\n'
  printf -- '- Description: campo multiline grande que disparava o SIGPIPE\n'
  printf -- '- Business rules: 1. regra numero um — requisito funcional do bloco grande (linha 1/25)\n'
  i=2
  while [[ "$i" -le 25 ]]; do
    printf '1. regra numero %d — requisito funcional do bloco grande (linha %d/25)\n' "$i" "$i"
    i=$((i+1))
  done
  printf -- '- Acceptance criteria:\n  1. criterio um\n  2. criterio dois\n'
  printf -- '- Tests:\n  1. cenario A -> outcome A\n  2. cenario B -> outcome B\n  3. cenario C -> outcome C\n'
} > "$big/.opencode/known_issues.md"

rc=$(run_lint "$big" 1 --strict)
assert_eq "0" "$rc" "t01: large multi-line entry exits 0 (no 141 crash)"
assert_contains "$RUN_OUT" "lint: PASS" "t01: PASS verdict emitted (no silent abort)"
assert_not_contains "$RUN_OUT" "141" "t01: no 141 in output"

# ===========================================================================
# t02 — short canonical entry (chore, Tests: -) → exit 0 (no regression)
# ===========================================================================
short="$TMP/short"; mkdir -p "$short/.opencode"
{
  printf '## Known Issues\n\n'
  printf '### 1. Short chore entry\n'
  printf -- '- Status: ready\n- Type: chore\n- Severity: low\n'
  printf -- '- Base branch: main\n- Reviewers: 1 (backend)\n- Tests: -\n'
} > "$short/.opencode/known_issues.md"

rc=$(run_lint "$short" 1)
assert_eq "0" "$rc" "t02: short canonical chore entry exits 0"

# ===========================================================================
# t03 — schema-invalid entry (missing Reviewers) → exit 2 + FAIL verdict
# (no regression — the FAIL path still works, verdict is emitted)
# ===========================================================================
bad="$TMP/bad"; mkdir -p "$bad/.opencode"
{
  printf '## Known Issues\n\n'
  printf '### 1. Bug entry without Reviewers\n'
  printf -- '- Status: ready\n- Type: bug\n- Severity: low\n'
  printf -- '- Base branch: main\n- Business rules: none\n'
  printf -- '- Tests:\n  1. cenario A -> outcome A\n'
} > "$bad/.opencode/known_issues.md"

rc=$(run_lint "$bad" 1)
assert_eq "2" "$rc" "t03: schema-invalid entry exits 2 (FAIL)"
assert_contains "$RUN_OUT" "Reviewers" "t03: FAIL mentions missing Reviewers"

# ===========================================================================
# t04 — sed -n 1p ≡ head -1 on a single line (AC 3)
# ===========================================================================
single="linha unica de teste"
s_val="$(printf '%s\n' "$single" | sed -n 1p)"
h_val="$(printf '%s\n' "$single" | head -1)"
assert_eq "$h_val" "$s_val" "t04: sed -n 1p equals head -1 (single line)"

# ===========================================================================
# t05 — sed -n 1p ≡ head -1 on multi-line input (both yield the 1st line)
# ===========================================================================
multi="primeira linha
segunda linha
terceira linha"
s_val="$(printf '%s\n' "$multi" | sed -n 1p)"
h_val="$(printf '%s\n' "$multi" | head -1)"
assert_eq "$h_val" "$s_val" "t05: sed -n 1p equals head -1 (first of many lines)"

# ===========================================================================
# t06 — issue-lint.sh parses clean (bash -n) after the fix
# ===========================================================================
if bash -n "$LINT" >/dev/null 2>&1; then
  t_ok "t06: issue-lint.sh bash -n clean"
else
  t_fail "t06: issue-lint.sh has a syntax error"
fi

t_finish
