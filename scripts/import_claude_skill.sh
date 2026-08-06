#!/usr/bin/env bash
set -euo pipefail

# DEPRECATED — replaced by the vendor clone strategy.
#
# External skills are now kept as git clones under ~/.config/opencode/vendor/
# and loaded in-place via "skills.paths" in opencode.json. The old
# claude-code-templates copy flow has been removed.
#
# This script is kept as a thin shim for compatibility: any git-based import
# delegates to skill-vendor.sh add. Use `skill-vendor.sh` directly going
# forward (see scripts/skill-vendor.sh).

if [[ -z "${1:-}" ]]; then
  echo "Usage: import_claude_skill.sh <git-url|owner/repo> [--sparse <paths...>]" >&2
  echo "Deprecated — prefer: scripts/skill-vendor.sh add <git-url|owner/repo> [--sparse <paths...>]" >&2
  exit 1
fi

echo "[import_claude_skill] deprecated — delegating to skill-vendor.sh add $*" >&2
if ! exec "$(dirname "$0")/skill-vendor.sh" add "$@"; then
  echo "[import_claude_skill] import failed — the calling convention changed: pass a git URL or owner/repo (the old 'skill-path sector' syntax is gone). See scripts/skill-vendor.sh." >&2
  exit 1
fi
