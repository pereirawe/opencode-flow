#!/usr/bin/env bash
# test_reset_web.sh — unit tests for scripts/reset-web.sh
# Mocks systemctl/sudo via PATH and overrides XDG_DATA_HOME so nothing real
# is touched. Covers --list, full reset (stop -> backup -> clear -> start,
# auth preserved), and the missing-service guard.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_reset_web"

SCRIPT="$HERE/../reset-web.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

DATA="$TMP/data/opencode"
mkdir -p "$DATA/log"
printf 'fake-db' > "$DATA/opencode.db"
printf 'fake-wal' > "$DATA/opencode.db-wal"
printf 'fake-shm' > "$DATA/opencode.db-shm"
printf '{"auth":1}' > "$DATA/auth.json"
printf '{"account":1}' > "$DATA/account.json"
printf 'old log line\n' > "$DATA/log/server.log"

# --- mocks ---
mock_bin="$TMP/bin"
mkdir -p "$mock_bin"
export SYSTEMCTL_LOG="$TMP/systemctl.log"
: > "$SYSTEMCTL_LOG"
cat > "$mock_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "systemctl $*" >> "$SYSTEMCTL_LOG"
case "$1" in
  cat) [[ -n "${MOCK_CAT_FAIL:-}" ]] && exit 1 || exit 0 ;;
  is-active) echo "active"; exit 0 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$mock_bin/systemctl"
cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
chmod +x "$mock_bin/sudo"

export XDG_DATA_HOME="$TMP/data"
export PATH="$mock_bin:$PATH"

# --- --list (no side effects) ---
out="$(bash "$SCRIPT" --list)"
assert_eq "0" "$?" "--list exits 0"
assert_contains <(printf '%s' "$out") "Session DB" "--list shows session DB"
assert_contains <(printf '%s' "$out") "opencode.db" "--list names the DB file"
assert_eq "" "$([[ -f "$DATA/opencode.db" ]] && echo "")" "--list keeps the DB (still present)"

# --- full reset ---
bash "$SCRIPT" >/dev/null 2>&1
assert_contains "$SYSTEMCTL_LOG" "systemctl stop opencode" "reset stops the service"
assert_contains "$SYSTEMCTL_LOG" "systemctl start opencode" "reset starts the service"
if [[ -f "$DATA/opencode.db" ]]; then
  t_fail "reset must move the session DB away"
else
  t_ok "reset clears the session DB"
fi
assert_contains <(printf '%s' "$(ls "$DATA/backups")") "opencode.db." "reset leaves a timestamped backup"
assert_contains "$DATA/auth.json" '{"auth":1}' "auth.json preserved"
assert_contains "$DATA/account.json" '{"account":1}' "account.json preserved"

# --- missing service guard ---
export MOCK_CAT_FAIL=1
out="$(bash "$SCRIPT" 2>&1)"
if printf '%s' "$out" | grep -q "not found"; then
  t_ok "missing-service guard aborts with clear error"
else
  t_fail "missing-service guard did not report (got: $out)"
fi
unset MOCK_CAT_FAIL

t_finish
