# Commit Conventions

## Format

```
<type>: <short description> (#<issue-id>)

<body (optional)>

<trailer-flags>
```

## Types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `test` | Test changes |
| `docs` | Documentation |
| `chore` | Maintenance, config, deps |

## Examples

```
feat: add analytics endpoint (#6)

Status: in-progress
```

```
fix: validate URL scheme before fetch (#3)
Closes #3
```

```
refactor: extract service layer from handler (#7)
Status: resolved
```

## Trailer Flags

Trailers are `git-trailer` style key-value pairs appended to the commit body.
They update the issue status in `known_issues.md` automatically.

| Flag | Effect on `known_issues.md` | Remote effect |
|------|----------------------------|---------------|
| `Status: in-progress` | Sets issue to `in-progress` | None |
| `Status: resolved` | Sets issue to `resolved` | Closes remote issue via `close_issue.sh` |
| `Remote: #<id>` | Sets `Remote: #<id>` on the issue | Links local ↔ remote |
| `Closes #<id>` | Sets issue to `resolved` | Closes remote issue |

## Rules

- Use imperative present tense
- Keep the first line under 72 characters
- Reference the issue number in parentheses
- Body is optional but encouraged for complex changes
- Trailers are validated by `pre_commit.sh`
- If `Status: resolved` is set, the issue is archived to `resolved_issues.md`
