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
  PROJECT_ISSUES_DIR="$(pwd -P)/.opencode"
else
  PROJECT_ISSUES_FILE="$ISSUES_FILE"
  PROJECT_ISSUES_DIR="$CONFIG_DIR"
fi

# Resolved issue archive (same level as the source known_issues)
RESOLVED_FILE="$PROJECT_ISSUES_DIR/resolved_issues.md"

# Reviewer count for branch/PR reviews (default: 1)
# Projects can override by setting REVIEWER_COUNT in their own config
REVIEWER_COUNT="${REVIEWER_COUNT:-1}"
