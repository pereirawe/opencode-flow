#!/usr/bin/env bash
# test_git_cred_cache.sh — tests for scripts/git-cred-cache.sh (issue #209).
#
# Covers the 7 test scenarios from the issue:
#   1. --set under umask 000 and 022 → dir 0700 / files 0600; --status masked
#      (identity email as <set>).
#   2. --get with absent + unreadable (chmod 000) cache and closed stdin →
#      fail-silent, no prompt, no secrets, no hang; --status still diagnoses.
#   3. Concurrent --set (2 parallel) → intact store, one entry; symlink in
#      .opencode/cache → no write outside the project.
#   4. Empty GITLAB_TOKEN → treated as absent; --erase → --get fail-silent,
#      --status shows not set.
#   5. Redaction gate: grep for tokens + identity email in --status/--get/
#      errors → assert_not_contains (0 matches); cross-serving: --get never
#      emits identity fields, --identity never emits the token.
#   6. Config assertions: opencode.json read/edit-deny on .opencode/cache/**
#      (findLast) + agent files with granular bash permissions.
#   7. --init wires credential.helper (absolute path) + interactive never;
#      repeated --set does not duplicate, --force overwrites; EXCLUDE_RE keeps
#      .opencode/cache out of fingerprints (touching the cache does not
#      invalidate the test-runner fingerprint).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_git_cred_cache"

SCRIPT="$HERE/../git-cred-cache.sh"
TEST_RUNNER="$HERE/../test-runner.sh"
CONFIG="$HERE/../../opencode.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# make_project <dir> — fresh git repo with an empty .opencode dir (no cache)
make_project() {
  local d="$1"
  mkdir -p "$d/.opencode"
  git -C "$d" init -q
  git -C "$d" -c user.name=t -c user.email=t@t commit -qm init --allow-empty
}

# ===========================================================================
# Scenario 1 — permissions under umask 000 and 022 + masked --status
# ===========================================================================
for um in 000 022; do
  d="$TMP/perms-$um"
  make_project "$d"
  (
    cd "$d" || exit 1
    umask "$um"
    GITLAB_TOKEN="glpat-perm-$um" bash "$SCRIPT" --set
    bash "$SCRIPT" --identity --set --name "Test User" --email "user-$um@example.com"
    bash "$SCRIPT" --status
    bash "$SCRIPT" --get
  ) > "$TMP/out-$um.txt" 2> "$TMP/err-$um.txt"

  assert_eq "700" "$(stat -c %a "$d/.opencode/cache/git")" "umask $um: cache dir is 0700"
  assert_eq "600" "$(stat -c %a "$d/.opencode/cache/git/credentials")" "umask $um: credentials file is 0600"
  assert_eq "600" "$(stat -c %a "$d/.opencode/cache/git/identity")" "umask $um: identity file is 0600"
  assert_not_contains "$TMP/out-$um.txt" "glpat-perm-$um" "umask $um: no token in stdout"
  assert_not_contains "$TMP/out-$um.txt" "user-$um@example.com" "umask $um: no identity email in stdout"
  assert_contains "$TMP/out-$um.txt" "<set>" "umask $um: --status masks identity email as <set>"
  assert_not_contains "$TMP/err-$um.txt" "glpat-perm-$um" "umask $um: no token in stderr"
done

# ===========================================================================
# Scenario 2 — absent + unreadable cache, closed stdin → fail-silent
# ===========================================================================
d="$TMP/absent"
make_project "$d"
out_absent="$(cd "$d" && bash "$SCRIPT" --get </dev/null 2>&1)"
assert_eq "" "$out_absent" "--get with no cache is fail-silent (empty output)"
rc_absent="$(cd "$d" && bash "$SCRIPT" --get </dev/null >/dev/null 2>&1; echo $?)"
assert_eq "0" "$rc_absent" "--get with no cache exits 0 (no prompt)"

