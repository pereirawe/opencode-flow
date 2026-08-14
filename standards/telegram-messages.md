# Telegram Messages — Standard format for agent notifications

Standardized format for Telegram notifications sent by agents via the
`telegram-notifier` skill. Every message identifies the originating project
and follows a category-specific template.

## General rules

1. **Always include project context** — the first line MUST be `🔹 [PROJECT-NAME]`
   so the user knows which workspace the notification comes from.
2. **One notification per event** — each task completion, failure, question, or
   milestone generates exactly one message.
3. **Keep it under 300 characters** — mobile notifications; front-load key info.
4. **Always include an action line when user interaction is needed** — prefixed
   with `→`.
5. **Use the `--parse-mode html` flag** for bold, links, and code.
6. **Never ask for permission to send** — just send the notification.
7. **Detect project name** from the git repository name (`basename "$(git rev-parse --show-toplevel)"` or fallback to the current directory's last component).

## Categories

| Key | Emoji | Use |
|-----|-------|-----|
| `done` | ✅ | Task/command finished successfully |
| `fail` | ❌ | Task/command failed with error |
| `question` | 💬 | Agent needs user response |
| `blocked` | 🚫 | Agent cannot proceed (missing info, permissions) |
| `milestone` | 🏁 | Pipeline phase or release reached |
| `alert` | ⚠️ | Non-blocking warning / heads-up |
| `progress` | ⏳ | Long-running task update |

## Templates by key

### `done` — task completed successfully

```
🔹 [PROJECT]
✅ <what was done>

<1-line result or link>
```

Example:
```
🔹 [opencode-flow]
✅ Pipeline completed — issue #42

MR: https://github.com/pereirawe/opencode-flow/pull/34
```

### `fail` — task failed with error

```
🔹 [PROJECT]
❌ <what failed>

<error cause, 1 line>

→ <remediation action>
```

Example:
```
🔹 [setup-tecnologia]
❌ Test suite failed — 3/47 tests

pytest core/tests/test_auth.py - 2 assertion errors

→ Review failures and re-run development
```

### `question` — agent needs user input

```
🔹 [PROJECT]
💬 <context>

<the question>

→ Reply here or in terminal
```

Example:
```
🔹 [opencode-flow]
💬 Select reviewer count for issue #28

How many Senior Reviewers should review this branch?

→ Reply with a number (1–5)
```

### `blocked` — agent cannot proceed

```
🔹 [PROJECT]
🚫 Blocked — <blocker>

<why it cannot proceed, 1 line>

→ <what needs to happen>
```

Example:
```
🔹 [my-app]
🚫 Blocked — missing business rules

Issue #15 (feat) has no `Business rules:` field.

→ Add business rules to known_issues.md or refine via discovery
```

### `milestone` — pipeline milestone reached

```
🔹 [PROJECT]
🏁 <milestone description>

<link or key detail>
```

Example:
```
🔹 [opencode-flow]
🏁 Version 1.8.0 published

https://github.com/pereirawe/opencode-flow/releases/tag/v1.8.0
```

### `alert` — non-blocking warning

```
🔹 [PROJECT]
⚠️ <warning message>
```

Example:
```
🔹 [my-app]
⚠️ PR #12 has been open for 5 days — merge or close
```

### `progress` — long-running task update

```
🔹 [PROJECT]
⏳ <what's happening> (step X/Y)
```

Example:
```
🔹 [opencode-flow]
⏳ Deep scan in progress (step 2/3 — analyzing Go files)
```

## Script invocation

The script respects the category emoji being part of the `--title`, and the
project header + body as the message:

```bash
SCRIPT="$HOME/.config/opencode/scripts/telegram-notify.sh"

# done
"$SCRIPT" --title "✅ Pipeline completed" "🔹 [my-project]\n\nMR: https://github.com/..."

# fail
"$SCRIPT" --title "❌ Tests failed" "🔹 [my-project]\n\n→ Review failures and re-run"

# question
"$SCRIPT" --title "💬 Input needed" "🔹 [my-project]\n\nWhich branch for issue #42?\n\n→ Reply here"
```

For multi-line messages, use stdin:

```bash
printf "🔹 [my-project]\n\n✅ Feature implemented\nBranch: issue-42-login\nMR: %s" "$MR_URL" | \
  "$SCRIPT" --title "✅ Done"
```

## Chat ID per project (multi-repo setup)

When working across multiple projects, use the `.opencode/telegram.env` file
specific to each project. The script loads project credentials before global:

```
<project>/
├── .opencode/
│   └── telegram.env    ← loaded first (project-specific)
```

If all projects should notify the same chat, keep only the global file at
`~/.config/opencode/.opencode/telegram.env`.
