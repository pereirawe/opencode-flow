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
    if [[ -t 0 ]]; then
      read -p "➡️  Instalar opencode? (s/N): " install_opencode < /dev/tty
    else
      echo "[install] Non-interactive shell detected."
      install_opencode=""
    fi
    if [[ "$install_opencode" =~ ^[Ss]$ ]]; then
      echo "[install] Installing OpenCode via official script..."
      echo "[install] Running: curl -fsSL https://opencode.ai/install.sh | bash"
      curl -fsSL https://opencode.ai/install.sh -o /tmp/opencode-install.sh
      echo "[install] Script downloaded to /tmp/opencode-install.sh"
      if [[ -t 0 ]]; then
        read -p "➡️  Confirmar execução do script de instalação? (s/N): " confirm < /dev/tty
        if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
          echo "[install] ❌ Installation cancelled by user."
          exit 1
        fi
      fi
      if ! bash /tmp/opencode-install.sh; then
        echo "[install] ❌ OpenCode installation failed."
        exit 1
      fi
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

    if [[ ! -d "$INSTALL_DIR" ]]; then
      echo "[install] ⚠️  OpenCode config directory not found at $INSTALL_DIR"
      echo "[install]    Run 'opencode init' to initialize it, or the config overlay will create it."
    fi

    check_opencode_version
  fi
}

check_opencode_version() {
  local current_version
  current_version=$(opencode --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")

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
    latest_version=$(timeout 10 npm view @opencode-ai/cli version --timeout=10000 2>/dev/null || echo "")
  fi

  # Fallback to GitHub API
  if [[ -z "$latest_version" ]]; then
    echo "[install] npm not available, trying GitHub API..."
    latest_version=$(curl -sL --connect-timeout 10 --max-time 15 \
      https://api.github.com/repos/opencode-ai/opencode/releases/latest 2>/dev/null \
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

  # Semver comparison using sort -V
  local newer
  newer=$(printf '%s\n' "$current_version" "$latest_version" | sort -V | tail -1)
  if [[ "$newer" != "$latest_version" ]]; then
    echo "[install] 📦 New version available: v$current_version → v$latest_version"
    local prompt="➡️  Atualizar de v${current_version} para v${latest_version}? (s/N): "
    if [[ -t 0 ]]; then
      read -p "$prompt" update_opencode
    else
      echo "[install] Non-interactive mode — skipping update."
      echo "[install] Run manually: npm install -g @opencode-ai/cli@latest"
      return 0
    fi
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
      if npm install -g @opencode-ai/cli@latest; then
        local new_version
        new_version=$(opencode --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
        echo "[install] ✅ OpenCode updated to v${new_version:-latest}"
      else
        echo "[install] ⚠️  npm update failed. Try: sudo npm install -g @opencode-ai/cli@latest"
      fi
      ;;
    brew)
      echo "[install] Detected Homebrew installation — updating via brew..."
      if brew upgrade opencode; then
        local new_version
        new_version=$(opencode --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
        echo "[install] ✅ OpenCode updated to v${new_version:-latest}"
      else
        echo "[install] ⚠️  brew update failed. Try: brew upgrade opencode"
      fi
      ;;
    *)
      echo "[install] ⚠️  Could not detect installation method automatically."
      local opencode_path
      opencode_path=$(command -v opencode 2>/dev/null || true)
      if [[ -n "$opencode_path" ]]; then
        echo "[install] OpenCode binary found at: $opencode_path"
        if [[ -t 0 ]]; then
          read -p "➡️  Reinstalar via script oficial (curl -fsSL https://opencode.ai/install.sh | bash)? (s/N): " reinstall < /dev/tty
        else
          echo "[install] Non-interactive mode. Update manually:"
          echo "[install]   https://opencode.ai"
          return 0
        fi
        if [[ "$reinstall" =~ ^[Ss]$ ]]; then
          curl -fsSL https://opencode.ai/install.sh | bash
        fi
      else
        echo "[install] Please update OpenCode manually using one of these methods:"
        echo "[install]   - npm:  npm install -g @opencode-ai/cli@latest"
        echo "[install]   - brew: brew upgrade opencode"
        echo "[install]   - Other: https://opencode.ai"
      fi
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
