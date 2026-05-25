#!/usr/bin/env bash
set -euo pipefail

# Initialize opencode config in a project with repo context detection.
# Usage: bash scripts/init.sh [target=/path/to/project] [locale=en]
# If target is omitted, uses current directory.
# If locale is omitted, defaults to en.

TARGET="${1:-$PWD}"
LOCALE="${2:-en}"
CONFIG_DIR="$(cd "$(dirname "$(dirname "$0")")" && pwd)"

mkdir -p "$TARGET/.opencode"

# Copy template files
cp -r "$CONFIG_DIR/.opencode/." "$TARGET/.opencode/"

# Write locale file
echo "$LOCALE" > "$TARGET/.opencode/locale"

# Detect git repo info and substitute into AGENTS.md
if command -v git >/dev/null 2>&1 && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  # Default branch
  # Default branch — try origin/HEAD first, fallback to current HEAD symbolic ref, then "main"
  origin_head="$(git -C "$TARGET" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#refs/remotes/origin/##' || true)"
  if [ -n "$origin_head" ]; then
    default_branch="$origin_head"
  else
    default_branch="$(git -C "$TARGET" symbolic-ref HEAD 2>/dev/null | sed 's#refs/heads/##' || echo "main")"
  fi

  sed -i "s/__DEFAULT_BRANCH__/$default_branch/g" "$TARGET/.opencode/AGENTS.md"

  # Remotes — handle repos with no remotes
  git -C "$TARGET" remote -v 2>/dev/null | awk '{print "  - `" $1 "` -> `" $2 "`"}' | sort -u > /tmp/opencode_remotes_$$

  if [ -s /tmp/opencode_remotes_$$ ]; then
    awk 'NR==FNR{remotes[++n]=$0;next} /^__REMOTES__$/{for(i=1;i<=n;i++) print remotes[i];next} 1' \
      /tmp/opencode_remotes_$$ "$TARGET/.opencode/AGENTS.md" > "$TARGET/.opencode/AGENTS.md.tmp" \
      && mv "$TARGET/.opencode/AGENTS.md.tmp" "$TARGET/.opencode/AGENTS.md"
  else
    sed -i '/^__REMOTES__$/c\  <none>' "$TARGET/.opencode/AGENTS.md"
  fi

  rm -f /tmp/opencode_remotes_$$

  echo "[init] Repo context: default branch=$default_branch, $(git -C "$TARGET" remote | wc -w) remote(s)"
else
  sed -i 's/__DEFAULT_BRANCH__/<not a git repo>/g' "$TARGET/.opencode/AGENTS.md"
  sed -i '/^__REMOTES__$/c\  <none>' "$TARGET/.opencode/AGENTS.md"
  echo "[init] No git repo detected; skipping repo context"
fi

echo "[init] .opencode/ initialized in $TARGET"
echo "[init] Locale set to: $LOCALE"
echo "[init] Files include: AGENTS.md, workflow.md, opencode.json, known_issues.md"
echo "[init] Project issues go in .opencode/known_issues.md, config issues in ~/.config/opencode/known_issues.md"
