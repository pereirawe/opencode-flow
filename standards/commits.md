# Commit Conventions

## Principles

- **Atomic**: One commit = one logical change. Never mix concerns (e.g., fix +
  refactor + docs in the same commit).
- **Semantic**: The first line is a structured type declaration that enables
  changelog generation and git-log filtering.
- **Tracked**: Every commit references the issue it belongs to via trailers that
  sync with `known_issues.md`.

## Format

```
<type>(<scope>): <imperative description>

<body (optional)>

<trailers>
```

| Part | Required | Rule |
|------|----------|------|
| `type` | ✅ | One of: `feat`, `fix`, `refactor`, `test`, `docs`, `chore` |
| `scope` | ❌ | Optional context (e.g. `api`, `ui`, `config`) |
| `description` | ✅ | Imperative present tense, ≤ 72 chars, no period |
| `body` | ❌ | Free-form, wrap at 72 chars |
| `trailers` | ✅ | `Issue: #<id>` + optionally `Status:` / `Closes #<id>` |

## Types

| Type | Usage | Changelog section |
|------|-------|-------------------|
| `feat` | New feature or capability | Features |
| `fix` | Bug fix | Bug Fixes |
| `refactor` | Code restructuring with no behavior change | Code Quality |
| `test` | Adding or fixing tests | Tests |
| `docs` | Documentation only | Documentation |
| `chore` | Maintenance, config, tooling, deps | Miscellaneous |

## Examples

```
feat: add analytics endpoint (#6)

Issue: #6
Status: in-progress
```

```
fix(api): validate URL scheme before fetch

The URL scheme was not being validated, allowing SSRF attacks.

Issue: #3
Closes #3
```

```
refactor: extract service layer from handler

Moved business logic out of HTTP handlers into dedicated services.

Issue: #7
Status: resolved
```

```
chore: upgrade eslint to v9

Issue: #7
Status: in-progress
```

## Trailers

Trailers are `git-trailer` style key-value pairs. They sync status with
`known_issues.md` automatically via `pre_commit.sh`.

| Trailer | Effect on `known_issues.md` | Remote effect |
|---------|-----------------------------|---------------|
| `Issue: #<id>` | Sets issue reference | Links commit ↔ issue |
| `Status: in-progress` | Updates status to `in-progress` | None |
| `Status: resolved` | Updates status to `resolved` | Closes remote via `close_issue.sh` |
| `Remote: #<id>` | Sets the remote issue ID | Links local ↔ remote |
| `Closes #<id>` | Sets status to `resolved` (same as `Status: resolved`) | Closes remote issue |

Every commit MUST include `Issue: #<id>` to link the change to a tracked issue.
`Status:` and `Closes` are used to update the issue lifecycle.

## Rules

1. **One concern per commit** — if you need "and" in the description, split it
2. **Imperative present tense** — "add", "fix", "refactor", not "added", "fixes"
3. **First line ≤ 72 characters**
4. **Always reference an issue** — `Issue: #<id>` in trailers
5. **Use `Status: in-progress`** when work continues
6. **Use `Status: resolved` or `Closes #<id>`** when the change completes the issue
7. **Known issues** file must be updated if the change affects tracked work

## Pre-commit test run

`pre_commit.sh` delegates the test run to `scripts/test-runner.sh`, which is
cache-aware: identical code (same fingerprint) is never re-tested. If the cache
is fresh, the suite is skipped and the cached result is reused. This applies to
every agent that validates tests — developer, senior reviewers, QA, and
committer — never run an unchanged suite more than once.
