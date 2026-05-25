# Issue Tracking

Two-tier issue tracking:
- **Global**: `~/.config/opencode/known_issues.md` — opencode config-level issues
- **Project**: `<project>/.opencode/known_issues.md` — project-specific issues

## Entry Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <user-name> | <model-name>
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief description>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Acceptance criteria: <what must be true for the issue to be complete>
- Suggested fix: <approach or next step>
```

`Remote:` is required. Use `-` when no remote issue exists yet.
`Business rules:` is required for `feat` type issues — document the specific
business logic, domain constraints, and rules that must be implemented.
`Acceptance criteria:` is recommended for all types. `Tests:` can be added
as an additional field when specific test scenarios need documentation.

## Type Classification

When creating or reviewing issues, classify by origin:

| Type | When to use | Example |
|------|-------------|---------|
| `bug` | Code does not match documented spec or expected behavior | Button click crashes; wrong tax calculation vs defined formula |
| Missing business rule | Rule was never captured in the issue during discovery | Discovery didn't document "discount cannot exceed 30%" — this is an incomplete spec, not a bug |
| `feat` | New capability or rule being added | New discount engine, field-level permissions |
| `doc` | Missing or incorrect documentation | No README for new endpoint |
| `chore` | Maintenance, refactoring, tooling | Upgrade lib, fix CI, lint cleanup |

### Important: Bug vs Missing Business Rule

- A **bug** is when the implementation violates a documented rule or acceptance
  criterion.
- A **missing business rule** discovered during review means the issue was not
  fully refined in discovery. This must NOT be treated as a bug — instead, the
  issue must go back through refinement (PO → TL) to capture the rule properly,
  then the implementation is adjusted to match.

Senior Reviewers must tag missing business rules as `incomplete-spec`, never as
`bug`. The fix is to refine the issue, not to patch code against an incomplete
specification.

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
