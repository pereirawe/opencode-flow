---
name: strategic-brief
description: Author senior-grade strategic consolidation briefs (GO/NO-GO) that merge fragmented business docs into one robust decision base with branding, competitors, sector tasks, investment, opex, EBITDA/break-even/ROI, market scenarios and synthetic-data simulation plans. Complements tech-spec and proposal-writer. Use when the user asks for a strategic document, consolidated business case, GO/NO-GO decision base, "documento estrategico", "consolidado estrategico", or investment/financial planning before a spec, business case, viability study, or go/no-go decision. Do not use to write technical specifications or commercial proposals themselves — route those to tech-spec and proposal-writer.
---

# Strategic Brief Skill

Produce the single strategic document that decides whether a project
deserves a tech spec and a commercial proposal. It consolidates — never
summarizes away — all source docs, then expands into decision-grade
sections. Tone is senior, skeptical, and blocking: a weak thesis dies
here, before engineering burns cash.

## Position in the Pipeline

```
strategic-brief → tech-spec → proposal-writer
```

- **Input:** 1+ fragmented docs (business model, validation memos,
  annexes, HTML exports, interview notes). Never invent source claims —
  trace every section to its origin.
- **Output:** one robust `00-CONSOLIDADO-ESTRATEGICO-<Slug>.md` (or
  `docs/strategy/<slug>.md`) that becomes the normative business input
  for `tech-spec` (§1 Context, §4 Business Rules, §9 Roadmap, §10 Risks)
  and later `proposal-writer` (§2 Need, §7 Investment, §10 Risks).
- **Standalone:** the brief runs independently (GO/NO-GO only). When the
  downstream skills exist, it feeds them — it never replaces them.
- **Non-goals:** no API schemas, no endpoint/field detail, no proposal
  pricing tables or commercial terms — link or defer to `tech-spec`
  and `proposal-writer`.
- **Minimum inputs to start:** ≥1 source doc, a named decision-maker,
  and a decision date. Thin evidence is allowed, but every number gets
  an evidence grade (see Numbers Rigor) and a validation action in §16
  — never block on missing data, block on ungraded data.

## Canonical Structure

Every strategic brief produced through this skill MUST have these
sections, in order. Never delete a section — write `N/A — <reason>`
when it does not apply.

