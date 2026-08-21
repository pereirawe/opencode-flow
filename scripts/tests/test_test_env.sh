#!/usr/bin/env bash
# test_test_env.sh — unit tests for the versioned test environment (issue #210).
# Covers the 6 issue scenarios: out-of-range node, in-range --status metadata,
# sync-guard desync (with --check stderr purity), fingerprint exclusion + drift,
# missing/malformed manifest, absent node/python3 (warning-only), and init.sh
# conditional placeholders. Uses mock go/node/python3 binaries — never real node.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_test_env"

SCRIPT="$HERE/../test-runner.sh"
INIT="$HERE/../init.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- mock runner infrastructure (reuses test_test_runner.sh pattern) ---
MOCK_BIN="$TMP/bin"
MOCK_LOG="$TMP/mock-invocations.log"
MOCK_EXIT_FILE="$TMP/mock-exit"
MOCK_NODE_VERSION_FILE="$TMP/mock-node-version"
MOCK_PYTHON_VERSION_FILE="$TMP/mock-python-version"
export MOCK_LOG MOCK_EXIT_FILE MOCK_NODE_VERSION_FILE MOCK_PYTHON_VERSION_FILE
mkdir -p "$MOCK_BIN"
echo "0" > "$MOCK_EXIT_FILE"
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"

cat > "$MOCK_BIN/go" <<'EOF'
#!/usr/bin/env bash
echo "go called: $*" >> "$MOCK_LOG"
exit "$(cat "$MOCK_EXIT_FILE")"
EOF
chmod +x "$MOCK_BIN/go"

# mock node — prints a configurable version (never a real node)
cat > "$MOCK_BIN/node" <<'EOF'
#!/usr/bin/env bash
cat "$MOCK_NODE_VERSION_FILE"
EOF
chmod +x "$MOCK_BIN/node"

# mock python3 — prints a configurable version (never a real python3)
cat > "$MOCK_BIN/python3" <<'EOF'
#!/usr/bin/env bash
cat "$MOCK_PYTHON_VERSION_FILE"
EOF
chmod +x "$MOCK_BIN/python3"

# make_repo <dir> — tiny git repo with go.mod (Go runner detected)
make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'module test\n' > "$dir/go.mod"
  printf 'package main\n' > "$dir/main.go"
  git -C "$dir" init -q
  git -C "$dir" -c user.name=t -c user.email=t@t add -A
  git -C "$dir" -c user.name=t -c user.email=t@t commit -qm init
}

# make_env_repo <dir> — make_repo + pinned Node 22 + committed env manifest
# (with the `## Strict (machine-parseable)` header, per F4 section-scoping).
make_env_repo() {
  local dir="$1"
  make_repo "$dir"
  printf '22\n' > "$dir/.nvmrc"
  printf '22\n' > "$dir/.node-version"
  mkdir -p "$dir/.opencode"
  cat > "$dir/.opencode/env-manifest.md" <<'EOF'
## Strict (machine-parseable)

node: >=20 <23
python: >=3.10 <4
test-runner: >=1.0

## Bootstrap

1. Node: nvm install 22
EOF
  git -C "$dir" -c user.name=t -c user.email=t@t add -A
  git -C "$dir" -c user.name=t -c user.email=t@t commit -qm "env manifest"
}

invocations() {
  [[ -f "$MOCK_LOG" ]] && wc -l < "$MOCK_LOG" || echo 0
}

reset_mock() {
  : > "$MOCK_LOG"
  echo "0" > "$MOCK_EXIT_FILE"
}

