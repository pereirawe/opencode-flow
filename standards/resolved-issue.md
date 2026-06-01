# Resolved Issue Archive

Resolved issues are removed from `known_issues.md` and moved here in compact format to reduce token consumption.

## Entry Format

```markdown
### <id>. <title>
- Resolved: <YYYY-MM-DD>
- Type: bug | feat | doc | chore
- Report: <user-name> | <model-name>
- Reviewers: <number>
- Remote: - | #<remote-id>
- Summary: <2-3 linhas do que foi feito>
```

## Rules

- One entry per resolved issue, ordered by resolution date (most recent first)
- `Summary` must be concise — max 3 lines
- `Remote` links to the closed remote issue if applicable
- `Resolved` is the date the issue was closed locally
- Entries are never edited after creation
- If an issue is reopened, it moves back to `known_issues.md` and the archive entry stays as-is

## Lifecycle

```
known_issues.md (Status: resolved)
    │
    ▼
resolved_issues.md (appended to top, compact format)
```
