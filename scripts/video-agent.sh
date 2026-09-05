#!/usr/bin/env bash
# Video Script agent utility — validates and keeps the video-script agent
# family consistent (agents are authored in English, issue #36).
#
# Routine value: runs before committing agent edits so a broken or orphaned
# agent never reaches the repo. Read-only and idempotent — never writes,
# never overwrites, never fabricates content.

set -euo pipefail
source "$(dirname "$0")/config.sh"

AGENTS_DIR="$CONFIG_DIR/agents/marketing"
WRITER="video-script-writer.md"
SUBAGENTS=(video-script-seo.md video-script-thumbnail.md video-script-variations.md)

help() {
  cat <<'EOF'
Usage: video-agent.sh <command>

Commands:
  check | status   Validate the video-script agent family: writer + subagents
                   exist, have valid frontmatter (mode: subagent) and the
                   writer references each subagent. Exit 0 when healthy,
                   2 when an agent is missing, invalid or orphaned.
  --help | -h      Show this help.
EOF
}

# has_frontmatter <file> — true when the file opens with a YAML frontmatter
# block and declares `mode: subagent`.
has_frontmatter() {
  local file="$1"
  [[ "$(sed -n '1p' "$file")" == "---" ]] || return 1
  grep -q '^mode: subagent' "$file" || return 1
}

check() {
  local status=0 agent

  for agent in "$WRITER" "${SUBAGENTS[@]}"; do
    if [[ ! -f "$AGENTS_DIR/$agent" ]]; then
      echo "FAIL  missing agent: $AGENTS_DIR/$agent"
      status=2
    elif ! has_frontmatter "$AGENTS_DIR/$agent"; then
      echo "FAIL  invalid frontmatter (expected mode: subagent): $AGENTS_DIR/$agent"
      status=2
    else
      echo "ok    $agent"
    fi
  done

  for sub in "${SUBAGENTS[@]}"; do
    if ! grep -q "${sub%.md}" "$AGENTS_DIR/$WRITER"; then
      echo "FAIL  orphaned subagent (writer does not reference it): $sub"
      status=2
    else
      echo "ok    writer references ${sub%.md}"
    fi
  done

  if [[ "$status" -eq 0 ]]; then
    echo "VERDICT: PASS — video-script agent family is healthy"
  else
    echo "VERDICT: FAIL — fix the items above before committing agent edits"
  fi
  exit "$status"
}

case "${1:-}" in
  check|status) check ;;
  --help|-h|"") help ;;
  *) echo "video-agent.sh: unknown command '$1'" >&2; help; exit 2 ;;
esac
