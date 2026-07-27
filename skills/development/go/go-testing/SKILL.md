---
name: go-testing
description: Go testing style for table-driven tests, test helpers, useful failures, black-box testing, and realistic integrations. Use when writing or refining *_test.go files, testing handlers, stores, services, or reviewing Go test quality.
---

# Go Testing

Use this skill when creating or refining Go tests, especially `*_test.go` files, table-driven tests, setup helpers, handler tests, integration tests, and transport-level tests.

## Authoritative references

Treat these as the primary source of truth:

1. Go Code Review Comments
2. Google Go Style Decisions
3. Google Go Best Practices
4. Effective Go
5. Package names

## Default stance

Prefer idiomatic Go tests using the standard `testing` package and straightforward control flow.

Keep the failure decision in the `Test` function whenever practical.

Test code is still code. Optimize for readability and maintainability.

## Test structure

Prefer:

- focused test functions with obvious setup
- table-driven tests when many cases share the same logic
- subtests with `t.Run` when case names improve clarity
- black-box tests with `package foo_test` when validating only exported behavior
- same-package tests when unexported internals truly need direct exercise

Do not force table-driven tests when a small explicit test is clearer.

## Validation style

Prefer inlining validation and failure messages inside the `Test` function.

Avoid assertion-helper patterns that hide the failing condition.

If shared validation is needed:

- return a value such as `error` from shared validation logic when practical
- let the `Test` function decide how to fail
- reserve `t.Helper()` helpers for setup, cleanup, and test-environment operations

## Failure messages

Failures should clearly state:

- the input or scenario
- the actual result
- the expected result

Prefer messages in the style of:

```go
t.Errorf("Parse(input) = %v, want %v", got, want)
```

When helpful, include the specific case name or input values.

## `t.Error` vs `t.Fatal`

Use `t.Fatal` when the test cannot continue meaningfully, especially for setup failures.

Use `t.Error` when more checks can still run.

For table-driven tests:

- without subtests, use `t.Error` plus `continue` for case-local failures
- inside `t.Run`, use `t.Fatal` when the current subtest cannot continue

Never call `t.Fatal`, `t.FailNow`, or similar from spawned goroutines.

## Test helpers

Helpers that perform setup or cleanup should:

- call `t.Helper()`
- fail with contextual messages when setup cannot proceed
- keep resource acquisition and cleanup obvious
- use `t.Cleanup()` when it simplifies teardown

Do not pass `testing.T` around to create generic assertion facilities.

## Table-driven tests

When using tables:

- prefer named fields in larger or less obvious test cases
- omit zero-value fields only when clarity is preserved
- keep the table focused on the varying inputs and expectations
- avoid giant tables that hide what is actually being tested

## Integration and transports

When testing integration behavior, prefer real transports and realistic boundaries where feasible.

Examples:

- `httptest` for HTTP handlers and clients
- real transport clients against test servers instead of hand-written fake clients when transport behavior matters
- test doubles behind the server boundary when the dependency itself is what should be isolated

Prefer as much real production path as the test can safely exercise.

## Setup scope

Keep setup as close as possible to the tests that need it.

Avoid:

- package-global mutable fixtures
- order-dependent tests
- unnecessary shared initialization in `init`

Use a shared setup helper only when it genuinely improves clarity or cost.

Use `TestMain` only when:

- all tests in the package require the setup
- the setup is expensive enough to justify it
- teardown is required

## Test package naming

Use `package foo_test` when you want a black-box test of the exported API.

Use `package foo` when:

- unexported helpers or state must be exercised directly
- same-package access materially simplifies the test without weakening the test intent

Do not default to same-package tests without a reason.

## Review red flags

Flag these strongly:

- assertion helpers hiding the real failure site
- `t.Fatal` inside goroutines
- tests coupled through global state
- shared setup in `init` for tests that do not need it
- vague failure messages like `expected true`
- giant tables with unclear intent
- fake transports when real transport behavior is part of the contract

## Output expectations

When using this skill, produce tests or review feedback that states:

1. the test shape chosen
2. why that shape is idiomatic for the case
3. whether setup should be local, shared, or integrated
4. whether the failure messages are actionable
5. the smallest changes needed to improve the test
