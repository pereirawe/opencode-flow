# OpenCode Project Configuration

Generic, language-agnostic configuration for AI-assisted development workflow.

## Structure

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Entrypoint instructions |
| `opencode.json` | OpenCode configuration |
| `agents/` | Subagent definitions (CTO, PO, PM, Dev, etc.) |
| `commands/` | Slash command documentation |
| `skills/` | Reusable skills (issue-manager, etc.) |
| `scripts/` | Shell helpers for issue lifecycle |
| `standards/` | Development patterns (branching, commits, PR) |
| `known_issues.md` | Tracked work register |
| `Makefile` | Convenience targets |

## Usage

```
make -f .config/opencode/Makefile scan-issues
make -f .config/opencode/Makefile review
make -f .config/opencode/Makefile promote id=<n>
make -f .config/opencode/Makefile close-issue id=<n>
```

See individual directories for details.
