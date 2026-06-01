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

Status lifecycle: `backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved`

## Mandatory Pipeline Rule

**Every implementation request — regardless of how it's asked — MUST follow the
full pipeline defined in `workflow.md`.** No direct implementation without going
through the documented lifecycle: issue tracking → promotion (branch) →
development → senior review → QA → committer gate → commit → MR.

This rule exists to ensure consistency, traceability, and quality across all
changes. It applies to bugs, features, chores, and documentation alike.

For agents: if asked to implement something directly, first verify the issue
exists in `known_issues.md`, promote it, switch to the branch, then implement.

## Commit Convention

Every commit MUST follow `standards/commits.md`:
- **Atomic**: one logical change per commit
- **Semantic**: `<type>(<scope>): <imperative description>`
- **Tracked**: always include `Issue: #<id>` trailer

Run `/ocf:commit` or `make commit` to create a properly structured commit.

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
