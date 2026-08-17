#!/usr/bin/env bash
# test_watcher_e2e.sh — end-to-end tests for aibot-watcher.sh using mock
# gh/glab/opencode/curl binaries injected via PATH. Covers BR 1-18 and the
# acceptance criteria that can be exercised without a real server:
# allowlist enforcement (BR 1/AC 18), cursor idempotency (BR 2/AC 8/AC 13),
# token matching (BR 3/AC 15), tracked gate (BR 4/AC 3), status re-check
# (BR 5/AC 4/AC 5), flock serialization (BR 6), trigger+success (BR 7/8/AC 2/AC 10),
# failure path (BR 9/AC 11), provider matrix (BR 11/AC 18), health-check skip
# (BR 12/AC 9), self-trigger (BR 17/AC 14), PR-comment filter (BR 18/AC 16),
# first-run cursor init (Security M2), per-tick trigger cap (Security M3).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCHER="$HERE/../aibot-watcher.sh"
source "$HERE/lib.sh"
t_begin "test_watcher_e2e"

TMP="$(mktemp -d)"
if [[ -n "${KEEP_TMP:-}" ]]; then
  echo "KEEP:$TMP" > /tmp/opencode/e2e-keep.txt
else
  trap 'rm -rf "$TMP"' EXIT
fi
MOCK="$TMP/mock-bin"; mkdir -p "$MOCK"
STATE="$TMP/state/aibot"
CONFIG="$TMP/config"

# --- mock binaries ----------------------------------------------------------
cat > "$MOCK/curl" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == *down* ]] && exit 1
exit 0
EOF

cat > "$MOCK/gh" <<'EOF'
#!/usr/bin/env bash
echo "GH-CALL: $*" >> "${MOCK_GH_LOG:-/dev/null}"
case "$*" in
  *"api user"*)            echo "${MOCK_GH_USER:-mock-gh-user}"; exit 0 ;;
  *"/issues/comments"*)    cat "${MOCK_COMMENTS_FILE:-/dev/null}" 2>/dev/null; exit 0 ;;
  *"/issues"*)
    cat "${MOCK_ISSUES_FILE:-/dev/null}" 2>/dev/null || echo "30"
    exit 0 ;;
esac
exit 0
EOF

cat > "$MOCK/glab" <<'EOF'
#!/usr/bin/env bash
echo "GLAB-CALL: $*" >> "${MOCK_GLAB_LOG:-/dev/null}"
case "$*" in
  *"api user"*)            echo "${MOCK_GLAB_USER:-mock-glab-user}"; exit 0 ;;
  *"/notes"*)              cat "${MOCK_COMMENTS_FILE:-/dev/null}" 2>/dev/null; exit 0 ;;
  *"issues"*)              cat "${MOCK_ISSUES_FILE:-/dev/null}" 2>/dev/null || echo "30"; exit 0 ;;
esac
exit 0
EOF

cat > "$MOCK/opencode" <<'EOF'
#!/usr/bin/env bash
echo "OPENCODE-CALL: $*" >> "${MOCK_OPENCODE_LOG:-/dev/null}"
cmd=""; args=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --command) cmd="$2"; shift 2; args="$*"; break ;;
    *) shift ;;
  esac
done
case "$cmd" in
  ocf:develop)
    echo "DEVELOP:$args" >> "${MOCK_OPENCODE_LOG:-/dev/null}"
    # MOCK_DEVELOP_EXIT: simulate a blocked develop (non-zero exit, no MR).
    if [[ -n "${MOCK_DEVELOP_EXIT:-}" ]]; then
      exit "$MOCK_DEVELOP_EXIT"
    fi
    local_id="${args%% *}"
    # MOCK_DEVELOP_NO_MR: develop finishes (exit 0) but no MR was created —
    # the tracker is left untouched so the success check fails.
    if [[ -n "${MOCK_DEVELOP_NO_MR:-}" ]]; then
      exit 0
    fi
    # Success path: mark ONLY the developed issue in-publish with a PR.
    if [[ -n "${MOCK_TRACKER:-}" && -f "$MOCK_TRACKER" ]]; then
      awk -v id="$local_id" -v pr="#$((local_id + 100))" '
        $0 ~ "^### " id "\\." { found=1 }
        found && $0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\." { found=0 }
        found && $0 ~ /^- Status:/ { print "- Status: in-publish"; next }
        found && $0 ~ /^- PR:/ { print "- PR: " pr; next }
        { print }
      ' "$MOCK_TRACKER" > "$MOCK_TRACKER.tmp" && mv "$MOCK_TRACKER.tmp" "$MOCK_TRACKER"
    fi
    ;;
  ocf:aibot-notify)
    echo "NOTIFY:$args" >> "${MOCK_OPENCODE_LOG:-/dev/null}"
    ;;
