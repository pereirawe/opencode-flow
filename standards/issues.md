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

`Remote:` is required. Use `-` when no remote issue exists yet.

## Lifecycle

```
backlog -> ready -> open -> in-progress -> in-review -> resolved
```

| Status | Meaning |
|--------|---------|
| `backlog` | Captured, not yet refined |
| `ready` | Clear and approved to pick up |
| `open` | Selected, awaiting remote creation |
| `in-progress` | Remote issue exists, work started |
| `in-review` | Senior review done, MR created, awaiting merge |
| `resolved` | MR approved and merged (moved to archive) |

## Resolved Archive

Resolved issues are removed from `known_issues.md` and moved to `resolved_issues.md`
in compact format. See `standards/resolved-issue.md` for details.

## Branch Review Naming

Review output from `/roc:review-branch` is written to:

```
<project>/.opencode/<model>_<branch>_issues.md
```

This keeps reviews isolated by model and branch, avoiding clutter in the main tracker.
These files are ephemeral — once issues are triaged into `known_issues.md`, the
review file can be deleted or archived.
