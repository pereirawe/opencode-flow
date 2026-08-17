---
name: telegram-notifier
description: Sends Telegram notifications via the Bot API when an opencode command finishes or when an agent needs a response from the user. Use when finishing long tasks, reporting results, or asking the user for input when they may be away from the terminal ("notificar", "telegram", "avisar no telegram" also trigger this skill).
---

# Telegram Notifier

Response language: user's input language → `.opencode/locale` (project → global) → EN.

Sends Telegram notifications using the Bot API.
The script is at `$HOME/.config/opencode/scripts/telegram-notify.sh`.

## Configuration

Credentials are loaded from (priority order):
1. `./.opencode/telegram.env` (current project)
2. `~/.config/opencode/.opencode/telegram.env` (global)
3. Environment variables `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID`

## When to use

**ALWAYS when one of these situations occurs:**

1. **When a command/task finishes** — notify the result (success or failure).
2. **When you need a response from the user** — if the user is not visibly
   active in the terminal, send the question via Telegram and wait.
3. **When you hit a blocker** — missing business rule, conflict, failure.
4. **When a milestone completes** — pipeline done, MR created, deploy done.

## How to send notifications

### Simple message (via argument)

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh "Development of issue #42 finished. MR: https://github.com/..."
```

### Message with a title

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh --title "⚠️ Action Needed" \
  "Issue #28 needs business review. The 'max discount' field is not defined."
```

### Message via stdin (for long texts)

```bash
cat <<EOF | $HOME/.config/opencode/scripts/telegram-notify.sh --title "📋 Review Report"
Review finished:
- 2 critical issues found
- 5 warnings
- Test coverage: 87%
EOF
```

### Markdown mode

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh --parse-mode markdown \
  "*Review finished*\n\n✅ Tests: passing\n🔒 Security: ok"
```

## Message template

Always use this pattern:

```
Context: <project>/<branch>
<message body>

Action: <what the user needs to do, if applicable>
```

Example:

```
Context: setup-tecnologia/issue-28-close-issue
Implementation finished. MR created:
https://github.com/pereirawe/setup-tecnologia/pull/15

Action: Review and approve the MR.
```

⚠️ **Do not ask the user whether they want a notification** — just send it.
If the credentials are not configured, the script will fail with a clear
message and you continue normally.
