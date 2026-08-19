#!/usr/bin/env bash
# test_timestamps.sh — issues #57/#81: lifecycle timestamps
# (Opened/Ready/Started/In review/In QA/In publish/Resolved + per-stage Durations).
#
# Covers t01–t29: promote.sh stamping (Ready on backlog→ready, Started on
# ready→in-progress, Opened backfill set-if-absent), create_issue.sh Opened
# stamping on remote success, close_issue.sh Resolved + Durations with the
# guard/floor rules (t16/t17/t18), DST spring-forward (t21), double-run
# idempotency (t19), prompt-bypass without TTY (t20), field order
# Status < Opened < Ready < Started < In review < In QA < In publish (t23),
# standards parity (t24), a full end-to-end lifecycle (t25), transition.sh
# per-stage stamping + idempotency (t26/t27), per-stage duration isolation
# (t28), and invalid-status rejection (t29).
#
# Deterministic/self-contained: `date`, `gh`/`glab`, and `git` are mocked via
# PATH; no network, no TTY. Duration math delegates to the real `date`
# (`TZ=UTC date -d "$d" +%s`) so the DST-robustness check is real.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_timestamps"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROMOTE="$HERE/../promote.sh"
CREATE="$HERE/../create_issue.sh"
CLOSE="$HERE/../close_issue.sh"
TRANSITION="$HERE/../transition.sh"
RUN_OUT="$TMP/run.out"

FAKE_TODAY="2026-08-14"
export FAKE_TODAY

# --- mocks -----------------------------------------------------------------

# mock date: fixed "today" for `date +%Y-%m-%d`; delegates everything else
# (e.g. `TZ=UTC date -d "$d" +%s`) to the real date binary so the scripts'
# UTC-anchored duration math is exercised for real (t21).
MOCK_DATE="$TMP/mock-date"; mkdir -p "$MOCK_DATE"
cat > "$MOCK_DATE/date" <<'EOF'
#!/usr/bin/env bash
REAL=/usr/bin/date; [[ -x "$REAL" ]] || REAL=/bin/date
if [[ "$1" == "+%Y-%m-%d" ]]; then
  echo "${FAKE_TODAY:-2026-08-14}"
  exit 0
fi
exec "$REAL" "$@"
EOF
chmod +x "$MOCK_DATE/date"

# mock gh/glab: issue create/view/close + pr view, with invocation log.
MOCK_NET="$TMP/mock-net"; mkdir -p "$MOCK_NET"
cat > "$MOCK_NET/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "${GH_LOG:-/dev/null}"
case "$*" in
  *"issue create"*)
    if [[ "${GH_FAIL:-0}" == "1" ]]; then
      echo "mock create failed" >&2
      exit 1
    fi
    echo "https://github.com/owner/repo/issues/42"
    exit 0 ;;
  *"pr view"*)    echo "MERGED"; exit 0 ;;
  *"issue view"*) echo "CLOSED"; exit 0 ;;
esac
exit 0
EOF
chmod +x "$MOCK_NET/gh"
ln -sf "$MOCK_NET/gh" "$MOCK_NET/glab"
ln -sf "$MOCK_DATE/date" "$MOCK_NET/date"

# mock git (promote tests only): logs invocations; feature-branch show-ref
# fails so `checkout -b` is exercised. Real git is used everywhere else.
MOCK_GIT="$TMP/mock-git"; mkdir -p "$MOCK_GIT"
cat > "$MOCK_GIT/git" <<'EOF'
#!/usr/bin/env bash
echo "git $*" >> "${GIT_LOG:-/dev/null}"
case "$*" in
  *"show-ref --verify refs/heads/issue-"*) exit 1 ;;
esac
exit 0
EOF
chmod +x "$MOCK_GIT/git"
ln -sf "$MOCK_DATE/date" "$MOCK_GIT/date"

# --- helpers ---------------------------------------------------------------

