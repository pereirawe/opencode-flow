# Resolved Issue Archive

Resolved issues are removed from `known_issues.md` and moved here in compact format to reduce token consumption.

## Entry Format

```markdown
### <id>. <title>
- Resolved: <YYYY-MM-DD>
- Durations: backlog=Nd waiting=Nd dev=Nd total=Nd | -
- Severity: critical | high | medium | low
- Type: bug | feat | doc | chore
- Report: <user-name> | <model-name>
- Reviewers: <number>
- Remote: - | #<remote-id>
- Summary: <2-3 lines of what was done>
```

## Rules

- One entry per resolved issue, ordered by resolution date (most recent first)
- `Summary` must be concise — max 3 lines
- `Remote` links to the closed remote issue if applicable
- `Resolved` is the date the issue was closed locally
- `Durations` holds per-stage day counts computed by `scripts/close_issue.sh`
  at close time from the issue's timestamps (`backlog` Opened→Ready, `waiting`
  Ready→Started, `dev` Started→Resolved, `total` Opened→Resolved) using the
  UTC-anchored parse (`TZ=UTC date -d "$d" +%s`, DST-robust). A component
  renders `-` when a date is missing or start > end; `0d` when the difference
  is zero; the whole field renders the literal `-` when all dates are missing.
- Entries are never edited after creation
- If an issue is reopened, it moves back to `known_issues.md` and the archive entry stays as-is

## Lifecycle

```
known_issues.md (Status: resolved)
    │
    ▼
resolved_issues.md (appended to top, compact format)
```
