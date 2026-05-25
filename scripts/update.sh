#!/usr/bin/env bash
# OpenCode Config — Version check & update
# Usage: bash scripts/update.sh
# Usage: bash scripts/update.sh --check    # only check, don't update
# Usage: bash scripts/update.sh --force    # update even on same version
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

CHECK_ONLY=false
FORCE=false
REMOTE_URL="${OPENCODE_CONFIG_REPO:-https://github.com/anomalyco/opencode-config}"
BRANCH="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check|-c) CHECK_ONLY=true ;;
    --force|-f) FORCE=true ;;
    --repo=*) REMOTE_URL="${1#*=}" ;;
    --branch=*) BRANCH="${1#*=}" ;;
    --help|-h)
      echo "OpenCode Config Updater"
      echo ""
      echo "Usage: bash $CONFIG_DIR/scripts/update.sh [options]"
      echo ""
      echo "Options:"
      echo "  --check, -c     Only check for updates, don't apply"
      echo "  --force, -f     Update even if versions match"
      echo "  --repo=<url>    Remote repository URL"
      echo "  --branch=<name> Branch to track"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
  shift
done

# Read local version
LOCAL_VERSION="0.0.0"
LOCAL_FILE="$CONFIG_DIR/VERSION"
if [[ -f "$LOCAL_FILE" ]]; then
  LOCAL_VERSION=$(cat "$LOCAL_FILE" | tr -d ' \n')
fi

echo "[update] Local version: v$LOCAL_VERSION"

# Fetch remote version
REMOTE_VERSION=""
if command -v git &>/dev/null; then
  TMP_DIR=$(mktemp -d)
  if git clone --depth 1 --branch "$BRANCH" "$REMOTE_URL" "$TMP_DIR" 2>/dev/null; then
    if [[ -f "$TMP_DIR/VERSION" ]]; then
      REMOTE_VERSION=$(cat "$TMP_DIR/VERSION" | tr -d ' \n')
    fi
    rm -rf "$TMP_DIR"
  fi
fi

if [[ -z "$REMOTE_VERSION" ]]; then
  echo "[update] ⚠️  Could not fetch remote version from $REMOTE_URL"
  echo "[update] Check your internet connection or the repository URL"
  exit 1
fi

echo "[update] Remote version:  v$REMOTE_VERSION"

# Compare versions (simple string comparison for semver)
if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
  if [[ "$FORCE" == true ]]; then
    echo "[update] Versions match (v$LOCAL_VERSION), force update..."
  else
    echo "[update] ✅ Already up to date (v$LOCAL_VERSION)"
    exit 0
  fi
else
  echo "[update] 📦 New version available: v$LOCAL_VERSION → v$REMOTE_VERSION"
fi

if [[ "$CHECK_ONLY" == true ]]; then
  echo "[update] Check complete — use without --check to update"
  exit 0
fi

# Perform update
echo "[update] Updating..."

if [[ ! -d "$CONFIG_DIR/.git" ]]; then
  echo "[update] Not a git repository — pulling via git clone"
  TMP_DIR=$(mktemp -d)
  git clone --depth 1 --branch "$BRANCH" "$REMOTE_URL" "$TMP_DIR"
  cp -r "$TMP_DIR/"* "$CONFIG_DIR/"
  cp "$TMP_DIR/".* "$CONFIG_DIR/" 2>/dev/null || true
  rm -rf "$TMP_DIR"
else
  echo "[update] Git repository detected — pulling..."
  git -C "$CONFIG_DIR" fetch origin
  git -C "$CONFIG_DIR" checkout "$BRANCH"
  git -C "$CONFIG_DIR" pull origin "$BRANCH"
fi

# Verify
NEW_VERSION=$(cat "$CONFIG_DIR/VERSION" 2>/dev/null || echo "unknown")
echo "[update] ✅ Updated to v$NEW_VERSION"
echo "[update] Done!"
