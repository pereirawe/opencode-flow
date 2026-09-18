# QA Code Review Standard

Scope: test quality, coverage, edge cases, test reliability, and alignment
with the issue's `Tests:` scenarios.

## Checklist

- [ ] Every `Tests:` scenario from the issue has a corresponding test
- [ ] Tests are independent, deterministic, and fast
- [ ] Edge cases and failure paths covered, not just the happy path
- [ ] Mocks/stubs appropriate; no brittle implementation-coupled assertions
- [ ] Business rules from the issue are asserted in tests
- [ ] Test failures are actionable (clear messages, no flaky waits)

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Documented rule has no test | bug | Require test for the rule |
| Rule was never captured in the issue | incomplete-spec | Discovery refinement, not a test fix |
| Test passes locally but is flaky in CI | edge case | Stabilize with proper waits/seed |
| Test asserts implementation detail, breaks on refactor | bug | Rewrite as behavior assertion |

## Related skills

- `skills/development/test-runner`
- `skills/development/bug-triage`
- `skills/development/go/go-testing`