# make_fixture <dir> <status> <remote> <pr> [opened] [ready] [started]
make_fixture() {
  local d="$1" status="$2" remote="$3" pr="$4"
  local opened="${5:--}" ready="${6:--}" started="${7:--}"
  mkdir -p "$d/.opencode"
  git -C "$d" init -q
  git -C "$d" remote add origin "git@github.com:owner/repo.git"
  git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  {
    printf '## Known Issues\n\n'
    printf '### 1. Test issue\n'
    printf -- '- Status: %s\n' "$status"
    [[ "$opened" != "-" ]] && printf -- '- Opened: %s\n' "$opened"
    [[ "$ready" != "-" ]] && printf -- '- Ready: %s\n' "$ready"
    [[ "$started" != "-" ]] && printf -- '- Started: %s\n' "$started"
    printf -- '- Type: feat\n- Severity: medium\n- Report: test\n- Base branch: main\n- Reviewers: 1 (runtime)\n'
    printf -- '- Remote: %s\n' "$remote"
    printf -- '- PR: %s\n' "$pr"
    printf -- '- Description: test description\n- Business rules:\n  1. rule one\n- Acceptance criteria:\n  1. criterion one\n- Tests:\n  1. scenario -> outcome\n- Suggested fix: test fix\n'
  } > "$d/.opencode/known_issues.md"
}

# run <fixture-dir> <mock-dir> <script> <args...> — echoes rc; output in $RUN_OUT
run() {
  local fix="$1" mock="$2" script="$3"; shift 3
  local rc=0
  ( cd "$fix" && PATH="$mock:$PATH" bash "$script" "$@" ) >"$RUN_OUT" 2>&1 || rc=$?
  echo "$rc"
}

# field <file> <name> — value of the "- Name:" field (empty when absent)
field() {
  awk -F': ' -v f="$2" '$0 ~ "^\\- " f ":" {print $2; exit}' "$1"
}

# cnt <file> <fixed-needle> — occurrence count (0 when file missing)
cnt() {
  grep -cF -- "$2" "$1" 2>/dev/null || echo 0
}

# close_issue with a piped confirmation (no TTY): pipe-confirm <fixture> <answer>
pipe_confirm() {
  local fix="$1" answer="$2"
  local rc=0
  ( cd "$fix" && PATH="$MOCK_NET:$PATH" bash "$CLOSE" 1 ) <<< "$answer" >"$RUN_OUT" 2>&1 || rc=$?
  echo "$rc"
}

# ===========================================================================
# t01 — promote backlog→ready stamps Ready (and only Ready)
# ===========================================================================
fix="$TMP/t01"; make_fixture "$fix" backlog - -
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "0" "$rc" "t01: promote backlog→ready exit 0"
assert_eq "ready" "$(field "$fix/.opencode/known_issues.md" Status)" "t01: status = ready"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Ready)" "t01: Ready stamped with today"
assert_eq "" "$(field "$fix/.opencode/known_issues.md" Opened)" "t01: Opened not stamped in mode 1"
assert_eq "" "$(field "$fix/.opencode/known_issues.md" Started)" "t01: Started not stamped in mode 1"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Ready:')" "t01: single Ready line"

# ===========================================================================
# t02 — promote mode 1 preserves an existing Opened (set-if-absent)
# ===========================================================================
fix="$TMP/t02"; make_fixture "$fix" backlog - - 2026-08-01
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "0" "$rc" "t02: exit 0"
assert_eq "2026-08-01" "$(field "$fix/.opencode/known_issues.md" Opened)" "t02: existing Opened preserved"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Ready)" "t02: Ready stamped"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Opened:')" "t02: single Opened (no duplicate)"

