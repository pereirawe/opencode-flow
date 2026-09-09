---
name: proposal-writer
description: Turn an approved tech spec into a client-ready commercial proposal (scope, deliverables, timeline, investment, terms) with C-level validation on pricing and positioning. Use when the user asks to create, refine, or review a commercial proposal, SOW, quote, or client-facing project document derived from a spec. "proposal", "commercial proposal", "SOW", "proposta comercial", "proposta técnica" also trigger this skill.
---

# Proposal Writer Skill

Author commercial proposals that a client executive can read, understand,
and sign — grounded in an approved technical specification.

## Preconditions

- `docs/specs/<slug>/tech-spec.md` exists and is in `Status: approved`.
- Brand resolution ran via `scripts/proposal/brand-resolve.sh` (see the
  `proposal-design` standard below) OR the user explicitly chose a no-brand
  build. Never assume brand availability.
- The user has confirmed client identity, budget envelope, and timeline.

## Brand & PDF delivery (mandatory — see `standards/proposal-design.md`)

1. Resolve brand assets with `scripts/proposal/brand-resolve.sh [--project-dir
   <dir>]` (project `docs/assets/company.json` + `logo.*` → global
   `~/.config/opencode/assets/` → legacy spec copy). It prints `logo=`,
   `company_json=`, `source=`, `brand=`.
2. If NO brand (`exit 1`), ASK the user (never assume): (a) generate without
   brand, (b) provide company data/logo now (saved to `<project>/docs/assets/`),
   or (c) create the brand standard first (`DESIGN.md` via `brand-to-design-md`
   + `company.json` + `logo.*`). Generate only after the answer.
3. The final delivery MUST have three outputs from one source
   `docs/specs/<slug>/proposal.md`:
   - `proposal.md` (markdown source, Mermaid allowed)
   - `proposal.html` — rendered from the reference template
     `skills/business-ops/proposal-writer/templates/proposal.html` (never CSS
     from scratch), brand header filled from `company.json` + logo
   - `proposal.pdf` — via `scripts/proposal/pdf.sh proposal.html proposal.pdf`
     (Chrome headless, LibreOffice fallback)
4. Run the `proposal-design` standard checklist before delivering the PDF.

## Canonical Structure

```
<!-- Brand header: logo + company data resolved via brand-resolve.sh
     (docs/assets/company.json + logo.*). Rendered in proposal.html/pdf;
     in the .md source, reference the resolved logo relatively when it lives
     under docs/assets — from docs/specs/<slug>/proposal.md the path is
     ../../assets/logo.png (or ./assets/logo.png for the spec-local copy). -->
# Commercial Proposal — <Project Name>

- Version: <semver>
- Date: <YYYY-MM-DD>
- Valid until: <YYYY-MM-DD>
- Prepared for: <Client>
- Prepared by: <Company>

## 1. Executive Summary
   Three lines. What, why, how much.

## 2. Understanding of the Need
   Client context in their own words. Show you listened.

## 3. Proposed Solution
   3.1 Scope overview (Mermaid mindmap)
   3.2 Key deliverables (bullet list, each tied to tech-spec §X.Y)
   3.3 Out of scope (explicit exclusions)

## 4. Approach and Methodology
   Delivery model, milestones, review cadence, communication plan.

## 5. Timeline
   Mermaid gantt with phases, milestones, critical dates, freeze windows.

## 6. Team and Roles
   Named roles, allocation %, responsibilities. RACI if useful.

## 7. Effort and Investment
   7.1 Effort table (module → hours)
   7.2 Rate and calculation (show the math)
   7.3 Discounts / sponsorships (explicit deltas)
   7.4 Final price and payment schedule
   7.5 Effort split (Mermaid pie)

## 8. Assumptions and Client Inputs
   What the client must provide, by when. Blocks the timeline if missed.

## 9. Terms
   - Payment schedule
   - IP and ownership
   - Warranty and post-delivery support
   - Change request process
   - Confidentiality
   - Cancellation

## 10. Risks and Mitigations
    Top 3–5 risks with mitigation and owner.

## 11. Why Us
    Short. Track record, differentiators. No fluff.

## 12. Acceptance
    Signature block, date, contact.

## Appendix A — Validation Log
    C-level consultations that shaped this proposal.

## Appendix B — Change Log
    Version history if this is a revision.
```

## Diagrams (Mermaid only)

- **Scope overview**: `mindmap` centered on the project name, branches per
  module.
- **Timeline**: `gantt` with real dates, dependencies (`after`), milestones
  (`milestone`).
- **Effort split**: `pie showData` with modules and hours.
- **Architecture summary** (if useful): condensed `flowchart TB`.

## Effort → Price Math (must be visible)

```
| Module          | Hours |
|-----------------|------:|
| Module A        |   120 |
| Module B        |    80 |
| ...             |   ... |
| **Total**       |   436 |

Base rate:            R$ 195/h
Market value:         436 × 195 = R$ 85 020
Sponsorship (client): R$ –78 020
Final investment:     R$ 7 000
```

Never hide the calculation. Never round without saying so.

## Language Precision

- "Estimated" — best current guess, may change with new information
- "Target" — the number we aim for, subject to conditions
- "Commitment" — contractual, breach has consequences

Use them deliberately. Mixing them erodes trust.

## Quality Checklist

- [ ] Every deliverable line traces to a tech-spec section
- [ ] Timeline uses Mermaid gantt with dependencies and milestones
- [ ] Effort table shows hours per module and totals
- [ ] Price calculation is fully visible (rate × hours, discounts, final)
- [ ] Client-provided inputs are listed with deadlines
- [ ] Payment schedule is explicit
- [ ] Change request process is defined
- [ ] Risks are named with mitigations and owners
- [ ] Valid-until date is set (typically 30–60 days)
- [ ] Brand resolved via `brand-resolve.sh`; no-brand build is explicit and user-confirmed
- [ ] `proposal.md` + `proposal.html` + `proposal.pdf` delivered; HTML from the reference template; PDF via `scripts/proposal/pdf.sh`
- [ ] Header shows logo + company name + contact from `company.json` (missing fields omitted, never invented); single-asset/no-brand headers follow the standard §3.8
- [ ] `<html lang>` set to the resolved proposal locale
- [ ] Zero unrendered template tokens in `proposal.html` (`grep -E '\{\{' proposal.html` → 0)
- [ ] Logo self-contained (data URI or relative copy) — no `file://`/remote logo
- [ ] No remote fonts/network dependency in HTML/PDF; page-number footer present (LibreOffice output checked manually)
- [ ] No internal jargon, no agent names, no code identifiers
- [ ] Locale-correct prose

## Anti-Patterns to Reject

- Deliverables that don't map to the spec
- Round-number pricing with no derivation
- Vague timelines ("Q2") when the spec has hard dates
- Missing "out of scope" section — invites scope creep
- Legal boilerplate that contradicts the client's actual constraints
- ASCII charts when Mermaid renders
- Marketing prose in the executive summary — decision-makers hate it
