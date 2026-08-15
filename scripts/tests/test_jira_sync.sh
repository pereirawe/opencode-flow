#!/usr/bin/env bash
# test_jira_sync.sh — issue #48: Jira Cloud sync.
#
# Covers AC 1–12 / BR 1–12:
#   t01/t02 config enable/disable, t03 card creation via create_issue.sh,
#   t04 creation idempotency, t05 ensure-card on existing remote,
#   t06 promote mode 2 transition (In Progress), t07 promote mode 1 (To Do),
#   t08 close_issue resolved → Done, t08b custom statusMap (Closed),
#   t09 network failure is non-blocking, t10 disabled state = zero Jira calls
#   (regression-free AC 6), t11 secret never leaks (AC 9), t12 sync reconcile
#   (AC 5), t13 transition not allowed → no-op warning (BR 9), t14 already in
#   target status → no transition, t15 remote-creation failure still creates
#   the card, t16 standards parity (en/pt/es + known_issues format block),
#   t17 bash -n clean, t18 config never prints the token.
#
# Deterministic/self-contained: `curl`, `gh`, and `date` are mocked via PATH;
# no network, no TTY. Real git is used inside fixtures.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_jira_sync"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SCRIPTS="$HERE/.."
SYNC="$SCRIPTS/sync-jira.sh"
CREATE="$SCRIPTS/create_issue.sh"
PROMOTE="$SCRIPTS/promote.sh"
CLOSE="$SCRIPTS/close_issue.sh"
RUN_OUT="$TMP/run.out"

FAKE_TODAY="2026-08-15"
export FAKE_TODAY
JIRA_TOKEN="tok-supersecret-abc123"
export JIRA_TOKEN

# --- mocks -----------------------------------------------------------------

# mock date: fixed "today"; delegates the rest to the real date (durations math)
MOCK_DATE="$TMP/mock-date"; mkdir -p "$MOCK_DATE"
cat > "$MOCK_DATE/date" <<'EOF'
#!/usr/bin/env bash
REAL=/usr/bin/date; [[ -x "$REAL" ]] || REAL=/bin/date
if [[ "$1" == "+%Y-%m-%d" ]]; then
  echo "${FAKE_TODAY:-2026-08-15}"
  exit 0
fi
exec "$REAL" "$@"
EOF
chmod +x "$MOCK_DATE/date"

# mock curl: logs method/url/data ONLY (never headers — AC 9). Response
# selected by URL; env-tunable.
MOCK_NET="$TMP/mock-net"; mkdir -p "$MOCK_NET"
cat > "$MOCK_NET/curl" <<'EOF'
#!/usr/bin/env bash
# echo "curl $*"  # NEVER log headers — they carry the token (AC 9)
M="GET"; URL=""; DATA=""; OUT=""
a=("$@"); i=0
while [ $i -lt ${#a[@]} ]; do
  case "${a[$i]}" in
    -X) M="${a[$((i+1))]}"; i=$((i+1));;
    -H) i=$((i+1));;
    -d|--data) DATA="${a[$((i+1))]}"; i=$((i+1));;
    -o) OUT="${a[$((i+1))]}"; i=$((i+1));;
    -w) :;;
    *) case "${a[$i]}" in http*) URL="${a[$i]}";; esac;;
  esac
  i=$((i+1))
done
printf 'curl %s %s%s\n' "$M" "$URL" "${DATA:+ -d $DATA}" >> "${CURL_LOG:-/dev/null}"

if [[ "${JIRA_NET_FAIL:-0}" == "1" ]]; then
  echo "mock: connection failed" >&2
  exit 22
fi
if [[ -n "${JIRA_HTTP_CODE:-}" ]]; then
  code="$JIRA_HTTP_CODE"; BODY='{"errorMessages":["mock http error"]}'
