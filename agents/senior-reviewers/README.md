# Senior Reviewers

Specialized code reviewers, each focused on a specific domain.

Reviewers are called in parallel by the pipeline after Developer implementation,
before corrections are applied and the Publish Requester creates the MR.

All senior reviewers must:
- Verify acceptance criteria defined in the issue are met
- Confirm tests were written and pass
- Register any new issues found in `known_issues.md`
- Ensure `known_issues.md` status reflects current state

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
