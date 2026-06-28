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
| `known_issues.md` | Project-specific issue tracker |
| `prioritization.md` | PO prioritization proposals (project backlog) |
| `resolved_issues.md` | Resolved issues archive (compact) |
| `reviews/` | Branch review reports |
| `locale` | Active language setting (`pt`, `es`, `en`) |

All files are optional. OpenCode merges project config with global config
(`~/.config/opencode/`) automatically.

### Global Config Reference

The global config at `~/.config/opencode/` provides defaults for:
- **Pipeline**: `workflow.md` — discovery, development, and publishing lifecycle
- **Issue tracking**: `known_issues.md`, `prioritization.md`, `resolved_issues.md`
- **Standards**: `standards/` — branching, commits, PR templates, code review guidelines
- **Agents**: `agents/` — CTO, PO, Tech Lead, PM, QA, Developer, Senior Reviewers, Committer, Publish Requester
- **Scripts**: `scripts/` — promote, create_issue, close_issue, maintain, backup
- **Commands**: `commands/` — slash commands documented in `opencode.json`

See the global README (`~/.config/opencode/README.md`) for full documentation.
