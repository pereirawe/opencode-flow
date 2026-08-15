---
name: owasp-samm
description: OWASP Software Assurance Maturity Model (SAMM) — business functions, security practices, maturity levels, and how to assess an organization's software security posture. Use when assessing or planning security program maturity, benchmarking security practices, or building a security improvement roadmap.
---

# OWASP SAMM

The Software Assurance Maturity Model (SAMM) is a framework for assessing,
formulating, and improving an organization's software security posture. Use
this skill to evaluate a security program's maturity and to plan concrete
improvements.

## Business functions and security practices

| Business Function | Security Practices |
|-------------------|--------------------|
| Governance | Strategy & Metrics, Policy & Compliance, Education & Guidance |
| Design | Threat Assessment, Security Requirements, Secure Architecture |
| Implementation | Secure Build, Secure Deployment, Defect Management |
| Verification | Architecture Assessment, Requirements-driven Testing, Security Testing |
| Operations | Data Protection, Legacy Management, Operations Enablement |

## Maturity levels (0–3)

| Level | Name | Behavior |
|-------|------|----------|
| 0 | (Not started) | Activity is absent or ad hoc; no defined process |
| 1 | Initial | Activity performed inconsistently, dependent on individuals, informal |
| 2 | Defined | Activity standardized, documented, and consistently executed across teams |
| 3 | Managed | Activity measured, monitored, and optimized based on data |

Assessment criteria per practice: objectives, success metrics, and activities
at each level. Score each practice 0–3; derive a maturity profile per business
function.

## Assessment approach

1. **Scope**: identify the organization/team and the software portfolio.
2. **Assess**: for each of the 15 practices, determine the current maturity
   level by comparing actual behavior against the SAMM level definitions.
3. **Record**: build a maturity profile table (practice → level 0–3).
4. **Gap analysis**: compare current vs target level; identify the activities
   required to move one level up.
5. **Roadmap**: prioritize improvements by risk reduction and effort; propose
   a phased plan.

## Improvement roadmap guidance

- Address the highest-risk gaps first (practices at level 0–1 in
  business-critical functions).
- Prefer process changes that are measurable at level 2 before aiming for
  level 3 optimization.
- Tie each improvement to a concrete success metric (e.g. % of apps with
  threat models, time to patch critical CVEs, coverage of security testing).

## Output format

1. Maturity profile table (practice → current level)
2. Per business function: summary and strengths/weaknesses
3. Gap analysis vs target levels
4. Prioritized improvement roadmap with metrics
