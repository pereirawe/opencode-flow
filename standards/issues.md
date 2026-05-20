# Issue Tracking

Two-tier issue tracking:
- **Global**: `~/.config/opencode/known_issues.md` — opencode config-level issues
- **Project**: `<project>/.opencode/known_issues.md` — project-specific issues

## Entry Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <user-name> | <model-name>
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief description>
- Impact: <what or who is affected>
- Suggested fix: <approach or next step>
```

## Lifecycle

```
backlog -> ready -> open -> in-progress -> resolved
```

| Status | Meaning |
|--------|---------|
| `backlog` | Captured, not yet refined |
| `ready` | Clear and approved to pick up |
| `open` | Selected, awaiting remote creation |
| `in-progress` | Remote issue exists, work started |
| `resolved` | Completed or closed |
