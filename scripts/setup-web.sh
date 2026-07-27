#!/usr/bin/env bash
set -euo pipefail

# setup-web.sh — Install or update the opencode systemd web service
#
# Usage:
#   ./setup-web.sh                    # interactive (asks for user/binary path)
#   ./setup-web.sh --user william-pereira --bin /home/william-pereira/.opencode/bin/opencode
#   ./setup-web.sh --uninstall        # remove the service

OPENCODE_BIN="${OPENCODE_BIN:-}"
SERVICE_USER="${SERVICE_USER:-}"
SERVICE_NAME="opencode"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) SERVICE_USER="$2"; shift 2 ;;
    --bin)  OPENCODE_BIN="$2"; shift 2 ;;
    --uninstall)
      echo "Removing service..."
      sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
      sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
      sudo rm -f "$SERVICE_FILE"
      sudo systemctl daemon-reload
      echo "Service removed."
      exit 0
      ;;
    --help)
      echo "Usage: $0 [--user <user>] [--bin <path>] [--uninstall]"
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
  read -r -p "System user to run opencode: " SERVICE_USER
fi

if [[ -z "$OPENCODE_BIN" ]]; then
  OPENCODE_BIN="$(which opencode 2>/dev/null || echo "/home/$SERVICE_USER/.opencode/bin/opencode")"
  if [[ ! -x "$OPENCODE_BIN" ]]; then
    read -r -p "Path to opencode binary: " OPENCODE_BIN
  fi
fi

echo "Installing/updating service..."
echo "  User:   $SERVICE_USER"
echo "  Binary: $OPENCODE_BIN"
echo "  Target: $SERVICE_FILE"

# Create service file from template
sed -e "s|__OPENCODE_BIN__|$OPENCODE_BIN|g" \
    -e "s|__USER__|$SERVICE_USER|g" \
    "$TEMPLATE_DIR/opencode.service" | sudo tee "$SERVICE_FILE" > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

echo "Done. Service status:"
sudo systemctl status "$SERVICE_NAME" --no-pager
