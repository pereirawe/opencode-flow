#!/usr/bin/env bash
# test_run_ci_workflow.sh — unit tests for scripts/run-ci-workflow.sh gate
# functions. Tests each gate in isolation by extracting function definitions
# from the script with mocked commands and temp directories.
#
# No BATS dependency — plain bash with lib.sh assertions.
# Run: bash scripts/tests/test_run_ci_workflow.sh

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_run_ci_workflow"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Absolute paths (set BEFORE anything sources config.sh)
SCRIPTS_ABS="$(cd "$HERE/.." && pwd)"
CONFIG_ABS="$(cd "$SCRIPTS_ABS/.." && pwd)"
RUN_CI="$SCRIPTS_ABS/run-ci-workflow.sh"

# --- helpers ---

make_workspace() {
  local d="$1" url="$2"
  mkdir -p "$d"
  git -C "$d" init -q
  [[ -n "$url" ]] && git -C "$d" remote add origin "$url"
}

# --- create a minimal aibot-messages.md ---

MESSAGES_FILE="$TMP/standards/aibot-messages.md"
mkdir -p "$TMP/standards"
cat > "$MESSAGES_FILE" <<'MESSAGES_EOF'
### success
Desenvolvimento concluido ✅

A issue #{issue_id} foi desenvolvida e a MR esta pronta:
{mr_link}

— aibot

### already-in-progress
Ja existe desenvolvimento em andamento para esta issue 🚧

Novo disparo ignorado.

— aibot

### already-resolved
Esta issue ja foi resolvida ✔️

Nenhuma acao necessaria.

— aibot

### not-tracked
Esta issue nao esta rastreada localmente neste workspace ❌

O pipeline nao pode ser iniciado.

— aibot

### cannot-develop
Nao foi possivel desenvolver esta issue automaticamente ⚠️

A tarefa deve ser revisada.

— aibot
MESSAGES_EOF

# --- mock commands ---

MOCK_BIN="$TMP/bin"
mkdir -p "$MOCK_BIN"

for cmd in gh glab opencode; do
  cat > "$MOCK_BIN/$cmd" <<'MOCK_EOF'
#!/usr/bin/env bash
exit 0
MOCK_EOF
  chmod +x "$MOCK_BIN/$cmd"
done

# jq mock: exit 0 if key exists in JSON, exit 1 otherwise
cat > "$MOCK_BIN/jq" <<'JQ_MOCK'
#!/usr/bin/env bash
# Simulate: jq -e --arg r "repo" 'has($r)' file.json
ARG_R=""
FILE=""
EXPRESSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --arg) shift; shift; ARG_R="$1"; shift ;;  # --arg name value
    -e|-r|--raw-output) shift ;;
    -*) shift ;;  # skip other flags
    *)
      if [[ -z "$EXPRESSION" ]]; then
        EXPRESSION="$1"
      elif [[ -z "$FILE" ]]; then
        FILE="$1"
      fi
      shift ;;
  esac
done
if [[ -n "$FILE" && -f "$FILE" && -n "$ARG_R" ]]; then
  python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if sys.argv[2] in d else 1)" "$FILE" "$ARG_R" 2>/dev/null
else
  exit 1
fi
JQ_MOCK
chmod +x "$MOCK_BIN/jq"

# --- source remote.sh (safe, only defines detect_provider/parse_remote) ---
source "$SCRIPTS_ABS/remote.sh"

# --- extract and source only the function definitions from run-ci-workflow.sh ---
# We use awk to extract function bodies, avoiding the main flow execution
# and the config.sh sourcing that would clobber our variables.

extract_functions() {
  local script="$1"
  awk '
    # Match function definitions: name() { or function name {
    /^[a-zA-Z_][a-zA-Z_0-9]*\(\) *\{/ || /^function [a-zA-Z_][a-zA-Z_0-9]* *\{/ {
      in_func = 1
      depth = 0
    }
    in_func {
      # Count braces to find the end of the function
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "{") depth++
        if (c == "}") depth--
      }
      print
      if (depth == 0) {
        in_func = 0
        print ""
      }
    }
  ' "$script"
}

