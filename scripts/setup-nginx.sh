#!/usr/bin/env bash
set -euo pipefail

# setup-nginx.sh — Install/update nginx reverse proxy with HTTPS for opencode web
#
# Usage:
#   ./setup-nginx.sh                           # interactive defaults
#   ./setup-nginx.sh --hostname opencode.local # custom hostname
#   ./setup-nginx.sh --hostname opencode.local --non-interactive  # skip prompts
#   ./setup-nginx.sh --uninstall               # remove opencode nginx footprint
#
# Requirements:
#   - mkcert (https://github.com/FiloSottile/mkcert) — MUST be installed.
#     The script aborts with a clear error if mkcert is not found.
#   - nginx (full) — installed automatically via apt or dnf if missing.
#   - opencode web service running on 127.0.0.1:4096 (via systemd).
#
# What it does:
#   1. Detects OS and installs nginx-full via apt (Debian/Ubuntu) or
#      dnf (RHEL-family) if not already installed.
#   2. Checks mkcert availability — aborts if missing (no self-signed fallback).
#   3. Runs `mkcert -install` to ensure local CA is trusted (preserves CAROOT).
#   4. Selects an available HTTP port: tries 80, then 8080, then 8081, etc.
#      (port 80 is likely occupied by docker on this machine).
#   5. Checks port 443 is free — aborts if occupied.
#   6. Ensures /etc/hosts has <hostname> → 127.0.0.1 (idempotent).
#   7. Generates cert for <hostname>, 127.0.0.1, ::1 into /etc/opencode/certs/.
#   8. Renders nginx-opencode.conf from the template.
#   9. Tests config with nginx -t, reloads nginx.
#  10. Optionally asks about opening firewall ports.
#
# Idempotent: running twice does not duplicate config blocks or /etc/hosts
# entries. Existing nginx vhosts and the docker container on port 80 are
# never touched.

HOSTNAME="opencode.local"
HTTP_PORT=""
MODE="install"
NON_INTERACTIVE=false
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_TEMPLATE="$SCRIPT_DIR/nginx-opencode.conf"
NGINX_CONF_FILE="/etc/nginx/conf.d/opencode.conf"
CERT_DIR="/etc/opencode/certs"

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hostname) HOSTNAME="$2"; shift 2 ;;
    --uninstall) MODE="uninstall"; shift ;;
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# ── helpers ───────────────────────────────────────────────────────────────────

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "[setup-nginx] ERROR: this script requires root (sudo)." >&2
    exit 1
  fi
}

port_in_use() {
  ss -tlnp 2>/dev/null | grep -q ":${1} " || lsof -i ":${1}" >/dev/null 2>&1 || false
}

skip_port() {
  # skip port if it's used by a known docker container (port 80 on this machine)
  # but still treat it as "in use" — we just don't touch it.
  port_in_use "$1"
}

is_nginx_installed() {
  command -v nginx >/dev/null 2>&1
}

# ── uninstall ─────────────────────────────────────────────────────────────────

if [[ "$MODE" == "uninstall" ]]; then
  require_root
  echo "[setup-nginx] Uninstalling opencode nginx footprint..."

  if [[ -f "$NGINX_CONF_FILE" ]]; then
    rm -f "$NGINX_CONF_FILE"
    echo "[setup-nginx] removed $NGINX_CONF_FILE"
  else
    echo "[setup-nginx] $NGINX_CONF_FILE already removed (skip)"
  fi

  if [[ -d "$CERT_DIR" ]]; then
    rm -rf "$CERT_DIR"
    echo "[setup-nginx] removed $CERT_DIR"
  else
    echo "[setup-nginx] $CERT_DIR already removed (skip)"
  fi

  if is_nginx_installed; then
    nginx -t && systemctl reload nginx || echo "[setup-nginx] WARNING: nginx config test failed — skipping reload"
  fi

  echo "[setup-nginx] Done. Kept: nginx package, other vhosts, mkcert CA, /etc/hosts entry, opencode service."
  exit 0
fi

# ── install ───────────────────────────────────────────────────────────────────

require_root

echo "[setup-nginx] opencode nginx reverse proxy setup"
echo "[setup-nginx] Hostname: $HOSTNAME"

# ── 1. Check mkcert ───────────────────────────────────────────────────────────

