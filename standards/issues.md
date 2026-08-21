# Issue Tracking

Two-tier issue tracking:
- **Global**: `~/.config/opencode/known_issues.md` — opencode config-level issues
- **Project**: `<project>/.opencode/known_issues.md` — project-specific issues

## Entry Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Opened: <YYYY-MM-DD> | -
- Ready: <YYYY-MM-DD> | -
- Started: <YYYY-MM-DD> | -
- In review: <YYYY-MM-DD> | -
- In QA: <YYYY-MM-DD> | -
- In publish: <YYYY-MM-DD> | -
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Priority: low | medium | high | critical (bugs: derived from the bug-triage score matrix; feats: set by PO)
- Flow: lean | escalated (bugs only — optional, informative; feats MUST NOT carry it)
- Report: <user-name> | <model-name>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <number> (<profile1>, <profile2>)
- Remote: - | #<remote-id>
- Jira: - | <KEY-N>
- PR: - | #<pr-number>
- Location: <file-path>:<line-numbers>
- Description: <brief description>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Acceptance criteria: <what must be true for the issue to be complete>
- Tests: <scenario → outcome lines, defined during discovery>
- Suggested fix: <approach or next step>
```

`Remote:` is required. Use `-` when no remote issue exists yet.
`Jira:` is optional (default `-`) — the Jira Cloud issue key (e.g. `DEV-123`)
for the card mirrored from this issue when the Jira sync is enabled (issue #48).
It is separate from `Remote:` (which stays exclusive to the git provider
GitHub/GitLab). Populated by `scripts/sync-jira.sh` (via hooks in
`create_issue.sh`/`promote.sh`/`close_issue.sh` or the `ocf:sync-jira` command);
the sync is non-blocking and the local `Status:` always wins over Jira.
`Business rules:` is required for `feat` type issues — document the specific
business logic, domain constraints, and rules that must be implemented.
For `bug` type issues, business rules are documented WHEN APPLICABLE: a bug
with no business rule MUST declare the literal `- Business rules: none`.
QA pre-development accepts this literal and REJECTS `-` (placeholder) as
`incomplete-spec` — a rule-less bug must state so explicitly, never with a
placeholder.
`Priority:` is the issue priority. For `feat` issues the PO sets it directly
(`high | medium | low`). For `bug` issues it is DERIVED from the bug-triage
score matrix during PO triage — the matrix (weights, buckets, guard rule,
worked examples) lives in a single source, the `bug-triage` skill
(`skills/development/bug-triage/SKILL.md`), loaded on-demand by the PO. The
derived `- Priority:` value is validated by QA pre-development against that
matrix before promotion; a missing or inconsistent value returns the bug to
PO re-triage.
`Flow:` is optional and BUG-ONLY — `lean | escalated`. It records which
discovery track produced the issue: `lean` when the bug entered via the lean
triage track (PO triage → QA → PM), `escalated` when escalation restarted the
full 6-phase discovery at the CTO. `feat` issues MUST NOT carry `- Flow:`
(the full flow is the default). Informative for PM promotion only — pipeline
scripts ignore extra fields (`Jira:` precedent).
`Reviewers:` is set during discovery (Tech Lead defines profiles) and consumed
during senior review and MR creation.
`Acceptance criteria:` is recommended for all types.

### Timestamps (Opened / Ready / Started / In review / In QA / In publish / Resolved + Durations)

Per-issue lifecycle timestamps are stored as entry fields in `known_issues.md`
(`- Opened:`, `- Ready:`, `- Started:`, `- In review:`, `- In QA:`,
`- In publish:`, in that canonical order after `- Status:`) and computed/stored
in the resolved archive at close time (`- Resolved:` and `- Durations:`). They
are stamped directly by the pipeline scripts — never via commit-trailer
parsing (issue #24).

| Field | Stamped by | When |
|-------|-----------|------|
| `- Opened:` | `scripts/create_issue.sh` | on remote issue creation success (set-if-absent). `scripts/promote.sh` backfills it set-if-absent during mode 2 (ready → in-progress) with the current date — a documented approximation when the remote was created before timestamping (BR 3). |
| `- Ready:` | `scripts/promote.sh` | on backlog → ready (set-if-absent) |
| `- Started:` | `scripts/promote.sh` | on ready → in-progress (set-if-absent). Also stamped by `scripts/transition.sh` on the same transition when used as the delivery entrypoint. |
| `- In review:` | `scripts/transition.sh` | on in-progress → in-review (set-if-absent) — marks when development finished and review started |
| `- In QA:` | `scripts/transition.sh` | on in-review → in-qa (set-if-absent) — marks when review finished and QA started |
| `- In publish:` | `scripts/transition.sh` | on in-qa → in-publish (set-if-absent) — marks when QA passed and the committer gate approved the MR |
| `- Resolved:` | `scripts/close_issue.sh` | at close time (= close date / today) |
| `- Durations:` | `scripts/close_issue.sh` | at close time, in the archive entry — day differences between the timestamps, UTC-anchored parse (`TZ=UTC date -d "$d" +%s`, DST-robust) |

`Durations` components: `backlog` (Opened→Ready), `waiting` (Ready→Started),
`dev` (Started→In review — the ACTUAL development time), `review`
(In review→In QA), `qa` (In QA→In publish), `publish` (In publish→Resolved),
`total` (Opened→Resolved, relative to the close date). Guards: a component
renders `-` when a date is missing or start > end (guarded BEFORE division);
`0d` when the difference is zero; values are floored at 0 (non-negative); when
ALL dates are missing the whole field renders the literal `- Durations: -`.

Backward compatibility: entries created before per-stage tracking have no
`In review:`/`In QA:`/`In publish:` fields. For those, `dev` falls back to
Started→Resolved (the legacy meaning) and `review`/`qa`/`publish` render `-`.

Stamping is idempotent (set-if-absent): re-running a script never duplicates
or overwrites existing timestamps, and `close_issue.sh` never appends a
duplicate archive entry. Timestamps apply to new issues only — existing
entries are never retroactively rewritten.

### `Tests:` — mandatory test standards

`Tests:` is MANDATORY for every new issue, captured during discovery (QA
pre-development, Phase 5) as `scenario → outcome` lines — never added ad-hoc
during development. Developers write tests against these documented scenarios
instead of inventing them on the fly.

- For `doc`/`chore` types, the literal `- Tests: -` is permitted (no test
  surface).
- For `feat`/`bug` types, at least one `scenario → outcome` line is REQUIRED
  and the value may NEVER be `-`.
- Scenario depth is a FLOOR with no upper bound, by severity: `critical`/`high`
  → ≥3 `scenario → outcome` lines; `medium` → ≥2; `low` → ≥1. If `- Severity:`
  is missing at QA validation time, the medium floor (≥2) applies.
- Enforcement is **verified by QA pre-development review (Phase 5) and senior
  reviewers** — NOT enforced by scripts.
- Missing or insufficient `Tests:` found during senior review or post-review
  QA = `incomplete-spec` (discovery gap), NOT a bug — the issue returns to
  discovery refinement to capture the missing scenarios.
- Applies to ALL new issues going forward; existing in-flight issues are not
  retroactively rewritten.

> Follow-up (not part of any gate): an optional `promote.sh`/lint gate could
> enforce `Tests:` mechanically in the future.

## Type Classification

When creating or reviewing issues, classify by origin:

| Type | When to use | Example |
|------|-------------|---------|
| `bug` | Code does not match documented spec or expected behavior | Button click crashes; wrong tax calculation vs defined formula |
| Missing business rule | Rule was never captured in the issue during discovery | Discovery didn't document "discount cannot exceed 30%" — this is an incomplete spec, not a bug |
| `feat` | New capability or rule being added | New discount engine, field-level permissions |
| `doc` | Missing or incorrect documentation | No README for new endpoint |
| `chore` | Maintenance, refactoring, tooling | Upgrade lib, fix CI, lint cleanup |

### Important: Bug vs Missing Business Rule

- A **bug** is when the implementation violates a documented rule or acceptance
  criterion.
- A **missing business rule** discovered during review means the issue was not
  fully refined in discovery. This must NOT be treated as a bug — instead, the
  issue must go back through refinement (PO → TL) to capture the rule properly,
  then the implementation is adjusted to match.

Senior Reviewers must tag missing business rules as `incomplete-spec`, never as
`bug`. The fix is to refine the issue, not to patch code against an incomplete
specification.

## Lifecycle

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| Status | Meaning |
|--------|---------|
| `backlog` | Captured, not yet refined |
| `ready` | Clear, approved, testable — ready to pick up |
| `open` | Selected, awaiting remote creation |
| `in-progress` | Remote issue exists, work started |
| `in-review` | Senior review completed, awaiting QA |
| `in-qa` | QA verifying post-review (may loop to `in-progress`) |
| `in-publish` | Committer gate passed, MR created, awaiting merge |
| `resolved` | MR approved and merged (moved to archive) |

## Resolved Archive

Resolved issues are removed from `known_issues.md` and moved to `resolved_issues.md`
in compact format. See `standards/resolved-issue.md` for details.

## Branch Review Naming

Review output from `/ocf:review-branch` is written to:

```
<project>/.opencode/<model>_<branch>_issues.md
```

This keeps reviews isolated by model and branch, avoiding clutter in the main tracker.
These files are ephemeral — once issues are triaged into `known_issues.md`, the
review file can be deleted or archived.