eval "$(extract_functions "$RUN_CI")"

# --- test env setup ---

setup_env() {
  local workspace="$1" author="$2" body="${3:-}" issue="${4:-1}"
  WORKSPACE="$workspace"
  ISSUE="$issue"
  AUTHOR="$author"
  BODY="$body"
  DRY_RUN="1"
  AIBOT_CONFIG_DIR="$TMP"
  AIBOT_REPOS_FILE="$TMP/aibot-repos.json"
  AIBOT_TOKEN="@aibot:develop"
  AIBOT_MODEL="test-model"
  AIBOT_AUTHORS=""
  OPENCODE_API_KEY=""
  CONFIG_ROOT="$TMP"
  REPO=""
  PROVIDER=""
  export PATH="$MOCK_BIN:$PATH"
}

# =========================================================================
# Test 1: is_aibot_author — detects [bot] suffix
# =========================================================================
setup_env "$TMP/ws1" "aibot[bot]"
assert_eq "0" "$(is_aibot_author "aibot[bot]"; echo $?)" \
  "is_aibot_author: [bot] suffix detected"

# Test: real user is NOT the aibot
setup_env "$TMP/ws2" "william_pereira"
assert_eq "1" "$(is_aibot_author "william_pereira"; echo $?)" \
  "is_aibot_author: real user rejected"

# Test: empty author is NOT the aibot
assert_eq "1" "$(is_aibot_author ""; echo $?)" \
  "is_aibot_author: empty author rejected"

# Test: author in AIBOT_AUTHORS env var
setup_env "$TMP/ws3" "ci-bot"
AIBOT_AUTHORS="ci-bot,other-bot"
assert_eq "0" "$(is_aibot_author "ci-bot"; echo $?)" \
  "is_aibot_author: matches AIBOT_AUTHORS list"

# Test: author NOT in AIBOT_AUTHORS
AIBOT_AUTHORS="other-bot"
assert_eq "1" "$(is_aibot_author "ci-bot"; echo $?)" \
  "is_aibot_author: not in AIBOT_AUTHORS list"

# Test: github bot author via gh api mock
make_workspace "$TMP/ws4" "https://github.com/owner/repo.git"
cat > "$MOCK_BIN/gh" <<'GH_MOCK'
#!/usr/bin/env bash
if [[ "$*" == "api user --jq .login" ]]; then
  echo "github-bot"
  exit 0
fi
exit 0
GH_MOCK
chmod +x "$MOCK_BIN/gh"
setup_env "$TMP/ws4" "github-bot"
assert_eq "0" "$(is_aibot_author "github-bot"; echo $?)" \
  "is_aibot_author: matches gh api user login"

# Test: non-matching github user
assert_eq "1" "$(is_aibot_author "other-user"; echo $?)" \
  "is_aibot_author: gh api user non-match rejected"

# Reset gh mock
cat > "$MOCK_BIN/gh" <<'MOCK_EOF'
#!/usr/bin/env bash
exit 0
MOCK_EOF
chmod +x "$MOCK_BIN/gh"

# =========================================================================
# Test 2: has_token — validates standalone token detection
# =========================================================================

# Token present as standalone line
assert_eq "0" "$(has_token "@aibot:develop"; echo $?)" \
  "has_token: standalone token detected"

# Token with surrounding whitespace
assert_eq "0" "$(has_token "  @aibot:develop  "; echo $?)" \
  "has_token: token with whitespace"

# Token in a line with other text (NOT standalone)
assert_eq "1" "$(has_token "please run @aibot:develop now"; echo $?)" \
  "has_token: token embedded in text rejected"

# Token inside fenced code block (use printf to avoid bash $'...' parsing)
assert_eq "1" "$(has_token "$(printf '```json\n@aibot:develop\n```')"; echo $?)" \
  "has_token: token in code fence rejected"