if ! command -v mkcert >/dev/null 2>&1; then
  echo "[setup-nginx] ERROR: mkcert is not installed." >&2
  echo "[setup-nginx] Install mkcert and try again:" >&2
  echo "[setup-nginx]   https://github.com/FiloSottile/mkcert#installation" >&2
  echo "[setup-nginx] On Ubuntu/Debian:" >&2
  echo "[setup-nginx]   sudo apt install mkcert" >&2
  echo "[setup-nginx] On Fedora/RHEL:" >&2
  echo "[setup-nginx]   sudo dnf install mkcert" >&2
  exit 1
fi

echo "[setup-nginx] mkcert found at $(which mkcert)"

# ── 2. Install nginx ──────────────────────────────────────────────────────────

if ! is_nginx_installed; then
  echo "[setup-nginx] nginx not found — installing..."
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      debian|ubuntu|linuxmint|pop|elementary|zorin)
        apt-get update -qq && apt-get install -y -qq nginx
        ;;
      fedora|rhel|centos|rocky|almalinux|ol|amzn)
        dnf install -y nginx
        ;;
      *)
        echo "[setup-nginx] ERROR: unsupported OS '$ID'. Install nginx manually and re-run." >&2
        exit 1
        ;;
    esac
  else
    echo "[setup-nginx] ERROR: cannot detect OS (/etc/os-release missing). Install nginx manually and re-run." >&2
    exit 1
  fi
  echo "[setup-nginx] nginx installed."
else
  echo "[setup-nginx] nginx already installed: $(nginx -v 2>&1)"
fi

# ── 3. Select HTTP port ───────────────────────────────────────────────────────

# Try 80 first, then 8080, 8081, ...
for port in 80 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8091 8092 8093 8094 8095 8096 8097 8098 8099; do
  if ! skip_port "$port"; then
    HTTP_PORT="$port"
    break
  fi
done

if [[ -z "$HTTP_PORT" ]]; then
  echo "[setup-nginx] ERROR: no available HTTP port found (tried 80, 8080–8099)." >&2
  exit 1
fi

echo "[setup-nginx] HTTP port selected: $HTTP_PORT ($(skip_port "$HTTP_PORT" && echo 'in use' || echo 'free'))"
echo "[setup-nginx] HTTPS port: 443"

# ── 4. Check port 443 ─────────────────────────────────────────────────────────

if skip_port 443; then
  echo "[setup-nginx] ERROR: port 443 is in use. Cannot bind HTTPS." >&2
  echo "[setup-nginx] Free port 443 and re-run, or check: sudo ss -tlnp | grep 443" >&2
  exit 1
fi

echo "[setup-nginx] port 443 is free."

# ── 5. /etc/hosts ─────────────────────────────────────────────────────────────

if grep -qE "^127\.0\.0\.1\s+.*\<${HOSTNAME}\>" /etc/hosts 2>/dev/null; then
  echo "[setup-nginx] /etc/hosts already has $HOSTNAME → 127.0.0.1 (skip)"
else
  echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
  echo "[setup-nginx] added $HOSTNAME → 127.0.0.1 to /etc/hosts"
fi

# ── 6. Generate certs ─────────────────────────────────────────────────────────

mkdir -p "$CERT_DIR"

if [[ -f "$CERT_DIR/${HOSTNAME}.pem" ]] && [[ -f "$CERT_DIR/${HOSTNAME}-key.pem" ]]; then
  echo "[setup-nginx] cert already exists for $HOSTNAME (skip)"
else
  echo "[setup-nginx] generating mkcert cert for $HOSTNAME (127.0.0.1, ::1)..."
  mkcert -install >/dev/null 2>&1 || true
  mkcert -cert-file "$CERT_DIR/${HOSTNAME}.pem" \
         -key-file  "$CERT_DIR/${HOSTNAME}-key.pem" \
         "$HOSTNAME" 127.0.0.1 ::1
  chmod 644 "$CERT_DIR/${HOSTNAME}.pem"
  chmod 640 "$CERT_DIR/${HOSTNAME}-key.pem"
  echo "[setup-nginx] cert generated."
fi

# ── 7. Render nginx config ────────────────────────────────────────────────────

RENDERED_CONF="/tmp/opencode-nginx-rendered.conf"

