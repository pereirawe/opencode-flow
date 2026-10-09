#!/usr/bin/env bash
# test_init.sh — validates scripts/init.sh explicit-whitelist copy (issue #242).
#
# - init copies ONLY the whitelist into <target>/.opencode/
# - init NEVER copies real secrets (*.env), node_modules/, preflight/,
#   reviews/, skills/, agents/, commands/, adorable-proposal/,
#   package.json/lock, README.md, resolved_issues.md, or standards/
# - repo context (branch/remotes) still injected; locale written;
#   LSP suggestions still read from the global catalog at runtime
# - second run exits 0 with identical content (idempotent)
#
# Self-contained: mktemp + trap; CONFIG_DIR resolves from the script path
# (read-only use of the real template — never writes to it).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_init"

INIT="$HERE/../init.sh"
MD5BIN="$(command -v md5sum || true)"
hash_tree() { # <dir> — portable directory digest (GNU md5sum or BSD md5)
  find "$1" -type f | LC_ALL=C sort | while IFS= read -r f; do
    if [ -n "$MD5BIN" ]; then md5sum "$f"; else md5 -r "$f"; fi
  done | if [ -n "$MD5BIN" ]; then md5sum; else md5; fi | cut -d' ' -f1
}
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- 1. Fresh init into empty non-git dir → whitelist only ---
D1="$TMP/proj-empty"
mkdir -p "$D1"
bash "$INIT" "$D1" en </dev/null >/dev/null 2>&1
rc="$?"
assert_eq "0" "$rc" "fresh init exits 0"

for f in AGENTS.md workflow.md opencode.json locale known_issues.md env-manifest.md .gitignore; do
  if [ -f "$D1/.opencode/$f" ]; then
    t_ok "whitelist file present: $f"
  else
    t_fail "whitelist file present: $f (missing)"
  fi
done

# Exact top-level set: nothing beyond the whitelist (C collation for determinism)
extra="$(ls -A "$D1/.opencode" | LC_ALL=C sort | tr '\n' ' ')"
assert_eq ".gitignore AGENTS.md env-manifest.md known_issues.md locale opencode.json workflow.md " "$extra" "target .opencode/ contains exactly the whitelist"

# Forbidden entries absent
for bad in preflight reviews node_modules skills agents commands adorable-proposal standards; do
  if [ -e "$D1/.opencode/$bad" ]; then
    t_fail "forbidden dir absent: $bad (present)"
  else
    t_ok "forbidden dir absent: $bad"
  fi
done
for bad in package.json package-lock.json README.md resolved_issues.md telegram.env openwa.env; do
  if [ -e "$D1/.opencode/$bad" ]; then
    t_fail "forbidden file absent: $bad (present)"
  else
    t_ok "forbidden file absent: $bad"
  fi
done

# No real *.env and no node_modules anywhere under target
leftover="$(find "$D1" \( -name node_modules -o -name '*.env' ! -name '*.env.example' \) 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "0" "$leftover" "find for node_modules|*.env (excl. *.env.example) → 0"

# Non-git marker preserved
assert_contains "$D1/.opencode/AGENTS.md" "<not a git repo>" "non-git target shows <not a git repo>"

# Locale + tracker skeleton
assert_eq "en" "$(cat "$D1/.opencode/locale")" "locale file contains en"
assert_contains "$D1/.opencode/known_issues.md" "## Known Issues" "project known_issues.md skeleton created"

# --- 2. Git repo with remote → branch/remotes injected, no secrets ---
D2="$TMP/proj-git"
mkdir -p "$D2"
git -C "$D2" init -b main -q 2>/dev/null || git -C "$D2" init -q
git -C "$D2" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$D2" remote add origin https://example.com/foo.git
bash "$INIT" "$D2" en </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "git-repo init exits 0"
assert_contains "$D2/.opencode/AGENTS.md" "main" "default branch injected into AGENTS.md"
assert_contains "$D2/.opencode/AGENTS.md" "origin" "remote injected into AGENTS.md"
if grep -q "__DEFAULT_BRANCH__\|__REMOTES__" "$D2/.opencode/AGENTS.md" 2>/dev/null; then
  t_fail "no unreplaced placeholders remain in AGENTS.md"
