## /ocf:develop [id]

---
description: Start or resume development on an issue, auto-promoting if needed
---

Start or resume development on a tracked issue. Promotion, remote creation,
and branch setup happen automatically — no questions asked.

### Auto-Promotion Flow

The promote flow runs silently. Missing data is handled gracefully:
`Base branch:` → detected from git; `Reviewers:` → defaults to 1;
`Remote:` → auto-created if missing.

| Status | Action |
|--------|--------|
| `backlog` | `promote.sh <id>` → `ready` → `create_issue.sh <id>` (remote) → `promote.sh <id>` → `in-progress` + branch |
| `ready` | Auto-create remote if missing, then `promote.sh <id>` → `in-progress` + branch |
| `open` with Remote set | Update status to `in-progress`, checkout/create branch `issue-<id>-<slug>` |
| `open` with `Remote: -` | `create_issue.sh <id>` → `in-progress` + branch |
| `in-progress` | Proceed directly |
| `in-review` / `in-qa` / `in-publish` / `resolved` | Refuse — issue is past development |

### Flow

1. **Detect issue**: from argument, current branch (`issue-<id>-<slug>`), or ask
   if neither is available
2. **Check & fill gaps**: detect `Base branch:` from git if empty, default
   `Reviewers:` to 1 if empty, auto-create `Remote:` if needed — no user prompts
3. **Auto-promote**: run the promotion flow above based on current status
4. **Verify branch**: if not already on `issue-<id>-<slug>`, checkout or create it
5. **Invoke Developer agent** with full issue context to implement
6. **Stop**: development ends here — no MR creation prompt. Use `/ocf:commit`
   to commit, then run review → QA → committer → publish pipeline separately

### Validation Notes

- `Business rules:` empty for `feat` type → warns it will be blocked by Committer
- `Remote:` auto-created when missing before `ready → in-progress`
- Reviewer profiles validated during `promote.sh` (warns only, non-blocking)
- Uncommitted changes: suggest stash or commit before promoting

### Usage

```
/ocf:develop
/ocf:develop 4
```