d="$TMP/unreadable"
make_project "$d"
mkdir -p "$d/.opencode/cache/git"
printf 'https://oauth2:glpat-unread@gitlab.com\n' > "$d/.opencode/cache/git/credentials"
chmod 600 "$d/.opencode/cache/git/credentials"
chmod 000 "$d/.opencode/cache/git/credentials"
out_unread="$(cd "$d" && bash "$SCRIPT" --get </dev/null 2>&1)"
assert_eq "" "$out_unread" "--get with unreadable cache is fail-silent (empty output)"
rc_unread="$(cd "$d" && bash "$SCRIPT" --get </dev/null >/dev/null 2>&1; echo $?)"
assert_eq "0" "$rc_unread" "--get with unreadable cache exits 0 (no prompt)"
( cd "$d" && bash "$SCRIPT" --status </dev/null ) > "$TMP/status-unread.txt" 2>&1
assert_contains "$TMP/status-unread.txt" "unreadable" "--status still works as diagnosis for unreadable cache"
assert_not_contains "$TMP/status-unread.txt" "glpat-unread" "--status does not expose the unreadable token"

# ===========================================================================
# Scenario 3 — concurrent --set integrity + symlink safety
# ===========================================================================
d="$TMP/concurrent"
make_project "$d"
(
  cd "$d" || exit 1
  GITLAB_TOKEN="glpat-cc1" bash "$SCRIPT" --set &
  GITLAB_TOKEN="glpat-cc2" bash "$SCRIPT" --set &
  wait
)
assert_eq "1" "$(wc -l < "$d/.opencode/cache/git/credentials" 2>/dev/null || echo 0)" \
  "concurrent --set leaves exactly one entry"
assert_eq "600" "$(stat -c %a "$d/.opencode/cache/git/credentials")" \
  "concurrent --set keeps 0600 perms"
assert_eq "1" "$(grep -cE '^https://oauth2:[^@]+@gitlab\.com$' "$d/.opencode/cache/git/credentials" 2>/dev/null || true)" \
  "concurrent --set store is a valid git credential line"

d="$TMP/symlink"
VICTIM="$TMP/victim"
mkdir -p "$d/.opencode/cache" "$VICTIM"
ln -s "$VICTIM" "$d/.opencode/cache/git"
(
  cd "$d" || exit 1
  GITLAB_TOKEN="glpat-leak" bash "$SCRIPT" --set
)
assert_eq "0" "$(ls -A "$VICTIM" | wc -l)" \
  "symlink: --set does not write through .opencode/cache/git symlink"
assert_eq "1" "$([[ -L "$d/.opencode/cache/git" ]] && echo 1 || echo 0)" \
  "symlink: cache dir remains a symlink (script refused)"

# ===========================================================================
# Scenario 4 — empty env var treated as absent; --erase fail-silent
# ===========================================================================
d="$TMP/empty-env"
make_project "$d"
(
  cd "$d" || exit 1
  GITLAB_TOKEN="" bash "$SCRIPT" --set
)
assert_eq "0" "$([[ -f "$d/.opencode/cache/git/credentials" ]] && echo 1 || echo 0)" \
  "empty GITLAB_TOKEN creates no credentials entry"

(
  cd "$d" || exit 1
  GITLAB_TOKEN="glpat-erase" bash "$SCRIPT" --set
  bash "$SCRIPT" --erase
)
assert_eq "0" "$([[ -f "$d/.opencode/cache/git/credentials" ]] && echo 1 || echo 0)" \
  "--erase removes the credentials file"
out_after_erase="$(cd "$d" && bash "$SCRIPT" --get </dev/null 2>&1)"
assert_eq "" "$out_after_erase" "--get after --erase is fail-silent"
( cd "$d" && bash "$SCRIPT" --status ) > "$TMP/status-erase.txt" 2>&1
assert_contains "$TMP/status-erase.txt" "credentials: absent" "--status after --erase shows no credentials"
assert_contains "$TMP/status-erase.txt" "identity:    not set" "--status after --erase shows no identity"
assert_not_contains "$TMP/status-erase.txt" "glpat-erase" "--status after --erase exposes no token"

# ===========================================================================
# Scenario 5 — redaction gate + cross-serving (--get vs --identity)
# ===========================================================================
d="$TMP/cross"
make_project "$d"
(
  cd "$d" || exit 1
  GITLAB_TOKEN="glpat-cross" bash "$SCRIPT" --set
  bash "$SCRIPT" --identity --set --name "Cross User" --email "cross@example.com"
) > "$TMP/cross-set.txt" 2>&1

