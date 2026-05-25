## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <user-name> | <model-name>
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.

### Status Lifecycle

- `backlog`: item captured but not yet refined or prioritized
- `ready`: item is clear enough to be picked up
- `open`: item selected locally and awaiting remote issue creation
- `in-progress`: remote issue exists and work has started
- `in-review`: senior review done, QA verified, awaiting merge
- `resolved`: completed or closed item (removed from active list)

Resolved issues move to `resolved_issues.md` (same directory as this file). See `standards/resolved-issue.md` for the archive format.
