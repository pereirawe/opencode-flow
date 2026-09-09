#!/usr/bin/env bash
# test_committer_check.sh — regression test for issue #222: the committer
# security gate (1) selected a superseded/wrong security report via
# `ls -1 ... | head -1` (lexicographic order) and (2) failed to detect a
# blocking verdict from real report vocabulary — false PASS/FAIL. A broad
# legacy `security-*.md` fallback also picked up another issue's report
# (false FAIL / false PASS).
#
# Fix under test (delivered on main, 5d9dd6f): issue-scoped report selection by
# NEWEST mtime (`security-issue-<id>-*` → `security-<id>-*`, no broad fallback)
# and verdict parsing anchored on the LAST `Verdict` section with a bounded
# window, requiring explicit approval (vocabulary: refus/request changes/block
# approval/denied/gate does not pass/minimum required fixes/unresolved
# critical|high).
#
# Coverage (Tests 1-3 from the issue):
#   t01 — reviews/ with `security-issue-1-*` REQUEST_CHANGES (old mtime) +
#         `security-issue-1-recheck-*` APPROVED (new mtime) → committer-check 1
#         → PASS, reading the NEWEST report (exit 0 + "VERDICT: PASS")
#   t02 — single `security-issue-1-*` report with
#         `**Verdict: REQUEST_CHANGES** — 3 critical + 3 high findings block
#         approval` → FAIL (exit 2, "security report refuses approval")
#   t03 — no `security-issue-1-*`/`security-1-*` report in reviews/, but a
#         `security-git-cred-cache-*` REFUSED from another issue → FAIL with
#         "no issue-scoped report found" (no cross-issue fallback)
#
# Self-contained: mktemp + trap; config.sh resolves PROJECT_ISSUES_FILE /
# PROJECT_ISSUES_DIR from the CWD (`.opencode/known_issues.md`), so each case
# runs with `cd` into an isolated fixture dir (mirroring test_issue_lint.sh).
# committer-check.sh also calls `test-runner.sh --check` from the fixture CWD;
# a minimal `.opencode/test-cache/<branch>-pytest.result` is seeded with the
# fingerprint reported by `test-runner.sh --status`, so the "Tests cache" gate
# passes and the security gate is the ONLY variable under test. Deterministic:
# report mtimes are pinned with `touch -d`.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_committer_check"