esac
exit 0
EOF
chmod +x "$MOCK"/*

# --- fixtures ---------------------------------------------------------------
make_workspace() { # <dir> <remote-url> <status>
  local ws="$1" url="$2" status="$3"
  mkdir -p "$ws"
  git -C "$ws" init -q
  git -C "$ws" remote add origin "$url"
  cat > "$ws/known_issues.md" <<EOF
## Known Issues

### 7. Test issue
- Status: $status
- Type: feat
- Severity: medium
- Report: test
- Base branch: main
- Reviewers: 1
- Remote: #30
- PR: -
- Description: test
- Business rules:
  1. rule
- Acceptance criteria:
  1. criterion
EOF
  (cd "$ws" && git add -A && git -c user.email=t@t -c user.name=t commit -qm init) >/dev/null 2>&1
}

make_allowlist() { # <file> <key> <workspace>
  cat > "$1" <<EOF
{
  "_doc": "test allowlist",
  "$2": { "workspace": "$3" }
}
EOF
}

: > "$TMP/comments.json"
printf '%s\n' '{"id":5,"author":"dev","issue":30,"body":"@aibot:develop"}' > "$TMP/comments-one.json"

run_watcher() { # <repos-file> <workspace> [extra env assignments...]
  local repos="$1" ws="$2"; shift 2
  local rc=0
  env AIBOT_CONFIG_DIR="$CONFIG" \
      AIBOT_STATE_DIR="$STATE" \
      AIBOT_REPOS_FILE="$repos" \
      AIBOT_WEB_URL="${AIBOT_WEB_URL:-http://up.local}" \
      MOCK_GH_LOG="$TMP/gh.log" \
      MOCK_GLAB_LOG="$TMP/glab.log" \
      MOCK_OPENCODE_LOG="$TMP/opencode.log" \
      MOCK_COMMENTS_FILE="${MOCK_COMMENTS_FILE:-$TMP/comments.json}" \
      MOCK_ISSUES_FILE="${MOCK_ISSUES_FILE:-$TMP/issues.txt}" \
      MOCK_TRACKER="${MOCK_TRACKER:-$ws/known_issues.md}" \
      "$@" PATH="$MOCK:$PATH" \
      bash "$WATCHER" >"$TMP/run.log" 2>&1 || rc=$?
  return "$rc"
}

seed_cursor() { # <key> <id>
  mkdir -p "$STATE"
  printf '%s\n' "$2" > "$STATE/$(printf '%s' "$1" | tr '/:' '__').cursor"
}

get_field_() { # <tracker> <id> <Field>
  awk -v id="$2" -v f="^- $3:" '
    $0 ~ "^### " id "\\." { found=1; next }
    found && $0 ~ /^### [0-9]+\./ { exit }
    found && $0 ~ f { sub(/^[^:]*: /, ""); print; exit }
    ' "$1"
}

reset_logs() {
  : > "$TMP/gh.log"; : > "$TMP/glab.log"; : > "$TMP/opencode.log"
  printf '%s\n' "30" > "$TMP/issues.txt"   # default: issue 30 is the only real issue
}

# ============================================================================
# S1 — BR 7/8/AC 2/AC 10: trigger + success → develop + success notify with PR
# ============================================================================
ws="$TMP/ws1"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow1.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
cp "$TMP/comments-one.json" "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow1.json" "$ws"
assert_eq "0" "$?" "S1: watcher exit 0"
assert_contains "$TMP/opencode.log" "DEVELOP:7"             "S1: develop triggered for local issue 7"
assert_contains "$TMP/opencode.log" "NOTIFY:30 success 107" "S1: success notification with PR 107"
assert_contains "$TMP/run.log" "in-publish"                 "S1: tracker updated to in-publish"
assert_eq "#107" "$(get_field_ "$ws/known_issues.md" 7 PR)" "S1: PR populated in tracker"
# F3 (runtime): BR 7 exact command form — attach+auto, qualified model, NO `--`
assert_contains "$TMP/opencode.log" "run --attach http://up.local --auto" "S1: forma BR 7 (--attach --auto)"
assert_contains "$TMP/opencode.log" "--model opencode-go/deepseek-v4-flash" "S1: modelo qualificado"
assert_contains "$TMP/opencode.log" "--command ocf:develop 7" "S1: args follow --command without a separator"
assert_not_contains "$TMP/opencode.log" "--command ocf:develop -- " "S1: formulário com -- proibido"

# ============================================================================
# S2 — BR 4/AC 3: untracked issue → not-tracked, no develop
# ============================================================================
ws="$TMP/ws2"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow2.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' '{"id":6,"author":"dev","issue":999,"body":"@aibot:develop"}' > "$TMP/comments.json"
reset_logs
printf '%s\n' "999" > "$TMP/issues.txt"   # 999 is a real issue, just not tracked
run_watcher "$TMP/allow2.json" "$ws"
assert_eq "0" "$?" "S2: watcher exit 0"
assert_contains "$TMP/opencode.log" "NOTIFY:999 not-tracked" "S2: not-tracked notification"
assert_not_contains "$TMP/opencode.log" "DEVELOP"            "S2: no develop"

# ============================================================================
# S3 — BR 5/AC 4: status in-progress → already-in-progress, no develop
# ============================================================================
ws="$TMP/ws3"
make_workspace "$ws" "git@github.com:test/repo.git" "in-progress"
make_allowlist "$TMP/allow3.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
cp "$TMP/comments-one.json" "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow3.json" "$ws"
assert_contains "$TMP/opencode.log" "NOTIFY:30 already-in-progress" "S3: already-in-progress notification"
assert_not_contains "$TMP/opencode.log" "DEVELOP"                   "S3: no develop"

# ============================================================================
# S4 — BR 2/AC 8/AC 13: replay does not re-trigger (cursor persists)
# ============================================================================
ws="$TMP/ws4"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow4.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
cp "$TMP/comments-one.json" "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow4.json" "$ws"
run_watcher "$TMP/allow4.json" "$ws"
assert_count "$TMP/opencode.log" "DEVELOP:7" 1 "S4: replay → exactly one develop"

# ============================================================================
# S5 — BR 3/AC 7: comments without token → cursor advances, nothing triggers
# ============================================================================
ws="$TMP/ws5"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow5.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' \
  '{"id":7,"author":"dev","issue":30,"body":"comentario comum"}' \
  '{"id":8,"author":"dev","issue":30,"body":"veja @aibot:develop aqui"}' \
  > "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow5.json" "$ws"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S5: no develop"
assert_not_contains "$TMP/opencode.log" "NOTIFY"  "S5: no notification"
assert_eq "8" "$(cat "$STATE/test_repo.cursor")" "S5: cursor advanced to the last comment"

# ============================================================================
# S6 — BR 17/AC 14: the aibot own comment never triggers
# ============================================================================
ws="$TMP/ws6"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow6.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' '{"id":9,"author":"aibot[bot]","issue":30,"body":"@aibot:develop"}' > "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow6.json" "$ws"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S6: self-trigger does not fire"
assert_not_contains "$TMP/opencode.log" "NOTIFY"  "S6: self-trigger does not notify"

# ============================================================================
# S7 — BR 3/AC 15: token in fence/quoted/linked does not trigger
# ============================================================================
ws="$TMP/ws7"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow7.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' \
  '{"id":10,"author":"dev","issue":30,"body":"```\n@aibot:develop\n```"}' \
  '{"id":11,"author":"dev","issue":30,"body":"> @aibot:develop"}' \
  '{"id":12,"author":"dev","issue":30,"body":"[@aibot:develop](https://x)"}' \
  > "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow7.json" "$ws"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S7: token in fence/quoted/linked does not trigger"
assert_not_contains "$TMP/opencode.log" "NOTIFY"  "S7: no notifications"
assert_eq "12" "$(cat "$STATE/test_repo.cursor")" "S7: cursor advanced"

# ============================================================================
# S8 — BR 1: remote path ≠ allowlist key → refused before any fetch
# ============================================================================
ws="$TMP/ws8"
make_workspace "$ws" "git@github.com:other/repo.git" "ready"
make_allowlist "$TMP/allow8.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
reset_logs
run_watcher "$TMP/allow8.json" "$ws"
assert_eq "0" "$?" "S8: watcher exit 0"
assert_not_contains "$TMP/gh.log" "GH-CALL"        "S8: no gh call (refused at allowlist gate)"
assert_not_contains "$TMP/opencode.log" "DEVELOP"  "S8: no develop"
assert_contains "$TMP/run.log" "does not match allowlist key" "S8: refusal log"

# ============================================================================
# S9 — AC 17: empty/nonexistent workspace → clean refusal
# ============================================================================
make_allowlist "$TMP/allow9.json" "test/repo" "$TMP/does-not-exist"
seed_cursor "test/repo" 0
reset_logs
run_watcher "$TMP/allow9.json" "$TMP/does-not-exist"
assert_eq "0" "$?" "S9: watcher exit 0"
assert_contains "$TMP/run.log" "empty or nonexistent" "S9: workspace refusal log"

# ============================================================================
# S10 — BR 12/AC 9: web server down → tick skipped, clean exit
# ============================================================================
ws="$TMP/ws10"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow10.json" "test/repo" "$ws"
rm -rf "$STATE"
reset_logs
AIBOT_WEB_URL="http://down.local" run_watcher "$TMP/allow10.json" "$ws"
assert_eq "0" "$?" "S10: watcher exit 0 com web down"
assert_not_contains "$TMP/gh.log" "GH-CALL"       "S10: no gh call"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S10: no develop"
assert_eq "0" "$([[ -d "$STATE" ]] && echo 1 || echo 0)" "S10: state not created with web down"

# ============================================================================
# S11 — AC 18: provider gitlab via glab
# ============================================================================
ws="$TMP/ws11"
make_workspace "$ws" "https://gitlab.com/group/project.git" "ready"
make_allowlist "$TMP/allow11.json" "group/project" "$ws"
seed_cursor "group/project" 0
cp "$TMP/comments-one.json" "$TMP/comments.json"
printf '%s\n' "30" > "$TMP/issues.txt"
reset_logs
run_watcher "$TMP/allow11.json" "$ws"
assert_eq "0" "$?" "S11: watcher exit 0"
assert_contains "$TMP/glab.log" "GLAB-CALL"              "S11: glab used for gitlab"
assert_contains "$TMP/opencode.log" "DEVELOP:7"          "S11: develop triggered (gitlab)"
assert_contains "$TMP/opencode.log" "NOTIFY:30 success"  "S11: success notified (gitlab)"

# ============================================================================
# S12 — AC 18: unknown remote → refused
# ============================================================================
ws="$TMP/ws12"
make_workspace "$ws" "git@bitbucket.org:team/repo.git" "ready"
make_allowlist "$TMP/allow12.json" "team/repo" "$ws"
seed_cursor "team/repo" 0
reset_logs
run_watcher "$TMP/allow12.json" "$ws"
assert_eq "0" "$?" "S12: watcher exit 0"
assert_not_contains "$TMP/gh.log" "GH-CALL"       "S12: no gh call"
assert_not_contains "$TMP/glab.log" "GLAB-CALL"   "S12: no glab call"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S12: no develop"
assert_contains "$TMP/run.log" "not supported"    "S12: provider refusal log"

# ============================================================================
# S13 — AC 5: two triggers on the same issue in the same tick → a single develop
# ============================================================================
ws="$TMP/ws13"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow13.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' \
  '{"id":5,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  '{"id":13,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  > "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow13.json" "$ws"
assert_count "$TMP/opencode.log" "DEVELOP:7" 1 "S13: exactly one develop (same issue)"

# ============================================================================
# S14 — Security M2: first run initializes the cursor at the newest comment
# ============================================================================
ws="$TMP/ws14"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow14.json" "test/repo" "$ws"
rm -f "$STATE/test_repo.cursor"   # no cursor → first run
printf '%s\n' \
  '{"id":1,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  '{"id":2,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  '{"id":3,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  > "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow14.json" "$ws"
assert_eq "3" "$(cat "$STATE/test_repo.cursor")" "S14: cursor initialized at the newest comment"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S14: no replay of historical comments"
assert_not_contains "$TMP/opencode.log" "NOTIFY"  "S14: no notifications at init"

# ============================================================================
# S15 — BR 18/AC 16: comment on a PR (non-real issue) is filtered
# ============================================================================
ws="$TMP/ws15"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow15.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' "30" > "$TMP/issues.txt"            # only issue 30 is a real issue
printf '%s\n' \
  '{"id":5,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  '{"id":14,"author":"dev","issue":999,"body":"@aibot:develop"}' \
  > "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow15.json" "$ws"
assert_count "$TMP/opencode.log" "DEVELOP:7" 1       "S15: develop only on the real issue"
assert_not_contains "$TMP/opencode.log" "NOTIFY:999" "S15: PR comment does not notify"
assert_eq "14" "$(cat "$STATE/test_repo.cursor")"    "S15: cursor passed the PR comment"

# ============================================================================
# S16 — Security M3: MAX_TRIGGERS_PER_TICK limita spawns paralelos
# ============================================================================
ws="$TMP/ws16"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
# second tracked issue for the second trigger
cat >> "$ws/known_issues.md" <<'EOF'

### 8. Second issue
- Status: ready
- Type: feat
- Severity: medium
- Report: test
- Base branch: main
- Reviewers: 1
- Remote: #31
- PR: -
- Description: test
- Business rules:
  1. rule
EOF
(cd "$ws" && git add -A && git -c user.email=t@t -c user.name=t commit -qm "add second issue") >/dev/null 2>&1
make_allowlist "$TMP/allow16.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
printf '%s\n' \
  '{"id":5,"author":"dev","issue":30,"body":"@aibot:develop"}' \
  '{"id":15,"author":"dev","issue":31,"body":"@aibot:develop"}' \
  > "$TMP/comments.json"
reset_logs
printf '%s\n' "30" "31" > "$TMP/issues.txt"   # both are real issues
run_watcher "$TMP/allow16.json" "$ws"
assert_count "$TMP/opencode.log" "DEVELOP" 1 "S16: cap MAX_TRIGGERS_PER_TICK=1 → one spawn"
assert_contains "$TMP/run.log" "deferred" "S16: second trigger deferred (log)"
assert_eq "5" "$(cat "$STATE/test_repo.cursor")" "S16: cursor does NOT advance for the deferred comment"
# run 2: the deferred comment is re-examined and triggers (F1 — deferral, not loss)
run_watcher "$TMP/allow16.json" "$ws"
assert_count "$TMP/opencode.log" "DEVELOP" 2 "S16: deferred issue is developed on the next tick"
assert_contains "$TMP/opencode.log" "DEVELOP:8" "S16: second issue developed"
assert_contains "$TMP/opencode.log" "NOTIFY:31 success 108" "S16: success notified for the second issue"
assert_eq "15" "$(cat "$STATE/test_repo.cursor")" "S16: cursor advanced after processing the deferred comment"

# ============================================================================
# S18 — BR 9/AC 11: blocked develop (exit != 0) → cannot-develop, no MR
# ============================================================================
ws="$TMP/ws18"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow18.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
cp "$TMP/comments-one.json" "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow18.json" "$ws" MOCK_DEVELOP_EXIT=1
assert_eq "1" "$(count_occurrences "$TMP/opencode.log" "DEVELOP:7")" "S18: develop was attempted"
assert_contains "$TMP/opencode.log" "NOTIFY:30 cannot-develop" "S18: failure → cannot-develop"
assert_not_contains "$TMP/opencode.log" "NOTIFY:30 success" "S18: no success notification"
assert_eq "ready" "$(get_field_ "$ws/known_issues.md" 7 Status)" "S18: tracker without MR (status intact)"
assert_eq "-" "$(get_field_ "$ws/known_issues.md" 7 PR)" "S18: PR not populated"

# ============================================================================
# S19 — BR 9/AC 11: develop finishes but without MR → cannot-develop, no MR
# ============================================================================
ws="$TMP/ws19"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
make_allowlist "$TMP/allow19.json" "test/repo" "$ws"
seed_cursor "test/repo" 0
cp "$TMP/comments-one.json" "$TMP/comments.json"
reset_logs
run_watcher "$TMP/allow19.json" "$ws" MOCK_DEVELOP_NO_MR=1
assert_eq "1" "$(count_occurrences "$TMP/opencode.log" "DEVELOP:7")" "S19: develop was attempted"
assert_contains "$TMP/opencode.log" "NOTIFY:30 cannot-develop" "S19: no MR → cannot-develop"
assert_not_contains "$TMP/opencode.log" "NOTIFY:30 success" "S19: no success notification"
assert_eq "ready" "$(get_field_ "$ws/known_issues.md" 7 Status)" "S19: tracker without MR (status intact)"
assert_eq "-" "$(get_field_ "$ws/known_issues.md" 7 PR)" "S19: PR not populated"

# ============================================================================
# S17 — no allowlist file → clean exit
# ============================================================================
ws="$TMP/ws17"
make_workspace "$ws" "git@github.com:test/repo.git" "ready"
seed_cursor "test/repo" 0
reset_logs
AIBOT_REPOS_FILE="$TMP/nonexistent-repos.json" run_watcher "$TMP/nonexistent-repos.json" "$ws"
assert_eq "0" "$?" "S17: watcher exit 0 without allowlist"
assert_not_contains "$TMP/opencode.log" "DEVELOP" "S17: no develop"

t_finish