# ===========================================================================
# t03 — promote mode 1 double-run: second run errors, no duplicate fields
# ===========================================================================
fix="$TMP/t03"; make_fixture "$fix" backlog - -
run "$fix" "$MOCK_GIT" "$PROMOTE" 1 >/dev/null
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "1" "$rc" "t03: second promote errors (ready + Remote:- → remote gate)"
assert_eq "ready" "$(field "$fix/.opencode/known_issues.md" Status)" "t03: status still ready"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Ready:')" "t03: single Ready (no duplicate)"
assert_eq "" "$(field "$fix/.opencode/known_issues.md" Started)" "t03: Started not stamped"

# ===========================================================================
# t04 — promote ready→in-progress stamps Started and backfills Opened
# ===========================================================================
fix="$TMP/t04"; make_fixture "$fix" ready "#42" -
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "0" "$rc" "t04: exit 0"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t04: status = in-progress"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Opened)" "t04: Opened backfilled (BR 3 approximation)"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Started)" "t04: Started stamped"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Opened:')" "t04: single Opened"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Started:')" "t04: single Started"

# ===========================================================================
# t05 — (regression) promote mode 2 remote gate: Remote:- blocks, no changes
# ===========================================================================
fix="$TMP/t05"; make_fixture "$fix" ready - -
cp "$fix/.opencode/known_issues.md" "$TMP/t05.before"
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "1" "$rc" "t05: remote gate blocks promotion"
assert_contains "$RUN_OUT" "must be populated" "t05: gate message about Remote"
diff -q "$TMP/t05.before" "$fix/.opencode/known_issues.md" >/dev/null \
  && t_ok "t05: tracker untouched on gate failure" \
  || t_fail "t05: tracker modified on gate failure"

# ===========================================================================
# t06 — promote mode 2 preserves an existing Opened (set-if-absent backfill)
# ===========================================================================
fix="$TMP/t06"; make_fixture "$fix" ready "#42" - 2026-08-01
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "2026-08-01" "$(field "$fix/.opencode/known_issues.md" Opened)" "t06: existing Opened preserved"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Opened:')" "t06: no duplicate Opened"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Started)" "t06: Started stamped"

# ===========================================================================
# t07 — (regression) promote mode 2 creates the feature branch from Base branch
# ===========================================================================
fix="$TMP/t07"; make_fixture "$fix" ready "#42" -
GIT_LOG="$TMP/t07.gitlog"; export GIT_LOG; : > "$GIT_LOG"
rc=$(run "$fix" "$MOCK_GIT" "$PROMOTE" 1)
assert_eq "0" "$rc" "t07: exit 0"
assert_contains "$GIT_LOG" "checkout main" "t07: base branch main checked out"
assert_contains "$GIT_LOG" "checkout -b issue-1-" "t07: feature branch created from base"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t07: status = in-progress"

# ===========================================================================
# t08 — create_issue stamps Opened on remote creation success
# ===========================================================================
fix="$TMP/t08"; make_fixture "$fix" ready - -
GH_LOG="$TMP/t08.ghlog"; export GH_LOG; : > "$GH_LOG"
rc=$(run "$fix" "$MOCK_NET" "$CREATE" 1)
assert_eq "0" "$rc" "t08: create_issue exit 0"
assert_eq "#42" "$(field "$fix/.opencode/known_issues.md" Remote)" "t08: Remote = #42"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Opened)" "t08: Opened stamped on remote success"
assert_eq "ready" "$(field "$fix/.opencode/known_issues.md" Status)" "t08: status stays ready"
assert_contains "$GH_LOG" "issue create" "t08: gh issue create invoked"

# ===========================================================================
# t09 — create_issue failure: NO Opened stamped, Remote: error:...
# ===========================================================================
fix="$TMP/t09"; make_fixture "$fix" ready - -
GH_LOG="$TMP/t09.ghlog"; export GH_LOG; : > "$GH_LOG"
export GH_FAIL=1
rc=$(run "$fix" "$MOCK_NET" "$CREATE" 1)
unset GH_FAIL
assert_eq "0" "$rc" "t09: create failure logged, script completes"
assert_contains "$fix/.opencode/known_issues.md" "error:mock create failed" "t09: Remote: error:... recorded"
assert_eq "" "$(field "$fix/.opencode/known_issues.md" Opened)" "t09: Opened NOT stamped on failure"

