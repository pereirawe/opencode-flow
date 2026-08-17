#!/usr/bin/env bash
# telegram-notify.sh — Sends a Telegram notification via the Bot API
# Usage: telegram-notify.sh [--title <title>] [--parse-mode html|markdown] [--chat-id <id>] [message]
#      echo "message" | telegram-notify.sh [flags]
#
# Credentials loaded from (priority order):
#   1. ./.opencode/telegram.env (current project)
#   2. ~/.config/opencode/.opencode/telegram.env (global)
#   3. Environment variables TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSE_MODE="HTML"
TITLE=""
MESSAGE=""
CHAT_ID=""
BOT_TOKEN=""

usage() {
    cat <<EOF
Usage: telegram-notify.sh [--title <title>] [--parse-mode html|markdown] [--chat-id <id>] [message]

Sends a notification to Telegram via the Bot API.

Options:
  --title <title>       Notification title (rendered in bold)
  --parse-mode <mode>   Parse mode: html (default), markdown
  --chat-id <id>        Destination chat ID (overrides config/env)
  -h, --help            Show this help

The message can be passed as an argument or via stdin.
EOF
    exit 0
}

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)
            TITLE="$2"
            shift 2
            ;;
        --parse-mode)
            PARSE_MODE="$2"
            shift 2
            ;;
        --chat-id)
            CHAT_ID="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "❌ Unknown flag: $1" >&2
            exit 1
            ;;
        *)
            MESSAGE="$1"
            shift
            ;;
    esac
done

# --- Load credentials ---
load_env_file() {
    local env_file="$1"
    if [[ -f "$env_file" ]]; then
        # shellcheck source=/dev/null
        source "$env_file"
    fi
}

# 1. Project-level .opencode/telegram.env
load_env_file "./.opencode/telegram.env"

# 2. Global ~/.config/opencode/.opencode/telegram.env
load_env_file "$HOME/.config/opencode/.opencode/telegram.env"

# 3. Environment variables (override)
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-$BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID:-$CHAT_ID}"

# --- Validate ---
if [[ -z "$BOT_TOKEN" ]]; then
    echo "❌ TELEGRAM_BOT_TOKEN not set." >&2
    echo "   Create .opencode/telegram.env or export the variable." >&2
    exit 1
fi

if [[ -z "$CHAT_ID" ]]; then
    echo "❌ TELEGRAM_CHAT_ID not set." >&2
    echo "   Pass --chat-id, create .opencode/telegram.env or export the variable." >&2
    exit 1
fi

# --- Read message from stdin if not provided as argument ---
if [[ -z "$MESSAGE" ]]; then
    if [[ ! -t 0 ]]; then
        MESSAGE=$(cat)
    fi
fi

if [[ -z "$MESSAGE" ]]; then
    echo "❌ No message provided." >&2
    echo "   Pass it as an argument or via stdin." >&2
    exit 1
fi

# --- Build message with optional title ---
FULL_MESSAGE="$MESSAGE"
if [[ -n "$TITLE" ]]; then
    if [[ "$PARSE_MODE" == "HTML" ]]; then
        FULL_MESSAGE="<b>${TITLE}</b>"$'\n\n'"${MESSAGE}"
    elif [[ "$PARSE_MODE" == "markdown" || "$PARSE_MODE" == "MarkdownV2" ]]; then
        FULL_MESSAGE="*${TITLE}*"$'\n\n'"${MESSAGE}"
    else
        FULL_MESSAGE="${TITLE}"$'\n\n'"${MESSAGE}"
    fi
fi

# --- Send via Telegram API ---
API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

response=$(curl -s -X POST "$API_URL" \
    -d "chat_id=${CHAT_ID}" \
    -d "parse_mode=${PARSE_MODE}" \
    --data-urlencode "text=${FULL_MESSAGE}" \
    2>&1)

# --- Check result ---
if echo "$response" | grep -q '"ok":true'; then
    echo "✅ Notification sent to chat ${CHAT_ID}" >&2
    exit 0
else
    error_desc=$(echo "$response" | grep -o '"description":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "❌ Failed to send notification: ${error_desc:-$response}" >&2
    exit 1
fi
