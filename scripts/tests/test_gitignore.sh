#!/usr/bin/env bash
# test_gitignore.sh — regression test for issue #250: the PORTABLE
# .opencode/.gitignore (the only .gitignore scripts/init.sh copies into every
# bootstrapped project) must ignore routine development-flow artifacts under
# .opencode/ — preflight/, reviews/, design-outputs/ and transient spikes —
# while preserving the versioned .md spike deliverables.
#
# Real git semantics only: every ignore assertion uses `git check-ignore`, so
# removing the rules from .opencode/.gitignore makes this test fail
# (issue #250, AC 3).
#
# Also covers the pre_commit.sh defense-in-depth guard (BR 6): a staged routine
# artifact fails the commit, while known_issues.md and spikes/*.md are allowed.
#
# Self-contained: mktemp + trap; the template is resolved from the script path
# (read-only use — never writes to the real template).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_gitignore"

INIT="$HERE/../init.sh"
PRECOMMIT="$HERE/../pre_commit.sh"
[[ -f "$INIT" ]]      || { t_fail "init.sh not found at $INIT";            t_finish; exit 1; }
[[ -f "$PRECOMMIT" ]] || { t_fail "pre_commit.sh not found at $PRECOMMIT"; t_finish; exit 1; }

# BR 10 — managed block in the project ROOT .gitignore (init.sh, idempotent).
ROOT_BEGIN="# >>> opencode-flow managed ignores (issue #250)"
ROOT_END="# <<< opencode-flow managed ignores (issue #250)"
ROOT_RULES=(
  '.opencode/preflight/'
  '.opencode/reviews/'
  '.opencode/test-cache/'
  '.opencode/design-outputs/'
  '.opencode/spikes/*'
  '!.opencode/spikes/*.md'
)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# bootstrap <dir> — fresh git repo + scripts/init.sh (portable template copied)
bootstrap() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -b main -q 2>/dev/null || git -C "$d" init -q
  bash "$INIT" "$d" en </dev/null >/dev/null 2>&1
}

# ===========================================================================
# t01 — bootstrapped project: routine artifacts are ignored (git check-ignore)
# ===========================================================================
D="$TMP/proj"
bootstrap "$D"

mkdir -p "$D/.opencode/preflight" "$D/.opencode/reviews" \
         "$D/.opencode/design-outputs/s" "$D/.opencode/spikes"
: > "$D/.opencode/preflight/issue-1.md"
: > "$D/.opencode/preflight/review-1-backend.md"
: > "$D/.opencode/reviews/security-issue-1-x.md"
: > "$D/.opencode/design-outputs/s/design_spec.json"
: > "$D/.opencode/spikes/scratch.tmp"
: > "$D/.opencode/spikes/nota.md"

is_ignored() { git -C "$D" check-ignore -q -- "$1"; }

for p in \
  .opencode/preflight/issue-1.md \
  .opencode/preflight/review-1-backend.md \
  .opencode/reviews/security-issue-1-x.md \
  .opencode/design-outputs/s/design_spec.json \
  .opencode/spikes/scratch.tmp
do
  if is_ignored "$p"; then
    t_ok "ignored: $p"
  else
    t_fail "ignored: $p (NOT ignored by .opencode/.gitignore)"
  fi
done

if is_ignored .opencode/spikes/nota.md; then
  t_fail "not ignored: .opencode/spikes/nota.md (markdown deliverable must stay tracked)"
else
  t_ok "not ignored: .opencode/spikes/nota.md"
fi

# The whitelist files copied by init.sh must NEVER become ignored.
for p in .opencode/known_issues.md .opencode/.gitignore .opencode/AGENTS.md; do
  if is_ignored "$p"; then
    t_fail "not ignored (whitelist): $p (unexpectedly ignored)"
  else
    t_ok "not ignored (whitelist): $p"
  fi
done

# --- Root .gitignore managed block (BR 10) ---------------------------------
ROOT_GI="$D/.gitignore"
if [ -f "$ROOT_GI" ]; then
  t_ok "root .gitignore created by bootstrap"
else
  t_fail "root .gitignore created by bootstrap (missing)"
fi
assert_count "$ROOT_GI" "$ROOT_BEGIN" 1 "root .gitignore has begin marker exactly once"
assert_contains "$ROOT_GI" "$ROOT_END" "root .gitignore has end marker"
for r in "${ROOT_RULES[@]}"; do
  # exact whole-line match: '.opencode/spikes/*' is a substring of
  # '!.opencode/spikes/*.md', so a substring check would be ambiguous.
  if grep -qxF -- "$r" "$ROOT_GI" 2>/dev/null; then
    t_ok "root .gitignore rule: $r"
  else
    t_fail "root .gitignore rule: $r (missing exact line)"
  fi
