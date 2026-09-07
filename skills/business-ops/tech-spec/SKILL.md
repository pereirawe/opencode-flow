---
name: tech-spec
description: Author rigorous technical specifications through structured discovery, C-level consultation, and a 12-dimension quality checklist. Use when the user asks to create, refine, or review a technical specification, tech spec, functional spec, SRS, or architecture document. "tech spec", "technical specification", "SRS", "escrever spec técnica", "especificação técnica" also trigger this skill.
---

# Tech Spec Skill

Produce technical specifications that are unambiguous, testable, and
decision-ready. A good spec eliminates ambiguity so the delivery team never
has to guess.

## Canonical Structure

Every tech spec produced through this skill MUST have these sections, in
order. Never delete a section — write `N/A — <reason>` when it doesn't
apply.

```
![Logo](./assets/logo.<ext>)

# <Project Name> — Technical Specification

- Version: <semver>
- Status: draft | review | approved
- Owner: <name>
- Last updated: <YYYY-MM-DD>

## 1. Context and Problem
## 2. Goals and Non-Goals
## 3. Users and Personas
## 4. Business Rules (BR-XXX-NN)
## 5. Functional Scope
   5.1 Screens / user flows
   5.2 API surface
   5.3 Integrations
## 6. Data Model
## 7. Non-Functional Requirements
   7.1 Performance (measurable targets)
   7.2 Security & privacy
   7.3 Accessibility
   7.4 Observability
   7.5 Compliance (LGPD/GDPR/sector-specific)
## 8. Architecture
   8.1 Diagram (Mermaid flowchart)
   8.2 Stack decisions (ADR references)
   8.3 Deploy topology
## 9. Roadmap and Phases
## 10. Risks and Trade-offs
## 11. Open Questions ([NEEDS DECISION] / [DEFERRED])
## 12. Sign-off
   - CTO — <date> — <what was validated>
   - CMO — <date> — <what was validated>
   - CFO — <date> — <what was validated>
   - COO — <date> — <what was validated>
```

## Discovery — 12 Dimensions to Probe

Before drafting, cover all 12. Ask the user in themed batches; escalate to
a C-level when the answer requires senior judgment.

1. **Problem framing** — what breaks today, who feels it, cost of inaction
2. **Users** — personas, volume, distribution across geographies/devices
3. **Business rules** — what MUST be true, what CANNOT happen, exceptions
4. **Functional scope** — screens, flows, actions, boundaries of the MVP
5. **Data** — entities, relationships, PII, retention, sensitive fields
6. **Integrations** — external systems, contracts, SLAs, fallbacks
7. **Non-functional** — latency, throughput, availability, RTO/RPO
8. **Security** — auth model, threat surface, ASVS level
9. **Compliance** — LGPD/GDPR/sector, consent, audit trail
10. **Architecture** — stack, hosting, ADRs required
11. **Operations** — runbook, on-call, deploy cadence, feature flags
12. **Timeline & phasing** — hard dates, dependencies, freeze windows

## Business Rule Convention

`BR-<DOMAIN>-<NN>` — 3-letter domain, two-digit number, single sentence
that starts with a modal verb (`MUST`, `MUST NOT`, `MAY`, `SHOULD`).

Example:
- `BR-AUTH-01` — Authentication MUST be phone + password + WhatsApp OTP.
  No other channel is permitted.

Every BR has:
- A short justification
- At least one testable acceptance line (feeds the delivery `Tests:` block)
- A domain owner

## Non-Functional Rigor

- Never write "must be fast" — write `p95 latency ≤ 300ms measured at the
  edge`.
- Never write "highly available" — write `99.9% monthly, RTO 15min, RPO
  5min`.
- Never write "secure" — write `OWASP ASVS L2, no critical/high findings
  in the last review`.

## Diagrams

Use Mermaid, not ASCII:

- Architecture: `flowchart TB` with subgraphs per layer
- User flows: `graph LR` colored by role
- Sequence: `sequenceDiagram` for cross-service protocols
- Roadmap: `gantt` with phases, milestones, dependencies
- Effort split: `pie showData`

## Quality Checklist (run before sign-off)

- [ ] Every BR has a domain, a modal verb, and a test line
- [ ] Every NFR has a measurable target and a measurement method
- [ ] Data model calls out PII and retention
- [ ] Security section names the ASVS level and threat model status
- [ ] Compliance section names the applicable regulation(s)
- [ ] Architecture has a Mermaid diagram (not ASCII)
- [ ] Roadmap has a Mermaid gantt with real dates
- [ ] Every `[NEEDS DECISION]` has an owner and a deadline
- [ ] Sign-off section lists at least the CTO (mandatory)
- [ ] Logo asset embedded at the top
- [ ] Locale-correct: user-facing prose in project locale, code in English

## Anti-Patterns to Reject

- Wall-of-text business rules without IDs
- "TBD" without owner or deadline
- Aspirational NFRs ("fast", "scalable", "reliable")
- ASCII diagrams when Mermaid renders
- Mixing scope changes into a "draft" spec — new scope opens a new spec or
  ADR
- Silent assumptions ("obviously we'll use Postgres") — write it as a
  decision with rationale
