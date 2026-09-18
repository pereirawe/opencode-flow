---
name: openwa-notifier
description: Sends WhatsApp notifications via the OpenWA API when an opencode command finishes or when an agent needs a response from the user. Use when finishing long tasks, reporting results, or asking the user for input when they may be away from the terminal ("notificar no whatsapp", "aviso whatsapp", "notificação whatsapp" also trigger this skill).
---

# OpenWA Notifier (WhatsApp)

Response language: user's input language → `.opencode/locale` (project → global) → EN.

Sends WhatsApp notifications using the OpenWA API.
The script is at `$HOME/.config/opencode/scripts/openwa-notify.sh`.

## Configuration

Credentials are loaded from (priority order):
1. `./.opencode/openwa.env` (current project)
2. `~/.config/opencode/.opencode/openwa.env` (global)
3. Environment variables `OPENWA_BASE_URL` / `OPENWA_SESSION_ID` / `OPENWA_API_KEY` / `OPENWA_CHAT_ID`

The env file must contain:

```
OPENWA_BASE_URL=https://<host>
OPENWA_SESSION_ID=<session-id>
OPENWA_API_KEY=<api-key>
OPENWA_CHAT_ID=<chat-id>@lid
```

## When to use

**ALWAYS when one of these situations occurs:**

1. **When a command/task finishes** — notify the result (success or failure).
2. **When you need a response from the user** — if the user is not visibly
   active in the terminal, send the question via WhatsApp and wait.
3. **When you hit a blocker** — missing business rule, conflict, failure.
4. **When a milestone completes** — pipeline done, MR created, deploy done.

## How to send notifications

### Simple message (via argument)

```bash
$HOME/.config/opencode/scripts/openwa-notify.sh "Development of issue #42 finished. MR: https://github.com/..."
```

### Message with a title

```bash
$HOME/.config/opencode/scripts/openwa-notify.sh --title "⚠️ Action Needed" \
  "Issue #28 needs business review. The 'max discount' field is not defined."
```

### Message via stdin (for long texts)

```bash
cat <<EOF | $HOME/.config/opencode/scripts/openwa-notify.sh --title "📋 Review Report"
Review finished:
- 2 critical issues found
- 5 warnings
- Test coverage: 87%
EOF
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