# ===========================================================================
# t10 — create_issue idempotent: second run aborts, no duplicates
# ===========================================================================
fix="$TMP/t10"; make_fixture "$fix" ready - -
GH_LOG="$TMP/t10.ghlog"; export GH_LOG; : > "$GH_LOG"
run "$fix" "$MOCK_NET" "$CREATE" 1 >/dev/null
rc=$(run "$fix" "$MOCK_NET" "$CREATE" 1)
assert_eq "1" "$rc" "t10: second create aborts (already has remote)"
assert_eq "#42" "$(field "$fix/.opencode/known_issues.md" Remote)" "t10: Remote unchanged"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Opened:')" "t10: single Opened"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '#42')" "t10: single Remote #42"

# ===========================================================================
# t11 — create_issue preserves an existing Opened (set-if-absent)
# ===========================================================================
fix="$TMP/t11"; make_fixture "$fix" ready - - 2026-08-01
GH_LOG="$TMP/t11.ghlog"; export GH_LOG; : > "$GH_LOG"
rc=$(run "$fix" "$MOCK_NET" "$CREATE" 1)
assert_eq "2026-08-01" "$(field "$fix/.opencode/known_issues.md" Opened)" "t11: existing Opened preserved"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" '- Opened:')" "t11: single Opened"

# ===========================================================================
# t12 — legacy `open` path preserved (BR 7 / AC 11): status→in-progress,
#       Remote, Opened, and legacy branch creation all still work
# ===========================================================================
fix="$TMP/t12"; make_fixture "$fix" open - -
GH_LOG="$TMP/t12.ghlog"; export GH_LOG; : > "$GH_LOG"
rc=$(run "$fix" "$MOCK_NET" "$CREATE" 1)
assert_eq "0" "$rc" "t12: open path exit 0"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t12: open → in-progress"
assert_eq "#42" "$(field "$fix/.opencode/known_issues.md" Remote)" "t12: Remote set"
assert_eq "$FAKE_TODAY" "$(field "$fix/.opencode/known_issues.md" Opened)" "t12: Opened stamped"
git -C "$fix" branch --list 'issue-42-*' | grep -q 'issue-42-test-issue' \
  && t_ok "t12: legacy branch issue-42-test-issue created (real git)" \
  || t_fail "t12: legacy branch not created"

# ===========================================================================
# t13 — (regression) close_issue rejects non-closeable statuses
# ===========================================================================
fix="$TMP/t13"; make_fixture "$fix" ready - -
cp "$fix/.opencode/known_issues.md" "$TMP/t13.before"
rc=$(run "$fix" "$MOCK_NET" "$CLOSE" 1)
assert_eq "1" "$rc" "t13: close rejects ready status"
assert_contains "$RUN_OUT" "cannot be closed" "t13: rejection message"
diff -q "$TMP/t13.before" "$fix/.opencode/known_issues.md" >/dev/null \
  && t_ok "t13: tracker untouched" \
  || t_fail "t13: tracker modified"
if [[ -f "$fix/.opencode/resolved_issues.md" ]]; then
  t_fail "t13: archive written despite rejection"
else
  t_ok "t13: no archive written"
fi

