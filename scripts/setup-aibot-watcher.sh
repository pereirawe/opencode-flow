#!/usr/bin/env bash
set -euo pipefail

# setup-aibot-watcher.sh — Install or uninstall the aibot watcher systemd
# timer + service (issue #39).
#
# Usage:
#   ./setup-aibot-watcher.sh                        # interactive defaults
#   ./setup-aibot-watcher.sh --user william_pereira --bin /home/william_pereira/.opencode/bin/opencode
#   ./setup-aibot-watcher.sh --uninstall
#
# The watcher polls remote issue comments for `@aibot:develop` and triggers
# the continuous development pipeline via the opencode web server. It runs
# under the same user as the opencode web service (BR 12).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="aibot-watcher"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}.timer"

SERVICE_USER=""
OPENCODE_BIN=""
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) SERVICE_USER="$2"; shift 2 ;;
    --bin)  OPENCODE_BIN="$2"; shift 2 ;;
    --uninstall)
      echo "Removing aibot watcher..."
      sudo systemctl stop "$SERVICE_NAME.timer" 2>/dev/null || true
      sudo systemctl disable "$SERVICE_NAME.timer" 2>/dev/null || true
      sudo systemctl stop "$SERVICE_NAME.service" 2>/dev/null || true
      sudo systemctl disable "$SERVICE_NAME.service" 2>/dev/null || true
      sudo rm -f "$SERVICE_FILE" "$TIMER_FILE"
      sudo systemctl daemon-reload
      echo "Watcher removed."
      exit 0
      ;;
    --help)
      echo "Usage: $0 [--user <user>] [--bin <opencode-binary>] [--uninstall]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Detect defaults
if [[ -z "$SERVICE_USER" ]]; then
  SERVICE_USER="${SUDO_USER:-$USER}"
fi
if [[ -z "$SERVICE_USER" ]]; then
  read -r -p "System user to run the aibot watcher: " SERVICE_USER
fi

if [[ -z "$OPENCODE_BIN" ]]; then
  OPENCODE_BIN="$(which opencode 2>/dev/null || echo "/home/$SERVICE_USER/.opencode/bin/opencode")"
  if [[ ! -x "$OPENCODE_BIN" ]]; then
    read -r -p "Path to opencode binary: " OPENCODE_BIN
  fi
fi

if [[ ! -d "$SCRIPT_DIR" ]]; then
  echo "ERROR: watcher scripts dir not found: $SCRIPT_DIR"
  exit 1
fi

echo "Installing aibot watcher..."
echo "  User:   $SERVICE_USER"
echo "  Binary: $OPENCODE_BIN"
echo "  Script: $SCRIPT_DIR/aibot-watcher.sh"

# Render the service from the template (timer needs no substitution)
sed -e "s|__USER__|$SERVICE_USER|g" \
    -e "s|__SCRIPT__|$SCRIPT_DIR|g" \
    -e "s|__OPENCODE_BIN__|$OPENCODE_BIN|g" \
    "$SCRIPT_DIR/aibot-watcher.service" | sudo tee "$SERVICE_FILE" > /dev/null

sudo cp "$SCRIPT_DIR/aibot-watcher.timer" "$TIMER_FILE"

# Validate rendered units before activating (Runtime m4)
if command -v systemd-analyze >/dev/null 2>&1; then
  if ! systemd-analyze verify "$SERVICE_FILE" "$TIMER_FILE"; then
    echo "ERROR: systemd-analyze verify failed on rendered units."
    echo "  Remove the invalid units: sudo rm -f $SERVICE_FILE $TIMER_FILE"
    exit 1
  fi
fi

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME.timer"
sudo systemctl start "$SERVICE_NAME.timer"

echo "Done. Timer status:"
sudo systemctl list-timers "$SERVICE_NAME" --no-pager