```
# STRATEGIC CONSOLIDATION — <Project>
## Decision-Base for GO / NO-GO, Tech Spec and Commercial Proposal

- Version: <semver>
- Date: <YYYY-MM-DD>
- Status: draft | review | approved
- Sources consolidated: <list with paths>

## 1. Consolidated Executive Summary
   One-phrase idea, traction thesis, revenue thesis, the single
   12-month numeric objective the GO verdict is conditioned on
   (e.g. "X paying units + R$Y MRR by month 12"), conditional
   GO/NO-GO verdict up front.

## 2. Value Proposition per Audience
   Table: who → quantified pain (frequency × current workaround cost)
   → budget owner (whose P&L pays, existing budget line?) →
   willingness to pay, each row evidence-graded (E1/E2/E3). Rows
   without a priced status quo stay E3 and block `Status: approved`.

## 3. Product Architecture (modules & flows)
   Consolidated modules, wave scope, regulatory blockers flagged.
   Plan-gating rule: every feature visible in all plans; unentitled
   features show locked state with minimum-plan badge + upsell CTA
   (1 click to CTA, 7-day trial before hard paywall, no dark patterns,
   instrumented lock_view/upsell_click/trial_start); entitlement
   matrix plan × feature + per-tenant flags go to tech-spec.

## 4. Branding, Brand and Identity
   Provisional vs final name, INPI/domain screening, white-label vs
   marketplace rule, minimum viable identity, forbidden claims.

## 5. Marketing and Go-To-Market
   B2B engine, B2C engagement without direct CAC, message per segment,
   indirect channels.

## 6. Competitor Assessment
   Priced table (plan range + add-ons), strengths/weaknesses,
   differentiation matrix, central strategic dilemma with architectural
   decision (e.g. SaaS vs Marketplace → white-label first),
   incumbent-response paragraph (what the market leader most likely
   ships in 6–12 months and why we still win).

## 7. Technical Aspects
   Wave scope, critical integrations (messaging API, e-signature,
   fiscal, payments), data/RBAC summary, compliance blockers
   (sector regulation + LGPD/GDPR).

## 8. Sector Task Assignment
   RACI per front (CEO/CMO/CFO/CTO/COO/Legal), capability gaps +
   key hires (founder-team fit stated explicitly), rituals and gates,
   next-30-days list.

## 9. Investment Planning (CAPEX / build)
   Effort + build cost per wave, cumulative capital at risk per gate
   (max loss if the project is killed there), funding rule (next wave
   only on gate).

## 10. Expense Planning (OPEX)
    Fixed monthly lines + variable per-use lines with margin rule
    (never unlimited metered resources).

## 11. Financial Planning, Break-even, EBITDA, ROI and Indicators
    Final pricing, revenue by phase, break-even math (shown),
    EBITDA levers, ROI/payback, runway to break-even in months under
    base AND pessimistic, monthly cockpit with targets + alerts.
    Cockpit metrics follow the revenue model — subscription:
    MRR/ARR, NRR, CAC payback, LTV/CAC, logo churn, gross margin;
    marketplace/commission: GMV, take rate, contribution margin
    after incentives; transactional/services: orders, contribution
    margin per order, repeat rate.

## 12. Market Simulations
    TAM/SAM/SOM (order of magnitude), pessimistic/base/optimistic
    12-month table with explicit assumptions, sensitivity ranking.
    SOM must be triangulated top-down AND bottom-up (sales capacity
    × conversion); disagreement beyond 3x stays E3 with a validation
    action in §16.

## 13. Risks, Mitigation and Governance
    Top risks with mitigation + owner. Regulatory and unit-economics
    risks are mandatory.

## 14. GO / NO-GO Decision Criterion
    Checkbox gate: all must hold for GO; any trigger forces NO-GO/pivot.
    Includes dated kill triggers (metric + threshold + date, e.g.
    "pessimistic break-even beyond month 18 → NO-GO") and a
    one-paragraph pre-mortem (how this business dies in 18 months).

## 15. Commercial & Financial Simulation Plan (synthetic data)
    Spec for /simulations/: params.yaml, generator.py (fixed seed),
    finance.py, scenarios/, outputs (charts + decision table), rules
    (no real PII, assumptions on every chart footer).

## 16. Wave Roadmap + Immediate Next Steps
    Multi-sector gantt from decision to launch (decision, project
    management, design/UX, brand, development, finance, sector
    training/go-live — never dev-only), with wave gates + actionable
    checklist.

## Appendix — Traceability
   Which source doc fed which section + assumption register
   (assumption, confidence high/med/low, validation action + owner).
```

## Discovery — 10 Dimensions to Probe

Before drafting, cover all 10. Ask in themed batches; escalate to
C-level when senior judgment is required.

1. **Sources** — which docs, which version is normative on conflict
2. **Thesis** — traction flywheel, why now, cost of inaction
3. **Audiences** — pains vs willingness to pay (evidence, not wishes),
   budget owner and existing budget line per audience
4. **Product** — modules, wave boundaries, what is deliberately deferred
5. **Brand** — name status, trademark/domain, white-label vs directory
6. **GTM** — direct vs indirect channels, CAC payback per channel
   (flywheel models: B2C CAC must be ~0)
7. **Competition** — real prices, add-on traps, exploitable weaknesses
8. **Money** — full-operation commitment per wave (build + phase
   OPEX + phase GTM), never dev-only; OPEX split fixed/variable;
   pricing, margin rule; working-capital buffer
9. **Risk** — regulatory blockers, unit-economics killers, scope creep
10. **Simulations** — assumptions to vary, seed discipline, decision table

## Senior Challenge Protocol (mandatory)

The brief is not a cheerleader. Apply in order, and block on failure:

1. **Kill the thesis first** — state the strongest case against building.
2. **Price the status quo** — what does the customer pay today to
   tolerate the pain? If zero, demand payment evidence.
3. **Expose the dilemma** — name the one architectural conflict that
   kills adoption (e.g. marketplace cannibalization) and decide it as
   a business rule, not a footnote.
