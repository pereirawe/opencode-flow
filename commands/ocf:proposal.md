---
description: Author a client-ready commercial proposal from an approved tech spec. Delegates to the business-ops/proposal-writer agent, which reads docs/specs/<slug>/tech-spec.md, runs commercial discovery, invokes C-level experts on pricing and positioning, and produces proposal.md + proposal.html + proposal.pdf with the company brand header.
agent: business-ops/proposal-writer
---

## /ocf:proposal

Create the commercial proposal for an approved technical specification.

Usage:

```
/ocf:proposal <slug>
```

Example:

```
/ocf:proposal dia-educacao-2026
```

## Preconditions

- `docs/specs/<slug>/tech-spec.md` exists and is marked
  `Status: approved` with at least one C-level sign-off.
- Brand resolved via `scripts/proposal/brand-resolve.sh` OR the user explicitly
  chose a no-brand build (the agent asks when no brand is found).

## What happens

1. The `business-ops/proposal-writer` agent reads the approved tech spec
   end-to-end.
2. It runs commercial discovery (client profile, budget, timeline, terms,
   sponsorship structure) in question batches.
3. It invokes C-level agents for pricing (`cfo`,
   `commercial/pricing-strategist`), positioning (`cmo`), delivery
   feasibility (`cto` + `business-ops/capacity-planner`), and legal
   (`commercial/deal-desk`) as needed.
4. It derives effort and price with visible math, drafts the proposal with
   Mermaid diagrams (mindmap, gantt, pie), runs the quality checklist, and
   asks for explicit sign-off before saving.
5. Outputs: `docs/specs/<slug>/proposal.md` (source), `proposal.html`
   (from the reference template) and `proposal.pdf` (via
   `scripts/proposal/pdf.sh`), with the company logo + data header per
   `standards/proposal-design.md`.