else
  code=200
  if [[ "$URL" == *"fields=status"* ]]; then
    BODY="{\"fields\":{\"status\":{\"name\":\"${JIRA_CARD_STATUS//%20/ }\"}}}"
  elif [[ "$URL" == *"/transitions"* ]]; then
    if [[ "$M" == "GET" ]]; then
      if [[ "${JIRA_TRANSITIONS_MODE:-full}" == "limited" ]]; then
        BODY='{"transitions":[{"id":"21","name":"Done"},{"id":"31","name":"Closed"}]}'
      else
        BODY='{"transitions":[{"id":"41","name":"To Do"},{"id":"11","name":"In Progress"},{"id":"51","name":"In Review"},{"id":"61","name":"QA/Testing"},{"id":"71","name":"Ready for Release"},{"id":"21","name":"Done"},{"id":"31","name":"Closed"}]}'
      fi
    else
      BODY='{"status":"ok"}'
    fi
  elif [[ "$URL" == *"/comment"* ]]; then
    BODY='{"id":"10000"}'
  else
    BODY="{\"key\":\"${JIRA_NEW_KEY:-DEV-123}\"}"
  fi
fi
[[ -n "$OUT" ]] && printf '%s' "$BODY" > "$OUT"
printf '%s' "$code"
EOF
chmod +x "$MOCK_NET/curl"

# mock gh: issue create/view/close + pr view
cat > "$MOCK_NET/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"issue create"*)
    if [[ "${GH_FAIL:-0}" == "1" ]]; then echo "mock create failed" >&2; exit 1; fi
    echo "https://github.com/owner/repo/issues/42"; exit 0 ;;
  *"pr view"*)    echo "MERGED"; exit 0 ;;
  *"issue view"*) echo "CLOSED"; exit 0 ;;
esac
exit 0
EOF
chmod +x "$MOCK_NET/gh"
ln -sf "$MOCK_DATE/date" "$MOCK_NET/date"

# --- helpers ---------------------------------------------------------------

# make_fixture <dir> <status> <remote> <jira> [pr]
make_fixture() {
  local d="$1" status="$2" remote="$3" jira="$4" pr="${5:--}"
  mkdir -p "$d/.opencode"
  git -C "$d" init -q -b main 2>/dev/null || { git -C "$d" init -q && git -C "$d" checkout -q -b main; }
  git -C "$d" remote add origin "git@github.com:owner/repo.git"
  git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  {
    printf '## Known Issues\n\n'
    printf '### 1. Test issue\n'
    printf -- '- Status: %s\n' "$status"
    printf -- '- Type: feat\n- Severity: high\n- Report: test\n- Base branch: main\n- Reviewers: 1 (runtime)\n'
    printf -- '- Remote: %s\n' "$remote"
    printf -- '- Jira: %s\n' "$jira"
    printf -- '- PR: %s\n' "$pr"
    printf -- '- Description: test description\n- Business rules:\n  1. rule one\n- Acceptance criteria:\n  1. criterion\n- Tests:\n  1. scenario -> outcome\n- Suggested fix: test fix\n'
  } > "$d/.opencode/known_issues.md"
}

# write_jira_json <dir> [statusmap-json]
write_jira_json() {
  local d="$1" map="${2:-}"
  if [[ -n "$map" ]]; then
    printf '{"baseUrl":"https://acme.atlassian.net","email":"dev@acme.com","projectKey":"DEV","statusMap":%s}\n' "$map" > "$d/.opencode/jira.json"
  else
    printf '{"baseUrl":"https://acme.atlassian.net","email":"dev@acme.com","projectKey":"DEV"}\n' > "$d/.opencode/jira.json"
  fi
}
jira_env() {
  printf 'JIRA_BASE_URL=https://acme.atlassian.net JIRA_PROJECT_KEY=DEV JIRA_EMAIL=dev@acme.com JIRA_API_TOKEN=%s' "$JIRA_TOKEN"
}

# run <fixture> <script> <env-string> <args...> — echoes rc; output in $RUN_OUT
run() {
  local fix="$1" script="$2" envs="$3"; shift 3
  local rc=0
  ( cd "$fix" && export $envs && PATH="$MOCK_NET:$PATH" bash "$script" "$@" ) >"$RUN_OUT" 2>&1 || rc=$?
  echo "$rc"
}

# field <file> <name> — value of the "- Name:" field ("" when absent)
field() {
  awk -F': ' -v f="$2" '$0 ~ "^\\- " f ":" {print $2; exit}' "$1"
}

# cnt <file> <needle> — occurrence count
cnt() {
  grep -cF -- "$2" "$1" 2>/dev/null || echo 0
}

