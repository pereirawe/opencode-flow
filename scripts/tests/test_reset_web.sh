#!/usr/bin/env bash
# test_reset_web.sh — unit tests for scripts/reset-web.sh
# Mocks systemctl/sudo via PATH (stateful: active/inactive) and overrides
# XDG_DATA_HOME per scenario so nothing real is touched. Covers --list, full
# reset (stop -> backup -> clear -> start, auth + WAL/SHM handling), the
# stop-failure abort, the missing-service guard, and the no-DB branch.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_reset_web"

SCRIPT="$HERE/../reset-web.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- mocks (stateful) ---
mock_bin="$TMP/bin"
mkdir -p "$mock_bin"
export SYSTEMCTL_LOG="$TMP/systemctl.log"
export STATE_FILE="$TMP/service-state"
echo active > "$STATE_FILE"
: > "$SYSTEMCTL_LOG"
cat > "$mock_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "systemctl $*" >> "$SYSTEMCTL_LOG"
case "$1" in
  cat) [[ -n "${MOCK_CAT_FAIL:-}" ]] && exit 1 || exit 0 ;;
  stop)
    [[ -n "${MOCK_STOP_FAIL:-}" ]] && exit 1
    echo inactive > "$STATE_FILE"; exit 0 ;;
  start) echo active > "$STATE_FILE"; exit 0 ;;
  is-active)
    st="$(cat "$STATE_FILE")"; echo "$st"
    [[ "$st" == "active" ]] ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$mock_bin/systemctl"
cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
chmod +x "$mock_bin/sudo"

export PATH="$mock_bin:$PATH"

make_data() { # <dir> [with_db]
  local d="$1" with_db="${2:-0}"
  mkdir -p "$d/opencode/log"
  if [[ "$with_db" == "1" ]]; then
    printf 'fake-db'   > "$d/opencode/opencode.db"
    printf 'fake-wal'  > "$d/opencode/opencode.db-wal"
    printf 'fake-shm'  > "$d/opencode/opencode.db-shm"
    printf 'old log line\n' > "$d/opencode/log/server.log"
  fi
  printf '{"auth":1}'     > "$d/opencode/auth.json"
  printf '{"account":1}'  > "$d/opencode/account.json"
}

run() { # <data-parent> <args...>
  local parent="$1"; shift
  XDG_DATA_HOME="$parent" bash "$SCRIPT" "$@"
}

# --- --list (no side effects) ---
D1="$TMP/d1"; make_data "$D1" 1
out="$(run "$D1" --list)"
assert_eq "0" "$?" "--list exits 0"
assert_contains <(printf '%s' "$out") "Session DB" "--list shows session DB"
assert_contains <(printf '%s' "$out") "opencode.db" "--list names the DB files"
assert_eq "1" "$([[ -f "$D1/opencode/opencode.db" ]] && echo 1)" "--list keeps the DB (still present)"

# --- full reset: stop -> backup (db+wal+shm) -> clear logs -> start; auth kept ---
D2="$TMP/d2"; make_data "$D2" 1
run "$D2" >/dev/null 2>&1
assert_contains "$SYSTEMCTL_LOG" "systemctl stop opencode" "reset stops the service"
assert_contains "$SYSTEMCTL_LOG" "systemctl start opencode" "reset starts the service"
assert_eq "1" "$([[ -f "$D2/opencode/opencode.db" ]] && echo 0 || echo 1)" "reset clears the main DB"
assert_eq "1" "$([[ -f "$D2/opencode/opencode.db-wal" ]] && echo 0 || echo 1)" "reset clears the WAL file"
assert_eq "1" "$([[ -f "$D2/opencode/opencode.db-shm" ]] && echo 0 || echo 1)" "reset clears the SHM file"
backups="$(ls "$D2/opencode/backups")"
assert_contains <(printf '%s' "$backups") "opencode.db."      "backup has main DB"
assert_contains <(printf '%s' "$backups") "opencode.db-wal."  "backup has WAL file"
assert_contains <(printf '%s' "$backups") "opencode.db-shm."  "backup has SHM file"
assert_contains "$D2/opencode/auth.json" '{"auth":1}' "auth.json preserved"
assert_contains "$D2/opencode/account.json" '{"account":1}' "account.json preserved"
assert_eq "1" "$([[ -f "$D2/opencode/log/server.log" ]] && echo 0 || echo 1)" "reset clears the log dir"

# --- stop failure: must abort before moving the DB ---
D3="$TMP/d3"; make_data "$D3" 1
export MOCK_STOP_FAIL=1
out="$(run "$D3" 2>&1)"; rc=$?
unset MOCK_STOP_FAIL
assert_eq "1" "$([[ "$rc" -ne 0 ]] && echo 1)" "stop failure exits non-zero"
assert_eq "1" "$([[ -f "$D3/opencode/opencode.db" ]] && echo 1 || echo 0)" "stop failure leaves the DB untouched"

# --- no session DB files branch ---
D4="$TMP/d4"; make_data "$D4" 0
out="$(run "$D4")"
assert_contains <(printf '%s' "$out") "no session DB files to clear" "no-DB branch reported"

# --- missing service guard ---
D5="$TMP/d5"; make_data "$D5" 1
export MOCK_CAT_FAIL=1
out="$(run "$D5" 2>&1)"
unset MOCK_CAT_FAIL
if printf '%s' "$out" | grep -q "not found"; then
  t_ok "missing-service guard aborts with clear error"
else
  t_fail "missing-service guard did not report (got: $out)"
fi
assert_eq "1" "$([[ -f "$D5/opencode/opencode.db" ]] && echo 1)" "missing-service guard leaves DB untouched"

t_finish
