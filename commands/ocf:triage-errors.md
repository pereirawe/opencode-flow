## /ocf:triage-errors [--loop <label> | --id <n>] [--min-severity <s>] [--apply]

---
description: Review the per-loop error journal and file actionable errors as canonical issues in the global opencode tracker or the target project tracker
---

Run the **loop error review** manually. Normally this runs automatically at the
end of every discovery/delivery loop (see `workflow.md` § Loop Error Review);
this command exposes it for on-demand use (e.g. after investigating a run, or
to drain an accumulated journal).

### Arguments

```
/ocf:triage-errors                 # consolidated pass over all journals of the run
/ocf:triage-errors --loop discovery
/ocf:triage-errors --id 244        # single loop journal
/ocf:triage-errors --min-severity high
/ocf:triage-errors --apply         # file proposals (default is plan-only)
```

### Flow

1. **Plan**: `scripts/loop-error-triage.sh --plan [--loop <label>]` writes
   `.opencode/preflight/loop-errors-<label>.md` (digest) and
   `.opencode/preflight/loop-errors-<label>.proposals.tsv` (plan).
2. **Review**: invoke `Task(development/loop-error-reviewer)` with the loop
   label/id. The agent drops noise, validates `global` vs `project`, merges
   duplicates and adjusts severity by editing the TSV.
3. **Apply**: the agent runs `scripts/loop-error-triage.sh --apply --from
   <proposals.tsv>`, filing canonical `bug` entries (`Status: backlog`) in
   `~/.config/opencode/known_issues.md` or the workspace tracker.
4. **One Telegram notification** with the outcome (filed/skipped per tracker).

### Notes

- Read-only unless the review concludes there is an actionable error and reaches
  `--apply`.
- Non-blocking and idempotent: never changes any issue status, never duplicates
  an already-filed error.
- Nothing is filed without a journal entry behind it (no fabrication).