sed -e "s|{HTTP_PORT}|$HTTP_PORT|g" \
    -e "s|{HOSTNAME}|$HOSTNAME|g" \
    "$CONF_TEMPLATE" > "$RENDERED_CONF"

# Idempotency: only write if content differs
if [[ -f "$NGINX_CONF_FILE" ]]; then
  if cmp -s "$RENDERED_CONF" "$NGINX_CONF_FILE"; then
    echo "[setup-nginx] nginx config unchanged (skip)"
    rm -f "$RENDERED_CONF"
  else
    cp "$RENDERED_CONF" "$NGINX_CONF_FILE"
    echo "[setup-nginx] nginx config updated."
  fi
else
  cp "$RENDERED_CONF" "$NGINX_CONF_FILE"
  echo "[setup-nginx] nginx config written to $NGINX_CONF_FILE"
fi

# ── 8. Test & reload ──────────────────────────────────────────────────────────

echo "[setup-nginx] testing nginx config..."
if nginx -t 2>&1; then
  echo "[setup-nginx] config OK — reloading nginx..."
  systemctl reload nginx
  echo "[setup-nginx] nginx reloaded."
else
  echo "[setup-nginx] ERROR: nginx -t failed — config was NOT applied." >&2
  echo "[setup-nginx] Config file: $NGINX_CONF_FILE" >&2
  exit 1
fi

# ── 9. Firewall prompt ────────────────────────────────────────────────────────

detect_firewall() {
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "ufw"
  elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    echo "firewalld"
  elif command -v iptables >/dev/null 2>&1; then
    echo "iptables"
  else
    echo "none"
  fi
}

FW="$(detect_firewall)"

if [[ "$FW" != "none" ]] && [[ "$NON_INTERACTIVE" != "true" ]]; then
  echo ""
  echo "[setup-nginx] Firewall detected: $FW"
  echo "[setup-nginx] Open ports $HTTP_PORT (HTTP) and 443 (HTTPS) in $FW?"
  read -r -p "[setup-nginx] (y/N) " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    case "$FW" in
      ufw)
        ufw allow "$HTTP_PORT"/tcp
        ufw allow 443/tcp
        echo "[setup-nginx] opened ports $HTTP_PORT, 443 via ufw"
        ;;
      firewalld)
        firewall-cmd --add-port="${HTTP_PORT}"/tcp --permanent
        firewall-cmd --add-port=443/tcp --permanent
        firewall-cmd --reload
        echo "[setup-nginx] opened ports $HTTP_PORT, 443 via firewalld"
        ;;
      iptables)
        iptables -A INPUT -p tcp --dport "$HTTP_PORT" -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT
        echo "[setup-nginx] opened ports $HTTP_PORT, 443 via iptables (runtime-only, not saved)"
        echo "[setup-nginx] WARNING: iptables rules are not persisted across reboots. Use iptables-save or your distro's save mechanism."
        ;;
    esac
  else
    echo "[setup-nginx] firewall ports NOT opened — you'll need to open them manually."
    echo "[setup-nginx]   HTTP: $HTTP_PORT, HTTPS: 443"
  fi
elif [[ "$FW" != "none" ]]; then
  echo "[setup-nginx] Non-interactive mode — firewall ports NOT opened."
  echo "[setup-nginx] Open them manually: HTTP $HTTP_PORT, HTTPS 443 ($FW)"
elif [[ "$FW" == "none" ]]; then
  echo "[setup-nginx] No active firewall detected."
fi

# ── 10. Summary ───────────────────────────────────────────────────────────────

echo ""
echo "[setup-nginx] ✓ Setup complete."
echo "[setup-nginx]   Hostname: $HOSTNAME"
echo "[setup-nginx]   HTTP:     http://$HOSTNAME:$HTTP_PORT → 301 → https://$HOSTNAME"
echo "[setup-nginx]   HTTPS:    https://$HOSTNAME"
echo "[setup-nginx]   Backend:  http://127.0.0.1:4096 (opencode web)"
echo "[setup-nginx]   Config:   $NGINX_CONF_FILE"
echo "[setup-nginx]   Certs:    $CERT_DIR"
echo ""
echo "[setup-nginx] Access:"
echo "[setup-nginx]   curl -sI http://$HOSTNAME:$HTTP_PORT/"
echo "[setup-nginx]   curl --cacert \"\$(mkcert -CAROOT)/rootCA.pem\" https://$HOSTNAME/"
