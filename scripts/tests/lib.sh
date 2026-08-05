# lib.sh — tiny assertion helpers for the plain-bash test suite.
# No external dependencies (no bats): each test_*.sh sources this, runs
# assertions, and exits non-zero when any failed. Files are executed by
# run_all.sh in separate processes, so counters are per-file.

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_FILE=""

t_begin() { CURRENT_FILE="$1"; }
t_ok()    { TESTS_RUN=$((TESTS_RUN+1)); printf 'ok   - %s\n' "$1"; }
t_fail()  { TESTS_FAILED=$((TESTS_FAILED+1)); printf 'FAIL - %s\n' "$1"; }

# assert_eq <expected> <actual> <label>
assert_eq() {
  if [[ "$1" == "$2" ]]; then
    t_ok "$3"
  else
    t_fail "$3 (expected '$1' got '$2')"
  fi
}

# assert_contains <file> <needle> <label> — file contains the needle
assert_contains() {
  if grep -qF -- "$2" "$1" 2>/dev/null; then
    t_ok "$3"
  else
    t_fail "$3 (missing '$2' in $1)"
  fi
}

# assert_not_contains <file> <needle> <label> — file does NOT contain the needle
assert_not_contains() {
  if grep -qF -- "$2" "$1" 2>/dev/null; then
    t_fail "$3 (unexpected '$2' in $1)"
  else
    t_ok "$3"
  fi
}

# count_occurrences <file> <needle> — prints the count (0 when file missing)
count_occurrences() {
  grep -cF -- "$2" "$1" 2>/dev/null || echo 0
}

# assert_count <file> <needle> <expected> <label>
assert_count() {
  local n
  n="$(count_occurrences "$1" "$2")"
  if [[ "$n" -eq "$3" ]]; then
    t_ok "$4"
  else
    t_fail "$4 (expected $3 occurrences of '$2', got $n)"
  fi
}

# t_finish — summary; exit status reflects failures (use as last command)
t_finish() {
  printf '%s: %d passed, %d failed\n' \
    "$CURRENT_FILE" "$((TESTS_RUN - TESTS_FAILED))" "$TESTS_FAILED"
  [[ "$TESTS_FAILED" -eq 0 ]]
}