done

# ===========================================================================
# t02 — pre_commit.sh blocks a STAGED routine artifact (BR 6 defense-in-depth)
# The artifact is force-staged (git add -f) to emulate a path staged before the
# ignore rule existed — exactly the drift this guard defends against.
# ===========================================================================
DB="$TMP/block"
bootstrap "$DB"
mkdir -p "$DB/.opencode/reviews"
: > "$DB/.opencode/reviews/security-issue-1-x.md"
git -C "$DB" add -f -- .opencode/reviews/security-issue-1-x.md
rc=0
( cd "$DB" && bash "$PRECOMMIT" ) >"$TMP/block.out" 2>&1 || rc=$?
assert_eq "1" "$rc" "t02: staged routine artifact fails the commit (exit 1)"
assert_contains "$TMP/block.out" "Artefato rotineiro" "t02: blocking message emitted"

# ===========================================================================
# t03 — pre_commit.sh ALLOWS known_issues.md and spikes/*.md (BR 6)
# ===========================================================================
DA="$TMP/allow"
bootstrap "$DA"
mkdir -p "$DA/.opencode/spikes"
: > "$DA/.opencode/spikes/nota.md"
git -C "$DA" add -f -- .opencode/spikes/nota.md .opencode/known_issues.md
rc=0
( cd "$DA" && bash "$PRECOMMIT" ) >"$TMP/allow.out" 2>&1 || rc=$?
assert_eq "0" "$rc" "t03: known_issues.md and spikes/*.md are allowed (exit 0)"
assert_not_contains "$TMP/allow.out" "Artefato rotineiro" "t03: no false blocking"

# ===========================================================================
# t04 — idempotency (BR 10): a second init.sh run must NOT duplicate the block
# ===========================================================================
bash "$INIT" "$D" en </dev/null >/dev/null 2>&1
assert_count "$ROOT_GI" "$ROOT_BEGIN" 1 "t04: begin marker still exactly once after re-run"
assert_count "$ROOT_GI" "$ROOT_END" 1 "t04: end marker still exactly once after re-run"
for r in "${ROOT_RULES[@]}"; do
  n="$(grep -cxF -- "$r" "$ROOT_GI" 2>/dev/null || true)"; n="${n:-0}"
  if [ "$n" -eq 1 ]; then
    t_ok "t04: rule not duplicated after re-run: $r"
  else
    t_fail "t04: rule not duplicated after re-run: $r (expected 1 exact line, got $n)"
  fi
done

# ===========================================================================
# t05 — preservation (BR 10): a pre-existing project .gitignore is never
# clobbered — the project's own rules survive and the managed block is appended
# ===========================================================================
DP="$TMP/preserve"
mkdir -p "$DP"
git -C "$DP" init -b main -q 2>/dev/null || git -C "$DP" init -q
printf 'my-project-specific-rule/\n' > "$DP/.gitignore"
bash "$INIT" "$DP" en </dev/null >/dev/null 2>&1
assert_contains "$DP/.gitignore" "my-project-specific-rule/" "t05: pre-existing project rule preserved"
assert_contains "$DP/.gitignore" "$ROOT_BEGIN" "t05: managed block appended"
assert_count "$DP/.gitignore" "$ROOT_BEGIN" 1 "t05: managed block appended exactly once"

# A pre-existing .gitignore WITHOUT a trailing newline must not be concatenated
# onto the marker line.
DP2="$TMP/preserve-nonl"
mkdir -p "$DP2"
git -C "$DP2" init -b main -q 2>/dev/null || git -C "$DP2" init -q
printf 'no-trailing-newline-rule/' > "$DP2/.gitignore"
bash "$INIT" "$DP2" en </dev/null >/dev/null 2>&1
assert_contains "$DP2/.gitignore" "no-trailing-newline-rule/" "t05b: sentinel still present"
assert_contains "$DP2/.gitignore" "$ROOT_BEGIN" "t05b: managed block appended"
if grep -qE 'no-trailing-newline-rule/# >>> opencode-flow' "$DP2/.gitignore"; then
  t_fail "t05b: newline inserted before managed block"
else
  t_ok "t05b: newline inserted before managed block"
fi

t_finish
