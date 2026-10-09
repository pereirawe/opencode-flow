#!/usr/bin/env bash
set -euo pipefail

# Initialize opencode config in a project with repo context detection.
#
# Usage: bash scripts/init.sh [target=/path/to/project] [locale=en] [flags]
#   --force        overwrite project-owned template files (dangerous)
#   --dry-run      show what would happen; write nothing
#   --lsp/--no-lsp enable/disable VS Code LSP configuration
#   --locale <l>   set the locale explicitly
#
# Safety contract (issue #245):
#   - re-runs NEVER delete or overwrite project-owned files
#     (resolved_issues.md, known_issues.md, standards/, README.md,
#      AGENTS.md, workflow.md, opencode.json, env-manifest.md, .gitignore,
#      locale, *.env)
#   - templates are copied only when the destination is absent (unless --force)
#   - the locale defaults to the resolved locale (target .opencode/locale →
#     global ~/.config/opencode/locale → en), never a hardcoded `en`
#   - all mandatory templates are validated BEFORE any write (no half-init)
#   - portable across GNU/BSD sed and honors TMPDIR

TARGET=""; LOCALE=""; FORCE=0; DRY_RUN=0
LSP="${INIT_CONFIGURE_LSP:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --force)     FORCE=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --lsp)       LSP=1; shift ;;
    --no-lsp)    LSP=0; shift ;;
    --locale)    [ $# -ge 2 ] || { echo "[init] --locale requires a value" >&2; exit 3; }; LOCALE="$2"; shift 2 ;;
    --locale=*)  LOCALE="${1#--locale=}"; shift ;;
    -*)          echo "[init] unknown flag: $1" >&2; exit 3 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"
       elif [ -z "$LOCALE" ]; then LOCALE="$1"
       else echo "[init] unexpected argument: $1" >&2; exit 3; fi
       shift ;;
  esac
done
TARGET="${TARGET:-$PWD}"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd -P)"

# --- target validation (L5): refuse a file target, normalize the path ---------
if [ -e "$TARGET" ] && [ ! -d "$TARGET" ]; then
  echo "[init] FATAL: target is not a directory: $TARGET" >&2
  exit 2
