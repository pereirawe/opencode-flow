#!/usr/bin/env bash
# test_remote.sh — unit tests for scripts/remote.sh provider detection
# (BR 11 / AC 12 / AC 18): detect_provider and parse_remote over the
# remote.origin.url matrix github / gitlab / none / unknown.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_remote"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

source "$HERE/../remote.sh"

make_repo() { # <dir> <remote-url-or-''>
  local d="$1" url="$2"
  mkdir -p "$d"
  git -C "$d" init -q
  if [[ -n "$url" ]]; then
    git -C "$d" remote add origin "$url"
  fi
}

# --- detect_provider ---
repo="$TMP/gh-ssh"; make_repo "$repo" "git@github.com:owner/repo.git"
assert_eq "github" "$(detect_provider "$repo")" "detect github (ssh form)"

repo="$TMP/gh-https"; make_repo "$repo" "https://github.com/owner/repo.git"
assert_eq "github" "$(detect_provider "$repo")" "detect github (https form)"

repo="$TMP/gl-https"; make_repo "$repo" "https://gitlab.com/group/project.git"
assert_eq "gitlab" "$(detect_provider "$repo")" "detect gitlab"

repo="$TMP/gl-ssh"; make_repo "$repo" "git@gitlab.example.com:group/project.git"
assert_eq "gitlab" "$(detect_provider "$repo")" "detect gitlab (custom host)"

repo="$TMP/no-remote"; make_repo "$repo" ""
assert_eq "none" "$(detect_provider "$repo")" "no remote → none"

repo="$TMP/unknown"; make_repo "$repo" "git@bitbucket.org:team/repo.git"
assert_eq "unknown" "$(detect_provider "$repo")" "unknown host → unknown"

# --- parse_remote ---
repo="$TMP/p-gh-ssh"; make_repo "$repo" "git@github.com:owner/repo.git"
assert_eq "github owner/repo" "$(parse_remote "$repo")" "parse github ssh → owner/repo"

repo="$TMP/p-gh-https"; make_repo "$repo" "https://github.com/owner/repo.git"
assert_eq "github owner/repo" "$(parse_remote "$repo")" "parse github https → owner/repo"

repo="$TMP/p-gh-short"; make_repo "$repo" "https://github.com/owner/repo"
assert_eq "github owner/repo" "$(parse_remote "$repo")" "parse github without .git"

repo="$TMP/p-gl-https"; make_repo "$repo" "https://gitlab.com/group/sub/project.git"
assert_eq "gitlab group/sub/project" "$(parse_remote "$repo")" "parse gitlab nested path"

repo="$TMP/p-none"; make_repo "$repo" ""
assert_eq "none -" "$(parse_remote "$repo")" "parse no remote → 'none -'"

repo="$TMP/p-unknown"; make_repo "$repo" "git@bitbucket.org:team/repo.git"
assert_eq "unknown -" "$(parse_remote "$repo")" "parse unknown remote → 'unknown -'"

t_finish
