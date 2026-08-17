#!/usr/bin/env bash
# test_test_runner.sh — unit tests for scripts/test-runner.sh.
# Covers: valid/invalid check, run populates the cache, re-run does not re-execute,
# fingerprint changes with edits, git-less fallback, environment diagnostics.
# Uses a mock runner (go) in PATH with an invocation counter.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_test_runner"

SCRIPT="$HERE/../test-runner.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- mock runner infrastructure ---
MOCK_BIN="$TMP/bin"
MOCK_LOG="$TMP/mock-invocations.log"
MOCK_EXIT_FILE="$TMP/mock-exit"
export MOCK_LOG MOCK_EXIT_FILE
mkdir -p "$MOCK_BIN"
echo "0" > "$MOCK_EXIT_FILE"

cat > "$MOCK_BIN/go" <<'EOF'
#!/usr/bin/env bash
echo "go called: $*" >> "$MOCK_LOG"
cat "$MOCK_EXIT_FILE" > /dev/null
exit "$(cat "$MOCK_EXIT_FILE")"
EOF
chmod +x "$MOCK_BIN/go"

# make_repo <dir> — creates a tiny git repo with go.mod (Go runner detected)
make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'module test\n' > "$dir/go.mod"
  printf 'package main\n' > "$dir/main.go"
  git -C "$dir" init -q
  git -C "$dir" -c user.name=t -c user.email=t@t add -A
  git -C "$dir" -c user.name=t -c user.email=t@t commit -qm init
}

invocations() {
  [[ -f "$MOCK_LOG" ]] && wc -l < "$MOCK_LOG" || echo 0
}

reset_mock() {
  : > "$MOCK_LOG"
  echo "0" > "$MOCK_EXIT_FILE"
}

# --- 1. --check before any run → exit 3 ---
repo="$TMP/proj"
make_repo "$repo"
reset_mock
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1
  echo $?
) > "$TMP/check1.rc"
assert_eq "3" "$(cat "$TMP/check1.rc")" "--check without a valid cache exits 3"

# --- 2. --run writes a cache with the correct fingerprint and exit code ---
reset_mock
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1
  echo $?
) > "$TMP/run1.rc"
assert_eq "0" "$(cat "$TMP/run1.rc")" "--run exits 0 when the suite passes"
assert_eq "1" "$(invocations)" "--run invoked the runner exactly once"
branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD)"
assert_eq "1" "$([[ -f "$repo/.opencode/test-cache/$branch-go.result" ]] && echo 1 || echo 0)" "cache .result created"
assert_contains "$repo/.opencode/test-cache/$branch-go.result" "exit_code=0" "cache records exit_code"
assert_contains "$repo/.opencode/test-cache/$branch-go.result" "fingerprint=" "cache records fingerprint"

# --- 3. re-run with the same fingerprint → does NOT re-execute (uses cache) ---
reset_mock
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1
  echo $?
) > "$TMP/run2.rc"
assert_eq "0" "$(cat "$TMP/run2.rc")" "re-run exits 0 (from the cache)"
assert_eq "0" "$(invocations)" "re-run does NOT invoke the runner again (counter 0)"
out=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run 2>&1 || true)
assert_contains <(printf '%s' "$out") "reusing cached result" "re-run reports cache use"

# --- 4. touching a test file → fingerprint changes → re-executes ---
reset_mock
printf 'package main\n\nvar x = 1\n' > "$repo/main.go"
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1
  echo $?
) > "$TMP/run3.rc"
assert_eq "0" "$(cat "$TMP/run3.rc")" "run after a change exits 0"
assert_eq "1" "$(invocations)" "minimal change re-executes the runner"

# --- 5. --check after a valid run → exit 0 + report path ---
out=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check 2>&1 || true)
assert_contains <(printf '%s' "$out") ".opencode/test-cache/$branch-go.result" "--check prints the report path"
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--check with a valid cache exits 0"

# --- 6. runner failure is propagated and cached ---
reset_mock
echo "1" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 2\n' > "$repo/main.go"
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1; echo $?)
assert_eq "1" "$rc" "--run propagates the runner failure exit code"
assert_contains "$repo/.opencode/test-cache/$branch-go.result" "exit_code=1" "cache records the failure exit_code"

# --- 7. --status without git → diagnoses without breaking ---
nogit="$TMP/nogit"
mkdir -p "$nogit"
printf 'def test_x():\n    assert True\n' > "$nogit/test_x.py"
out=$(cd "$nogit" && bash "$SCRIPT" --status 2>&1 || true)
assert_contains <(printf '%s' "$out") "test-runner status" "--status works without git"
assert_contains <(printf '%s' "$out") "git repo:     no" "--status diagnoses the absence of git"

