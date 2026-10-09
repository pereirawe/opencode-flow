#!/usr/bin/env bash
# test_loop_error_triage.sh — regression test for issue #244:
# scripts/loop-error-triage.sh (classify global vs project, dedup, route to the
# correct tracker) and the OCF_ISSUES_FILE tracker override in scripts/config.sh.
#
# Coverage:
#   t01 — --plan writes digest + proposals TSV with only actionable rows
#   t02 — explicit scope drives the target (global file vs project tracker)
#   t03 — --min-severity filters (critical => empty plan; low => includes low)
#   t04 — --apply files global rows into the global tracker only
#   t05 — --apply files project rows into the project tracker only
#   t06 — re-applying does not duplicate (dedup by Location)
#   t07 — --from <tsv> applies an edited plan
#   t08 — OCF_ISSUES_FILE redirects append-issue + issue-lint away from cwd
#   t09 — bash -n parses both scripts
#
# Self-contained: mktemp + trap.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_loop_error_triage"

TRIAGE="$HERE/../loop-error-triage.sh"
JOURNAL_SH="$HERE/../loop-journal.sh"
APPEND="$HERE/../append-issue.sh"
LINT="$HERE/../issue-lint.sh"
for f in "$TRIAGE" "$JOURNAL_SH" "$APPEND" "$LINT"; do
  [[ -f "$f" ]] || { t_fail "missing $f"; t_finish; exit 1; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PROJ="$TMP/proj"
mkdir -p "$PROJ/.opencode" "$TMP/global"
PROJECT_TRACKER="$PROJ/.opencode/known_issues.md"
GLOBAL_TRACKER="$TMP/global/known_issues.md"
printf '# Known issues\n' > "$PROJECT_TRACKER"
printf '# Known issues\n' > "$GLOBAL_TRACKER"
J="$TMP/loop-develop-244.jsonl"
PTSV="$PROJ/.opencode/preflight/loop-errors-t244.proposals.tsv"

# Seed the journal (integration with loop-journal.sh).
bash "$JOURNAL_SH" append --journal "$J" --loop develop --id 244 --phase review \
  --severity high --scope global --location "scripts/foo.sh:10" \
  --command "scripts/foo.sh 244" --exit-code 2 --message "boom global" >/dev/null 2>&1
bash "$JOURNAL_SH" append --journal "$J" --loop develop --id 244 --phase review \
  --severity medium --scope project --location "src/app.py:2" \
  --command "pytest tests/test_app.py" --exit-code 1 --message "boom project" >/dev/null 2>&1
bash "$JOURNAL_SH" append --journal "$J" --loop develop --id 244 --phase review \
  --severity low --scope project --location "src/low.py:1" \
  --command "lint" --exit-code 1 --message "below threshold" >/dev/null 2>&1

run_triage() { ( cd "$PROJ" && bash "$TRIAGE" "$@" \
  --journal "$J" --global-tracker "$GLOBAL_TRACKER" --project-tracker "$PROJECT_TRACKER" \
  --label t244 ) 2>&1; }

# t01 — plan: only actionable rows (medium+) present
OUT="$(run_triage --plan)"; rc=$?
assert_eq "0" "$rc" "t01a plan exits 0"
[[ -f "$PTSV" ]] && t_ok "t01b proposals TSV written" || t_fail "t01b proposals TSV missing"
assert_contains "$PTSV" "scripts/foo.sh:10" "t01c global row present"
assert_contains "$PTSV" "src/app.py:2" "t01d project row present"
assert_not_contains "$PTSV" "src/low.py:1" "t01e low row filtered (min-severity medium)"

# t02 — explicit scope column drives target
assert_contains "$PTSV" "global" "t02a scope global recorded"
assert_contains "$PTSV" "src/app.py:2" "t02b scope project recorded"

# t03 — min-severity
run_triage --plan --min-severity critical >/dev/null 2>&1
DIGEST="$PROJ/.opencode/preflight/loop-errors-t244.md"
assert_contains "$DIGEST" "No actionable errors" "t03a critical plan is empty"
run_triage --plan --min-severity low >/dev/null 2>&1
assert_contains "$PTSV" "src/low.py:1" "t03b low plan includes low row"

# t04/t05 — apply routes each row to its target tracker, and only there
run_triage --apply >/dev/null 2>&1
assert_contains "$GLOBAL_TRACKER" "Location: scripts/foo.sh:10" "t04a global row filed globally"
assert_contains "$GLOBAL_TRACKER" "- Type: bug" "t04b global entry typed bug"
assert_not_contains "$GLOBAL_TRACKER" "src/app.py:2" "t04c project row NOT in global"
assert_contains "$PROJECT_TRACKER" "Location: src/app.py:2" "t05a project row filed in project tracker"
assert_not_contains "$PROJECT_TRACKER" "scripts/foo.sh:10" "t05b global row NOT in project tracker"

# t06 — dedup: re-apply does not duplicate
run_triage --apply >/dev/null 2>&1
assert_count "$GLOBAL_TRACKER" "Location: scripts/foo.sh:10" "1" "t06a one global entry after re-apply"
assert_count "$PROJECT_TRACKER" "Location: src/app.py:2" "1" "t06b one project entry after re-apply"

# t07 — --from applies an edited plan
FROM="$TMP/custom.tsv"
printf '#scope\tseverity\ttarget\tlocation\tcommand\texit_code\tloop\tid\tphase\tmessage\n' > "$FROM"
printf 'global\tmedium\t%s\tscripts/bar.sh:5\tscripts/bar.sh\t1\tdevelop\t244\treview\tboom bar\n' \
  "$GLOBAL_TRACKER" >> "$FROM"
( cd "$PROJ" && bash "$TRIAGE" --apply --from "$FROM" --global-tracker "$GLOBAL_TRACKER" \
  --project-tracker "$PROJECT_TRACKER" --label t244 ) >/dev/null 2>&1
assert_contains "$GLOBAL_TRACKER" "Location: scripts/bar.sh:5" "t07 --from applied the edited row"

# t08 — OCF_ISSUES_FILE override redirects append-issue + issue-lint
( cd "$PROJ" && OCF_ISSUES_FILE="$GLOBAL_TRACKER" bash "$APPEND" --id 99 \
  --title "override test" --type chore --severity low --priority low \
  --tests "-" --no-lint ) >/dev/null 2>&1
assert_contains "$GLOBAL_TRACKER" "### 99. override test" "t08a append-issue honored override"
assert_not_contains "$PROJECT_TRACKER" "override test" "t08b cwd tracker untouched"
( cd "$PROJ" && OCF_ISSUES_FILE="$GLOBAL_TRACKER" bash "$LINT" 99 ) >/dev/null 2>&1
assert_eq "0" "$?" "t08c issue-lint honored override (PASS)"

# t09 — syntax
bash -n "$TRIAGE" 2>/dev/null
assert_eq "0" "$?" "t09a loop-error-triage.sh bash -n"
bash -n "$HERE/../config.sh" 2>/dev/null
assert_eq "0" "$?" "t09b config.sh bash -n"

t_finish
