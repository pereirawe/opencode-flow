#!/usr/bin/env bash
# OpenCode Config — Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/refs/heads/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/main/install.sh | bash -s -- --repo=https://github.com/user/repo --branch=v1.0.0
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/pereirawe/opencode-flow}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/opencode}"
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo=*) REPO_URL="${1#*=}" ;;
    --branch=*) BRANCH="${1#*=}" ;;
    --dir=*) INSTALL_DIR="${1#*=}" ;;
    --force|-f) FORCE=true ;;
    --help|-h)
      echo "OpenCode Config Installer"
      echo ""
      echo "Usage: curl -fsSL <url> | bash -s -- [options]"
      echo ""
      echo "Options:"
      echo "  --repo=<url>     Repository URL (default: $REPO_URL)"
      echo "  --branch=<name>  Branch or tag to install (default: $BRANCH)"
      echo "  --dir=<path>     Install directory (default: $INSTALL_DIR)"
      echo "  --force, -f      Overwrite existing installation"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage"
      exit 1
      ;;
  esac
  shift
done

echo "========================================"
echo " OpenCode Config Installer"
echo "========================================"
echo "  Repository: $REPO_URL"
echo "  Branch:     $BRANCH"
echo "  Target:     $INSTALL_DIR"
echo ""

# Check if already installed
if [[ -d "$INSTALL_DIR" ]]; then
  if [[ -f "$INSTALL_DIR/VERSION" ]]; then
    INSTALLED_VERSION=$(cat "$INSTALL_DIR/VERSION")
    echo "[install] OpenCode Config already installed at $INSTALL_DIR (v$INSTALLED_VERSION)"
  else
    echo "[install] Directory $INSTALL_DIR already exists"
  fi

  if [[ "$FORCE" != true ]]; then
    echo "[install] Use --force to overwrite, or set a different --dir"
    exit 1
  fi
  echo "[install] Force mode — overwriting..."
fi

# Check for git
if ! command -v git &>/dev/null; then
  echo "[install] ERROR: git is required but not installed"
  exit 1
fi

# Clone or update
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[install] Updating existing repository..."
  git -C "$INSTALL_DIR" fetch origin
  git -C "$INSTALL_DIR" checkout "$BRANCH"
  git -C "$INSTALL_DIR" pull origin "$BRANCH"
else
  echo "[install] Cloning repository..."
  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
  fi
  git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# Verify installation
if [[ -f "$INSTALL_DIR/VERSION" ]]; then
  VERSION=$(cat "$INSTALL_DIR/VERSION")
  echo ""
  echo "[install] ✅ OpenCode Config v$VERSION installed successfully!"
  echo ""
  echo "  Location: $INSTALL_DIR"
  echo "  To update: bash $INSTALL_DIR/scripts/update.sh"
  echo "  Make targets: make -C $INSTALL_DIR help"
else
  echo "[install] ⚠️  Installation incomplete — VERSION file not found"
  exit 1
fi
