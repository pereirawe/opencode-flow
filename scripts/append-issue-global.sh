#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# append-issue-global.sh — append a canonical issue entry to the GLOBAL
# (opencode config-level) tracker, regardless of the current working directory.
#
# Why this exists (issue #244): the loop error-review router runs from the
# workspace where a loop executed (often a target project whose `.opencode/`
# tracker is the project one) but must be able to file a config/tooling error
# into `~/.config/opencode/known_issues.md`. It forces the tracker with the
# `OCF_ISSUES_FILE` override understood by `scripts/config.sh`.
#
# Accepts every flag of `append-issue.sh` and forwards them unchanged.
#
# Usage:
#   scripts/append-issue-global.sh --title "..." --type bug --severity high ...

OCF_ISSUES_FILE="$ISSUES_FILE" exec "$SCRIPTS_DIR/append-issue.sh" "$@"