CHECK="$HERE/../committer-check.sh"
RUNNER="$HERE/../test-runner.sh"
[[ -f "$CHECK" ]]  || { t_fail "committer-check.sh not found at $CHECK";  t_finish; exit 1; }
[[ -f "$RUNNER" ]] || { t_fail "test-runner.sh not found at $RUNNER"; t_finish; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RUN_OUT="$TMP/run.out"

# seed_test_cache <dir> — seeds a minimal .opencode/test-cache result so the
# `test-runner.sh --check` called by committer-check.sh (from the fixture CWD)
# exits 0. The fingerprint comes from `test-runner.sh --status` itself, so the
# seeded cache always matches whatever the fixture contains (the cache dir is
# excluded from the fingerprint via EXCLUDE_RE, so seeding never invalidates it).
seed_test_cache() {
  local dir="$1" status fp branch runner
  status="$(cd "$dir" && bash "$RUNNER" --status 2>/dev/null)"
  fp="$(printf '%s\n' "$status" | awk '/^[[:space:]]+fingerprint:/{print $2; exit}')"
  branch="$(printf '%s\n' "$status" | awk '/^[[:space:]]+branch:/{print $2; exit}')"
  runner="$(printf '%s\n' "$status" | awk '/^[[:space:]]+runner:/{print $2; exit}')"
  [[ -n "$fp" && -n "$branch" && -n "$runner" ]] || { t_fail "seed_test_cache: could not parse test-runner --status (fp='$fp' branch='$branch' runner='$runner')"; return 1; }
  mkdir -p "$dir/.opencode/test-cache"
  cat > "$dir/.opencode/test-cache/${branch}-${runner}.result" <<EOF
fingerprint=$fp
exit_code=0
timestamp=$(date +%s)
output=${branch}-${runner}.log
node_version=
python_version=
runner_version=1.0.0
EOF
}

# make_issue <dir> — canonical in-review bug entry whose Reviewers include the
# `security` profile (engages the security gate), plus a requirements.txt so
# test-runner detects the pytest runner for the seeded cache.
make_issue() {
  local dir="$1"
  mkdir -p "$dir/.opencode/reviews"
  {
    printf '## Known Issues\n\n'
    printf '### 1. Bug: committer security gate regression\n'
    printf -- '- Status: in-review\n- Opened: 2026-09-09\n- Started: 2026-09-09T15:25\n'
    printf -- '- Type: bug\n- Severity: high\n- Priority: high\n- Base branch: main\n'
    printf -- '- Reviewers: 1 (security)\n- Remote: -\n- Business rules: none\n'
    printf -- '- Tests:\n  1. cenario -> outcome\n'
  } > "$dir/.opencode/known_issues.md"
  printf 'dummy\n' > "$dir/requirements.txt"
}

# run_check <dir> <id> — runs committer-check.sh with CWD = <dir> so config.sh
# resolves the fixture's .opencode/; echoes the exit code, output in $RUN_OUT.
run_check() {
  local dir="$1" id="$2"
  local rc=0
  ( cd "$dir" && bash "$CHECK" "$id" ) >"$RUN_OUT" 2>&1 || rc=$?
  echo "$rc"
}

# ===========================================================================
# t01 — newest APPROVED report supersedes an older REQUEST_CHANGES one.
# Before the fix, `ls -1 | head -1` (lexicographic) picked `-original.md`
# (REQUEST_CHANGES) and the gate FAILED despite the approved recheck.
# ===========================================================================
t1="$TMP/t1"
make_issue "$t1"
{
  printf '# Security Review — issue 1 (original round)\n\n'
  printf '**Verdict: REQUEST_CHANGES** — findings require fixes before approval\n\n'
  printf '## Findings\n- 2 critical\n- 1 high\n'
} > "$t1/.opencode/reviews/security-issue-1-original.md"
{
  printf '# Security Review — issue 1 (recheck round)\n\n'
  printf '**Verdict: APPROVED** — all findings resolved\n\n'
  printf '## Details\n- nothing outstanding\n'
} > "$t1/.opencode/reviews/security-issue-1-recheck.md"
touch -d "2026-09-01 10:00:00" "$t1/.opencode/reviews/security-issue-1-original.md"
touch -d "2026-09-09 10:00:00" "$t1/.opencode/reviews/security-issue-1-recheck.md"
seed_test_cache "$t1" || { t_fail "t01: seeding test cache"; t_finish; exit 1; }

rc=$(run_check "$t1" 1)
assert_eq "0" "$rc" "t01: newest APPROVED report supersedes older REQUEST_CHANGES (exit 0)"
assert_contains "$RUN_OUT" "Security review: report present and approved" "t01: security gate passes"
assert_contains "$RUN_OUT" "security-issue-1-recheck.md" "t01: NEWEST report selected (by mtime, not name)"
assert_not_contains "$RUN_OUT" "security report refuses approval" "t01: no false refusal of the approved recheck"
assert_not_contains "$RUN_OUT" "security-issue-1-original.md" "t01: superseded REQUEST_CHANGES report not used"
assert_contains "$RUN_OUT" "VERDICT: PASS" "t01: overall verdict PASS"

# ===========================================================================
# t02 — a single blocking report (real vocabulary) MUST fail the gate.
# Before the fix the fragile vocabulary missed `block approval` and the gate
# PASSED (false PASS) despite `**Verdict: REQUEST_CHANGES**`.
# ===========================================================================
t2="$TMP/t2"
make_issue "$t2"
{
  printf '# Security Review — issue 1\n\n'
  printf '**Verdict: REQUEST_CHANGES** — 3 critical + 3 high findings block approval\n\n'
  printf '## Details\n- fix before merge\n'
} > "$t2/.opencode/reviews/security-issue-1-final.md"
touch -d "2026-09-09 10:00:00" "$t2/.opencode/reviews/security-issue-1-final.md"
seed_test_cache "$t2" || { t_fail "t02: seeding test cache"; t_finish; exit 1; }

rc=$(run_check "$t2" 1)
assert_eq "2" "$rc" "t02: blocking REQUEST_CHANGES verdict detected (exit 2)"
assert_contains "$RUN_OUT" "security report refuses approval" "t02: refusal message emitted"
assert_contains "$RUN_OUT" "security-issue-1-final.md" "t02: failing report identified"
assert_contains "$RUN_OUT" "VERDICT: FAIL" "t02: overall verdict FAIL"

# ===========================================================================
# t03 — no issue-scoped report: the gate must FAIL WITHOUT falling back to
# another issue's report (the legacy `security-*.md` fallback was the #222
# false-FAIL / false-PASS cross-issue class).
# ===========================================================================
t3="$TMP/t3"
make_issue "$t3"
{
  printf '# Security Review — git-cred-cache (issue 209 scope)\n\n'
  printf '**Verdict: REFUSED** — credential cache design needs rework\n\n'
} > "$t3/.opencode/reviews/security-git-cred-cache-20260909.md"
seed_test_cache "$t3" || { t_fail "t03: seeding test cache"; t_finish; exit 1; }

rc=$(run_check "$t3" 1)
assert_eq "2" "$rc" "t03: no issue-scoped report -> FAIL (exit 2)"
assert_contains "$RUN_OUT" "no issue-scoped report found" "t03: no issue-scoped report message"
assert_not_contains "$RUN_OUT" "security-git-cred-cache" "t03: other issue's report NOT used as fallback"
assert_contains "$RUN_OUT" "VERDICT: FAIL" "t03: overall verdict FAIL"

t_finish
