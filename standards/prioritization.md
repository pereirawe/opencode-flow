# PO Prioritization Proposals

This file documents the Product Owner's prioritization proposals for backlog items.
Proposals are registered here before being promoted to `known_issues.md`.

## Format

Each proposal follows this structure:

```markdown
### Proposal YYYY-MM-DD-<N>: <title>
- Priority: critical | high | medium | low
- Business value: <what value this delivers>
- Target sprint: <sprint-name | next | backlog>
- Description: <brief>
- Business rules: <known business logic, constraints, domain rules>
- Stakeholders: <who requested or benefits>
- Rationale: <why now, why this priority>
- Dependencies: <related issues, external factors>
- Proposed issue type: bug | feat | doc | chore
```

`Business rules:` is required for `feat` proposals — document everything known
at proposal time. Unknown rules will be captured during discovery refinement.

## Active Proposals

<!-- PO: add new proposals here, ordered by priority -->

## Lifecycle

1. **Proposal** — PO registers the idea with business context and priority
2. **CTO/TL Review** — CTO and Tech Lead assess architectural impact and feasibility
3. **Refined** — User story created with acceptance criteria by PO, refined by TL
4. **QA Review** — QA ensures testability and adds quality criteria
5. **Promoted** — Entry added to `known_issues.md` as `backlog` or `ready`
6. **Executed** — Follows standard issue lifecycle from `known_issues.md`