# ===========================================================================
# t14 — close in-publish success (prompt "s"): Resolved + Durations + archive,
#       entry removed, remote closed
# ===========================================================================
fix="$TMP/t14"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-01 2026-08-03 2026-08-05
GH_LOG="$TMP/t14.ghlog"; export GH_LOG; : > "$GH_LOG"
rc=$(pipe_confirm "$fix" "s")
assert_eq "0" "$rc" "t14: close exit 0"
assert_contains "$GH_LOG" "pr view 9" "t14: PR merge verified before close"
assert_contains "$GH_LOG" "issue close 42" "t14: remote issue closed"
assert_contains "$fix/.opencode/resolved_issues.md" "- Resolved: $FAKE_TODAY" "t14: Resolved stamped (close date)"
assert_contains "$fix/.opencode/resolved_issues.md" "- Durations:" "t14: Durations present"
assert_contains "$fix/.opencode/resolved_issues.md" "- Severity: medium" "t14: Severity in archive"
assert_not_contains "$fix/.opencode/known_issues.md" "### 1." "t14: entry removed from tracker"

# ===========================================================================
# t15 — exact per-stage durations (normal dates)
# ===========================================================================
fix="$TMP/t15"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-01 2026-08-03 2026-08-05
pipe_confirm "$fix" "s" >/dev/null
assert_contains "$fix/.opencode/resolved_issues.md" \
  "- Durations: backlog=2d waiting=2d dev=9d review=- qa=- publish=- total=13d" \
  "t15: exact per-stage durations (Opened 08-01 → Resolved 08-14)"

# ===========================================================================
# t16 — guard start > end: component renders `-` BEFORE division
# ===========================================================================
fix="$TMP/t16"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-10 2026-08-01 2026-08-05
pipe_confirm "$fix" "s" >/dev/null
assert_contains "$fix/.opencode/resolved_issues.md" \
  "- Durations: backlog=- waiting=4d dev=9d review=- qa=- publish=- total=4d" \
  "t16: start>end component renders '-' (backlog), others computed"

# ===========================================================================
# t17 — diff == 0 renders "0d"
# ===========================================================================
fix="$TMP/t17"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-14 2026-08-14 2026-08-14
pipe_confirm "$fix" "s" >/dev/null
assert_contains "$fix/.opencode/resolved_issues.md" \
  "- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=- total=0d" \
  "t17: zero-day differences render 0d"

# ===========================================================================
# t18 — ALL dates missing → literal `- Durations: -`
# ===========================================================================
fix="$TMP/t18"; make_fixture "$fix" in-publish "#42" "#9"
pipe_confirm "$fix" "s" >/dev/null
assert_contains "$fix/.opencode/resolved_issues.md" "- Durations: -" "t18: all-missing renders literal '- Durations: -'"

# ===========================================================================
# t19 — double-run close: exactly one archive entry, pre-existing entries
#       preserved verbatim (AC 4 / BR 13)
# ===========================================================================
fix="$TMP/t19"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-01 2026-08-03 2026-08-05
cat > "$fix/.opencode/resolved_issues.md" <<'EOF'
# Resolved Issues

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 5. Old issue
- Resolved: 2026-07-01
- Type: feat
- Report: test
- Reviewers: 1
- Remote: #5
- Summary: old summary preserved verbatim
EOF
pipe_confirm "$fix" "s" >/dev/null
rc=$(pipe_confirm "$fix" "s")
assert_eq "1" "$rc" "t19: second close aborts (issue not found)"
assert_eq "1" "$(grep -cE '^### 1\.' "$fix/.opencode/resolved_issues.md")" "t19: exactly one archive entry for id 1"
assert_contains "$fix/.opencode/resolved_issues.md" "### 5. Old issue" "t19: pre-existing entry preserved"
assert_contains "$fix/.opencode/resolved_issues.md" "old summary preserved verbatim" "t19: pre-existing body preserved"

