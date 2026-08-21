---
hidden: true
description: Design sector agents index — the Adorable pipeline: greenfield 4-pass flow (art-director, ui-architect, ui-implementer, ui-critic) plus the audit/refactor entry for existing codebases (ui-auditor, ui-refactor-planner)
---

# Design

Subagent definitions for the **design** sector: the Adorable pipeline that
turns a brief into production UI with a hard quality gate — including the
audit/refactor entry that lets the pipeline work on **existing** codebases,
not just greenfield projects.

```
GREENFIELD:
brief → art-director → design_spec.json → ui-architect → component_tree.json
     → ui-implementer → code → ui-critic → APPROVED / ISSUES_FOUND

EXISTING CODEBASE (audit/refactor entry):
codebase → ui-auditor → audit_report.json → ui-refactor-planner → refactor_plan.json
     (the planner also consumes the art-director's design_spec.json;
      refactor_plan.json feeds ui-architect and ui-implementer, then
      ui-critic — the greenfield flow above)
```

Each agent has a single responsibility and consumes/produces structured JSON
— no ambiguous text between agents:

| Agent | Function |
|-------|----------|
| `ui-auditor` | Entry pass for existing codebases — reads the codebase via detection-only bash and produces `audit_report.json`: detected stack, file inventory, visual/structural/state/accessibility/responsiveness/performance findings, 1–5 severity scores per dimension, CRIT-xxx issues with file+line citations, and preserved_patterns. Never writes or edits |
| `ui-refactor-planner` | Consumes `audit_report.json` + the art-director's `design_spec.json` and produces the migration contract `refactor_plan.json`: Group A/B/C issue triage, per-stack token strategy, component decisions (PRESERVE/ADAPT/REFACTOR/SPLIT/REPLACE/DEPRECATE), phased plan with rollback, dependency map, token mapping. Never plans big bang |
| `art-director` | Pass 1 — receives a brief and produces `design_spec.json`: palette, typography, spacing, radius, shadow, motion, layout_spec (breakpoints), component vocabulary, signature element, copywriting principles, accessibility requirements, quality_checklist. Never writes code |
| `ui-architect` | Pass 2 — consumes `design_spec.json` (and `refactor_plan.json` when refactoring) and produces `component_tree.json`: layout regions, component contracts (props/states/events/accessibility/responsive), interaction map, build order, quality_gates. Never writes code |
| `ui-implementer` | Pass 3 — consumes both JSONs and writes production code files per the contracts, following the build_order and the pre-delivery verification protocol; produces the structured JSON hand-off for the critic |
| `ui-critic` | Pass 4 — quality gate: evaluates the code against the design_spec quality_checklist, component_tree contracts and quality_gates, and returns APPROVED or ISSUES_FOUND with component-specific findings. Blocks delivery on any blocking failure |

## Shared conventions

- Agents run on the user's default model — the frontmatter declares no
  hardcoded model (repo convention).
- All agents respond in the user's input language (locale rule, #73) —
  including the ui-auditor and ui-refactor-planner.
- Output JSON schemas are chained: `audit_report.json` (ui-auditor) feeds
  `refactor_plan.json` (ui-refactor-planner); the critic only checks fields
  the art-director/architect produce; the 6 data states (empty, loading,
  error, partial, success, offline) are the same end-to-end. The ui-auditor
  and ui-refactor-planner also output pure JSON with no text outside it.
- Skills consumed: `design-tokens`, `reference-library`, `visual-hierarchy`
  (art-director, ui-critic, ui-auditor), `component-patterns` (ui-architect,
  ui-implementer, ui-critic, ui-auditor, ui-refactor-planner).
- See `skills/design/*` for the canonical token system and pattern library.
