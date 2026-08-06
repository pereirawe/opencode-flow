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
DB="$DATA_DIR/opencode.db"
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

db_exists() { [[ -f "$DB" ]]; }

if [[ "$MODE" == "list" ]]; then
  echo "[reset-web] Service:  $SERVICE_NAME ($(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo 'unknown'))"
  echo "[reset-web] Data dir: $DATA_DIR"
  if db_exists; then
    echo "[reset-web] Session DB: $DB ($(du -sh "$DB" | cut -f1))"
  else
    echo "[reset-web] Session DB: not found (nothing to clear)"
  fi
  echo "[reset-web] Auth (preserved): $DATA_DIR/auth.json, $DATA_DIR/account.json"
  exit 0
fi

# Guard: the service must exist — do not create a fresh DB for a missing unit.
if ! systemctl cat "$SERVICE_NAME" >/dev/null 2>&1; then
  echo "[reset-web] ERROR: service '$SERVICE_NAME' not found — run scripts/setup-web.sh first" >&2
  exit 1
fi

echo "[reset-web] Stopping service $SERVICE_NAME..."
svc stop "$SERVICE_NAME"

mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
moved=0
for f in "$DB" "$DB-wal" "$DB-shm"; do
  if [[ -f "$f" ]]; then
    mv "$f" "$BACKUP_DIR/$(basename "$f").$TS"
    echo "[reset-web] backed up $(basename "$f") → backups/"
    moved=1
  fi
done
if [[ "$moved" -eq 0 ]]; then
  echo "[reset-web] no session DB files to clear"
fi

if [[ -d "$LOG_DIR" ]]; then
  rm -f "$LOG_DIR"/* 2>/dev/null || true
  echo "[reset-web] cleared log dir"
fi

echo "[reset-web] Starting service $SERVICE_NAME..."
svc start "$SERVICE_NAME"

echo "[reset-web] done. Service state: $(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo unknown)"
