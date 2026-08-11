---
hidden: true
description: Senior reviewers index — specialized code review domains
---

# Senior Reviewers

Specialized code reviewers, each focused on a specific domain.

Reviewers are called in parallel by the pipeline after Developer implementation,
before corrections are applied and the Publish Requester creates the MR.

All senior reviewers must:
- Verify acceptance criteria defined in the issue are met
- Confirm tests were written and pass — prefer `scripts/test-runner.sh --check`
  (via the `test-runner` skill): a fresh cache confirms the suite passed for
  the current code without re-running it. Only re-run when the cache is stale
  or you need a domain-specific test (use `--run -- <filter>`). Never re-run an
  unchanged suite.
- Register any new issues found in `known_issues.md`
- Ensure `known_issues.md` status reflects current state
- Distinguish bugs from missing business rules:
  - **Bug** = code violates documented acceptance criteria or business rules
  - **Missing business rule** = rule was never captured in the issue during discovery
    → tag as `incomplete-spec`, do NOT register as bug. The fix is to refine the
    issue through discovery (PO → TL), not to patch code against an incomplete spec

## Roles

| Agent | Focus |
|-------|-------|
| Devops | Infrastructure, CI/CD, deployment |
| Backend | Server-side logic, APIs, data flow |
| Frontend | UI components, state management, styling |
| Data | Database queries, schemas, migrations |
| Security | Auth, input validation, dependency vulnerabilities |
| Performance | Optimization, caching, resource usage |
| UX/UI | User experience, accessibility, design consistency |
| Runtime | Environment configuration, build, packaging |
| Mobile | Mobile-specific code, responsiveness |
| QA | Test quality, coverage, edge cases |
