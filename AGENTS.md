## OpenCode Configuration

Entrypoints:
- `AGENTS.md`
- `opencode.json`
- `agents/` — subagent definitions
- `commands/` — slash command docs
- `skills/` — reusable skills (load via skill tool)
  - `locale-loader` — loads locale-appropriate standards based on `.opencode/locale`
- `.opencode/locale` — active language setting (`pt`, `es`, `en`) — **not** in `opencode.json`
- `scripts/` — shell helpers
- `standards/` — development patterns
- `architecture.md` — technical vision and structural decisions
- `conventions.md` — development conventions and best practices
- `decisions.md` — architecture decision records
- `workflow.md` — development workflow pipeline

## Tracked Work

Two-tier issue tracking:
- **Global**: `known_issues.md` — opencode config-level issues
- **Project**: `<project>/.opencode/known_issues.md` — project-specific issues

Status lifecycle: `backlog -> ready -> open -> in-progress -> resolved`

## Commit Convention

Every commit MUST follow `standards/commits.md`:
- **Atomic**: one logical change per commit
- **Semantic**: `<type>(<scope>): <imperative description>`
- **Tracked**: always include `Issue: #<id>` trailer

Run `/roc:commit` or `make commit` to create a properly structured commit.

## Local Helpers

```
make scan-issues
make review
make promote id=<n>
make close-issue id=<n>
make commit
make bootstrap target=<path>
```

## Project Bootstrap

To use this template in another project:
```
make bootstrap target=/path/to/project
```
Or manually copy `.opencode/` to the target project root.