# curl_log <fixture> <label> — count of Jira API calls (rest/api/3)
jira_calls() {
  local n
  n="$(grep -cF "/rest/api/3/" "$1" 2>/dev/null || true)"
  [[ -z "$n" ]] && n=0
  echo "$n"
}

# ===========================================================================
# t01 — config enabled via env vars
# ===========================================================================
fix="$TMP/t01"; make_fixture "$fix" ready "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t01.log"; export CURL_LOG="$TMP/t01.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$SYNC" "$envs" config)
assert_eq "0" "$rc" "t01: config exit 0 when enabled"
assert_contains "$RUN_OUT" "enabled=yes" "t01: enabled=yes"
assert_not_contains "$RUN_OUT" "$JIRA_TOKEN" "t01: config output never prints the token"

# ===========================================================================
# t02 — config disabled without jira.json and without env
# ===========================================================================
fix="$TMP/t02"; make_fixture "$fix" ready "#42" "DEV-123"
unset JIRA_BASE_URL JIRA_PROJECT_KEY JIRA_EMAIL JIRA_API_TOKEN
envs="CURL_LOG=$TMP/t02.log"; export CURL_LOG="$TMP/t02.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$SYNC" "$envs" config)
assert_eq "1" "$rc" "t02: config exit 1 when disabled"
assert_contains "$RUN_OUT" "enabled=no" "t02: enabled=no"

# ===========================================================================
# t03 — create_issue.sh creates the card and fills Jira: <KEY-N> (AC 1)
# ===========================================================================
fix="$TMP/t03"; make_fixture "$fix" ready "-" "-"
write_jira_json "$fix"
envs="$(jira_env) CURL_LOG=$TMP/t03.log"; export CURL_LOG="$TMP/t03.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$CREATE" "$envs" 1)
assert_eq "0" "$rc" "t03: create_issue exit 0"
assert_eq "#42" "$(field "$fix/.opencode/known_issues.md" Remote)" "t03: Remote = #42 (gh)"
assert_eq "DEV-123" "$(field "$fix/.opencode/known_issues.md" Jira)" "t03: Jira = DEV-123 (card created)"
assert_eq "ready" "$(field "$fix/.opencode/known_issues.md" Status)" "t03: status stays ready"
assert_eq "1" "$(jira_calls "$CURL_LOG")" "t03: exactly one Jira API call (issue create)"
assert_contains "$CURL_LOG" "POST https://acme.atlassian.net/rest/api/3/issue" "t03: POST to issue endpoint"
assert_contains "$CURL_LOG" "https://acme.atlassian.net" "t03: curl hit acme (jira.json baseUrl)"

# ===========================================================================
# t04 — creation idempotency: second run creates no duplicate card (AC 2/BR 5)
# ===========================================================================
fix="$TMP/t04"; make_fixture "$fix" ready "-" "-"
write_jira_json "$fix"
envs="$(jira_env) CURL_LOG=$TMP/t04.log"; export CURL_LOG="$TMP/t04.log"; : > "$CURL_LOG"
run "$fix" "$CREATE" "$envs" 1 >/dev/null
rc=$(run "$fix" "$CREATE" "$envs" 1)
assert_eq "1" "$rc" "t04: second create_issue aborts (Remote already set)"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" 'Jira: DEV-123')" "t04: single Jira field"
assert_eq "1" "$(grep -c 'rest/api/3/issue ' "$CURL_LOG")" "t04: exactly one card-creation POST"
# ensure-card directly on an entry that already has a card → no-op
rc=$(run "$fix" "$SYNC" "$envs" ensure-card "$fix/.opencode/known_issues.md" 1)
assert_eq "0" "$rc" "t04: ensure-card idempotent exit 0"
assert_contains "$RUN_OUT" "already exists" "t04: ensure-card no-op warning"
assert_eq "1" "$(grep -c 'rest/api/3/issue ' "$CURL_LOG")" "t04: no second card POST after ensure-card"

# ===========================================================================
# t05 — ensure-card on an existing remote with Jira: - inserts the field
# ===========================================================================
fix="$TMP/t05"; make_fixture "$fix" ready "#42" "-"
write_jira_json "$fix"
envs="$(jira_env) CURL_LOG=$TMP/t05.log"; export CURL_LOG="$TMP/t05.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$SYNC" "$envs" ensure-card "$fix/.opencode/known_issues.md" 1)
assert_eq "0" "$rc" "t05: ensure-card exit 0"
assert_eq "DEV-123" "$(field "$fix/.opencode/known_issues.md" Jira)" "t05: Jira field populated"
assert_eq "1" "$(cnt "$fix/.opencode/known_issues.md" 'Jira: DEV-123')" "t05: single Jira line (no duplicate)"

