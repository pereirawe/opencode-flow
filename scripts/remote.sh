#!/usr/bin/env bash
# remote.sh — shared remote provider detection for opencode scripts.
#
# Extracted from sync_github_issues.sh (issue #39) so the aibot-watcher and
# other scripts share one provider-detection implementation based on
# `git config --get remote.origin.url`.
#
# Usage (source this file):
#   source "$(dirname "$0")/remote.sh"
#   PROVIDER="$(detect_provider /path/to/repo)"
#   parse_remote /path/to/repo   # prints "<provider> <owner/repo>"
#
# Provider values: github | gitlab | none (no remote) | unknown (remote present
# but not recognized as GitHub/GitLab).

# detect_provider <dir> — echo github | gitlab | none | unknown
detect_provider() {
  local dir="${1:-.}"
  local url
  url="$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "")"
  if [[ -z "$url" ]]; then
    echo "none"
  elif [[ "$url" == *"github.com"* ]]; then
    echo "github"
  elif [[ "$url" == *"gitlab"* ]]; then
    echo "gitlab"
  else
    echo "unknown"
  fi
}

# get_remote_url <dir> — echo remote.origin.url (empty string when none)
get_remote_url() {
  local dir="${1:-.}"
  git -C "$dir" config --get remote.origin.url 2>/dev/null || echo ""
}

# parse_remote <dir> — echo "<provider> <owner/repo>"
#   github:  "github pereirawe/opencode-flow"
#   gitlab:  "gitlab group/project"
#   none:    "none -"
#   unknown: "unknown -"
parse_remote() {
  local dir="${1:-.}"
  local provider url path
  provider="$(detect_provider "$dir")"
  url="$(get_remote_url "$dir")"
  if [[ "$provider" == "none" || "$provider" == "unknown" || -z "$url" ]]; then
    echo "$provider -"
    return 0
  fi
  # Strip transport prefix, keep "<owner>/<repo>":
  #   git@github.com:owner/repo.git          -> owner/repo
  #   ssh://git@github.com/owner/repo.git    -> owner/repo
  #   https://github.com/owner/repo.git      -> owner/repo
  path="$(printf '%s' "$url" \
    | sed -E 's#^[^@/]+@[^:]+:##; s#^[a-z][a-z0-9+.-]*://[^/]+/##; s#\.git$##; s#/$##')"
  echo "$provider $path"
}