# --- 8. --run without git does not break (content fingerprint) ---
# Force fake Python runner detection even without git
cat > "$MOCK_BIN/pytest" <<'EOF'
#!/usr/bin/env bash
echo "pytest called: $*" >> "$MOCK_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/pytest"
printf '[project]\nname = "x"\nversion = "0.1.0"\n' > "$nogit/pyproject.toml"
printf 'def test_y():\n    assert True\n' > "$nogit/test_y.py"
rc=$(cd "$nogit" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--run without git exits 0 (content fallback)"
assert_contains <(cd "$nogit" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status 2>&1) "git repo:     no" "--status without git stays coherent"

# --- 9. environment diagnostics: runner missing ---
empty="$TMP/empty"
mkdir -p "$empty"
out=$(cd "$empty" && bash "$SCRIPT" --run 2>&1 || true)
assert_contains <(printf '%s' "$out") "no test runner detected" "missing runner produces a clear diagnostic"
rc=$(cd "$empty" && bash "$SCRIPT" --run >/dev/null 2>&1; echo $?)
assert_eq "2" "$rc" "--run without a runner exits 2 (cannot run, not a test failure)"
rc=$(cd "$empty" && bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "3" "$rc" "--check without a runner exits 3"

# --- 10. package.json without a test script → diagnosed, no silent failure ---
noproj="$TMP/nopkgtest"
mkdir -p "$noproj"
printf '{"dependencies":{}}\n' > "$noproj/package.json"
out=$(cd "$noproj" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run 2>&1 || true)
assert_contains <(printf '%s' "$out") "no 'test' script" "package.json without a test script is diagnosed"

# --- 11. filter (--run -- <args>) does NOT touch the shared cache (B1) ---
reset_mock
# ensure a complete FRESH and PASSING cache first (invalidates the test-6 failure cache)
echo "0" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 11\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
fp_full="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
# filtered run — must actually execute and NOT overwrite the cache
reset_mock
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run -- -run TestFoo >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--run with a filter exits 0"
assert_eq "1" "$(invocations)" "filtered run executes the runner (does not use cache)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
assert_eq "$fp_full" "$fp_after" "filtered run does NOT overwrite the shared cache (B1)"
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--check stays valid after a filtered run"

# --- 12. file deletion invalidates the fingerprint (B2) ---
reset_mock
printf 'package main\n\nvar x = 3\n' > "$repo/extra.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
fp_before="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
rm "$repo/extra.go"
reset_mock
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "1" "$(invocations)" "file deletion re-executes the runner (B2)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
if [[ "$fp_before" != "$fp_after" ]]; then
  t_ok "deletion changes the fingerprint (B2)"
else
  t_fail "deletion did NOT change the fingerprint (B2)"
fi

# --- 13. a fresh cache from a FAILED suite does not satisfy --check (B4) ---
reset_mock
echo "1" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 4\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "3" "$rc" "--check with a fresh but FAILED cache exits 3 (B4)"

# --- 14. a path with spaces invalidates the fingerprint (B3) ---
reset_mock
echo "0" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 5\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
fp_space="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
mkdir -p "$repo/dir with space"
printf 'package main\n\nvar y = 1\n' > "$repo/dir with space/extra_test.go"
reset_mock
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "1" "$(invocations)" "file with spaces re-executes the runner (B3)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
if [[ "$fp_space" != "$fp_after" ]]; then
  t_ok "file with spaces changes the fingerprint (B3)"
else
  t_fail "file with spaces did NOT change the fingerprint (B3)"
fi
rm -rf "$repo/dir with space"
reset_mock
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "1" "$(invocations)" "deletion of a file with spaces re-executes (B3)"

# --- 15. filtered run uses a separate log, does not overwrite the suite log (improvement) ---
reset_mock
echo "0" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 6\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
full_log="$repo/.opencode/test-cache/$branch-go.log"
if [[ -f "$full_log" ]]; then
  t_ok "suite log exists before the filtered run"
else
  t_fail "suite log does not exist before the filtered run"
fi
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run -- -run TestFoo >/dev/null 2>&1 )
if [[ -f "$repo/.opencode/test-cache/$branch-go-filtered.log" ]]; then
  t_ok "filtered run creates a separate log (-filtered.log)"
else
  t_fail "filtered run did NOT create a separate log"
fi

t_finish