# ===========================================================================
# t06 — promote ready→in-progress transitions the card to "In Progress"
# ===========================================================================
fix="$TMP/t06"; make_fixture "$fix" ready "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t06.log JIRA_CARD_STATUS=To%20Do"; export CURL_LOG="$TMP/t06.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$PROMOTE" "$envs" 1)
assert_eq "0" "$rc" "t06: promote exit 0"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t06: status advanced locally"
assert_contains "$CURL_LOG" "POST https://acme.atlassian.net/rest/api/3/issue/DEV-123/transitions" "t06: transition POST issued"
assert_contains "$CURL_LOG" '-d {"transition":{"id":"11"}}' "t06: transition id 11 = In Progress"
assert_contains "$RUN_OUT" "transitioned to 'In Progress'" "t06: transition logged"

# ===========================================================================
# t07 — promote backlog→ready transitions the card to "To Do"
# ===========================================================================
fix="$TMP/t07"; make_fixture "$fix" backlog "-" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t07.log JIRA_CARD_STATUS=Backlog"; export CURL_LOG="$TMP/t07.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$PROMOTE" "$envs" 1)
assert_eq "0" "$rc" "t07: promote mode 1 exit 0"
assert_eq "ready" "$(field "$fix/.opencode/known_issues.md" Status)" "t07: status = ready"
assert_contains "$CURL_LOG" '-d {"transition":{"id":"41"}}' "t07: transition id 41 = To Do"
assert_contains "$RUN_OUT" "transitioned to 'To Do'" "t07: mode 1 transition logged"

# ===========================================================================
# t08 — close_issue resolved transitions the card to "Done"
# ===========================================================================
fix="$TMP/t08"; make_fixture "$fix" resolved "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t08.log"; export CURL_LOG="$TMP/t08.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$CLOSE" "$envs" 1)
assert_eq "0" "$rc" "t08: close exit 0"
assert_contains "$CURL_LOG" '-d {"transition":{"id":"21"}}' "t08: transition id 21 = Done"
assert_contains "$fix/.opencode/resolved_issues.md" "- Resolved:" "t08: local archive written"
assert_not_contains "$fix/.opencode/known_issues.md" "### 1." "t08: entry archived"

# ===========================================================================
# t08b — custom statusMap (resolved → "Closed", id 31) honored
# ===========================================================================
fix="$TMP/t08b"; make_fixture "$fix" resolved "#42" "DEV-123"
write_jira_json "$fix" '{"resolved":"Closed"}'
envs="$(jira_env) CURL_LOG=$TMP/t08b.log"; export CURL_LOG="$TMP/t08b.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$CLOSE" "$envs" 1)
assert_eq "0" "$rc" "t08b: close exit 0"
assert_contains "$CURL_LOG" '-d {"transition":{"id":"31"}}' "t08b: custom map → transition id 31 = Closed"

# ===========================================================================
# t09 — network failure is non-blocking: pipeline completes, status advances
# ===========================================================================
fix="$TMP/t09"; make_fixture "$fix" ready "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t09.log JIRA_NET_FAIL=1"; export CURL_LOG="$TMP/t09.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$PROMOTE" "$envs" 1)
assert_eq "0" "$rc" "t09: promote exit 0 despite Jira network failure (AC 7)"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t09: local status advanced (non-blocking)"
assert_contains "$RUN_OUT" "Warning: status sync failed" "t09: warning logged"
assert_contains "$RUN_OUT" "non-blocking" "t09: warning labeled non-blocking"

# ===========================================================================
# t10 — disabled state: zero Jira calls across all pipeline scripts (AC 6)
# ===========================================================================
fix="$TMP/t10"; make_fixture "$fix" ready "-" "-"
envs="CURL_LOG=$TMP/t10a.log"; export CURL_LOG="$TMP/t10a.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$CREATE" "$envs" 1)
assert_eq "0" "$rc" "t10: create_issue exit 0 (no Jira config)"
assert_eq "0" "$(jira_calls "$CURL_LOG")" "t10: create_issue → zero Jira calls"
assert_eq "#42" "$(field "$fix/.opencode/known_issues.md" Remote)" "t10: remote still created (regression-free)"