else
  t_ok "no unreplaced placeholders remain in AGENTS.md"
fi
leftover2="$(find "$D2" \( -name node_modules -o -name '*.env' ! -name '*.env.example' \) 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "0" "$leftover2" "git target: find for node_modules|*.env → 0"

# --- 3. Idempotency: second run exit 0 + identical content ---
sum_before="$(hash_tree "$D2/.opencode")"
bash "$INIT" "$D2" en </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "second run exits 0"
sum_after="$(hash_tree "$D2/.opencode")"
assert_eq "$sum_before" "$sum_after" "second run leaves identical content"
assert_eq "en" "$(cat "$D2/.opencode/locale")" "locale uncorrupted after second run"
assert_contains "$D2/.opencode/AGENTS.md" "main" "AGENTS.md uncorrupted after second run"

# Project tracker never overwritten: append a marker, re-run, marker survives
echo "### 999. marker" >> "$D2/.opencode/known_issues.md"
bash "$INIT" "$D2" en </dev/null >/dev/null 2>&1
assert_contains "$D2/.opencode/known_issues.md" "### 999. marker" "project known_issues.md never overwritten"

# Project-owned .env never deleted by re-run (user data preserved; init just never copies secrets in)
printf 'BOT_TOKEN=owner-value\n' > "$D2/.opencode/telegram.env"
bash "$INIT" "$D2" en </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "re-run with project .env exits 0"
assert_contains "$D2/.opencode/telegram.env" "owner-value" "project-owned telegram.env preserved"

# --- 4. Locale pt + LSP flow unchanged (suggestions shown, opt-in merge) ---
D4="$TMP/proj-lsp"
mkdir -p "$D4"
printf '{"name":"demo"}\n' > "$D4/package.json"
out="$(printf 'n\n' | bash "$INIT" "$D4" pt 2>&1)"
assert_eq "pt" "$(cat "$D4/.opencode/locale")" "locale pt written"
if printf '%s' "$out" | grep -q "LSP suggestions"; then
  t_ok "LSP suggestions shown from global catalog"
else
  t_fail "LSP suggestions shown from global catalog"
fi
if [ -e "$D4/.vscode/settings.json" ]; then
  t_fail "declined LSP prompt creates no .vscode/settings.json"
else
  t_ok "declined LSP prompt creates no .vscode/settings.json"
fi

# --- 5. Safety sweep: only stale blind-copy pollution removed; project files kept ---
D5="$TMP/proj-stale"
mkdir -p "$D5/.opencode"
mkdir -p "$D5/.opencode/node_modules" "$D5/.opencode/preflight" "$D5/.opencode/reviews" "$D5/.opencode/standards"
touch "$D5/.opencode/package.json" "$D5/.opencode/README.md"
printf 'archived\n' > "$D5/.opencode/resolved_issues.md"
bash "$INIT" "$D5" en </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "sweep run exits 0"
for bad in node_modules preflight reviews package.json; do
  if [ -e "$D5/.opencode/$bad" ]; then
    t_fail "stale pollution swept: $bad (still present)"
  else
    t_ok "stale pollution swept: $bad"
  fi
done
for keep in standards README.md resolved_issues.md; do
  if [ -e "$D5/.opencode/$keep" ]; then
    t_ok "project-owned preserved: $keep"
  else
    t_fail "project-owned preserved: $keep (removed)"
  fi
done
assert_contains "$D5/.opencode/resolved_issues.md" "archived" "resolved_issues.md content preserved"

