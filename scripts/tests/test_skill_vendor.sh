#!/usr/bin/env bash
# test_skill_vendor.sh — unit tests for scripts/skill-vendor.sh
# Covers add / add --sparse / update / list / remove and permission.skill
# registration in a fake config, without touching the real vendor/ dir.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_skill_vendor"

SCRIPT="$HERE/../skill-vendor.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

VENDOR="$TMP/vendor"
CONFIG="$TMP/opencode.json"
echo '{"permission": {"skill": {}}}' > "$CONFIG"

export SKILL_VENDOR_DIR="$VENDOR"
export SKILL_VENDOR_CONFIG="$CONFIG"

# make_skill_repo <dir> <skill-name> <skill-file-path> <content>
# Builds a git repo (1 commit) containing a SKILL.md at the given path.
make_skill_repo() {
  local dir="$1" name="$2" fpath="$3" content="$4"
  mkdir -p "$dir/$(dirname "$fpath")"
  printf -- '---\nname: %s\ndescription: test skill\n---\n\n# %s\n\n%s\n' \
    "$name" "$name" "$content" > "$dir/$fpath"
  git -C "$dir" init -q
  git -C "$dir" add -A
  git -C "$dir" -c user.name=t -c user.email=t@t commit -qm "add $name"
}

# --- add (single-skill repo, local path → clone dir = repo basename) ---
src="$TMP/repo-color"
make_skill_repo "$src" "test-color" "SKILL.md" "palette logic"
out="$(bash "$SCRIPT" add "$src")"
assert_eq "0" "$?" "add exits 0"
assert_eq "repo-color" "$(ls "$VENDOR")" "add clones into vendor/<repo-basename>"
assert_contains "$VENDOR/repo-color/SKILL.md" "name: test-color" "add preserves SKILL.md"
assert_contains "$CONFIG" '"test-color": "allow"' "add registers skill in permission.skill"

# --- add with quoted frontmatter name (name: "quoted-name") ---
srcq="$TMP/repo-quoted"
mkdir -p "$srcq"
printf -- '---\nname: "quoted-name"\ndescription: quoted\n---\n\n# quoted\n' > "$srcq/SKILL.md"
git -C "$srcq" init -q
git -C "$srcq" add -A
git -C "$srcq" -c user.name=t -c user.email=t@t commit -qm "add quoted"
bash "$SCRIPT" add "$srcq" >/dev/null
assert_contains "$CONFIG" '"quoted-name": "allow"' "add unquotes frontmatter name"

# --- add --sparse (multi-skill repo, only one folder checked out) ---
multi="$TMP/repo-multi"
make_skill_repo "$multi" "want-a" "skills/want-a/SKILL.md" "a"
make_skill_repo "$multi" "skip-b" "skills/skip-b/SKILL.md" "b"
git -C "$multi" add -A
git -C "$multi" -c user.name=t -c user.email=t@t commit -qm "add both"
bash "$SCRIPT" add "$multi" --sparse skills/want-a >/dev/null
assert_contains "$CONFIG" '"want-a": "allow"' "sparse registers only the wanted skill"
if grep -qF '"skip-b": "allow"' "$CONFIG"; then
  t_fail "sparse must not register skipped skill"
else
  t_ok "sparse does not register skipped skill"
fi
assert_eq "want-a" "$(ls "$VENDOR/repo-multi/skills")" "sparse checks out only the wanted folder"

# --- list ---
list_out="$(bash "$SCRIPT" list)"
assert_contains <(printf '%s' "$list_out") "repo-color" "list shows vendored repo"
assert_contains <(printf '%s' "$list_out") "repo-multi" "list shows second vendored repo"

# --- update (origin repo gains a commit; update pulls it) ---
origin="$TMP/repo-update"
make_skill_repo "$origin" "up-skill" "SKILL.md" "v1"
bash "$SCRIPT" add "$origin" >/dev/null
assert_contains "$VENDOR/repo-update/SKILL.md" "v1" "update baseline: v1 present"

printf -- '---\nname: up-skill\ndescription: test\n---\n\n# v2 content\n' > "$origin/SKILL.md"
git -C "$origin" add -A
git -C "$origin" -c user.name=t -c user.email=t@t commit -qm "v2"
bash "$SCRIPT" update repo-update >/dev/null
assert_contains "$VENDOR/repo-update/SKILL.md" "v2 content" "update pulls the newer commit"

# --- remove ---
bash "$SCRIPT" remove repo-color >/dev/null
if [[ -d "$VENDOR/repo-color" ]]; then
  t_fail "remove leaves vendor dir behind"
else
  t_ok "remove deletes the vendor dir"
fi
if grep -qF '"test-color": "allow"' "$CONFIG"; then
  t_fail "remove must unregister the skill from permission.skill"
else
  t_ok "remove unregisters the skill from permission.skill"
fi

# --- config stays valid JSON after all operations ---
if python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
  t_ok "config remains valid JSON"
else
  t_fail "config is no longer valid JSON"
fi

t_finish