get_out="$(cd "$d" && bash "$SCRIPT" --get </dev/null)"
assert_not_contains <(printf '%s' "$get_out") "glpat-cross" "--get never emits the token"
assert_contains <(printf '%s' "$get_out") "****" "--get masks tokens"
assert_not_contains <(printf '%s' "$get_out") "name=" "--get never emits identity fields"
assert_not_contains <(printf '%s' "$get_out") "email=" "--get never emits identity email"

ident_out="$(cd "$d" && bash "$SCRIPT" --identity </dev/null)"
assert_not_contains <(printf '%s' "$ident_out") "glpat-cross" "--identity never emits the token"
assert_not_contains <(printf '%s' "$ident_out") "https://" "--identity never emits credential lines"
assert_contains <(printf '%s' "$ident_out") "name=Cross User" "--identity prints the real name (for git -c)"
assert_contains <(printf '%s' "$ident_out") "email=cross@example.com" "--identity prints the real email (for git -c)"

( cd "$d" && bash "$SCRIPT" --status ) > "$TMP/status-cross.txt" 2>&1
assert_not_contains "$TMP/status-cross.txt" "glpat-cross" "--status exposes no token"
assert_not_contains "$TMP/status-cross.txt" "cross@example.com" "--status exposes no identity email"
assert_contains "$TMP/status-cross.txt" "<set>" "--status masks identity email as <set>"
assert_not_contains "$TMP/cross-set.txt" "glpat-cross" "no token in the write-path log"
assert_not_contains "$TMP/status-cross.txt" "name=Cross User" "--status never prints identity values"

# ===========================================================================
# Scenario 6 — opencode.json deny (findLast) + agent granular bash perms
# ===========================================================================
if ! command -v jq >/dev/null 2>&1; then
  t_fail "jq is required for the config assertions in test_git_cred_cache"
