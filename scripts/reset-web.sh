#!/usr/bin/env bash
set -euo pipefail

# reset-web.sh — stop the opencode web systemd service, clear accumulated
# session state (the SQLite session DB), and restart it.
#
# Safe by design:
#   - auth.json / account.json are preserved (they live beside, not inside,
#     the session DB)
#   - the session DB files are moved to a timestamped backup (rollback-safe)
#   - the service must already exist — the script refuses to run blind and
#     create a fresh DB where there was no service
#
# Usage:
#   reset-web.sh                # stop -> backup session DB -> clear logs -> start
#   reset-web.sh --list         # show service/data-dir/session-DB size, no changes
#   reset-web.sh --dry-run      # same as --list
#   reset-web.sh --help
#
# Env overrides (for tests):
#   XDG_DATA_HOME        — base for the data dir (default $HOME/.local/share)
#   OPENCODE_WEB_SERVICE — systemd unit name (default opencode)
#   RESET_SUDO           — sudo wrapper (default: sudo)

SERVICE_NAME="${OPENCODE_WEB_SERVICE:-opencode}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
BACKUP_DIR="$DATA_DIR/backups"
LOG_DIR="$DATA_DIR/log"
MODE="full"

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list|--dry-run) MODE="list"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

svc() { ${RESET_SUDO:-sudo} systemctl "$@"; }

db_exists() { compgen -G "$DATA_DIR/opencode.db*" >/dev/null; }

if [[ "$MODE" == "list" ]]; then
  echo "[reset-web] Service:  $SERVICE_NAME ($(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo 'unknown'))"
  echo "[reset-web] Data dir: $DATA_DIR"
  if db_exists; then
    echo "[reset-web] Session DB: $DATA_DIR/opencode.db* ($(du -ch "$DATA_DIR"/opencode.db* 2>/dev/null | tail -1 | cut -f1))"
  else
    echo "[reset-web] Session DB: not found (nothing to clear)"
  fi
  echo "[reset-web] Auth (preserved): $DATA_DIR/auth.json, $DATA_DIR/account.json"
  exit 0
fi

# Root guard: as root, $HOME is /root and DATA_DIR would resolve to the wrong
# place — a silent no-op that still restarts the live service. Refuse to run
# as root; use sudo only for the systemctl calls.
if [[ "$EUID" -eq 0 ]]; then
  echo "[reset-web] ERROR: run as the service user (e.g. william_pereira), not root — the data dir is \$HOME-based" >&2
  exit 1
fi

# Guard: the service must exist — do not create a fresh DB for a missing unit.
if ! svc cat "$SERVICE_NAME" >/dev/null 2>&1; then
  echo "[reset-web] ERROR: service '$SERVICE_NAME' not found — run scripts/setup-web.sh first" >&2
  exit 1
fi

echo "[reset-web] Stopping service $SERVICE_NAME..."
svc stop "$SERVICE_NAME"

# Never move a live DB: abort if the service is still active.
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "[reset-web] ERROR: service still active after stop — aborting before clearing the session DB" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)-$$"
moved=0
for f in "$DATA_DIR"/opencode.db*; do
  [[ -f "$f" ]] || continue
  mv "$f" "$BACKUP_DIR/$(basename "$f").$TS"
  echo "[reset-web] backed up $(basename "$f") → backups/"
  moved=1
done
if [[ "$moved" -eq 0 ]]; then
  echo "[reset-web] no session DB files to clear"
fi

if [[ -d "$LOG_DIR" ]]; then
  find "$LOG_DIR" -maxdepth 1 -type f -delete 2>/dev/null || true
  echo "[reset-web] cleared log dir"
fi

echo "[reset-web] Starting service $SERVICE_NAME..."
svc start "$SERVICE_NAME"

echo "[reset-web] done. Service state: $(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo unknown)"
