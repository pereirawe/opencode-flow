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

# --- LSP / Editor Configuration ---
CATALOG="$CONFIG_DIR/standards/lsp-catalog.json"

if [ -f "$CATALOG" ]; then
  # Detect languages using python3 (preferred) or jq
  DETECTED=""
  if command -v python3 &>/dev/null; then
    DETECTED=$(TARGET="$TARGET" CATALOG="$CATALOG" python3 -c '
import os, json, glob

target = os.environ["TARGET"]
catalog_path = os.environ["CATALOG"]

try:
    with open(catalog_path) as f:
        catalog = json.load(f)
except Exception:
    print("[]")
    exit(0)

results = []
seen = set()
for entry in catalog:
    lang = entry["language"]
    if lang in seen:
        continue
    for detector in entry["detectors"]:
        if "*" in detector or "?" in detector:
            matches = glob.glob(os.path.join(target, detector))
            if matches:
                results.append(entry)
                seen.add(lang)
                break
        else:
            if os.path.isfile(os.path.join(target, detector)):
                results.append(entry)
                seen.add(lang)
                break

print(json.dumps(results))
' 2>/dev/null) || DETECTED=""
  elif command -v jq &>/dev/null; then
    # Fallback: use jq to iterate over catalog entries
    COUNT=$(jq length "$CATALOG")
    DETECTED="["
    FIRST=1
    for i in $(seq 0 $((COUNT - 1))); do
      ENTRY=$(jq ".[$i]" "$CATALOG")
      LANG=$(echo "$ENTRY" | jq -r '.language')
      DETECTORS=$(echo "$ENTRY" | jq -r '.detectors[]')
      FOUND=0
      while IFS= read -r det; do
        if echo "$det" | grep -q '[*?]'; then
          # Glob pattern
          for f in "$TARGET"/$det; do
            if [ -f "$f" ]; then
              FOUND=1
              break
            fi
          done
        else
          if [ -f "$TARGET/$det" ]; then
            FOUND=1
          fi
        fi
        [ "$FOUND" = 1 ] && break
      done <<< "$DETECTORS"
      if [ "$FOUND" = 1 ]; then
        if [ "$FIRST" = 1 ]; then
          DETECTED="$DETECTED$ENTRY"
          FIRST=0
        else
          DETECTED="$DETECTED,$ENTRY"
        fi
      fi
    done
    DETECTED="$DETECTED]"
  fi

  if [ -n "$DETECTED" ] && [ "$DETECTED" != "[]" ]; then
    # Count detected languages for summary
    LANG_COUNT=$(echo "$DETECTED" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(len(data))
except Exception:
    print("0")
' 2>/dev/null || echo "0")

    if [ "$LANG_COUNT" -gt 0 ]; then
      echo ""
      echo "[init] Detected languages: $(echo "$DETECTED" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(", ".join(e["language"] for e in data))
' 2>/dev/null)"

      # Show LSP suggestions
      echo "[init] LSP suggestions available for detected languages:"
      echo "$DETECTED" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for entry in data:
    exts = entry.get("extensions", [])
    if exts:
        print("  \u2192 " + entry["language"] + ": " + ", ".join(exts))
    else:
        print("  \u2192 " + entry["language"] + ": (built-in support)")
' 2>/dev/null

      # Ask user for confirmation
      echo ""
      printf "[init] Configure VS Code with these LSPs? (s/N) "
      read -r CONFIRM
      if [ "$CONFIRM" = "s" ] || [ "$CONFIRM" = "S" ]; then
        mkdir -p "$TARGET/.vscode"
        echo "[init] Creating/updating .vscode/settings.json..."

        # Extract combined settings from detected languages
        NEW_SETTINGS=$(echo "$DETECTED" | python3 -c '
import json, sys
data = json.load(sys.stdin)
settings = {}
for entry in data:
    entry_settings = entry.get("settings", {})
    for key, val in entry_settings.items():
        settings[key] = val
print(json.dumps(settings, indent=2))
' 2>/dev/null) || NEW_SETTINGS="{}"

        EXISTING_FILE="$TARGET/.vscode/settings.json"
        MERGED=""

        if [ -f "$EXISTING_FILE" ]; then
          if command -v jq &>/dev/null; then
            MERGED=$(jq -s --argjson new "$NEW_SETTINGS" '.[0] * $new' "$EXISTING_FILE" 2>/dev/null) || MERGED=""
          elif command -v python3 &>/dev/null; then
            MERGED=$(EXISTING_FILE="$EXISTING_FILE" NEW_SETTINGS="$NEW_SETTINGS" python3 -c '
import os, json
with open(os.environ["EXISTING_FILE"]) as f:
    existing = json.load(f)
new = json.loads(os.environ["NEW_SETTINGS"])
existing.update(new)
print(json.dumps(existing, indent=2))
' 2>/dev/null) || MERGED=""
          fi

          if [ -n "$MERGED" ]; then
            echo "$MERGED" > "$EXISTING_FILE"
            echo "[init] Merged LSP settings into existing $EXISTING_FILE"
          else
            echo "[init] Warning: could not merge settings. $EXISTING_FILE unchanged."
            echo "[init] New settings would be:"
            echo "$NEW_SETTINGS"
          fi
        else
          echo "$NEW_SETTINGS" > "$EXISTING_FILE"
          echo "[init] Created $EXISTING_FILE with LSP configuration"
        fi

        # List extensions to install
        echo ""
        echo "[init] Recommended VS Code extensions to install:"
        echo "$DETECTED" | python3 -c '
import json, sys
data = json.load(sys.stdin)
all_exts = []
for entry in data:
    all_exts.extend(entry.get("extensions", []))
for ext in all_exts:
    print("  - " + ext)
' 2>/dev/null

        echo ""
        echo "[init] VS Code configured with LSPs for detected languages"
      else
        echo "[init] Skipping VS Code configuration"
      fi
    fi
  else
    echo "[init] No project languages detected from catalog"
  fi
else
  echo "[init] LSP catalog not found at $CATALOG; skipping editor configuration"
fi
