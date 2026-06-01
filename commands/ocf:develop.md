## /ocf:develop [id]

---
description: Start or resume development on an issue, promoting first if needed
---

Start development on a tracked issue, handling promotion automatically if
the issue hasn't been promoted yet.

### Flow

1. **Detect issue**: ask user for issue ID, or detect from current branch
   name (`issue-<id>-<slug>`)
2. **Check Status** in `known_issues.md`:
   - `backlog` / `ready` → run promote flow first: ask base branch, reviewer
     count, create remote issue, then proceed
   - `open` with `Remote: -` → refuse — user must create remote first via
     `ocf:promote` or `ocf:sync-issues`
   - `open` with Remote set / `in-progress` → proceed to development
   - `in-review` / `in-qa` / `in-publish` / `resolved` → refuse — issue is
     past the development phase
3. **Verify branch**: confirm current branch matches `issue-<id>-<slug>`;
   if not, checkout the correct branch
4. **Invoke Developer agent** with full issue context (title, business rules,
   acceptance criteria, location, branch) to implement the feature or fix

### Usage

```
/ocf:develop
/ocf:develop 4
```
