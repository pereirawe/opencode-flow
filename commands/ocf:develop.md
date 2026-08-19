## /ocf:develop [id...]

---
description: Run the full task lifecycle end-to-end for one or more issues: promote, develop, review, QA, MR, auto-merge, archive
---

Run the ENTIRE task flow for one or more tracked issues, from promotion to
archived merge. Everything happens automatically — no confirmation, no
permission prompts, no pausing between pipeline phases.

At least ONE issue ID is required. Multiple IDs may be passed separated by
spaces, commas, or dashes. Each issue runs the full flow sequentially, and a
single Telegram notification is sent after the LAST issue.

### Arguments

```
/ocf:develop 4
/ocf:develop 4 5 6
/ocf:develop 4,5,6
/ocf:develop 4-5-6
/ocf:develop #4 #5 #6
```

IDs are deduplicated (preserving order) and processed one at a time, in order.

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

### Full Task Flow (per issue)

1. **Resolve `known_issues.md`** (project `.opencode/` first, global fallback)
2. **Check & fill gaps**: detect `Base branch:` from git if empty, default
   `Reviewers:` to 1 if empty, auto-create `Remote:` if needed — no user prompts
3. **Auto-promote**: run the promotion flow above based on current status
4. **Verify branch**: if not already on `issue-<id>-<slug>`, checkout or create it
5. **Deliver**: invoke the `development/delivery` subagent (skipping its Phase 6
   promotion, since the issue is already `in-progress`) — it runs Developer
   (via develop-router) → Senior Review → QA → corrections loop → Committer
   gate → Publish Requester, which creates the MR
6. **Auto-merge**: once review and QA approve, merge the MR on the remote
   (GitHub `gh pr merge` / GitLab `glab mr merge`) — no permission prompt
7. **Return to base**: `git checkout <base-branch>` + `git pull origin <base-branch>`
   so the local checkout ends on the updated main/master
8. **Close & archive**: `close_issue.sh <id>` closes the remote issue and
   archives the entry; the tracker update is committed to the base branch
9. **Repeat** for the next issue in the list — each one starts clean from the
   updated base branch

### Telegram Notifications

Only ONE Telegram notification is sent for this command — after the LAST issue
completes, summarizing the final outcome (success or failure) with a per-issue
summary. No intermediate notifications during promotion, development, review,
QA, merge, or between issues. Pipeline subagents (delivery, develop-router,
implementation agents) are instructed to defer — the final message is sent
exclusively by this command session.

### Failure Handling

If ANY issue in the list fails (not found, refused status, development blocked,
review/QA not approved, committer gate fails, MR creation fails, merge fails),
STOP the entire list immediately — do not continue to the next issue and do not
ask. Send exactly ONE failure notification. Already-merged issues stay resolved;
the failed issue stays in `known_issues.md` with its current status.

### Validation Notes

- `Business rules:` empty for `feat` type → warns it will be blocked by Committer
- `Remote:` auto-created when missing before `ready → in-progress`
- Reviewer profiles validated during `promote.sh` (warns only, non-blocking)
- Uncommitted changes: suggest stash or commit before promoting
