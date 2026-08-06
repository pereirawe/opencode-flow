#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# skill-vendor.sh — manage external skills as git clones (vendor strategy).
#
# External skills are NEVER copied into skills/. They stay as git clones under
# ~/.config/opencode/vendor/ and are loaded in-place via "skills.paths" in
# opencode.json. Updating is a plain `git pull` (no re-import).
#
# Usage:
#   skill-vendor.sh add <url|owner/repo> [--sparse <paths...>]
#   skill-vendor.sh update <name>
#   skill-vendor.sh list
#   skill-vendor.sh remove <name>
#
# Examples:
#   skill-vendor.sh add meodai/skill.color-expert
#   skill-vendor.sh add Leonxlnx/taste-skill --sparse skills/taste-skill skills/redesign-skill skills/minimalist-skill
#   skill-vendor.sh update taste-skill

VENDOR_DIR="${SKILL_VENDOR_DIR:-$HOME/.config/opencode/vendor}"
OPENCODE_CONFIG="${SKILL_VENDOR_CONFIG:-$HOME/.config/opencode/opencode.json}"

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  echo "Usage: skill-vendor.sh add <url|owner/repo> [--sparse <paths...>] | update <name> | list | remove <name>"
  exit 1
fi

# validate_name <name> — a vendor dir name must be a single path component
# (no /, no . or ..) to keep remove/update/add confined to VENDOR_DIR.
validate_name() {
  [[ -n "$1" && "$1" != "." && "$1" != ".." && "$1" != */* ]]
}

# normalize_url <url|owner/repo|local-path> — print a cloneable source
normalize_url() {
  local u="$1"
  case "$u" in
    /* | ./*) echo "$u" ;;              # local path (also used in tests)
    *://* | git@*) echo "$u" ;;
    *) echo "https://github.com/$u" ;;
  esac
}

# repo_name <url> — print the local directory name for a repo URL
repo_name() {
  local u="$1"
  u="${u%/}"                            # strip trailing slash
  u="${u##*/}"
  u="${u%.git}"
  [[ -n "$u" ]] || { echo "could not derive repo name from '$1'" >&2; exit 1; }
  echo "$u"
}

# skill_name <sk.md> — print the frontmatter `name:` of a SKILL.md (empty if none)
skill_name() {
  local f="$1"
  awk '
    { gsub(/\r$/, "") }                    # tolerate CRLF line endings
    NR==1 && /^---$/ {infm=1; next}
    infm && /^---$/ {exit}
    infm && /^name:[[:space:]]/ {
      sub(/^name:[[:space:]]*/, "")
      sub(/[[:space:]]#.*$/, "")          # strip inline YAML comments
      gsub(/^["'\''\t ]+|["'\''\t ]+$/, "")
      print
      exit
    }
  ' "$f" 2>/dev/null
}

# discover_skills <dir> — print "path<TAB>name" per SKILL.md found
discover_skills() {
  local dir="$1"
  local f n
  while IFS= read -r f; do
    n="$(skill_name "$f")"
    [[ -n "$n" ]] && printf '%s\t%s\n' "$f" "$n"
  done < <(find "$dir" -name SKILL.md -type f 2>/dev/null)
}

# discover_names <dir> — print unique frontmatter names in a clone (one per line)
discover_names() {
  discover_skills "$1" | cut -f2 | sort -u
}

# config_register_skills <name...> — add each skill to permission.skill (atomic)
config_register_skills() {
  [[ "$#" -gt 0 ]] || return 0
  python3 -c '
import json, os, sys
path = sys.argv[1]
names = sys.argv[2:]
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)
skill = cfg.setdefault("permission", {}).setdefault("skill", {})
for n in names:
    skill[n] = "allow"
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=4, ensure_ascii=False)
    fh.write("\n")
os.replace(tmp, path)
' "$OPENCODE_CONFIG" "$@"
}

# config_unregister_skills <name...> — remove each skill from permission.skill (atomic)
config_unregister_skills() {
  [[ "$#" -gt 0 ]] || return 0
  python3 -c '
import json, os, sys
path = sys.argv[1]
names = set(sys.argv[2:])
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)
skill = cfg.get("permission", {}).get("skill", {})
changed = False
for n in names:
    if n in skill:
        del skill[n]
        changed = True
if changed:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(cfg, fh, indent=4, ensure_ascii=False)
        fh.write("\n")
    os.replace(tmp, path)
' "$OPENCODE_CONFIG" "$@"
}

# config_existing_skills <name...> — print names already registered as allow
config_existing_skills() {
  [[ "$#" -gt 0 ]] || return 0
  python3 -c '
import json, sys
cfg = json.load(open(sys.argv[1], encoding="utf-8"))
sk = cfg.get("permission", {}).get("skill", {})
want = set(sys.argv[2:])
print(" ".join(sorted(n for n in want if n in sk)))
' "$OPENCODE_CONFIG" "$@"
}

# clone_repo <url> <dir> [sparse paths...] — clone with partial-clone fallback
clone_repo() {
  local url="$1" dir="$2"
  shift 2
  mkdir -p "$VENDOR_DIR"
  if [[ "$#" -gt 0 ]]; then
    echo "[skill-vendor] cloning $url (sparse: $*)"
    if ! git clone --depth 1 --filter=blob:none --sparse "$url" "$dir" >/dev/null 2>&1; then
      rm -rf "$dir"
      echo "[skill-vendor] partial clone unsupported — falling back to shallow sparse clone"
      git clone --depth 1 --sparse "$url" "$dir" >/dev/null
    fi
    git -C "$dir" sparse-checkout set --skip-checks "$@"
  else
    echo "[skill-vendor] cloning $url"
    git clone --depth 1 "$url" "$dir" >/dev/null
  fi
}

