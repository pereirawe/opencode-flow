## Project OpenCode Configuration

This directory is a project-level override template.
Copy this directory to your project root for project-specific OpenCode setup.

### How to Bootstrap

```
make bootstrap target=/path/to/project
```

Or manually:
```
cp -r .opencode /path/to/project/.opencode
```

### Structure

| Path | Purpose |
|------|---------|
| `opencode.json` | Project-specific config (overrides global) |
| `AGENTS.md` | Project-specific instructions |
| `workflow.md` | Project-specific workflow rules |
| `agents/` | Project-specific agent definitions |
| `commands/` | Project-specific slash commands |
| `skills/` | Project-specific skills |

All files are optional. OpenCode merges project config with global config
(`~/.config/opencode/`) automatically.
