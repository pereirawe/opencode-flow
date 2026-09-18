#!/usr/bin/env bash
# openwa-notify.sh — Sends a WhatsApp notification via the OpenWA API
# Usage: openwa-notify.sh [--title <title>] [message]
#      echo "message" | openwa-notify.sh [flags]
#
# Credentials loaded from (load order; env vars override files):
#   1. ./.opencode/openwa.env (current project)
#   2. ~/.config/opencode/.opencode/openwa.env (global)
#   3. Environment variables OPENWA_BASE_URL / OPENWA_SESSION_ID / OPENWA_API_KEY / OPENWA_CHAT_ID (override)

set -euo pipefail

TITLE=""
MESSAGE=""
BASE_URL=""
SESSION_ID=""
API_KEY=""
CHAT_ID=""

usage() {
    cat <<EOF
Usage: openwa-notify.sh [--title <title>] [message]

Sends a notification to WhatsApp via the OpenWA API.

Options:
  --title <title>       Notification title (prepended to the message)
  -h, --help            Show this help

The message can be passed as an argument or via stdin.
EOF
    exit 0
}

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)
            if [[ $# -lt 2 ]]; then
                echo "❌ --title requires a value" >&2
                exit 1
            fi
            TITLE="$2"
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
# Capture env-var overrides BEFORE any file is sourced (BR1: env > project > global)
ENV_BASE_URL="${OPENWA_BASE_URL:-}"
ENV_SESSION_ID="${OPENWA_SESSION_ID:-}"
ENV_API_KEY="${OPENWA_API_KEY:-}"
ENV_CHAT_ID="${OPENWA_CHAT_ID:-}"

load_env_file() {
    local env_file="$1"
    [[ -f "$env_file" ]] || return 0
    # Set-if-absent: the first file that defines a variable wins, so the
    # project file beats the global file (and neither overwrites env vars).
    # The `|| [[ -n "$key" ]]` guard also reads a final line without a
    # trailing newline (read returns EOF status for it).
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        [[ "$key" == OPENWA_* ]] || continue
        if [[ -z "${!key:-}" ]]; then
            export "$key=$value"
        fi
    done < "$env_file"
}

# 1. Project-level .opencode/openwa.env
load_env_file "./.opencode/openwa.env"

# 2. Global ~/.config/opencode/.opencode/openwa.env
load_env_file "$HOME/.config/opencode/.opencode/openwa.env"

# 3. Environment variables (override)
BASE_URL="${ENV_BASE_URL:-${OPENWA_BASE_URL:-}}"
SESSION_ID="${ENV_SESSION_ID:-${OPENWA_SESSION_ID:-}}"
API_KEY="${ENV_API_KEY:-${OPENWA_API_KEY:-}}"
CHAT_ID="${ENV_CHAT_ID:-${OPENWA_CHAT_ID:-}}"

# --- Validate ---
if [[ -z "$API_KEY" ]]; then
    echo "❌ OPENWA_API_KEY not set." >&2
    echo "   Create .opencode/openwa.env or export the variable." >&2
    exit 1
fi

if [[ -z "$SESSION_ID" ]]; then
    echo "❌ OPENWA_SESSION_ID not set." >&2
    echo "   Create .opencode/openwa.env or export the variable." >&2
    exit 1
fi

if [[ -z "$BASE_URL" ]]; then
    echo "❌ OPENWA_BASE_URL not set." >&2
    echo "   Create .opencode/openwa.env or export the variable." >&2
    exit 1
fi

if [[ -z "$CHAT_ID" ]]; then
    echo "❌ OPENWA_CHAT_ID not set." >&2
    echo "   Create .opencode/openwa.env or export the variable." >&2
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
    FULL_MESSAGE="${TITLE}"$'\n\n'"${MESSAGE}"
fi

# --- JSON-escape a string (pure bash, no external deps) ---
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"          # backslash first
    s="${s//\"/\\\"}"          # double quotes
    s="${s//$'\t'/\\t}"        # tab
    s="${s//$'\n'/\\n}"        # newline
    s="${s//$'\r'/\\r}"        # carriage return
    # Strip remaining control characters that would break JSON
    s=$(printf '%s' "$s" | tr -d '\001-\010\013\014\016-\037\177')
    printf '%s' "$s"
}

ESCAPED_TEXT="$(json_escape "$FULL_MESSAGE")"
ESCAPED_CHAT_ID="$(json_escape "$CHAT_ID")"

# --- Send via OpenWA API ---
API_URL="${BASE_URL}/api/sessions/${SESSION_ID}/messages/send-text"
payload="{\"chatId\": \"${ESCAPED_CHAT_ID}\", \"text\": \"${ESCAPED_TEXT}\"}"

curl_rc=0
response=$(curl -sS --max-time 30 -w '\n%{http_code}' -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ${API_KEY}" \
    -d "$payload" 2>&1) || curl_rc=$?

if [[ "$curl_rc" -ne 0 ]]; then
    # Strip the trailing http_code line (e.g. '000') from curl's error output
    curl_err=$(printf '%s\n' "$response" | sed '$d')
    echo "❌ Failed to reach OpenWA API: ${curl_err}" >&2
    exit 1
fi

http_code=$(printf '%s\n' "$response" | tail -n 1)
body=$(printf '%s\n' "$response" | sed '$d')

if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    echo "✅ WhatsApp message sent to ${CHAT_ID}" >&2
    exit 0
fi

# --- API error: extract message/error field, fall back to raw body ---
error_msg=$(printf '%s' "$body" | grep -oE '"(message|error)":"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)
if [[ -z "$error_msg" ]]; then
    error_msg="$body"
fi
echo "❌ Failed to send WhatsApp message (HTTP ${http_code}): ${error_msg}" >&2
exit 1