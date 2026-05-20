## OpenCode Configuration

Entrypoints:
- `AGENTS.md`
- `opencode.json`
- `agents/` — subagent definitions
- `commands/` — slash command docs
- `skills/` — reusable skills (load via skill tool)
- `scripts/` — shell helpers
- `standards/` — development patterns

## Tracked Work

- Register: `known_issues.md`
- Status lifecycle: `backlog -> ready -> open -> in-progress -> resolved`

## Local Helpers

```
make -f .config/opencode/Makefile scan-issues
make -f .config/opencode/Makefile review
make -f .config/opencode/Makefile promote id=<n>
make -f .config/opencode/Makefile close-issue id=<n>
```
