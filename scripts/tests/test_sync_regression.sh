#!/usr/bin/env bash
# test_sync_regression.sh — AC 12: `sync_github_issues.sh --dry-run` behaves
# identically before/after the remote.sh extraction. The pre-extraction script
# is taken from HEAD (the extraction is uncommitted) and run against the same
# fixture + mock gh; outputs must be byte-identical.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_sync_regression"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
MOCK="$TMP/mock-bin"; mkdir -p "$MOCK"

cat > "$MOCK/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"pr view"*)    echo "MERGED"; exit 0 ;;
  *"issue view"*) echo "OPEN";   exit 0 ;;
esac
exit 0
EOF
chmod +x "$MOCK/gh"

# fixture repo + project tracker
fix="$TMP/fixture"
mkdir -p "$fix/.opencode"
git -C "$fix" init -q
git -C "$fix" remote add origin "git@github.com:test/repo.git"
cat > "$fix/.opencode/known_issues.md" <<'EOF'
### 7. Resolved issue
- Status: resolved
- Type: bug
- Severity: medium
- Report: test
- Remote: #30
- PR: #21
- Description: x

### 8. Published issue
- Status: in-publish
- Type: feat
- Severity: medium
- Report: test
- Remote: #31
- PR: #22
- Description: y
EOF

# pre-extraction script from HEAD + its config.sh
old="$TMP/oldsync"
mkdir -p "$old"
git -C "$HERE/.." show HEAD:scripts/sync_github_issues.sh > "$old/sync_github_issues.sh" || exit 1
cp "$HERE/../config.sh" "$old/config.sh"

(cd "$fix" && PATH="$MOCK:$PATH" bash "$old/sync_github_issues.sh" --dry-run) > "$TMP/old.out" 2>&1
(cd "$fix" && PATH="$MOCK:$PATH" bash "$HERE/../sync_github_issues.sh" --dry-run) > "$TMP/new.out" 2>&1

if diff -u "$TMP/old.out" "$TMP/new.out" > "$TMP/diff.out" 2>&1; then
  t_ok "AC12: sync --dry-run idêntico antes/depois da extração de remote.sh"
else
  t_fail "AC12: output diverge (diff:)"
  cat "$TMP/diff.out"
fi

# sanity: the combined output actually exercised the close paths
assert_contains "$TMP/new.out" "Would close remote issue #30" "AC12: resolved+OPEN → dry-run close #30"
assert_contains "$TMP/new.out" "Would close remote issue #31" "AC12: in-publish+MERGED+OPEN → dry-run close #31"

t_finish
