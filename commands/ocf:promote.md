## /ocf:promote <id>

---
description: Promote a backlog item to open and create remote issue
---

Promote a tracked backlog item inside `known_issues.md`.

### Flow

1. **Ask the user** how many Senior Reviewers should review after development
   (default: 1) — do **not** read from `opencode.json`
2. Store the count as `- Reviewers: <n>` in the issue entry
3. Change `Status` from `backlog` or `ready` to `open`
4. Reset `Remote` to `-`
5. **Ask the user**: "Criar issue remota agora? (s/N)"
   - **Yes**: run `create_issue.sh <id>` — creates remote issue, updates
     `Remote: #<id>` and `Status: in-progress`, switches to the generated
     branch `issue-<remote-id>-<slug>`
   - **No**: keep status as `open` — development MUST NOT start without a
     remote issue

### Status lifecycle

| Status | Description |
|--------|-------------|
| `backlog` / `ready` | Planning states — can be promoted |
| `open` | Pre-remote execution state — remote creation deferred |
| `in-progress` | Remote issue exists, work has started |
| `in-review` | Senior review completed, awaiting QA |
| `in-qa` | QA verifying post-review corrections |
| `in-publish` | Committer gate passed, MR created, awaiting merge |
| `resolved` | Terminal state — issue moved to archive |

### Usage

```
/ocf:promote 2
```