# --- 6. Locale resolution: existing target locale survives a re-run without arg ---
D6="$TMP/proj-locale"
mkdir -p "$D6/.opencode"
printf 'pt\n' > "$D6/.opencode/locale"
bash "$INIT" "$D6" </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "locale-preservation run exits 0"
assert_eq "pt" "$(cat "$D6/.opencode/locale")" "existing locale preserved without --force"

# --- 7. LSP opt-in: INIT_CONFIGURE_LSP=1 writes .vscode/settings.json ---
D7="$TMP/proj-lsp-optin"
mkdir -p "$D7"
printf '{"name":"demo"}\n' > "$D7/package.json"
INIT_CONFIGURE_LSP=1 bash "$INIT" "$D7" en </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "opt-in LSP run exits 0"
if [ -f "$D7/.vscode/settings.json" ]; then
  t_ok "INIT_CONFIGURE_LSP=1 writes .vscode/settings.json"
else
  t_fail "INIT_CONFIGURE_LSP=1 writes .vscode/settings.json (missing)"
fi

# --- 8. make init without target is refused (does not touch CWD) ---
CONFIG_DIR="$(cd "$HERE/../.." && pwd)"
out8="$(make -C "$CONFIG_DIR" init 2>&1)"
rc8=$?
if [ "$rc8" -ne 0 ] && printf '%s' "$out8" | grep -qi "Usage"; then
  t_ok "make init without target is refused"
else
  t_fail "make init without target is refused (rc=$rc8)"
fi

# --- 9. --dry-run writes nothing ---
D9="$TMP/proj-dryrun"
mkdir -p "$D9"
bash "$INIT" "$D9" en --dry-run </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "--dry-run exits 0"
if [ -e "$D9/.opencode" ]; then
  t_fail "--dry-run writes nothing (.opencode created)"
else
  t_ok "--dry-run writes nothing (.opencode not created)"
fi

# --- 10. Missing mandatory template → FATAL, no partial .opencode (AC6) ---
CFG10="$TMP/fakecfg"
mkdir -p "$CFG10/scripts" "$CFG10/.opencode" "$CFG10/standards"
cp "$HERE/../init.sh" "$CFG10/scripts/init.sh"
for t in workflow.md opencode.json env-manifest.md .gitignore locale; do
  cp "$HERE/../../.opencode/$t" "$CFG10/.opencode/$t"
done
# AGENTS.md intentionally omitted
[ -f "$HERE/../../standards/lsp-catalog.json" ] && cp "$HERE/../../standards/lsp-catalog.json" "$CFG10/standards/"
D10="$TMP/proj-missing"
mkdir -p "$D10"
out10="$(bash "$CFG10/scripts/init.sh" "$D10" en </dev/null 2>&1)"
rc10=$?
if [ "$rc10" -ne 0 ] && printf '%s' "$out10" | grep -q "FATAL"; then
  t_ok "missing mandatory template is FATAL"
else
  t_fail "missing mandatory template is FATAL (rc=$rc10)"
fi
if [ -e "$D10/.opencode" ]; then
  t_fail "no partial .opencode on preflight failure"
else
  t_ok "no partial .opencode on preflight failure"
fi

# --- 11. --force rewrites an existing project-owned template; default keeps it ---
D11="$TMP/proj-force"
mkdir -p "$D11/.opencode"
printf 'CUSTOM\n' > "$D11/.opencode/workflow.md"
bash "$INIT" "$D11" en --force </dev/null >/dev/null 2>&1
assert_eq "0" "$?" "--force run exits 0"
if grep -q "CUSTOM" "$D11/.opencode/workflow.md"; then
  t_fail "--force overwrites existing template"
else
  t_ok "--force overwrites existing template"
fi
D11b="$TMP/proj-noforce"
mkdir -p "$D11b/.opencode"
printf 'CUSTOM\n' > "$D11b/.opencode/workflow.md"
bash "$INIT" "$D11b" en </dev/null >/dev/null 2>&1
assert_contains "$D11b/.opencode/workflow.md" "CUSTOM" "without --force existing template preserved"

t_finish
