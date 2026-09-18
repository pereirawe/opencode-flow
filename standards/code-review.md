# Code Review Guidelines

Per-profile review standards. Each senior reviewer loads its profile file via
the locale-loader skill before reviewing. English is the source of truth
(pt/es translations are lazy).

## Profiles

- [Backend](code-review/backend.md) — server logic, APIs, data flow
- [Data](code-review/data.md) — schemas, queries, migrations
- [Frontend](code-review/frontend.md) — UI, state, styling, SSR
- [Security](code-review/security.md) — OWASP Top 10 / ASVS
- [Runtime](code-review/runtime.md) — env, build, packaging
- [DevOps](code-review/devops.md) — infra, CI/CD, deployment
- [Performance](code-review/performance.md) — optimization, caching
- [UX/UI](code-review/ux-ui.md) — experience, accessibility, design
- [QA](code-review/qa.md) — test quality and coverage
- [Mobile](code-review/mobile.md) — mobile-specific code
- [Auth](code-review/auth.md) — authN/authZ, tokens, tenancy

## Transverse rule

A missing business rule is NOT a bug — it is an `incomplete-spec`. Classify
findings as bug / incomplete-spec / edge case per the profile tables and send
incomplete specs back through discovery refinement.
