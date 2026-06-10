## /ocf:promote <id>

---
description: Promote an issue — backlog→ready or ready→in-progress with branch
---

Promote a tracked issue in `known_issues.md` to the next lifecycle stage.
Data is read from the issue entry. Missing fields are handled gracefully:
`Base branch:` detected from git, `Reviewers:` defaults to 1,
`Remote:` auto-created if missing — no user prompts.

### Flow

| Current Status | Action |
|----------------|--------|
| `backlog` | `promote.sh <id>` → `ready` (status only, no branch) |
| `ready` | Auto-create remote if missing, then `promote.sh <id>` → `in-progress` + branch `issue-<id>-<slug>` |
| other | Refuse — issue cannot be promoted from its current status |

The script handles: base branch checkout/pull, feature branch creation,
reviewer profile validation, remote creation if needed, and status update.

### Status lifecycle

| Status | Description |
|--------|-------------|
| `backlog` / `ready` | Planning states — can be promoted |
| `in-progress` | Remote issue exists, work has started |
| `in-review` | Senior review completed, awaiting QA |
| `in-qa` | QA verifying post-review corrections |
| `in-publish` | Committer gate passed, MR created, awaiting merge |
| `resolved` | Terminal state — issue moved to archive |

### Usage

```
/ocf:promote 2
```