else
  last_edit="$(jq -r '.permission.edit | to_entries[-1] | .key' "$CONFIG")"
  assert_eq "~/.config/opencode/.opencode/cache/**" "$last_edit" \
    "opencode.json: cache deny is the LAST edit rule (findLast wins)"
  deny_edit="$(jq -r '.permission.edit["~/.config/opencode/.opencode/cache/**"]' "$CONFIG")"
  assert_eq "deny" "$deny_edit" "opencode.json: edit deny on .opencode/cache/**"
  deny_read="$(jq -r '.permission.read["~/.config/opencode/.opencode/cache/**"]' "$CONFIG")"
  assert_eq "deny" "$deny_read" "opencode.json: read deny on .opencode/cache/**"
fi

DEV="$HERE/../../agents/development/developer.md"
for pat in '"*": deny' '"git *": allow' '"*scripts/git-cred-cache.sh *": allow' \
           '"git push --force*": deny' '"git reset --hard*": deny' '"git clean -f*": deny' '"git branch -D *": deny'; do
  if grep -qF -- "$pat" "$DEV"; then
    t_ok "developer.md: has $pat"
  else
    t_fail "developer.md: missing $pat"
  fi
done
ln_catch="$(grep -nF '"*": deny' "$DEV" | head -1 | cut -d: -f1)"
ln_git="$(grep -nF '"git *": allow' "$DEV" | head -1 | cut -d: -f1)"
ln_cred="$(grep -nF '"*scripts/git-cred-cache.sh *": allow' "$DEV" | head -1 | cut -d: -f1)"
ln_destr="$(grep -nF '"git push --force*": deny' "$DEV" | head -1 | cut -d: -f1)"
if [[ -n "$ln_catch" && -n "$ln_git" && -n "$ln_cred" && -n "$ln_destr" ]] \
   && [[ "$ln_catch" -lt "$ln_git" && "$ln_git" -lt "$ln_cred" && "$ln_cred" -lt "$ln_destr" ]]; then
  t_ok "developer.md: rule order catch-all → allows → destructive denies"
else
  t_fail "developer.md: rule order wrong (catch=$ln_catch git=$ln_git cred=$ln_cred destr=$ln_destr)"
fi

for AG in committer publish-requester; do
  F="$HERE/../../agents/development/$AG.md"
  if grep -qF 'bash: allow' "$F"; then
    t_fail "$AG.md: bash: allow must be scoped, not flat allow"
  else
    t_ok "$AG.md: bash: allow removed (scoped)"
  fi
  grep -qF '"*": deny' "$F" && t_ok "$AG.md: catch-all bash deny" || t_fail "$AG.md: missing catch-all bash deny"
  grep -qF '"gh *": allow' "$F" && t_ok "$AG.md: gh allow kept" || t_fail "$AG.md: missing gh allow"
  grep -qF '"glab *": allow' "$F" && t_ok "$AG.md: glab allow kept" || t_fail "$AG.md: missing glab allow"
  grep -qF 'edit: allow' "$F" && t_ok "$AG.md: edit: allow kept" || t_fail "$AG.md: edit: allow missing"
done

# ===========================================================================
# Scenario 7 — --init wiring, idempotency/--force, EXCLUDE_RE fingerprint
# ===========================================================================
d="$TMP/init-proj"
make_project "$d"
( cd "$d" && bash "$SCRIPT" --init )
helper="$(git -C "$d" config --local --get credential.helper)"
assert_eq "store --file=$d/.opencode/cache/git/credentials" "$helper" \
  "--init wires credential.helper to the ABSOLUTE cache store path"
assert_eq "never" "$(git -C "$d" config --local --get credential.interactive)" \
  "--init sets credential.interactive never"
# --init must NOT write identity or secrets into .git/config (BR 7)
assert_eq "" "$(git -C "$d" config --local --get user.name || true)" \
  "--init never writes user.name to .git/config"
assert_eq "" "$(git -C "$d" config --local --get user.email || true)" \
  "--init never writes user.email to .git/config"

(
  cd "$d" || exit 1
  GITLAB_TOKEN="glpat-idem" bash "$SCRIPT" --set
  GITLAB_TOKEN="glpat-idem" bash "$SCRIPT" --set
)
assert_eq "1" "$(wc -l < "$d/.opencode/cache/git/credentials")" \
  "repeated --set does not duplicate entries"
( cd "$d" && GITLAB_TOKEN="glpat-other" bash "$SCRIPT" --set )
assert_eq "1" "$(wc -l < "$d/.opencode/cache/git/credentials")" \
  "--set without --force keeps one entry"
assert_contains "$d/.opencode/cache/git/credentials" "glpat-idem" \
  "existing valid entry preserved without --force"
( cd "$d" && GITLAB_TOKEN="glpat-other" bash "$SCRIPT" --set --force )
assert_eq "1" "$(wc -l < "$d/.opencode/cache/git/credentials")" \
  "--force overwrites, store keeps one entry"
assert_contains "$d/.opencode/cache/git/credentials" "glpat-other" \
  "--force stores the new token"
assert_not_contains "$d/.opencode/cache/git/credentials" "glpat-idem" \
  "--force removes the stale token"

# EXCLUDE_RE: static + behavioral fingerprint stability
if grep -q '\.opencode/cache' "$TEST_RUNNER"; then
  t_ok "test-runner: EXCLUDE_RE covers .opencode/cache"
else
  t_fail "test-runner: EXCLUDE_RE missing .opencode/cache"
fi
d="$TMP/fp-proj"
make_project "$d"
(
  cd "$d" || exit 1
  fp1="$(bash "$TEST_RUNNER" --status 2>/dev/null | awk '/fingerprint:/{print $2}')"
  mkdir -p .opencode/cache/git
  printf 'https://oauth2:glpat-fp@gitlab.com\n' > .opencode/cache/git/credentials
  fp2="$(bash "$TEST_RUNNER" --status 2>/dev/null | awk '/fingerprint:/{print $2}')"
  printf '%s\n%s\n' "$fp1" "$fp2"
) > "$TMP/fp.txt"
assert_eq "$(sed -n 1p "$TMP/fp.txt")" "$(sed -n 2p "$TMP/fp.txt")" \
  "EXCLUDE_RE: creating .opencode/cache does not change the test-runner fingerprint"

t_finish
