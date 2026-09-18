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
- Confirm tests were written and pass — reviewers NEVER run
  `scripts/test-runner.sh --run`; the only trusted paths for test results are
  `scripts/test-runner.sh --check` returning PASS on a fresh cache and the
  verdict emitted by `scripts/committer-check.sh`. Never re-run an unchanged
  suite.
- Register any new issues found in `known_issues.md`
- Ensure `known_issues.md` status reflects current state
- Distinguish bugs from missing business rules:
  - **Bug** = code violates documented acceptance criteria or business rules
  - **Missing business rule** = rule was never captured in the issue during discovery
    → tag as `incomplete-spec`, do NOT register as bug. The fix is to refine the
    issue through discovery (PO → TL), not to patch code against an incomplete spec

## Bash discipline

Senior reviewers run with a **DENY-ALL + allowlist** bash permission model:

- Only commands on the allowlist may run: `git *`, `ls *`, `cat *`, `find *`,
  `head *`, `tail *`, `wc *`, `rg *`, `date *`, `echo *`, plus the scoped
  scripts (`scripts/preflight.sh`, `scripts/issue-lint.sh`, and the test runner
  with `--check`/`--status` only).
- `echo` is allowed EXCLUSIVELY for terminal status output — never with a
  redirect (`>`, `>>`) to write files; file writing goes through the `edit:`
  allowlist (`.opencode/known_issues.md`, `.opencode/reviews/**`).
- **NEVER run the test runner with `--run`** — reviewers only consume the test
  cache via `--check`/`--status`; re-running the suite is the Developer's job.
  `--check` PASS plus the committer-check report are the only paths to trust
  test results.
- Edit access is restricted to `.opencode/known_issues.md` and
  `.opencode/reviews/**` — everything else is denied.
- Broad codebase re-exploration is prohibited: use only `git diff`/`ls`/`cat`/
  `find`/`rg` within the review scope.

## Roles

| Agent | Focus |
|-------|-------|
| Devops | Infrastructure, CI/CD, deployment |
| Backend | Server-side logic, APIs, data flow |
| Frontend | UI components, state management, styling |
| Data | Database queries, schemas, migrations |
| Security | Auth, input validation, dependency vulnerabilities |
| Auth Architect | Auth architecture, JWT, OAuth, RBAC, multi-tenancy, token lifecycle |
| Performance | Optimization, caching, resource usage |
| UX/UI | User experience, accessibility, design consistency |
| Runtime | Environment configuration, build, packaging |
| Mobile | Mobile-specific code, responsiveness |
| QA | Test quality, coverage, edge cases |
