## /ocf:close-issue [id]

---
description: Close remote issue and archive after PR merge
---

Close a remote issue and archive it after its PR has been merged.

### Flow

1. **Detect issue**: from argument, current branch (`issue-<id>-<slug>`),
   or ask if neither is available
2. **Read issue entry** from `known_issues.md` — requires `Status: in-publish`
   and `Remote: #<id>` populated
3. **Verify PR merged** via `gh pr view <pr-id> --json state --jq '.state'`
   using the `- PR: #<n>` field; if missing, search merged PRs by branch
4. **If merged**: run `scripts/close_issue.sh <id>` which closes the remote
   issue and archives to `resolved_issues.md`
5. **If not merged**: report PR state and abort

### Usage

```
/ocf:close-issue
/ocf:close-issue 4
```
