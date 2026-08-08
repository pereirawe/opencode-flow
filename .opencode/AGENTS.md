## Project Instructions

This file is loaded as a project-level instruction overlay.
Global config from `~/.config/opencode/` is loaded automatically.

### Project Entrypoints

- `.opencode/opencode.json` — Project config
- `.opencode/agents/` — Project-specific agents
- `.opencode/commands/` — Project-specific commands
- `.opencode/skills/` — Project-specific skills
- `.opencode/locale` — Locale setting for this project (`pt`, `es`, `en`)

### Repository Context

- Default branch: `__DEFAULT_BRANCH__`
- Remotes:
__REMOTES__

### Workflow

See `.opencode/workflow.md` for project-specific workflow rules.

### Telegram Notifications

When finishing a command/task or when you need a response from the user and they
may be away from the terminal, send a Telegram notification via the
`telegram-notifier` skill or the script at
`$HOME/.config/opencode/scripts/telegram-notify.sh`. Credentials are loaded
from `.opencode/telegram.env` (project) or
`~/.config/opencode/.opencode/telegram.env` (global).

Do NOT ask the user whether they want a notification — just send it. If
credentials are missing, the script fails gracefully with a clear error message
and you continue normally.
