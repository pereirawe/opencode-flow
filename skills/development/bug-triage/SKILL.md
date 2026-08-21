---
name: bug-triage
description: Bug triage for the lean discovery track — the single source of the bug prioritization score matrix, escalation triggers, and the aging policy. Use when triaging a bug issue during PO discovery (primary decider), validating a derived bug priority (QA, secondary escalation), or applying the aging re-triage rule. "triagem de bugs", "bug triage", "prioridade de bug", "escalar bug" also trigger this skill.
---

# Bug Triage (lean discovery track)

Load this skill on-demand during bug discovery whenever you need to score a
bug, decide escalation, or apply the aging policy. It is the **single source
of truth** for the bug prioritization matrix — the matrix must never be
duplicated in `workflow.md`, `agents/development/discovery.md`,
`agents/development/product-owner.md`, `standards/issues.md`, or any other
file (BR 11).

## When to use

- **PO (triage, primary decider)**: score the bug, register `- Priority:` and
  `- Flow: lean`, decide escalation.
- **QA (lean phase 2, secondary decider)**: validate the derived `- Priority:`
  against the matrix; escalate when a trigger surfaces.
- **PO (backlog review)**: apply the aging re-triage policy.
- **PM (promotion)**: `- Priority:`/`- Flow:` are informative — do not gate.

## Score matrix (single source of truth)

Score = Severity + Impact + Frequency + Risk (range 4–15).

| Factor | Values |
|--------|--------|
| Severity (S) | critical=5, high=4, medium=3, low=2 |
| Impact (I) | blocking=4, financial=3, broad=2, isolated=1 |
| Frequency (F) | always=4, frequent=3, occasional=2, rare=1 |
| Risk (R) — regression or security exposure | yes=+2, no=0 |

Buckets:

- Score 12–15 → `- Priority: critical`
- Score 9–11 → `- Priority: high`
- Score 6–8 → `- Priority: medium`
- Score 4–5 → `- Priority: low`

**Guard rule**: if severity = `critical` OR impact = `blocking`, the derived
`- Priority:` is NEVER below `high` — even when the raw score lands in the
medium or low bucket.

### Worked example 1 (guard-rule case)

Severity critical (5) + isolated impact (1) + rare frequency (1) + no risk (0)
→ raw score 7 → medium bucket → **guard overrides** → `- Priority: high`.

### Worked example 2 (guard-rule case)

Severity medium (3) + blocking impact (4) + occasional frequency (2) + no risk
(0) → raw score 8 → medium bucket → **guard overrides** → `- Priority: high`.

### Worked example 3 (no guard)

Severity high (4) + financial impact (3) + frequent frequency (3) + regression
risk yes (+2) → raw score 12 → critical bucket → `- Priority: critical`.

## Escalation triggers (PO is primary decider, QA is secondary)

Escalate the bug to the full 6-phase discovery (restart from the CTO:
CTO → Tech Lead → PO#2 → QA → PM) when ANY of the following holds:

1. No root cause identified or no reproduction steps available.
2. The fix is multi-layer or cross-cutting (touches more than one layer or
   domain).
3. Business-rule ambiguity — the expected behavior cannot be stated precisely.
4. Security involvement — the bug is a security vulnerability or touches
   auth/authorization/data protection.
5. The change touches architecture or standards.

On escalation, set `- Flow: escalated`. The Developer signals gaps as new
issues (existing flow), never silently downgrades a bug.

## Aging policy (progressive prioritization)

A medium-priority bug persisting N days in `ready` (N = 7 by default,
configurable — a documented policy value, not a script) MUST be re-triaged by
the PO during triage/backlog review and raised to `- Priority: high`. Compute
the age from the existing `- Ready:` (or `- Opened:` when `- Ready:` is
absent) timestamps. This is a PROCESS rule — no new scripts; future
mechanization is explicitly out of scope.

## Bug-issue fixture (final format — Developer reference)

A bug discovered through the lean track lands in `known_issues.md` in this
format (derived `- Priority:`, literal `- Business rules: none` when the bug
has no business rule, `- Tests:` scenarios at the severity floor, `- Flow:
lean`):

```markdown
### 111. Login button crashes on Safari 16
- Status: ready
- Opened: 2026-08-21
- Type: bug
- Severity: high
- Priority: high
- Flow: lean
- Report: william_pereira
- Base branch: main
- Reviewers: 3 (frontend, qa, runtime)
- Remote: #120
- Location: <file-path>:<line-numbers>
- Description: As a user, I want to log in on Safari 16 so that I can access my account; the button crashes the page.
- Impact: All Safari 16 users (isolated to one browser version).
- Business rules: none
- Acceptance criteria:
  1. The login button renders and submits on Safari 16.
  2. No page crash on click; errors are handled gracefully.
- Tests:
  1. Bug with clear root cause + reproduction and no business rule → lean discovery runs exactly 3 phases (PO triage → QA → PM), zero CTO/TL invocations, entry carries `- Flow: lean`, `- Business rules: none`, `- Priority:` derived from the matrix, `- Tests:` meeting the severity floor → lands in known_issues.md with status ready.
  2. Bug severity high (4) + broad impact (2) + frequent frequency (3) + no risk (0) → raw score 9 → `- Priority: high`.
  3. Guard rule: severity critical OR impact blocking → `- Priority:` never below high.
- Suggested fix: Add a Safari 16-specific event binding guard.
```

Score derivation for the fixture: S=high(4) + I=broad(2) + F=frequent(3) +
R=no(0) → 9 → high bucket → `- Priority: high`.