# --- Scenario 1: node v19 out of range → actionable warning, not blocked, .result metadata ---
repo1="$TMP/sc1"
make_env_repo "$repo1"
printf 'v19.8.3\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
reset_mock
err1="$TMP/sc1.err"
( cd "$repo1" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>"$err1"; echo $? ) > "$TMP/sc1.rc"
assert_eq "0" "$(cat "$TMP/sc1.rc")" "sc1: out-of-range node does NOT block --run"
assert_eq "1" "$(invocations)" "sc1: runner still executes despite the warning"
assert_contains "$err1" "node v19.8.3 is outside the manifest range (>=20 <23)" "sc1: warning names the version and the expected range"
assert_contains "$err1" "nvm install 22" "sc1: warning includes an actionable install hint"
branch1="$(git -C "$repo1" rev-parse --abbrev-ref HEAD)"
assert_contains "$repo1/.opencode/test-cache/$branch1-go.result" "node_version=v19.8.3" "sc1: .result records node_version"
assert_contains "$repo1/.opencode/test-cache/$branch1-go.result" "python_version=3.12.0" "sc1: .result records python_version"
assert_contains "$repo1/.opencode/test-cache/$branch1-go.result" "runner_version=1.0.0" "sc1: .result records runner_version"
# exit code preserved on a failing suite too
reset_mock
echo "1" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 1\n' > "$repo1/main.go"
( cd "$repo1" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>"$err1"; echo $? ) > "$TMP/sc1f.rc"
assert_eq "1" "$(cat "$TMP/sc1f.rc")" "sc1: runner exit code 1 is preserved despite warnings"
assert_contains "$err1" "outside the manifest range" "sc1: warning still present on a failing run"

# --- Scenario 2: --status with in-range versions → no warning, exit 0, metadata shown ---
repo2="$TMP/sc2"
make_env_repo "$repo2"
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
out2="$TMP/sc2.out"; err2="$TMP/sc2.err"
( cd "$repo2" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >"$out2" 2>"$err2"; echo $? ) > "$TMP/sc2.rc"
assert_eq "0" "$(cat "$TMP/sc2.rc")" "sc2: --status always exits 0"
assert_contains "$out2" "node version:     v22.3.1" "sc2: --status shows node_version"
assert_contains "$out2" "python version:   3.12.0" "sc2: --status shows python_version"
assert_contains "$out2" "runner version:   1.0.0" "sc2: --status shows runner_version"
assert_eq "" "$(cat "$err2")" "sc2: no warnings when versions are in range (stderr empty)"

# --- Scenario 3: desync .nvmrc/.node-version/manifest → sync guard; --check stderr pure ---
repo3="$TMP/sc3"
make_env_repo "$repo3"
printf '18\n' > "$repo3/.node-version"   # desync: .nvmrc=22, .node-version=18
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
err3="$TMP/sc3.err"
# --check with NO cache: exit 3, stderr EMPTY even desynced
( cd "$repo3" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>"$err3"; echo $? ) > "$TMP/sc3a.rc"
assert_eq "3" "$(cat "$TMP/sc3a.rc")" "sc3: --check without cache exits 3 despite desync"
assert_eq "" "$(cat "$err3")" "sc3: --check stderr EMPTY (no cache, desynced)"
# --status: sync guard warning, exit 0
( cd "$repo3" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >/dev/null 2>"$err3"; echo $? ) > "$TMP/sc3b.rc"
assert_eq "0" "$(cat "$TMP/sc3b.rc")" "sc3: --status exits 0 despite desync"
assert_contains "$err3" "sync guard" "sc3: --status emits a sync-guard consistency warning"
# --run: sync guard warning, exit 0
reset_mock
( cd "$repo3" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>"$err3"; echo $? ) > "$TMP/sc3c.rc"
assert_eq "0" "$(cat "$TMP/sc3c.rc")" "sc3: --run exits 0 despite desync (warning-only)"
assert_contains "$err3" "sync guard" "sc3: --run emits a sync-guard consistency warning"
# --check WITH fresh cache: exit 0, stderr STILL empty
( cd "$repo3" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>"$err3"; echo $? ) > "$TMP/sc3d.rc"
assert_eq "0" "$(cat "$TMP/sc3d.rc")" "sc3: --check with fresh cache exits 0"
assert_eq "" "$(cat "$err3")" "sc3: --check stderr EMPTY (fresh cache, desynced)"

