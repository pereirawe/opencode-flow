## /ocf:discovery [proposal | id]

---
description: Run discovery for an idea or existing issue — routes by Type+severity into a LOOP (feat-full / bug-expedite / bug-lean / chore) and writes a canonical, linted issue
---

Transform a raw idea (free text) or an existing issue id into a tracked, typed,
linted issue. Discovery is the ONLY phase with user interaction — give the
business context in the argument; the agent does not prompt mid-flow.

Bugs and feats use **different loops** (see `workflow.md` § Loop Profiles):
bugs resolve faster (fewer agents) with a higher quality bar; feats keep full
depth (PO + TL). All loops end with `scripts/append-issue.sh` + `issue-lint.sh`.

### Arguments

```
/ocf:discovery "Add CSV export to reports screen"
/ocf:discovery 12          # refine an existing backlog/ready issue
/ocf:discovery "Bug: login fails when token expires"
```

### Flow

1. **Resolve `known_issues.md`** (project `.opencode/` first, global fallback).
2. **Classify**: if argument is a number and the issue exists, refine it;
   otherwise treat as a new proposal. Infer `- Type:` (`bug` if it reads like a
   defect/regression, else `feat`) and `- Severity:` when stated.
3. **Run the discovery subagent**: `Task(development/discovery)` with the
   proposal/context. It selects the loop, runs PO/TL as needed, calls
   `scripts/append-issue.sh` (canonical entry) and `scripts/issue-lint.sh
   --strict`, and reports the created `id`.
4. **Verify**: re-run `scripts/issue-lint.sh <id>` on the result; if it fails,
   report the gaps (do not auto-fix — discovery already attempted).
5. **One Telegram notification** with the outcome (id, type, loop, lint status,
   `known_issues.md` link).

### Notes

- No PM agent, no remote question — `Remote:` is auto-created at promotion
  (`ocf:develop` / `ocf:develop-full`).
- For `feat`, include business rules + acceptance in the argument when possible
  to skip a refinement cycle.
- After discovery, hand off with `/ocf:develop-full <id>` (end-to-end) or
  `/ocf:develop <id>` (manual merge).
