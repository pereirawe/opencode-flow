## /ocf:develop [id...]

---
description: Run the lifecycle up to MR creation for one or more issues — promote, develop, parallel review, QA gate, MR — then STOP (no auto-merge, no archive). Manual merge follows.
---

Run the task flow for one or more tracked issues, from promotion to **MR
creation**, automatically. No confirmation, no pausing. The command **stops
after the MR is created**: it does NOT merge, does NOT close/archive. The MR is
left OPEN for a human review/merge.

**Design:** same flattened engine as `/ocf:develop-full` — no `delivery`
orchestrator, no `develop-router`. `scripts/detect-lang.sh` picks the dev
agent; agents appear only for judgment (developer + parallel senior reviewers).
Mechanical steps (promote, preflight, committer gate, create-pr) are scripts.

At least ONE issue ID required. Multiple IDs separated by spaces/commas/dashes;
deduplicated, processed sequentially. One Telegram notification after the LAST.

### Arguments

```
/ocf:develop 4
/ocf:develop 4 5 6
/ocf:develop #4 #5 #6
```

### Auto-Promotion Flow (silent)

`Base branch:` → git default; `Reviewers:` → `1 (backend)`; `Remote:` →
auto-created via `create_issue.sh` if missing.

| Status | Action |
|--------|--------|
| `backlog` | `promote.sh` → `ready`; `create_issue.sh` if needed; `promote.sh` → `in-progress` + branch |
| `ready` | `create_issue.sh` if needed; `promote.sh` → `in-progress` + branch |
| `open` w/ Remote | `in-progress` + branch |
| `in-progress` | proceed |
| `in-review`/`in-qa`/`in-publish`/`resolved` | Refuse — past development |

### Task Flow (per issue, up to MR)

1. **Resolve `known_issues.md`** (project first, global fallback).
2. **Fill gaps** (base/reviewers/remote) — no prompts.
3. **Promote**: `create_issue.sh` + `promote.sh`.
4. **Warm current**: `scripts/preflight.sh <id>`.
5. **Pick dev agent**: `LANG=$(scripts/detect-lang.sh [location])`.
6. **Implement**: `Task(<devagent>)` → tests → self-review → `transition.sh <id> in-review`.
7. **Parallel senior review**: one `Task(development/senior-reviewers/<profile>)`
   per profile, in a single message. All approve; else fix+re-review loop.
8. **Gate**: `scripts/committer-check.sh <id>` + `scripts/issue-lint.sh --strict
   <id>` → PASS ⇒ `transition.sh <id> in-publish`. FAIL ⇒ STOP + notify.
9. **Create MR**: `scripts/create-pr.sh <id>` (sets `- PR: #<n>`).
10. **Report "esperando merge manual"**: do NOT merge/close. Issue stays
    `in-publish`, MR OPEN.
11. **Return to base**: `git checkout <base>` + `git pull` (base has no change).
12. **Repeat** for the next issue.

Closing/archiving after manual merge: `/ocf:check-pr <id>` (or Close Requester).

### Telegram & Failure

One notification after the LAST issue. Any failure → STOP list, one failure
notification. Delivered issues stay `in-publish` with MR open.