cmd_add() {
  [[ "$#" -ge 1 ]] || { echo "Usage: skill-vendor.sh add <url|owner/repo> [--sparse <paths...>]"; exit 1; }
  local url name sparse=() orig
  orig="$1"
  url="$(normalize_url "$1")"
  name="$(repo_name "$1")"
  shift

  if [[ "${1:-}" == "--sparse" ]]; then
    shift
    [[ "$#" -ge 1 ]] || { echo "--sparse requires at least one path"; exit 1; }
    sparse=("$@")
  fi

  validate_name "$name" || { echo "[skill-vendor] invalid repo name '$name' for '$orig'"; exit 1; }

  # Name collision: if the vendor dir already exists under a different upstream,
  # qualify with the owner (e.g. wispbit-ai/skills vs eachlabs/skills).
  if [[ -d "$VENDOR_DIR/$name/.git" ]]; then
    local existing
    existing="$(git -C "$VENDOR_DIR/$name" config --get remote.origin.url 2>/dev/null || true)"
    if [[ -n "$existing" && "$existing" != "$url" ]]; then
      name="$(printf '%s' "$url" | sed -E 's#.*[:/]([^/:]+)/[^/]+$#\1#')-$name"
      echo "[skill-vendor] '$orig' collides with an existing vendor dir — using '$name'"
    fi
  fi

  if [[ -d "$VENDOR_DIR/$name" ]]; then
    echo "[skill-vendor] '$name' already exists at $VENDOR_DIR/$name"
    echo "[skill-vendor] run 'skill-vendor.sh update $name' to refresh it"
    exit 1
  fi

  clone_repo "$url" "$VENDOR_DIR/$name" "${sparse[@]}"

  local -a names_arr=()
  local s
  while IFS= read -r s; do names_arr+=("$s"); done <<< "$(discover_names "$VENDOR_DIR/$name")"

  if [[ "${#names_arr[@]}" -eq 0 ]]; then
    echo "[skill-vendor] WARNING: no SKILL.md with frontmatter name found under $VENDOR_DIR/$name"
  else
    local dupes
    dupes="$(config_existing_skills "${names_arr[@]}")"
    config_register_skills "${names_arr[@]}"
    for s in "${names_arr[@]}"; do
      echo "[skill-vendor] registered skill '$s' in permission.skill"
    done
    if [[ -n "$dupes" ]]; then
      echo "[skill-vendor] WARNING: skills already registered by another vendor repo: $dupes"
    fi
  fi
  echo "[skill-vendor] cloned '$name' → $VENDOR_DIR/$name (update with 'skill-vendor.sh update $name')"
}

cmd_update() {
  local name="${1:-}"
  [[ -n "$name" ]] || { echo "Usage: skill-vendor.sh update <name>"; exit 1; }
  validate_name "$name" || { echo "[skill-vendor] invalid vendor name '$name'"; exit 1; }
  local dir="$VENDOR_DIR/$name"
  [[ -d "$dir/.git" ]] || { echo "[skill-vendor] '$name' not found in $VENDOR_DIR"; exit 1; }
  echo "[skill-vendor] pulling $name"
  git -C "$dir" pull
  git -C "$dir" sparse-checkout reapply 2>/dev/null || true
  local -a names_arr=()
  local s
  while IFS= read -r s; do names_arr+=("$s"); done <<< "$(discover_names "$dir")"
  [[ "${#names_arr[@]}" -eq 0 ]] || config_register_skills "${names_arr[@]}"
  echo "[skill-vendor] '$name' updated"
}

cmd_list() {
  [[ -d "$VENDOR_DIR" ]] || { echo "[skill-vendor] no vendor dir yet ($VENDOR_DIR)"; exit 0; }
  local dir name remote commit skills found=0
  for dir in "$VENDOR_DIR"/*/; do
    [[ -d "$dir/.git" ]] || continue
    found=1
    name="$(basename "$dir")"
    remote="$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "?")"
    commit="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo "?")"
    skills="$(discover_skills "$dir" | cut -f2 | paste -sd, -)"
    printf '%-24s %-60s %s\n' "$name" "$remote" "$commit"
    [[ -n "$skills" ]] && printf '  skills: %s\n' "$skills"
  done
  [[ "$found" -eq 1 ]] || echo "[skill-vendor] vendor dir is empty ($VENDOR_DIR)"
}

cmd_remove() {
  local name="${1:-}"
  [[ -n "$name" ]] || { echo "Usage: skill-vendor.sh remove <name>"; exit 1; }
  validate_name "$name" || { echo "[skill-vendor] invalid vendor name '$name'"; exit 1; }
  local dir="$VENDOR_DIR/$name"
  [[ -d "$dir/.git" ]] || { echo "[skill-vendor] '$name' not found in $VENDOR_DIR"; exit 1; }
  local -a names_arr=()
  local s
  while IFS= read -r s; do names_arr+=("$s"); done <<< "$(discover_names "$dir")"
  rm -rf "$dir"
  if [[ "${#names_arr[@]}" -gt 0 ]]; then
    config_unregister_skills "${names_arr[@]}"
    echo "[skill-vendor] removed '$name' (skills unregistered: ${names_arr[*]})"
  else
    echo "[skill-vendor] removed '$name' (no skills registered)"
  fi
}

case "$cmd" in
  add)    shift; cmd_add "$@" ;;
  update) shift; cmd_update "$@" ;;
  list)   cmd_list ;;
  remove) shift; cmd_remove "$@" ;;
  *)
    echo "Unknown command: $cmd"
    echo "Usage: skill-vendor.sh add <url|owner/repo> [--sparse <paths...>] | update <name> | list | remove <name>"
    exit 1
    ;;
esac