# ===========================================================================
# t20 — auto-close default vs opt-in prompt: non-interactive runs never hang
#       (no TTY). Default (OCF_CLOSE_REMOTE_ASK unset/0) closes the remote
#       automatically once the safety gates pass; OCF_CLOSE_REMOTE_ASK=1
#       restores the interactive confirmation (answer "n" skips remote close)
#       but still archives locally.
# ===========================================================================
fix="$TMP/t20"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-01 2026-08-03 2026-08-05
GH_LOG="$TMP/t20.ghlog"; export GH_LOG; : > "$GH_LOG"
rc=$(pipe_confirm "$fix" "n")
assert_eq "0" "$rc" "t20: non-interactive close completes without TTY"
assert_contains "$GH_LOG" "pr view" "t20: PR merge still checked"
assert_contains "$GH_LOG" "issue close 42" "t20: default auto-closes remote (no prompt)"
assert_contains "$fix/.opencode/resolved_issues.md" "- Resolved:" "t20: local archive still written"

fix="$TMP/t20b"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-01 2026-08-03 2026-08-05
GH_LOG="$TMP/t20b.ghlog"; export GH_LOG; : > "$GH_LOG"
rc=0
( cd "$fix" && PATH="$MOCK_NET:$PATH" OCF_CLOSE_REMOTE_ASK=1 bash "$CLOSE" 1 ) <<< "n" >"$RUN_OUT" 2>&1 || rc=$?
assert_eq "0" "$rc" "t20b: opt-in prompt (n) completes without hang"
assert_contains "$GH_LOG" "pr view" "t20b: PR merge still checked"
assert_not_contains "$GH_LOG" "issue close" "t20b: remote close skipped on 'n'"
assert_contains "$fix/.opencode/resolved_issues.md" "- Resolved:" "t20b: local archive still written"

# ===========================================================================
# t21 — DST spring-forward: UTC-anchored parse is DST-robust (BR 4 / AC 10)
#       2026-03-08 is a 23-hour day in America/New_York; the naive local-epoch
#       /86400 count would render 0d, the UTC-anchored parse renders 1d.
# ===========================================================================
fix="$TMP/t21"; make_fixture "$fix" in-publish "#42" "#9" 2026-03-08 2026-03-09 2026-03-10
rc=0
( cd "$fix" && PATH="$MOCK_NET:$PATH" TZ=America/New_York FAKE_TODAY=2026-03-11 \
    bash "$CLOSE" 1 ) <<< "s" >"$RUN_OUT" 2>&1 || rc=$?
assert_eq "0" "$rc" "t21: close exit 0 under DST timezone"
assert_contains "$fix/.opencode/resolved_issues.md" \
  "- Durations: backlog=1d waiting=1d dev=1d review=- qa=- publish=- total=3d" \
  "t21: spring-forward DST passes with UTC-anchored parse (naive local would give 0d)"

# ===========================================================================
# t22 — partial timestamps: missing dates render `-`, total still computed
# ===========================================================================
fix="$TMP/t22"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-09
pipe_confirm "$fix" "s" >/dev/null
assert_contains "$fix/.opencode/resolved_issues.md" \
  "- Durations: backlog=- waiting=- dev=- review=- qa=- publish=- total=5d" \
  "t22: missing dates render '-'; total computed from available timestamps"

# ===========================================================================
# t23 — field order asserted: Status < Opened < Ready < Started (AC 2 / BR 1)
# ===========================================================================
fix="$TMP/t23"; make_fixture "$fix" backlog - -
GH_LOG="$TMP/t23.ghlog"; export GH_LOG; : > "$GH_LOG"
run "$fix" "$MOCK_GIT" "$PROMOTE" 1 >/dev/null
run "$fix" "$MOCK_NET" "$CREATE" 1 >/dev/null
run "$fix" "$MOCK_GIT" "$PROMOTE" 1 >/dev/null
f="$fix/.opencode/known_issues.md"
s=$(grep -nF -- "- Status:" "$f" | cut -d: -f1)
o=$(grep -nF -- "- Opened:" "$f" | cut -d: -f1)
r=$(grep -nF -- "- Ready:" "$f" | cut -d: -f1)
st=$(grep -nF -- "- Started:" "$f" | cut -d: -f1)
if [[ -n "$s" && -n "$o" && -n "$r" && -n "$st" && "$s" -lt "$o" && "$o" -lt "$r" && "$r" -lt "$st" ]]; then
  t_ok "t23: field order Status < Opened < Ready < Started"
