---
hidden: true
description: Design sector agents index — the 4-pass Adorable pipeline (art-director, ui-architect, ui-implementer, ui-critic)
---

# Design

Subagent definitions for the **design** sector: the 4-pass Adorable pipeline
that turns a brief into production UI with a hard quality gate.

```
brief → art-director → design_spec.json → ui-architect → component_tree.json
     → ui-implementer → code → ui-critic → APPROVED / ISSUES_FOUND
```

Each agent has a single responsibility and consumes/produces structured JSON
— no ambiguous text between agents:

| Agent | Function |
|-------|----------|
| `art-director` | Pass 1 — receives a brief and produces `design_spec.json`: palette, typography, spacing, radius, shadow, motion, layout_spec (breakpoints), component vocabulary, signature element, copywriting principles, accessibility requirements, quality_checklist. Never writes code |
| `ui-architect` | Pass 2 — consumes `design_spec.json` and produces `component_tree.json`: layout regions, component contracts (props/states/events/accessibility/responsive), interaction map, build order, quality_gates. Never writes code |
| `ui-implementer` | Pass 3 — consumes both JSONs and writes production code files per the contracts, following the build_order and the pre-delivery verification protocol; produces the structured JSON hand-off for the critic |
| `ui-critic` | Pass 4 — quality gate: evaluates the code against the design_spec quality_checklist, component_tree contracts and quality_gates, and returns APPROVED or ISSUES_FOUND with component-specific findings. Blocks delivery on any blocking failure |

## Shared conventions

- Agents run on the user's default model — the frontmatter declares no
  hardcoded model (repo convention).
- All agents respond in the user's input language (locale rule, #73).
- Output JSON schemas are chained: the critic only checks fields the
  art-director/architect produce; the 6 data states (empty, loading, error,
  partial, success, offline) are the same end-to-end.
- Skills consumed: `design-tokens`, `reference-library`, `visual-hierarchy`
  (art-director, ui-critic), `component-patterns` (ui-architect,
  ui-implementer, ui-critic).
- See `skills/design/*` for the canonical token system and pattern library.
