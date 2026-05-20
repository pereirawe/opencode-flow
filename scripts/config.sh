# Shared configuration for opencode scripts.
# Source this file from any script to get absolute global paths.
#
# Usage:
#   source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPTS_DIR="$CONFIG_DIR/scripts"

# Global issue tracker (opencode config-level issues)
ISSUES_FILE="$CONFIG_DIR/known_issues.md"

# Project-local issue tracker (project-specific issues)
# Detected from CWD — falls back to global if no .opencode/ found
if [ -f ".opencode/known_issues.md" ]; then
  PROJECT_ISSUES_FILE="$(pwd -P)/.opencode/known_issues.md"
else
  PROJECT_ISSUES_FILE="$ISSUES_FILE"
fi