# Token inside HTML pre tag
assert_eq "1" "$(has_token "$(printf '<pre>\n@aibot:develop\n</pre>')"; echo $?)" \
  "has_token: token in HTML pre tag rejected"

# No token at all
assert_eq "1" "$(has_token "just a regular comment"; echo $?)" \
  "has_token: no token returns 1"

# Empty body
assert_eq "1" "$(has_token ""; echo $?)" \
  "has_token: empty body returns 1"

# Multiple lines, token on second line
assert_eq "0" "$(has_token "$(printf 'first line\n@aibot:develop\nthird line')"; echo $?)" \
  "has_token: token on second line"

# Token inside HTML code tag
assert_eq "1" "$(has_token '<code>@aibot:develop</code>'; echo $?)" \
  "has_token: token in HTML code tag rejected"

# =========================================================================
# Test 3: repo_in_allowlist — validates repo against allowlist
# =========================================================================

# Test via AIBOT_ALLOWLIST env var
AIBOT_REPOS_FILE=""
AIBOT_ALLOWLIST="owner/repo"
assert_eq "0" "$(repo_in_allowlist "owner/repo"; echo $?)" \
  "repo_in_allowlist: match in AIBOT_ALLOWLIST env"

AIBOT_ALLOWLIST="owner/repo other/repo"
assert_eq "0" "$(repo_in_allowlist "other/repo"; echo $?)" \
  "repo_in_allowlist: second entry in AIBOT_ALLOWLIST"

AIBOT_ALLOWLIST="owner/repo"
assert_eq "1" "$(repo_in_allowlist "not/listed"; echo $?)" \
  "repo_in_allowlist: not in AIBOT_ALLOWLIST"

# Test via aibot-repos.json file
AIBOT_ALLOWLIST=""
cat > "$TMP/aibot-repos.json" <<'JSON_EOF'
{
  "pereirawe/opencode-flow": { "workspace": "~/.config/opencode" }
}
JSON_EOF
AIBOT_REPOS_FILE="$TMP/aibot-repos.json"
assert_eq "0" "$(repo_in_allowlist "pereirawe/opencode-flow"; echo $?)" \
  "repo_in_allowlist: match in aibot-repos.json"

assert_eq "1" "$(repo_in_allowlist "other/repo"; echo $?)" \
  "repo_in_allowlist: not in aibot-repos.json"

# Test: empty repo name
AIBOT_ALLOWLIST="owner/repo"
assert_eq "1" "$(repo_in_allowlist ""; echo $?)" \
  "repo_in_allowlist: empty repo rejected"

# Test: no allowlist, no file
AIBOT_ALLOWLIST=""
AIBOT_REPOS_FILE="$TMP/nonexistent.json"
assert_eq "1" "$(repo_in_allowlist "owner/repo"; echo $?)" \
  "repo_in_allowlist: no allowlist no file returns 1"

# =========================================================================
# Test 4: find_tracked_issue — finds local ID by Remote: field
# =========================================================================

TRACKER_FILE="$TMP/tracker.md"
cat > "$TRACKER_FILE" <<'TRACKER_EOF'
### 1. First issue
- Status: backlog
- Remote: #42

### 2. Second issue
- Status: ready
- Remote: #99

### 3. No remote issue
- Status: backlog
- Remote: -
TRACKER_EOF

result="$(find_tracked_issue "$TRACKER_FILE" "42")"
assert_eq "1" "$result" \
  "find_tracked_issue: finds issue by Remote: #42"

result="$(find_tracked_issue "$TRACKER_FILE" "99")"
assert_eq "2" "$result" \
  "find_tracked_issue: finds issue by Remote: #99"

result="$(find_tracked_issue "$TRACKER_FILE" "55")"
assert_eq "" "$result" \
  "find_tracked_issue: missing issue returns empty"

# Test: no tracker file
result="$(find_tracked_issue "/nonexistent/file.md" "42")"
assert_eq "" "$result" \
  "find_tracked_issue: nonexistent file returns empty"

