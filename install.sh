#!/usr/bin/env bash
# OpenCode Config — Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/refs/heads/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/main/install.sh | bash -s -- --repo=https://github.com/user/repo --branch=v1.0.0
set -euo pipefail

# ─────────────────────────────────────────────
# OpenCode Tool Validation
# ─────────────────────────────────────────────

validate_opencode() {
  echo "----------------------------------------"
  echo " OpenCode Tool Validation"
  echo "----------------------------------------"

  local opencode_found=false
  if command -v opencode &>/dev/null; then
    opencode_found=true
  fi

  if [[ "$opencode_found" == false ]]; then
    echo "[install] ⚠️  OpenCode (AI tool) is not installed."
    echo "[install] This config is an overlay and requires OpenCode to function."
    read -p "➡️  Instalar opencode? (s/N): " install_opencode
    if [[ "$install_opencode" =~ ^[Ss]$ ]]; then
      echo "[install] Installing OpenCode via official script..."
      echo "[install] Running: curl -fsSL https://opencode.ai/install.sh | bash"
      if ! curl -fsSL https://opencode.ai/install.sh | bash; then
        echo "[install] ❌ OpenCode installation failed."
        exit 1
      fi
      # Re-check after installation
      if ! command -v opencode &>/dev/null; then
        echo "[install] ❌ OpenCode was installed but the 'opencode' command was not found."
        echo "[install] Please check your PATH or restart your terminal."
        exit 1
      fi
      echo "[install] ✅ OpenCode installed successfully!"
    else
      echo ""
      echo "[install] ❌ A instalação do opencode-flow não pode continuar pois o opencode não está instalado."
      echo "[install] Esta config é um overlay e não tem funcionalidade sem o opencode."
      echo "[install] Instale em: https://opencode.ai"
      exit 1
    fi
  else
    echo "[install] ✅ OpenCode binary found: $(command -v opencode)"

    # Secondary check: config directory at default location
    if [[ ! -d "$HOME/.config/opencode" ]]; then
      echo "[install] ℹ️  OpenCode config directory not found at ~/.config/opencode"
      echo "[install]    (This is expected — the config overlay will create it.)"
    fi

    # Version check
    check_opencode_version
  fi
}

check_opencode_version() {
  local current_version
  current_version=$(opencode --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")

  if [[ -z "$current_version" ]]; then
    echo "[install] ⚠️  Could not determine OpenCode version."
    echo "[install]    Proceeding with config installation anyway."
    return 0
  fi

  echo "[install] OpenCode version: v$current_version"

  # Fetch latest version from npm registry (more reliable than GitHub API)
  local latest_version=""
  if command -v npm &>/dev/null; then
    echo "[install] Checking for updates via npm registry..."
    latest_version=$(npm view @opencode-ai/cli version 2>/dev/null || echo "")
  fi

  # Fallback to GitHub API
  if [[ -z "$latest_version" ]]; then
    echo "[install] npm not available, trying GitHub API..."
    latest_version=$(curl -sL https://api.github.com/repos/anomaly/opencode/releases/latest 2>/dev/null \
      | grep '"tag_name":' \
      | sed 's/.*"v\?\([^"]*\)".*/\1/' \
      | tr -d ' \n' \
      || echo "")
  fi

  if [[ -z "$latest_version" ]]; then
    echo "[install] ⚠️  Could not fetch latest OpenCode version."
    echo "[install]    Check your internet connection."
    echo "[install]    Proceeding with config installation anyway."
    return 0
  fi

  # Compare versions (simple string comparison)
  if [[ "$current_version" != "$latest_version" ]]; then
    echo "[install] 📦 New version available: v$current_version → v$latest_version"
    # Use exact prompt format from business rules
    read -p "➡️  Atualizar de v${current_version} para v${latest_version}? (s/N): " update_opencode
    if [[ "$update_opencode" =~ ^[Ss]$ ]]; then
      update_opencode_tool
    else
      echo "[install] Skipping update (user declined)."
    fi
  else
    echo "[install] ✅ OpenCode is up to date (v$current_version)"
  fi
}

update_opencode_tool() {
  local method=""

  # Detect installation method: npm
  if command -v npm &>/dev/null; then
    if npm list -g @opencode-ai/cli &>/dev/null 2>&1; then
      method="npm"
    fi
  fi

  # Detect installation method: Homebrew
  if [[ -z "$method" ]] && command -v brew &>/dev/null; then
    if brew list opencode &>/dev/null 2>&1; then
      method="brew"
    fi
  fi

  case "$method" in
    npm)
      echo "[install] Detected npm installation — updating via npm..."
      npm install -g @opencode-ai/cli@latest
      ;;
    brew)
      echo "[install] Detected Homebrew installation — updating via brew..."
      brew upgrade opencode
      ;;
    *)
      echo "[install] ⚠️  Could not detect installation method automatically."
      echo "[install] Please update OpenCode manually using one of these methods:"
      echo "[install]   - npm:  npm install -g @opencode-ai/cli@latest"
      echo "[install]   - brew: brew upgrade opencode"
      echo "[install]   - Other: https://opencode.ai"
      ;;
  esac
}

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

# Validate that OpenCode tool is installed before proceeding
validate_opencode

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