else
  t_fail "t23: field order broken (status=$s opened=$o ready=$r started=$st)"
fi

# ===========================================================================
# t24 — bash -n clean on modified scripts + standards parity (AC 5 / AC 13)
# ===========================================================================
for s in "$PROMOTE" "$CREATE" "$CLOSE"; do
  if bash -n "$s" >/dev/null 2>&1; then
    t_ok "t24: bash -n clean on $(basename "$s")"
  else
    t_fail "t24: bash -n failed on $(basename "$s")"
  fi
done
ROOT="$HERE/../.."
for lang in "" "/pt" "/es"; do
  doc="$ROOT/standards${lang}/issues.md"
  if [[ -f "$doc" ]] && grep -qF -- "- Opened:" "$doc" && grep -qF -- "- Ready:" "$doc" && grep -qF -- "- Started:" "$doc"; then
    t_ok "t24: standards${lang:-/en}/issues.md documents timestamp fields"
  else
    t_fail "t24: standards${lang:-/en}/issues.md missing timestamp fields"
  fi
done
assert_contains "$ROOT/standards/resolved-issue.md" "- Durations:" "t24: resolved-issue.md documents Durations"
assert_contains "$ROOT/standards/resolved-issue.md" "- Severity:" "t24: resolved-issue.md documents Severity"
fmt_block=$(awk '/^### Format/,/^### [0-9]+\./' "$ROOT/known_issues.md")
if printf '%s\n' "$fmt_block" | grep -qF -- "- Opened:" \
   && printf '%s\n' "$fmt_block" | grep -qF -- "- Ready:" \
   && printf '%s\n' "$fmt_block" | grep -qF -- "- Started:"; then
  t_ok "t24: known_issues.md Format block documents timestamp fields"
else
  t_fail "t24: known_issues.md Format block missing timestamp fields"
fi

# ===========================================================================
# t25 — end-to-end lifecycle: promote → create → promote → close (AC 7/8/9/12)
# ===========================================================================
fix="$TMP/t25"; make_fixture "$fix" backlog - -
GH_LOG="$TMP/t25.ghlog"; export GH_LOG; : > "$GH_LOG"
run "$fix" "$MOCK_GIT" "$PROMOTE" 1 >/dev/null
run "$fix" "$MOCK_NET" "$CREATE" 1 >/dev/null
run "$fix" "$MOCK_GIT" "$PROMOTE" 1 >/dev/null
f="$fix/.opencode/known_issues.md"
assert_eq "in-progress" "$(field "$f" Status)" "t25: status in-progress after full promote"
assert_eq "$FAKE_TODAY" "$(field "$f" Opened)" "t25: Opened stamped via create_issue"
assert_eq "$FAKE_TODAY" "$(field "$f" Ready)" "t25: Ready stamped via promote mode 1"
assert_eq "$FAKE_TODAY" "$(field "$f" Started)" "t25: Started stamped via promote mode 2"
sed -i 's/^- Status: in-progress/- Status: in-publish/' "$f"
sed -i 's/^- PR: -/- PR: #9/' "$f"
rc=$(pipe_confirm "$fix" "s")
assert_eq "0" "$rc" "t25: close exit 0"
assert_contains "$fix/.opencode/resolved_issues.md" "- Resolved: $FAKE_TODAY" "t25: Resolved in archive"
assert_contains "$fix/.opencode/resolved_issues.md" "- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=- total=0d" "t25: durations computed (same-day lifecycle)"
assert_contains "$GH_LOG" "issue close 42" "t25: remote closed exactly once"
assert_eq "1" "$(grep -cE '^### 1\.' "$fix/.opencode/resolved_issues.md")" "t25: exactly one archive entry"
assert_not_contains "$fix/.opencode/known_issues.md" "### 1." "t25: tracker entry removed"

