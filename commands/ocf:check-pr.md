## /ocf:check-pr [id]

---
description: Check PR merge status for in-publish issues and auto-archive
---

Check if the Pull Request for an issue has been merged and auto-archive if so.

### Flow

1. Ask user for issue ID, or scan all with `Status: in-publish`
2. For each issue, detect its PR:

   **a. If `- PR: #<n>` field exists** → use `gh pr view <n>` directly

   **b. If no PR field** → search merged PRs:
   - Try `gh pr list --search "Issue: #<local-id> in:body" --state merged`
   - If ambiguous, list all merged PRs and filter by branch matching
     `issue-<remote-id>-*` (where remote-id is from `Remote:` field)

3. **If merged** → add `- PR: #<n>` field, update status to `resolved`,
   run `close_issue.sh <id>` to archive
4. **If not merged** → report current PR state (open/not found)
5. Issues without `Remote:` are skipped

### Usage

```
/ocf:check-pr          # scan all in-publish issues
/ocf:check-pr 3        # check specific issue
```
