#!/usr/bin/env bash
# ocf-telegram.sh — Runs a command and notifies via Telegram when it finishes
# Usage: ocf-telegram.sh <command...>
#
# Example:
#   ocf-telegram.sh opencode run --command "ocf:develop-full 42" --auto

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: ocf-telegram.sh <command...>" >&2
    echo "  Runs the command and sends a Telegram notification when it finishes." >&2
    exit 1
fi

NOTIFY_SCRIPT="$HOME/.config/opencode/scripts/telegram-notify.sh"
START_TIME=$(date +%s)
CMD="$*"

# Project context
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo '?')")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')

echo "🚀 Running: $CMD"
echo "   Project: $PROJECT | Branch: $BRANCH"
echo "---"

# Run the command capturing output
OUTPUT_FILE=$(mktemp)
set +e
eval "$CMD" > "$OUTPUT_FILE" 2>&1
EXIT_CODE=$?
set -e

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_STR=$(printf '%dm%ds' $((DURATION/60)) $((DURATION%60)))

# Tail of the output (show more when there is an error)
if [[ $EXIT_CODE -eq 0 ]]; then
    TAIL_LINES=$(tail -5 "$OUTPUT_FILE" 2>/dev/null || true)
    STATUS_ICON="✅"
    STATUS_TEXT="completed successfully"
else
    TAIL_LINES=$(tail -15 "$OUTPUT_FILE" 2>/dev/null || true)
    STATUS_ICON="❌"
    STATUS_TEXT="failed (exit $EXIT_CODE)"
fi

# Build notification message
MSG="${STATUS_ICON} Command ${STATUS_TEXT}
⏱ Duration: ${DURATION_STR}
📂 Project: ${PROJECT}
🌿 Branch: ${BRANCH}
💻 <code>${CMD}</code>"

if [[ -n "$TAIL_LINES" ]]; then
    MSG="${MSG}"$'\n\n'"<pre>${TAIL_LINES}</pre>"
fi

# Send notification (silent — does not break if it fails)
if [[ -x "$NOTIFY_SCRIPT" ]]; then
    "$NOTIFY_SCRIPT" --title "${STATUS_ICON} Command finished (${DURATION_STR})" "$MSG" 2>/dev/null || true
fi

rm -f "$OUTPUT_FILE"

# Forward the original exit code
exit $EXIT_CODE
