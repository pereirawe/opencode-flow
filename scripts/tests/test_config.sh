#!/usr/bin/env bash
# test_config.sh — validates the opencode.json `instructions` array (issues #205/#206/#207).
#
# Issue #205: the `~/.config/opencode/agents/*/*.md` glob is removed from
# `instructions` (agents in ~/.config/opencode/agents/ are auto-registered as
# subagents — the glob was pure context duplication), while the small
# `agents/*/devs/REGISTRY.md` glob is kept.
#
# Issue #206: `known_issues.md` and `prioritization.md` are removed from
# `instructions` — they are loaded on demand via awk by agents/commands, never
# injected into every session.
#
# Issue #207: the `standards/*.md`, `standards/pt/*.md` and `standards/es/*.md`
# globs are removed — standards load on demand via the locale-loader skill.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_config"

CONFIG="$HERE/../../opencode.json"

if ! command -v jq >/dev/null 2>&1; then
  t_fail "jq is required for test_config"
  t_finish
  exit 0
fi

instructions() {
  jq -r '.instructions[]' "$CONFIG" 2>/dev/null
}

# --- Issue #205: agents glob removed, REGISTRY.md kept ---
if instructions | grep -qF "~/.config/opencode/agents/*/devs/REGISTRY.md"; then
  t_ok "instructions keeps agents/*/devs/REGISTRY.md"
else
  t_fail "instructions missing agents/*/devs/REGISTRY.md"
fi

if instructions | grep -qF "~/.config/opencode/agents/*/*.md"; then
  t_fail "instructions contains forbidden agents/*/*.md glob"
else
  t_ok "instructions has no agents/*/*.md glob"
fi

t_finish