fi
mkdir -p "$TARGET" || { echo "[init] FATAL: cannot create $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd -P)"

P_TMP_REMOTES=""
cleanup() { [ -n "$P_TMP_REMOTES" ] && rm -f "$P_TMP_REMOTES"; return 0; }
trap cleanup EXIT

# Portable in-place sed (GNU vs BSD/macOS): p_sed <file> <sed-expr...>
p_sed() {
  local f="$1"; shift
  if sed --version >/dev/null 2>&1; then
    sed -i "$@" "$f"
  else
    sed -i '' "$@" "$f"
  fi
}

# --- resolve locale (M3 / BR3): arg > target locale > global locale > en -----
if [ -z "$LOCALE" ]; then
  if [ -f "$TARGET/.opencode/locale" ]; then
    LOCALE="$(head -n1 "$TARGET/.opencode/locale")"
  elif [ -f "$HOME/.config/opencode/locale" ]; then
    LOCALE="$(head -n1 "$HOME/.config/opencode/locale")"
  else
    LOCALE="en"
  fi
fi

# --- preflight (M1/M2 / BR5): validate every mandatory template before writing
REQUIRED="AGENTS.md workflow.md opencode.json env-manifest.md .gitignore"
MISSING=""
for f in $REQUIRED; do
  [ -f "$CONFIG_DIR/.opencode/$f" ] || MISSING="$MISSING $f"
done
if [ -n "$MISSING" ]; then
  echo "[init] FATAL: missing required template(s) in $CONFIG_DIR/.opencode:$MISSING" >&2
  exit 2
fi

# --- whitelist copy, set-if-absent (C1/H1/H2 / BR1/BR2) ----------------------
# Copy ONLY the files a project consumes. Never blind `cp -r` (issue #242).
# Never overwrite a file that already exists unless --force.
copy_if_absent() { # <relpath>
  local rel="$1" src="$CONFIG_DIR/.opencode/$1" dst="$TARGET/.opencode/$1"
  if [ -f "$dst" ] && [ "$FORCE" -ne 1 ]; then
    echo "[init] keep  $rel (project-owned)"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[init] would write $rel"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "[init] write $rel"
}

[ "$DRY_RUN" -eq 1 ] || mkdir -p "$TARGET/.opencode"
for f in AGENTS.md workflow.md opencode.json env-manifest.md .gitignore; do
  copy_if_absent "$f"
done

# --- safety sweep (BR4): ONLY blind-copy pollution, never project files ------
if [ "$DRY_RUN" -ne 1 ] && [ "$TARGET" != "$CONFIG_DIR" ]; then
  rm -rf "$TARGET/.opencode/node_modules" "$TARGET/.opencode/preflight" \
    "$TARGET/.opencode/reviews" "$TARGET/.opencode/adorable-proposal"
  rm -f "$TARGET/.opencode/package.json" "$TARGET/.opencode/package-lock.json"
fi

# Project-level issue tracker: create only when absent — never overwrite.
if [ ! -f "$TARGET/.opencode/known_issues.md" ] && [ "$DRY_RUN" -ne 1 ]; then
  printf '## Known Issues\n\nProject-level issue tracker.\nUse `$HOME/.config/opencode/known_issues.md` for opencode config-level issues.\n' > "$TARGET/.opencode/known_issues.md"
fi

# locale: write only when absent (or --force) — never flip a project's locale.
if [ ! -f "$TARGET/.opencode/locale" ] || [ "$FORCE" -eq 1 ]; then
  [ "$DRY_RUN" -eq 1 ] || printf '%s\n' "$LOCALE" > "$TARGET/.opencode/locale"
fi

# --- git context injection (C2/L1/L2/L4) ------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[init] would inject repo context into AGENTS.md (dry-run)"
elif command -v git >/dev/null 2>&1 && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  origin_head="$(git -C "$TARGET" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#refs/remotes/origin/##' || true)"
  if [ -n "$origin_head" ]; then
    default_branch="$origin_head"
  else
    default_branch="$(git -C "$TARGET" symbolic-ref HEAD 2>/dev/null | sed 's#refs/heads/##' || echo "main")"
  fi

  escaped_branch=$(printf '%s\n' "$default_branch" | sed 's/[\/&]/\\&/g')
  p_sed "$TARGET/.opencode/AGENTS.md" "s/__DEFAULT_BRANCH__/$escaped_branch/g"

  P_TMP_REMOTES="$(mktemp "${TMPDIR:-/tmp}/opencode_remotes.XXXXXX")"
  git -C "$TARGET" remote -v 2>/dev/null | awk '
    /\(fetch\)$/ {
      name = $1; line = $0
      sub(/^[^ \t]+[ \t]+/, "", line)
      sub(/[ \t]+\(fetch\)$/, "", line)
      print "  - `" name "` -> `" line "`"
    }
  ' | LC_ALL=C sort -u > "$P_TMP_REMOTES"

  if [ -s "$P_TMP_REMOTES" ]; then
    awk 'NR==FNR{remotes[++n]=$0;next} /^__REMOTES__$/{for(i=1;i<=n;i++) print remotes[i];next} 1' \
      "$P_TMP_REMOTES" "$TARGET/.opencode/AGENTS.md" > "$TARGET/.opencode/AGENTS.md.tmp" \
      && mv "$TARGET/.opencode/AGENTS.md.tmp" "$TARGET/.opencode/AGENTS.md"
  else
    p_sed "$TARGET/.opencode/AGENTS.md" 's/^__REMOTES__$/  <none>/'
  fi

  rm -f "$P_TMP_REMOTES"; P_TMP_REMOTES=""
  echo "[init] Repo context: default branch=$default_branch, $(git -C "$TARGET" remote | wc -w) remote(s)"
else
  p_sed "$TARGET/.opencode/AGENTS.md" 's/__DEFAULT_BRANCH__/<not a git repo>/g'
  p_sed "$TARGET/.opencode/AGENTS.md" 's/^__REMOTES__$/  <none>/'
  echo "[init] No git repo detected; skipping repo context"
fi

echo "[init] .opencode/ initialized in $TARGET"
echo "[init] Locale set to: $LOCALE"
echo "[init] Files include: AGENTS.md, workflow.md, opencode.json, known_issues.md, env-manifest.md, .gitignore, locale (whitelist only; never secrets, node_modules/, preflight/, reviews/, standards/)"
echo "[init] Project issues go in .opencode/known_issues.md, config issues in ~/.config/opencode/known_issues.md"

# --- LSP / Editor Configuration --------------------------------------------
CATALOG="$CONFIG_DIR/standards/lsp-catalog.json"

if [ -f "$CATALOG" ]; then
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
  fi

  if [ -n "$DETECTED" ] && [ "$DETECTED" != "[]" ]; then
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

      # LSP configuration is OPT-IN (H3): /ocf:init runs non-interactively, so
      # never block on a prompt. Enable via INIT_CONFIGURE_LSP=1/--lsp, or by
      # answering the prompt when a TTY is present.
      CONFIGURE=0
      case "${LSP:-}" in
        1|s|S|true|yes) CONFIGURE=1 ;;
        0|n|N|false|no) CONFIGURE=0 ;;
        *)
          if [ -t 0 ]; then
            echo ""
            printf "[init] Configure VS Code with these LSPs? (s/N) "
            read -r CONFIRM || CONFIRM="n"
            case "$CONFIRM" in s|S) CONFIGURE=1 ;; esac
          else
            echo "[init] Skipping VS Code configuration (set INIT_CONFIGURE_LSP=1 to enable)"
          fi
          ;;
      esac

      if [ "$CONFIGURE" -eq 1 ]; then
        echo "[init] Creating/updating .vscode/settings.json..."

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

          if [ "$DRY_RUN" -eq 1 ]; then
            echo "[init] would merge LSP settings into $EXISTING_FILE"
          elif [ -n "$MERGED" ]; then
            echo "$MERGED" > "$EXISTING_FILE"
            echo "[init] Merged LSP settings into existing $EXISTING_FILE"
          else
            echo "[init] Warning: could not merge settings. $EXISTING_FILE unchanged."
            echo "[init] New settings would be:"
            echo "$NEW_SETTINGS"
          fi
        else
          if [ "$DRY_RUN" -eq 1 ]; then
            echo "[init] would create $EXISTING_FILE with LSP configuration"
          else
            mkdir -p "$TARGET/.vscode"
            echo "$NEW_SETTINGS" > "$EXISTING_FILE"
            echo "[init] Created $EXISTING_FILE with LSP configuration"
          fi
        fi

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
      fi
    fi
  else
    echo "[init] No project languages detected from catalog"
  fi
else
  echo "[init] LSP catalog not found at $CATALOG; skipping editor configuration"
fi

# --- Test environment placeholders (issue #210) ---
if command -v node >/dev/null 2>&1; then
  if [[ ! -f "$TARGET/.nvmrc" ]]; then
    [ "$DRY_RUN" -eq 1 ] || printf '22\n' > "$TARGET/.nvmrc"
    echo "[init] Created $TARGET/.nvmrc (Node pin 22)"
  fi
  if [[ ! -f "$TARGET/.node-version" ]]; then
    [ "$DRY_RUN" -eq 1 ] || printf '22\n' > "$TARGET/.node-version"
    echo "[init] Created $TARGET/.node-version (Node pin 22)"
  fi
  echo "[init] Node detected — test environment pins created"
else
  echo "[init] Node not found in PATH — skipping .nvmrc/.node-version placeholders (no Node, no pin files)"
fi