# =========================================================================
# Test 5: get_field — extracts field value from tracker
# =========================================================================

assert_eq "backlog" "$(get_field "$TRACKER_FILE" "1" "Status")" \
  "get_field: extracts Status from issue 1"

assert_eq "#42" "$(get_field "$TRACKER_FILE" "1" "Remote")" \
  "get_field: extracts Remote from issue 1"

assert_eq "ready" "$(get_field "$TRACKER_FILE" "2" "Status")" \
  "get_field: extracts Status from issue 2"

assert_eq "" "$(get_field "$TRACKER_FILE" "1" "Nonexistent")" \
  "get_field: nonexistent field returns empty"

assert_eq "" "$(get_field "$TRACKER_FILE" "99" "Status")" \
  "get_field: nonexistent issue returns empty"

# =========================================================================
# Test 6: resolve_tracker — picks correct tracker file
# =========================================================================

# Test: workspace with .opencode/known_issues.md with entries
WS1="$TMP/resolve_ws1"
mkdir -p "$WS1/.opencode"
cat > "$WS1/.opencode/known_issues.md" <<'EOF1'
### 1. Local issue
- Status: backlog
EOF1
result="$(WORKSPACE="$WS1" resolve_tracker)"
assert_eq "$WS1/.opencode/known_issues.md" "$result" \
  "resolve_tracker: prefers .opencode/known_issues.md with entries"

# Test: workspace with root known_issues.md with entries (no .opencode)
WS2="$TMP/resolve_ws2"
mkdir -p "$WS2"
cat > "$WS2/known_issues.md" <<'EOF2'
### 1. Root issue
- Status: backlog
EOF2
result="$(WORKSPACE="$WS2" resolve_tracker)"
assert_eq "$WS2/known_issues.md" "$result" \
  "resolve_tracker: falls back to root known_issues.md"

# Test: workspace with empty .opencode/known_issues.md but root has entries
WS3="$TMP/resolve_ws3"
mkdir -p "$WS3/.opencode"
cat > "$WS3/.opencode/known_issues.md" <<'EOF3'
# Known Issues
(No entries)
EOF3
cat > "$WS3/known_issues.md" <<'EOF4'
### 1. Root entry
- Status: ready
EOF4
result="$(WORKSPACE="$WS3" resolve_tracker)"
assert_eq "$WS3/known_issues.md" "$result" \
  "resolve_tracker: empty .opencode tracker falls back to root with entries"

# Test: no tracker at all
WS4="$TMP/resolve_ws4"
mkdir -p "$WS4"
result="$(WORKSPACE="$WS4" resolve_tracker)"
assert_eq "" "$result" \
  "resolve_tracker: no tracker returns empty"

# =========================================================================
# Test 7: run_develop — constructs correct headless argv
# =========================================================================
cat > "$MOCK_BIN/opencode" <<'OPENCODE_MOCK'
#!/usr/bin/env bash
echo "ARGS: $*" > /tmp/opencode_mock_args.txt
exit 0
OPENCODE_MOCK
chmod +x "$MOCK_BIN/opencode"

setup_env "$TMP/ws_dev" "test-user" "" "5"
WORKSPACE="$TMP/ws_dev"
OPENCODE_BIN="opencode"
AIBOT_MODEL="test-model-123"
DRY_RUN="0"  # Not dry run — actually invoke mock opencode

run_develop "7"
MOCK_ARGS="$(cat /tmp/opencode_mock_args.txt 2>/dev/null || echo "")"
assert_eq "ARGS: run --auto --dir $TMP/ws_dev --model test-model-123 --command ocf:develop 7" \
  "$MOCK_ARGS" \
  "run_develop: correct headless argv construction"

rm -f /tmp/opencode_mock_args.txt

# =========================================================================
# Test 8: has_token — token inside <pre>/<code> with attributes
# =========================================================================
assert_eq "1" "$(has_token '<pre class="code">@aibot:develop</pre>'; echo $?)" \
  "has_token: token in pre with attributes rejected"

