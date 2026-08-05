#!/usr/bin/env bash
# test_watcher_unit.sh — unit tests for aibot-watcher.sh helpers:
# has_token (BR 3 / AC 15), find_tracked_issue (BR 4), get_field (BR 5/8),
# resolve_tracker (BR 4 / CWD quirk), is_aibot_author (BR 17 / AC 14),
# slug/cursor state files (BR 15).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_watcher_unit"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Isolate the watcher's config from the real repo.
export AIBOT_CONFIG_DIR="$TMP/config"
export AIBOT_STATE_DIR="$TMP/config/state/aibot"
export AIBOT_REPOS_FILE="$TMP/config/aibot-repos.json"
export AIBOT_WEB_URL="http://up.local"
mkdir -p "$AIBOT_STATE_DIR"

source "$HERE/../aibot-watcher.sh"
set +euo pipefail   # neutralize the watcher's strict options for the harness

# --- has_token (BR 3 / AC 15) ---
assert_cmd_ok()  { local l="$1"; shift; if "$@" >/dev/null 2>&1; then t_ok "$l"; else t_fail "$l"; fi; }
assert_cmd_fail(){ local l="$1"; shift; if "$@" >/dev/null 2>&1; then t_fail "$l"; else t_ok "$l"; fi; }

assert_cmd_ok   "token standalone linha"         has_token "@aibot:develop"
assert_cmd_ok   "token standalone com espacos"   has_token "   @aibot:develop   "
assert_cmd_ok   "token em linha propria multi"   has_token $'algum texto\n@aibot:develop\nmais texto'
assert_cmd_fail "token dentro de code fence"     has_token $'```\n@aibot:develop\n```'
assert_cmd_fail "token em fence com linguagem"   has_token $'```bash\n@aibot:develop\n```'
assert_cmd_fail "token em fence ~~~"             has_token $'~~~\n@aibot:develop\n~~~'
assert_cmd_fail "token em fence sem fechamento"  has_token $'```\n@aibot:develop'
assert_cmd_fail "token em bloco <pre>"           has_token $'<pre>\n@aibot:develop\n</pre>'
assert_cmd_fail "token em bloco <code>"          has_token $'<code>\n@aibot:develop\n</code>'
assert_cmd_fail "token em <pre> com atributo"    has_token $'<pre class="x">\n@aibot:develop\n</pre>'
assert_cmd_fail "token em <pre><code> aninhado"  has_token $'<pre><code>\n@aibot:develop\n</code></pre>'
assert_cmd_fail "token em quoted reply"          has_token $'> @aibot:develop'
assert_cmd_fail "token em texto linkado"         has_token "[@aibot:develop](https://example.com)"
assert_cmd_fail "token no meio de frase"         has_token "veja @aibot:develop por favor"
assert_cmd_fail "body vazio"                     has_token ""
assert_cmd_fail "sem token"                      has_token "comentario comum"

# --- find_tracked_issue (BR 4) ---
cat > "$TMP/tracker.md" <<'EOF'
## Known Issues

### 7. Issue rastreada
- Status: ready
- Type: feat
- Severity: medium
- Report: test
- Remote: #30
- PR: -

### 8. Issue com remote '-' 
- Status: backlog
- Type: chore
- Severity: low
- Report: test
- Remote: -
- PR: -

### 9. Issue com remote espaco
- Status: ready
- Type: feat
- Severity: medium
- Report: test
- Remote: #31 
- PR: -
EOF

assert_eq "7"   "$(find_tracked_issue "$TMP/tracker.md" 30)" "find issue por Remote #30"
assert_eq "9"   "$(find_tracked_issue "$TMP/tracker.md" 31)" "Remote com trailing space é tolerado"
assert_eq ""    "$(find_tracked_issue "$TMP/tracker.md" 999)" "issue não rastreada → vazio"
assert_eq ""    "$(find_tracked_issue "$TMP/missing.md" 30)" "tracker inexistente → vazio"

# --- get_field (BR 5 / BR 8) ---
assert_eq "ready"      "$(get_field "$TMP/tracker.md" 7 "Status")" "get_field Status"
assert_eq "#30"        "$(get_field "$TMP/tracker.md" 7 "Remote")" "get_field Remote"
assert_eq "-"          "$(get_field "$TMP/tracker.md" 7 "PR")"     "get_field PR default -"
assert_eq ""           "$(get_field "$TMP/tracker.md" 7 "Nope")"   "campo ausente → vazio"

# --- resolve_tracker (BR 4 / CWD quirk / Note 1) ---
ws="$TMP/ws-root"
mkdir -p "$ws/.opencode"
cp "$TMP/tracker.md" "$ws/known_issues.md"          # root tracker real
: > "$ws/.opencode/known_issues.md"                  # template vazio
assert_eq "$ws/known_issues.md" "$(resolve_tracker "$ws")" "fallback root quando .opencode é template vazio"

ws="$TMP/ws-dot"
mkdir -p "$ws/.opencode"
cp "$TMP/tracker.md" "$ws/.opencode/known_issues.md" # .opencode real
cp "$TMP/tracker.md" "$ws/known_issues.md"
assert_eq "$ws/.opencode/known_issues.md" "$(resolve_tracker "$ws")" ".opencode com entries tem precedência"

ws="$TMP/ws-none"
mkdir -p "$ws/.opencode"
: > "$ws/.opencode/known_issues.md"
assert_eq "$ws/.opencode/known_issues.md" "$(resolve_tracker "$ws")" "fallback final: template .opencode existente"

# --- is_aibot_author (BR 17 / AC 14) ---
AIBOT_AUTHORS="alice,carol"
assert_cmd_ok   "autor *[bot] é aibot"        is_aibot_author "github-actions[bot]"
assert_cmd_ok   "autor na lista AIBOT_AUTHORS" is_aibot_author "carol"
assert_cmd_ok   "autor = identidade local"    is_aibot_author "william" "william"
assert_cmd_fail "autor comum não é aibot"     is_aibot_author "bob" "william"
assert_cmd_fail "autor vazio"                 is_aibot_author "" "william"

# --- slug / cursor state (BR 15) ---
assert_eq "test_repo" "$(slug "test/repo")"   "slug converte / e : para _"
assert_eq "group_project" "$(slug "group/project")" "slug gitlab path"
assert_eq "" "$(read_cursor "test/repo")"      "cursor inicial vazio"
write_cursor "test/repo" "42"
assert_eq "42" "$(read_cursor "test/repo")"    "write/read cursor round-trip"
assert_eq "$AIBOT_STATE_DIR/test_repo.cursor"  "$(cursor_file "test/repo")" "cursor file path"
assert_eq "$AIBOT_STATE_DIR/test_repo.lock"    "$(lock_file "test/repo")"   "lock file path"

t_finish