# --- Scenario 4: env-file edits → fingerprint unchanged, cache reused; drift warning ---
repo4="$TMP/sc4"
make_env_repo "$repo4"
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
reset_mock
( cd "$repo4" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
branch4="$(git -C "$repo4" rev-parse --abbrev-ref HEAD)"
fp_before="$(awk -F= '/^fingerprint=/{print $2}' "$repo4/.opencode/test-cache/$branch4-go.result")"
# modify ONLY environment metadata (no code change)
printf '20\n' > "$repo4/.nvmrc"
printf '20\n' > "$repo4/.node-version"
printf '# comment-only change\n' >> "$repo4/.opencode/env-manifest.md"
reset_mock
( cd "$repo4" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "0" "$(invocations)" "sc4: env-file edits do NOT re-execute the runner (cache reused)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo4/.opencode/test-cache/$branch4-go.result")"
assert_eq "$fp_before" "$fp_after" "sc4: fingerprint unchanged after env-file edits"
# drift: cache was written under node v22, now node v19 → non-blocking warning
printf 'v19.8.3\n' > "$MOCK_NODE_VERSION_FILE"
err4="$TMP/sc4.err"
( cd "$repo4" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >/dev/null 2>"$err4"; echo $? ) > "$TMP/sc4.rc"
assert_eq "0" "$(cat "$TMP/sc4.rc")" "sc4: --status exits 0 with environment drift"
assert_contains "$err4" "drift" "sc4: --status emits a drift warning (non-blocking)"
assert_contains "$err4" "v22.3.1" "sc4: drift warning names the cached node version"

# --- Scenario 5: missing manifest → warning + skip; malformed range → degrade, no crash ---
repo5="$TMP/sc5"
make_repo "$repo5"   # plain repo, NO manifest
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
err5="$TMP/sc5.err"
( cd "$repo5" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>"$err5"; echo $? ) > "$TMP/sc5.rc"
assert_eq "0" "$(cat "$TMP/sc5.rc")" "sc5: missing manifest does NOT block --run (exit intact)"
assert_contains "$err5" "no .opencode/env-manifest.md found" "sc5: missing manifest → warning + validation skipped"
# malformed range (strict section present, range token incomplete)
repo5b="$TMP/sc5b"
make_env_repo "$repo5b"
printf '## Strict (machine-parseable)\n\nnode: >=20 <\n' > "$repo5b/.opencode/env-manifest.md"
err5b="$TMP/sc5b.err"
( cd "$repo5b" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>"$err5b"; echo $? ) > "$TMP/sc5b.rc"
assert_eq "0" "$(cat "$TMP/sc5b.rc")" "sc5b: malformed manifest does NOT crash --run"
assert_contains "$err5b" "malformed" "sc5b: parser degrades with an actionable message"

# --- Scenario 6: node AND python3 absent → two informative warnings, exit 0, never error ---
# minbin is also the restricted PATH for the init.sh Case A (F2/F3) — it must
# carry every external tool the scripts need (incl. dirname for init.sh's
# CONFIG_DIR derivation and mv for write_cache's atomic publish) but NOT node
# or python3, so the no-node/no-python environment is deterministic.
minbin="$TMP/minbin"
mkdir -p "$minbin"
for tool in bash git sha256sum cut awk sed cat mkdir date basename tr grep wc dirname cp rm sort mv; do
  tp="$(command -v "$tool" || true)"
  [[ -n "$tp" ]] && ln -s "$tp" "$minbin/$tool"
done
ln -s "$MOCK_BIN/go" "$minbin/go"
repo6="$TMP/sc6"
make_env_repo "$repo6"
err6="$TMP/sc6.err"
( cd "$repo6" && PATH="$minbin" bash "$SCRIPT" --status >/dev/null 2>"$err6"; echo $? ) > "$TMP/sc6.rc"
assert_eq "0" "$(cat "$TMP/sc6.rc")" "sc6: --status exits 0 with node AND python3 absent"
assert_count "$err6" "WARNING" "2" "sc6: both absences produce exactly two informative warnings"
assert_not_contains "$err6" "dirname" "sc6: no 'dirname: command not found' noise on stderr (F3)"
assert_contains "$err6" "node not found" "sc6: node-absent warning"
assert_contains "$err6" "python3 not found" "sc6: python3-absent warning"
( cd "$repo6" && PATH="$minbin" bash "$SCRIPT" --run >/dev/null 2>"$err6"; echo $? ) > "$TMP/sc6b.rc"
assert_eq "0" "$(cat "$TMP/sc6b.rc")" "sc6: --run exits 0 with node AND python3 absent (warning-only, never error)"
assert_count "$err6" "WARNING" "2" "sc6: --run also emits exactly two warnings"

# --- init.sh conditional placeholders (BR 7 / AC 8) ---
# Case A: no Node in PATH → NO pin files. Deterministic (F2): uses the same
# minbin restricted PATH as scenario 6, which has no node/python3 — the outcome
# never depends on whether the host happens to have node installed.
init_a="$TMP/init_a"
mkdir -p "$init_a"
PATH="$minbin" bash "$INIT" "$init_a" en < /dev/null > "$TMP/init_a.out" 2>&1 || true
assert_eq "0" "$([[ -f "$init_a/.nvmrc" ]] && echo 1 || echo 0)" "init: no .nvmrc created without Node in PATH"
assert_eq "0" "$([[ -f "$init_a/.node-version" ]] && echo 1 || echo 0)" "init: no .node-version created without Node in PATH"
assert_contains "$TMP/init_a.out" "skipping .nvmrc/.node-version" "init: reports the skip when Node is absent"
assert_not_contains "$TMP/init_a.out" "command not found" "init: Case A runs clean under the restricted PATH (F2/F3)"
# Case B: Node present (mock) → pin files created with 22
init_b="$TMP/init_b"
mkdir -p "$init_b"
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
PATH="$MOCK_BIN:$PATH" bash "$INIT" "$init_b" en < /dev/null > "$TMP/init_b.out" 2>&1 || true
assert_eq "1" "$([[ -f "$init_b/.nvmrc" ]] && echo 1 || echo 0)" "init: .nvmrc created when Node is present"
assert_eq "1" "$([[ -f "$init_b/.node-version" ]] && echo 1 || echo 0)" "init: .node-version created when Node is present"
assert_eq "22" "$(cat "$init_b/.nvmrc")" "init: .nvmrc pins Node 22"
assert_eq "22" "$(cat "$init_b/.node-version")" "init: .node-version pins Node 22"
assert_contains "$TMP/init_b.out" "test environment pins created" "init: reports the creation when Node is present"
assert_eq "1" "$([[ -f "$init_b/.opencode/env-manifest.md" ]] && echo 1 || echo 0)" "init: env-manifest template is copied with .opencode/"

# --- Senior-review regressions (F1–F6, QA-2, QA-3) ---

# F6: .nvmrc=22 vs .node-version=22.0.0 are semantically identical → NO sync warning
repo_f6="$TMP/f6"
make_env_repo "$repo_f6"
printf '22.0.0\n' > "$repo_f6/.node-version"
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
err_f6="$TMP/f6.err"
( cd "$repo_f6" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >/dev/null 2>"$err_f6"; echo $? ) > "$TMP/f6.rc"
assert_eq "0" "$(cat "$TMP/f6.rc")" "f6: --status exits 0"
assert_not_contains "$err_f6" "sync guard" "f6: pins 22 vs 22.0.0 produce NO sync-guard warning (normalized)"
assert_eq "" "$(cat "$err_f6")" "f6: fully in-range environment emits no warnings at all"

# QA-2: empty pin file → sync-guard warning (BR 1 requires a pinned version)
printf '' > "$repo_f6/.nvmrc"
( cd "$repo_f6" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >/dev/null 2>"$err_f6"; echo $? ) > "$TMP/qa2.rc"
assert_eq "0" "$(cat "$TMP/qa2.rc")" "qa2: --status exits 0 with an empty pin file (warning-only)"
assert_contains "$err_f6" "sync guard" "qa2: empty .nvmrc triggers a sync-guard warning"
assert_contains "$err_f6" "empty" "qa2: warning names the empty pin file"

# F4 + QA-3: section-scoped parser + inline comments stripped
repo_f4="$TMP/f4"
make_env_repo "$repo_f4"
cat > "$repo_f4/.opencode/env-manifest.md" <<'EOF'
Prose bootstrap note:
node: se instala via nvm   # prose line BEFORE the strict section — must be ignored (F4)

## Strict (machine-parseable)

node: >=20 <23 # inline comment on a range line — stripped (QA-3)
python: >=3.10 <4
test-runner: >=1.0

## Bootstrap

node: prose line AFTER the strict section — also ignored (F4)
EOF
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
err_f4="$TMP/f4.err"
( cd "$repo_f4" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >/dev/null 2>"$err_f4"; echo $? ) > "$TMP/f4.rc"
assert_eq "0" "$(cat "$TMP/f4.rc")" "f4: --status exits 0"
assert_not_contains "$err_f4" "malformed" "qa3: inline comment does NOT mark the manifest malformed"
assert_not_contains "$err_f4" "outside the manifest range" "f4: prose key-like lines outside the strict section do not poison validation"
assert_eq "" "$(cat "$err_f4")" "f4/qa3: valid strict section with comments → zero warnings"

# F5: duplicate key in the strict section → warning; last value wins
repo_f5="$TMP/f5"
make_env_repo "$repo_f5"
cat > "$repo_f5/.opencode/env-manifest.md" <<'EOF'
## Strict (machine-parseable)

node: >=20 <22
node: >=20 <23
python: >=3.10 <4
test-runner: >=1.0
EOF
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
err_f5="$TMP/f5.err"
( cd "$repo_f5" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status >/dev/null 2>"$err_f5"; echo $? ) > "$TMP/f5.rc"
assert_eq "0" "$(cat "$TMP/f5.rc")" "f5: duplicate key does not change the exit code (still 0)"
assert_contains "$err_f5" "duplicate" "f5: duplicate node key emits a warning"
assert_contains "$err_f5" "node" "f5: duplicate warning names the offending key"
assert_not_contains "$err_f5" "outside the manifest range" "f5: last value wins (>=20 <23) — v22.3.1 stays in range"

# F1: truncated .result → cache-reuse falls back to a real re-run, exit contract intact
repo_f1="$TMP/f1"
make_env_repo "$repo_f1"
printf 'v22.3.1\n' > "$MOCK_NODE_VERSION_FILE"
printf 'Python 3.12.0\n' > "$MOCK_PYTHON_VERSION_FILE"
reset_mock
( cd "$repo_f1" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
branch_f1="$(git -C "$repo_f1" rev-parse --abbrev-ref HEAD)"
res_f1="$repo_f1/.opencode/test-cache/$branch_f1-go.result"
assert_contains "$res_f1" "exit_code=0" "f1: fresh cache records exit_code=0"
# simulate truncation between fingerprint= and exit_code= (only the fingerprint line survives)
grep '^fingerprint=' "$res_f1" > "$res_f1.corrupt"
cp "$res_f1.corrupt" "$res_f1"
reset_mock
( cd "$repo_f1" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>"$TMP/f1.err"; echo $? ) > "$TMP/f1.rc"
assert_eq "0" "$(cat "$TMP/f1.rc")" "f1: corrupted cache falls back to a re-run with exit 0 (contract preserved, not rc=2)"
assert_eq "1" "$(invocations)" "f1: corrupted cache re-executes the runner (cache never blocks)"
assert_contains "$TMP/f1.err" "re-running" "f1: the fallback re-run is announced on stderr"
# failing variant: a corrupted cache must also preserve a failing exit code
: > "$MOCK_LOG"
echo "1" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 1\n' > "$repo_f1/main.go"
( cd "$repo_f1" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
grep '^fingerprint=' "$res_f1" > "$res_f1.corrupt"
cp "$res_f1.corrupt" "$res_f1"
: > "$MOCK_LOG"
( cd "$repo_f1" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1; echo $? ) > "$TMP/f1b.rc"
assert_eq "1" "$(cat "$TMP/f1b.rc")" "f1: corrupted cache re-run preserves a failing exit code 1"
assert_eq "1" "$(invocations)" "f1: corrupted cache re-executes the runner (failing case)"

t_finish