fix="$TMP/t10b"; make_fixture "$fix" ready "#42" "DEV-123"
envs="CURL_LOG=$TMP/t10b.log"; export CURL_LOG="$TMP/t10b.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$PROMOTE" "$envs" 1)
assert_eq "0" "$rc" "t10: promote exit 0 (no Jira config)"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t10: promote advanced locally"
assert_eq "0" "$(jira_calls "$CURL_LOG")" "t10: promote → zero Jira calls"

fix="$TMP/t10c"; make_fixture "$fix" resolved "#42" "DEV-123"
envs="CURL_LOG=$TMP/t10c.log"; export CURL_LOG="$TMP/t10c.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$CLOSE" "$envs" 1)
assert_eq "0" "$rc" "t10: close exit 0 (no Jira config)"
assert_eq "0" "$(jira_calls "$CURL_LOG")" "t10: close → zero Jira calls"

# ===========================================================================
# t11 — secret never leaks: token absent from output, tracker, and curl log
# ===========================================================================
fix="$TMP/t11"; make_fixture "$fix" ready "-" "-"
write_jira_json "$fix"
envs="$(jira_env) CURL_LOG=$TMP/t11.log"; export CURL_LOG="$TMP/t11.log"; : > "$CURL_LOG"
run "$fix" "$CREATE" "$envs" 1 >/dev/null
assert_not_contains "$RUN_OUT" "$JIRA_TOKEN" "t11: token absent from create_issue output"
assert_not_contains "$CURL_LOG" "$JIRA_TOKEN" "t11: token absent from curl log"
assert_not_contains "$CURL_LOG" "Authorization" "t11: curl log has no Authorization header"
assert_not_contains "$fix/.opencode/known_issues.md" "$JIRA_TOKEN" "t11: token absent from tracker"
assert_not_contains "$fix/.opencode/jira.json" "$JIRA_TOKEN" "t11: token absent from jira.json"
assert_not_contains "$fix/.opencode/known_issues.md" "dev@acme.com" "t11: email not persisted in tracker"

# ===========================================================================
# t12 — sync reconciles every issue with a card in one run (AC 5)
# ===========================================================================
fix="$TMP/t12"; mkdir -p "$fix/.opencode"
git -C "$fix" init -q -b main 2>/dev/null || { git -C "$fix" init -q; git -C "$fix" checkout -q -b main; }
{
  printf '### 1. First\n- Status: in-progress\n- Type: feat\n- Severity: high\n- Report: t\n- Base branch: main\n- Reviewers: 1 (runtime)\n- Remote: #11\n- Jira: DEV-101\n- PR: -\n- Description: a\n\n'
  printf '### 2. Second\n- Status: in-publish\n- Type: feat\n- Severity: high\n- Report: t\n- Base branch: main\n- Reviewers: 1 (runtime)\n- Remote: #12\n- Jira: DEV-102\n- PR: #7\n- Description: b\n\n'
  printf '### 3. No card\n- Status: ready\n- Type: feat\n- Severity: high\n- Report: t\n- Base branch: main\n- Reviewers: 1 (runtime)\n- Remote: #13\n- Jira: -\n- PR: -\n- Description: c\n'
} > "$fix/.opencode/known_issues.md"
envs="$(jira_env) CURL_LOG=$TMP/t12.log"; export CURL_LOG="$TMP/t12.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$SYNC" "$envs" sync "$fix/.opencode/known_issues.md")
assert_eq "0" "$rc" "t12: sync exit 0"
assert_eq "2" "$(grep -c 'POST https://acme.atlassian.net/rest/api/3/issue/DEV-1[01][0-9]/transitions' "$CURL_LOG")" "t12: two cards transitioned"
assert_contains "$CURL_LOG" "-d {\"transition\":{\"id\":\"11\"}}" "t12: DEV-101 → In Progress"
assert_contains "$CURL_LOG" "-d {\"transition\":{\"id\":\"71\"}}" "t12: DEV-102 → Ready for Release"
assert_contains "$RUN_OUT" "2 synced, 1 without card" "t12: sync summary covers all issues"