assert_eq "1" "$(has_token '<code class="highlight">@aibot:develop</code>'; echo $?)" \
  "has_token: token in code with attributes rejected"

# =========================================================================
# Test 9: repo_in_allowlist — space-separated AIBOT_ALLOWLIST
# =========================================================================
AIBOT_ALLOWLIST="owner/repo1 owner/repo2 owner/repo3"
AIBOT_REPOS_FILE=""
assert_eq "0" "$(repo_in_allowlist "owner/repo2"; echo $?)" \
  "repo_in_allowlist: space-separated list match"

# =========================================================================
# Test 10: is_aibot_author — multiple AIBOT_AUTHORS entries
# =========================================================================
AIBOT_AUTHORS="bot1,bot2,bot3"
assert_eq "0" "$(is_aibot_author "bot2"; echo $?)" \
  "is_aibot_author: middle entry in multi-author list"

AIBOT_AUTHORS="bot1,bot2,bot3"
assert_eq "1" "$(is_aibot_author "bot4"; echo $?)" \
  "is_aibot_author: entry not in multi-author list"

# =========================================================================
# Test 11: has_token — multiple code fences, token between them
# =========================================================================
assert_eq "0" "$(has_token "$(printf '```\nsome code\n```\n@aibot:develop\n```\nmore code\n```')"; echo $?)" \
  "has_token: token between code fences (outside fence)"

# =========================================================================
# Test 12: find_tracked_issue — duplicate Remote picks first match
# =========================================================================
TRACKER_MULTI="$TMP/tracker_multi.md"
cat > "$TRACKER_MULTI" <<'MULTI_EOF'
### 10. Issue with remote 100
- Status: backlog
- Remote: #100

### 11. Issue with remote 200
- Status: ready
- Remote: #200

### 12. Issue with remote 100 (duplicate remote)
- Status: in-progress
- Remote: #100
MULTI_EOF

result="$(find_tracked_issue "$TRACKER_MULTI" "100")"
assert_eq "10" "$result" \
  "find_tracked_issue: returns first match for duplicate Remote"

result="$(find_tracked_issue "$TRACKER_MULTI" "200")"
assert_eq "11" "$result" \
  "find_tracked_issue: returns correct match for Remote #200"

# =========================================================================
# Test 13: get_field — field with colon in value
# =========================================================================
TRACKER_COLON="$TMP/tracker_colon.md"
cat > "$TRACKER_COLON" <<'COLON_EOF'
### 5. Issue
- Status: ready
- Description: Has colon: inside
- PR: #42
COLON_EOF

assert_eq "Has colon: inside" "$(get_field "$TRACKER_COLON" "5" "Description")" \
  "get_field: preserves colon in value"

assert_eq "#42" "$(get_field "$TRACKER_COLON" "5" "PR")" \
  "get_field: extracts PR field"

# =========================================================================
# Test 14: resolve_tracker — .opencode empty, root has entries
# =========================================================================
WS5="$TMP/resolve_ws5"
mkdir -p "$WS5/.opencode"
touch "$WS5/.opencode/known_issues.md"
cat > "$WS5/known_issues.md" <<'EOF5'
### 1. Root entry
- Status: backlog
EOF5
result="$(WORKSPACE="$WS5" resolve_tracker)"
assert_eq "$WS5/known_issues.md" "$result" \
  "resolve_tracker: empty .opencode file falls back to root"

# =========================================================================
# Test 15: message_template — extracts correct sections
# =========================================================================
AIBOT_CONFIG_DIR="$TMP"
CONFIG_ROOT="$TMP"

for key in success already-in-progress already-resolved not-tracked cannot-develop; do
  msg="$(message_template "$key" 2>/dev/null || echo "FAIL")"
  if [[ "$msg" != "FAIL" && -n "$msg" ]]; then
    t_ok "message_template: key '$key' found"
  else
    t_fail "message_template: key '$key' not found"
  fi
done

t_finish
