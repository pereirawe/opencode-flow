#!/usr/bin/env bash
set -euo pipefail

# setup-web.sh — Install or update the opencode systemd web service
#
# Usage:
#   ./setup-web.sh                    # interactive (asks for user/binary path)
#   ./setup-web.sh --user william_pereira --bin /home/william_pereira/.opencode/bin/opencode
#   ./setup-web.sh --with-nginx       # install service AND nginx reverse proxy with HTTPS
#   ./setup-web.sh --user william_pereira --bin /home/william_pereira/.opencode/bin/opencode --with-nginx
#   ./setup-web.sh --uninstall        # remove the service
#   ./setup-web.sh --uninstall --with-nginx  # remove service AND nginx footprint
#
# With --with-nginx, this script also invokes setup-nginx.sh to install a
# mkcert-backed HTTPS reverse proxy (nginx) that exposes the opencode web
# service through https://opencode.local (default). Use --hostname to
# customize the domain.
#
# Requirements for --with-nginx:
#   - mkcert (https://github.com/FiloSottile/mkcert)
#   - nginx (installed automatically via apt/dnf if missing)

OPENCODE_BIN="${OPENCODE_BIN:-}"
SERVICE_USER="${SERVICE_USER:-}"
SERVICE_NAME="opencode"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
WITH_NGINX=false
NGINX_HOSTNAME="opencode.local"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) SERVICE_USER="$2"; shift 2 ;;
    --bin)  OPENCODE_BIN="$2"; shift 2 ;;
    --with-nginx) WITH_NGINX=true; shift ;;
    --hostname) NGINX_HOSTNAME="$2"; shift 2 ;;
    --uninstall)
      echo "Removing service..."
      sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
      sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
      sudo rm -f "$SERVICE_FILE"
      sudo systemctl daemon-reload
      echo "Service removed."

      # Also uninstall nginx if --with-nginx was passed (explicitly or later)
      NGINX_FLAG=false
      for arg in "$@"; do
        [[ "$arg" == "--with-nginx" ]] && NGINX_FLAG=true
      done
      if [[ "$WITH_NGINX" = true ]] || [[ "$NGINX_FLAG" = true ]]; then
        echo "Uninstalling nginx footprint..."
        sudo "$TEMPLATE_DIR/setup-nginx.sh" --uninstall
      fi
      exit 0
      ;;
    --help)
      echo "Usage: $0 [--user <user>] [--bin <path>] [--with-nginx] [--hostname <name>] [--uninstall]"
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

# ── nginx reverse proxy setup ─────────────────────────────────────────────────

if [[ "$WITH_NGINX" = true ]]; then
  echo ""
  echo "Setting up nginx reverse proxy with HTTPS..."
  sudo "$TEMPLATE_DIR/setup-nginx.sh" \
    --hostname "$NGINX_HOSTNAME"
fi