# ===========================================================================
# t26 — transition.sh stamps per-stage timestamps (issue #81): in-progress ->
#       Started, in-review -> In review, in-qa -> In QA, in-publish -> In publish
# ===========================================================================
fix="$TMP/t26"; make_fixture "$fix" ready "#42" -
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-progress >/dev/null
f="$fix/.opencode/known_issues.md"
assert_eq "in-progress" "$(field "$f" Status)" "t26: status in-progress after transition"
assert_eq "$FAKE_TODAY" "$(field "$f" Started)" "t26: Started stamped on in-progress"
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-review >/dev/null
assert_eq "in-review" "$(field "$f" Status)" "t26: status in-review after transition"
assert_eq "$FAKE_TODAY" "$(field "$f" "In review")" "t26: In review stamped on in-review"
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-qa >/dev/null
assert_eq "$FAKE_TODAY" "$(field "$f" "In QA")" "t26: In QA stamped on in-qa"
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-publish >/dev/null
assert_eq "in-publish" "$(field "$f" Status)" "t26: status in-publish after transition"
assert_eq "$FAKE_TODAY" "$(field "$f" "In publish")" "t26: In publish stamped on in-publish"

# ===========================================================================
# t27 — transition.sh idempotency: re-running a transition never overwrites or
#       duplicates existing per-stage timestamps (set-if-absent)
# ===========================================================================
fix="$TMP/t27"; make_fixture "$fix" ready "#42" -
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-review >/dev/null
f="$fix/.opencode/known_issues.md"
sed -i 's/^- In review: .*/&/' "$f"   # no-op; keep line
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-review >/dev/null
assert_eq "1" "$(grep -c '^- In review:' "$f")" "t27: single In review (no duplicate)"
assert_eq "$FAKE_TODAY" "$(field "$f" "In review")" "t27: In review preserved on re-run"
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-qa >/dev/null
run "$fix" "$MOCK_DATE" "$TRANSITION" 1 in-qa >/dev/null
assert_eq "1" "$(grep -c '^- In QA:' "$f")" "t27: single In QA (no duplicate)"

# ===========================================================================
# t28 — dev duration isolates development (Started → In review); review/qa/
#       publish computed from per-stage timestamps at close time
# ===========================================================================
fix="$TMP/t28"; make_fixture "$fix" in-publish "#42" "#9" 2026-08-01 2026-08-03 2026-08-05
f="$fix/.opencode/known_issues.md"
sed -i 's/^- Status: in-publish/- Status: in-publish/' "$f"
# Append per-stage timestamps after Started (Started 08-05, review 08-07, qa 08-09, publish 08-11)
awk '/^- Started:/ { print; print "- In review: 2026-08-07"; print "- In QA: 2026-08-09"; print "- In publish: 2026-08-11"; next } { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
rc=$(pipe_confirm "$fix" "s")
assert_eq "0" "$rc" "t28: close exit 0"
assert_contains "$fix/.opencode/resolved_issues.md" \
  "- Durations: backlog=2d waiting=2d dev=2d review=2d qa=2d publish=3d total=13d" \
  "t28: per-stage durations (dev 08-05→08-07, review 08-07→08-09, qa 08-09→08-11, publish 08-11→08-14)"

# ===========================================================================
# t29 — transition.sh rejects invalid statuses
# ===========================================================================
fix="$TMP/t29"; make_fixture "$fix" ready "#42" -
rc=$(run "$fix" "$MOCK_DATE" "$TRANSITION" 1 bogus)
assert_eq "1" "$rc" "t29: invalid status rejected"
assert_eq "ready" "$(field "$fix/.opencode/known_issues.md" Status)" "t29: status unchanged on invalid transition"

t_finish