4. **Protect the margin** — any metered or variable cost (messages,
   AI inference, gateway %, COGS, logistics) MUST have franchise +
   overage or pass-through math against a declared target gross margin
   with a sector benchmark (SaaS default ≥70% — a default, not a
   universal law). Unlimited metered plans are rejected outright.
   Every metered cost ALSO gets a billing gate: zero consumption
   without an active paid plan/add-on (no free-tier sends, no uncapped
   trials — demos run on an internal sandbox with a daily cap), plus
   quota alerts at 80% and 100%. State the franchise per plan in a
   table, based on measured or E3-estimated unit usage (e.g. messages
   per booking, AI minutes per user).
5. **Gate the waves** — no wave N+1 without the exit proof of wave N
   (paying users, margin proof, legal opinion). Each gate states
   metric + threshold + date.
6. **Charge the owners** — every `[NEEDS DECISION]` gets an owner and a
   deadline; ownerless items block `Status: approved`.
7. **Pre-mortem and disconfirming evidence** — write how the business
   dies in 18 months, then list the two facts that would prove the
   thesis wrong and how to check them within 30 days.
8. **Hygiene the brands** — no third-party product or company names
   outside the competitor section. Refer to concepts generically
   (social bio link, paid local search); the designated
   channel/supplier and regulators/standards stay named only where
   they are cost or compliance inputs. Trademark-collision screening
   points at "the incumbents mapped in §6", never re-lists them in
   the brand section.

## Numbers Rigor

- Every number carries an evidence grade: `E1` verified (≥2 sources or
  paid data), `E2` single-source, `E3` assumption. E3 numbers MUST have
  a validation action in §16 with owner + date.
- State the priced status quo per audience (what the customer pays
  today to tolerate the pain); audiences paying zero today stay E3
  until payment evidence exists.
- Margin targets cite a sector benchmark; the 70% gross-margin bar is
  the SaaS default, not a universal law.
- Never write "profitable" — write `break-even ≈ fixed / (ticket ×
  gross-margin)` with the actual inputs shown.
- Never write "large market" — write `TAM/SAM/SOM order of magnitude
  + source`.
- Never write "low churn" — write `monthly logo churn X% with alert at Y%`.
- Every scenario table names its assumptions (ticket, churn, CAC,
  margin). Base scenario must be reproducible from the brief alone.

## Mermaid Graphics (mandatory — never ASCII)

Every brief MUST embed at least these four Mermaid diagrams, placed in
their sections. Never use ASCII charts. Keep labels in the project
locale; keep node IDs in English. The examples below illustrate with a
SaaS case — adapt nouns to the business (patients, guests, orders,
shipments). They are structural templates, not content.

1. **Traction flywheel (§1)** — `graph LR` showing the B2B → tutor loop:

   ```mermaid
   graph LR
     A[B2B pain: agenda + no-show] --> B[White-label booking link]
     B --> C[Tutors onboard via clinic]
     C --> D[Health wallet + reminders]
     D --> E[Recurring bookings + retention]
     E --> A
   ```

2. **Wave roadmap (§16)** — `gantt` spanning decision → launch with
   one section per sector (decision, management, design, brand,
   development, finance, training), gates as milestones:

   ```mermaid
   gantt
     title Wave Roadmap (decision to launch)
     dateFormat YYYY-MM-DD
     section Decision
     Brief + GO/NO-GO              :d1, 2026-01-05, 14d
     section Management
     Weekly rites + gates          :after d1, 180d
     section Design and brand
     Name screening + identity     :after d1, 30d
     Wave 1 prototype              :after d1, 30d
     section Development
     Wave 1 build                  :w1, after d1, 60d
     Traction gate                 :milestone, m1, after w1, 0d
     section Finance
     Billing gate + gateway        :after d1, 30d
     section Training and go-live
     Playbooks + pilot             :before m1, 21d
     Launch                        :milestone, after m1, 0d
   ```

3. **Revenue mix (§11)** — `pie showData` with plan share:

   ```mermaid
   pie showData
     title MRR mix (Base scenario)
     "Petshop Pro" : 35
     "Clinica Essencial" : 25
     "Clinica Pro" : 20
     "Daycare/Hotel" : 12
     "Add-ons (WA + IA + fiscal)" : 8
   ```

