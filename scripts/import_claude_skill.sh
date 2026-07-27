#!/usr/bin/env bash
set -euo pipefail

SKILL_PATH="${1:-}"
SECTOR="${2:-}"

if [[ -z "$SKILL_PATH" ]]; then
  echo "Usage: import_claude_skill.sh <skill-path> [sector]"
  echo "Example: import_claude_skill.sh business-marketing/seo-optimizer marketing"
  echo "Sectors: development, marketing, bi, sales, finance, shared"
  echo "If omitted, you will be prompted."
  exit 1
fi

SKILL_NAME="${SKILL_PATH##*/}"
OPENCODE_SKILLS="$HOME/.config/opencode/skills"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"

if [[ -z "$SECTOR" ]]; then
  echo "Target sectors: development, marketing, bi, sales, finance, shared"
  read -r -p "Which sector? [shared] " SECTOR
  SECTOR="${SECTOR:-shared}"
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Installing skill: $SKILL_PATH → sector: $SECTOR"
npx --yes claude-code-templates@latest --skill "$SKILL_PATH" --yes --directory "$TMPDIR" 2>/dev/null

SRC="$TMPDIR/.claude/skills/$SKILL_NAME"
if [[ ! -d "$SRC" ]]; then
  echo "Skill not found: $SKILL_PATH"
  exit 1
fi

mkdir -p "$OPENCODE_SKILLS/$SECTOR/$SKILL_NAME"
cp -r "$SRC"/* "$OPENCODE_SKILLS/$SECTOR/$SKILL_NAME/"

python3 -c "
import json
with open('$OPENCODE_CONFIG', 'r') as f:
    cfg = json.load(f)
skills = cfg.get('permission', {}).get('skill', {})
skills['$SKILL_NAME'] = 'allow'
cfg.setdefault('permission', {}).setdefault('skill', {}).update(skills)
with open('$OPENCODE_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=4)
" 2>/dev/null || {
  echo "Could not auto-register in opencode.json — add manually:"
  echo "   \"$SKILL_NAME\": \"allow\""
}

echo "Skill '$SKILL_NAME' installed to $OPENCODE_SKILLS/$SECTOR/$SKILL_NAME/"
echo "Open a new session for it to appear in available_skills."