# ===========================================================================
# t13 — transition not allowed by workflow → no-op warning, no crash (BR 9)
# ===========================================================================
fix="$TMP/t13"; make_fixture "$fix" ready "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t13.log JIRA_TRANSITIONS_MODE=limited"; export CURL_LOG="$TMP/t13.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$PROMOTE" "$envs" 1)
assert_eq "0" "$rc" "t13: promote exit 0 (non-blocking)"
assert_eq "in-progress" "$(field "$fix/.opencode/known_issues.md" Status)" "t13: local status still advanced"
assert_contains "$RUN_OUT" "not allowed by the Jira workflow" "t13: workflow warning logged"
assert_eq "0" "$(grep -c 'POST .*transitions' "$CURL_LOG")" "t13: no transition POST attempted"

# ===========================================================================
# t14 — card already in target status → no transition
# ===========================================================================
fix="$TMP/t14"; make_fixture "$fix" ready "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t14.log JIRA_CARD_STATUS=To%20Do"; export CURL_LOG="$TMP/t14.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$SYNC" "$envs" transition "$fix/.opencode/known_issues.md" 1)
assert_eq "0" "$rc" "t14: transition exit 0"
assert_contains "$RUN_OUT" "already in 'To Do'" "t14: no-op message"
assert_eq "0" "$(grep -c 'POST .*transitions' "$CURL_LOG")" "t14: no transition POST (already in target)"

# ===========================================================================
# t15 — remote-creation failure still creates the Jira card
# ===========================================================================
fix="$TMP/t15"; make_fixture "$fix" ready "-" "-"
write_jira_json "$fix"
envs="$(jira_env) GH_FAIL=1 CURL_LOG=$TMP/t15.log"; export CURL_LOG="$TMP/t15.log"; : > "$CURL_LOG"
rc=$(run "$fix" "$CREATE" "$envs" 1)
assert_eq "0" "$rc" "t15: create_issue exit 0 despite gh failure"
assert_contains "$fix/.opencode/known_issues.md" "error:mock create failed" "t15: Remote: error:... recorded"
assert_eq "DEV-123" "$(field "$fix/.opencode/known_issues.md" Jira)" "t15: card still created (BR 4 independent of git provider)"

# ===========================================================================
# t16 — standards parity: issues.md (en/pt/es) + known_issues Format block
# ===========================================================================
ROOT="$HERE/../.."
for lang in "" "/pt" "/es"; do
  doc="$ROOT/standards${lang}/issues.md"
  if [[ -f "$doc" ]] && grep -qF -- "- Jira: - | <KEY-N>" "$doc"; then
    t_ok "t16: standards${lang:-/en}/issues.md documents Jira field"
  else
    t_fail "t16: standards${lang:-/en}/issues.md missing Jira field"
  fi
done
assert_contains "$ROOT/known_issues.md" "- Jira: - | <KEY-N>" "t16: known_issues.md Format block documents Jira field"
assert_contains "$ROOT/standards/mcp-registry.md" "sync-jira.sh" "t16: mcp-registry.md documents the Jira sync"
assert_contains "$ROOT/scripts/README.md" "sync-jira.sh" "t16: scripts/README.md documents sync-jira.sh"

# ===========================================================================
# t17 — bash -n clean on all modified scripts
# ===========================================================================
for s in "$SYNC" "$CREATE" "$PROMOTE" "$CLOSE" "$SCRIPTS/config.sh"; do
  if bash -n "$s" >/dev/null 2>&1; then
    t_ok "t17: bash -n clean on $(basename "$s")"
  else
    t_fail "t17: bash -n failed on $(basename "$s")"
  fi
done

# ===========================================================================
# t18 — config command never prints the token (AC 9 / BR 12)
# ===========================================================================
fix="$TMP/t18"; make_fixture "$fix" ready "#42" "DEV-123"
envs="$(jira_env) CURL_LOG=$TMP/t18.log"; export CURL_LOG="$TMP/t18.log"; : > "$CURL_LOG"
run "$fix" "$SYNC" "$envs" config >/dev/null
assert_not_contains "$RUN_OUT" "$JIRA_TOKEN" "t18: config output has no token"

t_finish