4. **Core transaction / consent flow (§3/§7)** — `sequenceDiagram`
   for the money-or-data handoff (consent, payment, fulfilment).
   Data-sharing businesses show opt-in; all others show the core
   paid transaction. Name the handoff event:

   ```mermaid
   sequenceDiagram
     participant E as Establishment
     participant P as Platform
     participant T as Tutor
     E->>P: Request access (phone / QR)
     P->>T: Push/WhatsApp consent request
     T->>P: Approve with scope (full / operational / limited)
     P->>E: Grant scoped read access (audited)
   ```

Optional fifth: `flowchart TB` for system architecture (only when §7
needs it).

Validation: every diagram must render (correct Mermaid syntax, no
unclosed blocks); every `gantt` uses real dates; every `pie` sums to
100 or declares absolute values; every `sequenceDiagram` names the
money/data handoff event.

## Quality Checklist (run before sign-off)

- [ ] Four Mermaid diagrams embedded and syntactically valid (flywheel, gantt, pie, sequence); no ASCII charts
- [ ] Sequence diagram shows the core transaction (or consent flow for data-sharing models)
- [ ] §1 states the single 12-month numeric objective conditioning the GO verdict
- [ ] Every number evidence-graded (E1/E2/E3); each E3 has a validation action in §16
- [ ] Priced status quo stated per audience
- [ ] No source claim dropped without traceability in the Appendix
- [ ] Assumption register in the Appendix with confidence + owner
- [ ] Branding section decides provisional vs final name + INPI/domain
- [ ] Competitor table has real prices + add-on charges
- [ ] Differentiation matrix lists ≥3 exploitable weaknesses
- [ ] Incumbent-response paragraph present (§6: leader's likely
  6–12 month move and why we still win)
- [ ] Sector tasks form a RACI with next-30-days
- [ ] Investment per wave (effort + cost) with funding rule
- [ ] OPEX split fixed vs variable with margin rule
- [ ] Break-even math visible with inputs
- [ ] Runway to break-even in months (base AND pessimistic)
- [ ] Capital at risk stated per wave gate as full-operation commitment (build + OPEX + GTM), never dev-only
- [ ] Billing gate on every metered cost (zero consumption without paid plan; capped sandbox demos; 80/100% alerts)
- [ ] Cockpit indicators have target + alert each
- [ ] 3 scenarios (pessimistic/base/optimistic) with assumptions
- [ ] GO/NO-GO is a checkbox gate, not prose
- [ ] Kill triggers dated + pre-mortem paragraph present
- [ ] Capability gaps + key hires stated in §8
- [ ] Simulation plan specs seed discipline + no-real-PII rule
- [ ] Every `[NEEDS DECISION]` has owner + deadline
- [ ] Gantt is multi-sector (decision → launch), not dev-only
- [ ] No third-party brand names outside the competitor section
- [ ] Locale-correct: decision prose in project locale, code/IDs in English

## Anti-Patterns to Reject

- Summary disguised as consolidation (dropping prices, limits, rules)
- Unlimited metered resources (messages, AI) bundled in flat plans
- Marketplace-before-trust (exposing clients to competitors in phase 1)
- Mandatory fee on the core free action (kills adoption flywheel)
- Round-number TAM without source or funnel math
- Vague gates ("validate later") without owner, metric or deadline
- Mixing spec-level detail (API fields) into the brief — link, do not embed
- Marketing prose in the verdict — executives decide on math, not adjectives

## Related Skills

- `tech-spec` — consumes §1 Context, §3 Product, §4 Brand rules,
  §7 Technical, §10 Cost constraints, §13 Risks, §16 Roadmap
  as normative input.
- `proposal-writer` — consumes §1 Need, §9 Investment, §11 Financials,
  §13 Risks via the approved spec.
- `financial-modeling` — deep projections behind §11–§12.
- `cfo-advisory` — fundraising/board reading of §§11–§12.
- `competitor-intelligence` — deep dives behind §6.
- `commercial-forecasting` — pipeline math behind §12.
