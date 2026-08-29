## /ocf:develop-full [id...]

---
description: End-to-end lifecycle for one or more issues — promote, develop, parallel review, QA gate, MR, auto-merge, close+archive. Agents are used only for judgment (developer + senior reviewers); everything mechanical is a script.
---

Run the ENTIRE task flow for one or more tracked issues, from promotion to
archived merge, automatically — no confirmation, no permission prompts, no
pausing. After the MR is created the pipeline **auto-merges**, returns to the
base branch, and closes/archives the issue.

**Design:** this command drives the pipeline directly. There is NO
`delivery` orchestrator agent and NO `develop-router` agent in the critical
path — `scripts/detect-lang.sh` replaces the router, and the merge/close is
`scripts/merge-and-close.sh`. Agents appear only where judgment is needed:
the **developer** (implementation) and the **senior reviewers** (parallel
domain review). This cuts the old 6+N agent chain to 1+N and removes
mechanical roundtrips.

At least ONE issue ID is required. Multiple IDs may be separated by spaces,
commas, or dashes; deduplicated (order preserved), processed sequentially. A
single Telegram notification is sent after the LAST issue.

### Arguments

```
/ocf:develop-full 4
/ocf:develop-full 4 5 6
/ocf:develop-full 4,5,6
/ocf:develop-full #4 #5 #6
```

### Auto-Promotion Flow (silent)

Missing data handled gracefully: `Base branch:` → git default; `Reviewers:` →
`1 (backend)`; `Remote:` → auto-created via `create_issue.sh` if missing.

| Status | Action |
|--------|--------|
| `backlog` | `promote.sh` → `ready`; if `Remote: -`, `create_issue.sh`; `promote.sh` → `in-progress` + branch |
| `ready` | if `Remote: -` → `create_issue.sh`; `promote.sh` → `in-progress` + branch |
| `open` w/ Remote | `in-progress` + branch `issue-<id>-<slug>` |
| `open` w/ `Remote: -` | `create_issue.sh` → `in-progress` + branch |
| `in-progress` | proceed |
| `in-review`/`in-qa`/`in-publish`/`resolved` | Refuse — past development |

### Full Task Flow (per issue)

1. **Resolve `known_issues.md`** (project `.opencode/` first, global fallback).
2. **Fill gaps**: detect `Base branch:` from git if empty, default `Reviewers:`
   to `1 (backend)`, auto-create `Remote:` if needed — no user prompts.
3. **Promote**: run the flow above (`create_issue.sh` + `promote.sh`).
4. **Warm current issue**: `scripts/preflight.sh <id>` builds the file
   inventory so the developer skips re-exploration.
5. **Pick dev agent**: `LANG=$(scripts/detect-lang.sh [location])` →
   `development/devs/golang` | `development/devs/python` | `development/developer`.
6. **Implement**: `Task(<devagent>)` — implement per business rules, write
   tests via `test-runner` skill, self-review, `transition.sh <id> in-review`.
   No pausing.
7. **Parallel senior review**: read `- Reviewers:` (`<n> (profiles)`). Launch
   **one `Task(development/senior-reviewers/<profile>)` per profile in a SINGLE
   message** for true parallelism. All must approve. On issues → `Task(<devagent>)`
   fixes, then re-review (loop within this step).
8. **Quality + committer gate**: run `scripts/committer-check.sh <id>` and
   `scripts/issue-lint.sh --strict <id>`. Both must PASS → `transition.sh <id>
   in-publish`. On FAIL → STOP the list, notify (do not auto-merge).
9. **Create MR**: `scripts/create-pr.sh <id>` (builds body from issue fields,
   sets `- PR: #<n>`).
10. **Merge + archive**: `OCF_CLOSE_COMMENT=1 scripts/merge-and-close.sh <id>`
    (merges MR, returns to base + pull, archives via `close_issue.sh`).
11. **Warm next**: if there is a next ID, `scripts/preflight.sh <next-id>` now
    (clean base) so the next developer starts warm.
12. **Repeat** for the next issue.

### Telegram Notifications

Exactly ONE, after the LAST issue: per-issue summary (id, PR link, merged). No
intermediate notifications. Subagents (developer, reviewers) never notify.

### Failure Handling

Any failure (not found, refused status, review not approved, committer/lint
FAIL, MR/merge fails) → STOP the list, send ONE failure notification. Already
merged issues stay resolved; the failed issue keeps its current status.

### Loop profiles

Discovery selects the loop; delivery is the same engine, differentiated by
reviewer count + auto-merge. See `workflow.md` § Loop Profiles:
`feat-full` (PO+TL, full depth), `bug-expedite` (critical/high, 2 reviewers +
security, high quality bar), `bug-lean` (low/medium, 1 reviewer, fast),
`chore` (light). Bugs trade depth for speed but keep a higher quality bar.
