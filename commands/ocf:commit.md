## /ocf:commit

---
description: Create an atomic semantic commit with issue trailers
---

Create a structured atomic commit using conventional commits format, with
trailers that sync `known_issues.md` and remote issue trackers.

### Convention

Follow `standards/commits.md` — atomic + semantic + tracked.

```
<type>(<scope>): <imperative description>

<body (optional)>

Issue: #<id>
Status: <in-progress | resolved>
```

### Mandatory rules

- **One logical change per commit** — split if you need "and" in the description
- **Always include `Issue: #<id>`** — every commit must reference a tracked issue
- **Use `Status: in-progress`** for work-in-progress commits
- **Use `Status: resolved` or `Closes #<id>`** when the commit completes the issue

### Types

| Type | When |
|------|------|
| `feat` | New feature or logic |
| `fix` | Bug fix |
| `refactor` | Restructuring, no behavior change |
| `test` | Test changes |
| `docs` | Documentation |
| `chore` | Config, deps, tooling |

### Examples

```
feat(api): add analytics endpoint

Issue: #6
Status: in-progress
```

```
fix: validate URL scheme before fetch

Issue: #3
Closes #3
```

```
refactor: extract service layer from handler

Issue: #7
Status: resolved
```

### Usage

```
/ocf:commit
```

The assistant will:
1. Ask for the commit type, scope (optional), description, and issue ID
2. Detect the project's `known_issues.md` and current status
3. Run `scripts/format.sh --staged` and re-stage the formatted files (issue #246)
4. Construct the commit following `standards/commits.md`
5. Run `git commit` with the structured message
6. Update `known_issues.md` status based on trailers

### Formatting

Before committing, `scripts/pre_commit.sh` runs the project's formatter on the
staged files and re-stages what it changed, so the commit always contains
formatted code. Detection and modes are documented in
`standards/formatting.md`. A missing formatter is non-blocking.
