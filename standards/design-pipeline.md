# Design Pipeline — Output Conventions and Session Protocol

Standard for the design pipeline orchestrated by `/ocf:build-ui` (greenfield)
and `/ocf:audit-ui` (audit/refactor for existing codebases). It defines where
pipeline outputs live, how sessions are managed, and how stages chain their
JSON contracts.

## Output directory convention

Every run creates a **session id** and a dedicated output directory:

```
.opencode/design-outputs/<session-id>/
```

- The session id is a UTC timestamp in the format `YYYY-MM-DDTHH-MM-SS`
  (e.g. `2026-08-17T14-30-00`) — hyphens replace colons so the value is safe
  for use in file and directory names.
- The output directory is created at command start if missing.
- Shorthand: hereafter `<dir>` = `.opencode/design-outputs/<session-id>/`.

## Output files

All pipeline stages write pure JSON into the session's output directory.
The five canonical output files:

| File | Producer | Consumed by |
|------|----------|-------------|
| `design_spec.json` | `art-director` | `ui-architect`, `ui-refactor-planner`, `ui-critic` |
| `component_tree.json` | `ui-architect` | `ui-implementer`, `ui-critic` |
| `refactor_plan.json` | `ui-refactor-planner` | `ui-architect`, `ui-implementer` |
| `audit_report.json` | `ui-auditor` | `ui-refactor-planner` |
| `quality_report.json` | `ui-critic` | delivery gate |

- `design_spec.json` — palette, typography, spacing, radius, shadow, motion,
  layout spec, component vocabulary, signature element, copywriting
  principles, accessibility requirements, quality checklist.
- `component_tree.json` — layout regions, component contracts, interaction
  map, build order, quality gates. Consumes `design_spec.json` (and
  `refactor_plan.json` when refactoring).
- `refactor_plan.json` — Group A/B/C issue triage, per-stack token strategy,
  component decisions, phased plan with rollback, dependency map, token
  mapping. Consumes `audit_report.json` + `design_spec.json`. During refactor
  flows (`/ocf:audit-ui` optional pass 3) `ui-implementer` ALSO consumes
  `refactor_plan.json`, alongside `design_spec.json` and
  `component_tree.json`.
- `audit_report.json` — detected stack, 1–5 scores per dimension, `file:line`
  citations, preserved patterns.
- `quality_report.json` — `APPROVED` or `ISSUES_FOUND` with component-specific
  findings; blocking failures block delivery.

### Implementer hand-off (`handoff.json`)

Passes 1, 2 and 4 produce deterministic files (`design_spec.json`,
`component_tree.json`, `quality_report.json`), so a resumed run can tell
whether a stage completed. The implementer (pass 3) writes code, which a
resumed run cannot detect — so the implementer's structured hand-off is
persisted to a deterministic auxiliary file `<dir>/handoff.json`. **Pass 3 is
considered complete when `<dir>/handoff.json` exists; resumption skips it
then.** `handoff.json` is an AUXILIARY pipeline artifact, in addition to the
five canonical output files above — it is the internal hand-off that enables
resumption, documented as such, not a sixth canonical output.

## JSON chaining contract

Each stage receives the **previous stage's output file path** as context and
writes its own output file at the path given by the command. Outputs are pure
JSON — no text outside the JSON — so downstream stages can consume them
programmatically. The critic only checks fields the `art-director` /
`ui-architect` produce; the 6 data states (empty, loading, error, partial,
success, offline) are the same end-to-end.

## Session protocol

1. **Create** — at command start, create the session id and output directory
   (`.opencode/design-outputs/<session-id>/`).
2. **Resume** — re-running the command with the same session id skips stages
   whose output files already exist and continues from the first missing
   stage. Pass 3 is considered complete when the implementer's auxiliary
   hand-off `<dir>/handoff.json` exists (see "Implementer hand-off
   (`handoff.json`)").
3. **Share** — `build-ui` and `audit-ui` share the session id convention, so a
   prior `/ocf:build-ui` `design_spec.json` can feed `/ocf:audit-ui`'s planner
   (and vice versa when chaining into the build pipeline).

## Pipeline stages

### Greenfield (4 passes — `/ocf:build-ui`)

```
brief → art-director → design_spec.json → ui-architect → component_tree.json
     → ui-implementer → code → ui-critic → quality_report.json
```

`ui-critic` returns `APPROVED` or `ISSUES_FOUND`; blocking findings iterate
back to `ui-implementer` (max 3 rounds) before delivery. If still
`ISSUES_FOUND` after 3 rounds, the command stops, logs the failure, sends a
Telegram notification, and delivers with the remaining findings listed in the
summary.

### Audit/refactor (`/ocf:audit-ui`)

```
codebase → ui-auditor → audit_report.json → ui-refactor-planner → refactor_plan.json
```

The planner also consumes the art-director's `design_spec.json` when
available. Optional pass 3 chains into the build pipeline, reusing the same
session id and output files: `ui-architect` consumes `design_spec.json` (when
available) + `refactor_plan.json` → `component_tree.json`; `ui-implementer`
consumes `design_spec.json` + `component_tree.json` + `refactor_plan.json` +
project root → production code; `ui-critic` consumes code + `design_spec.json`
+ `component_tree.json` → `quality_report.json`.

## Failure policy

On any stage failure the command logs the failure, sends a Telegram
notification (via the `telegram-notifier` skill /
`scripts/telegram-notify.sh`), and **stops** — no continuation to the next
stage. Stages do not retry silently.

## Model and language

- **No hardcoded model** — every stage's agent runs on the user's default
  model (issue #82).
- **Response language** — agents respond in the user's input language
  (locale rule, issue #73).

## Related

- Agents: `agents/design/README.md` (pipeline flow and per-agent contracts)
- Commands: `commands/ocf:build-ui.md`, `commands/ocf:audit-ui.md`
