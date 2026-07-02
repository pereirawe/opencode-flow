---
name: go-style-review
description: Go idiomatic review for naming, interfaces, errors, comments, context, receivers, formatting, and implementation-level clarity. Use when reviewing Go code quality, refining Go implementation details, or checking whether code feels idiomatic.
---

# Go Style Review

Use this skill when the task is a Go idiomaticity review or when Go code needs refinement in naming, errors, interfaces, comments, context, receivers, formatting, or implementation-level clarity.

## Authoritative references

Treat these as the primary source of truth:

1. Google Go Style Guide
2. Google Go Style Decisions
3. Google Go Best Practices
4. Go Code Review Comments
5. Effective Go
6. Package names
7. Go Proverbs

## Review mindset

Prioritize:

1. clarity
2. simplicity
3. concision
4. maintainability
5. consistency

Prefer code that is easy to read from top to bottom.

Clear is better than clever.

## Naming checklist

Review whether:

- package names are lowercase, concise, and informative
- exported names avoid repetition with the package name
- getters avoid `Get` unless the domain truly uses that word
- initialisms use Go casing such as `ID`, `URL`, `HTTP`, `API`, `DB`
- receiver names are short, type-derived, and consistent
- local variable names are proportional to scope
- names avoid redundant type words and surrounding context
- package names avoid `util`, `helper`, `common`, `model`, `types`, `api`, `interfaces`

## Formatting and imports checklist

Review whether:

- files are `gofmt`-formatted
- imports are grouped conventionally
- imports are renamed only when needed for collision or clarity
- dot imports are avoided outside the narrow test-only exception
- blank imports are used only where side effects are truly intended

## Interface checklist

Review whether:

- an interface exists because of a real use case, not habit
- the interface lives with the consumer when appropriate
- the interface is small and behavior-focused
- concrete types are returned by default unless an interface is justified
- interfaces were not added only for mocking
- the abstraction got stronger rather than weaker

Remember: the bigger the interface, the weaker the abstraction.

## Error handling checklist

Review whether:

- fallible APIs return `error` as the last result
- error flow is flat and early-return based
- errors are handled, not ignored
- error strings are lowercase and unpunctuated
- added context is useful and non-redundant
- `%w` is used only when callers should inspect the underlying error
- code uses `errors.Is` or `errors.As` instead of string matching
- `panic` is avoided for normal error handling

## Context checklist

Review whether:

- `context.Context` is the first parameter when needed
- contexts are passed explicitly rather than hidden in structs
- cancellation and deadlines flow through I/O boundaries
- context-specific behavior is documented only when non-obvious
- application data is not being smuggled through context without reason

## Type and receiver checklist

Review whether:

- the zero value is useful where possible
- `new` and composite literals are used idiomatically
- pointer receivers are used when mutation, large values, or non-copyable fields require them
- receiver type choice is consistent across the type
- values are passed instead of pointers when a pointer adds no semantic or performance benefit

## Comments and documentation checklist

Review whether:

- exported top-level names have doc comments
- doc comments start with the symbol name and are full sentences
- package comments live directly above the package clause
- comments explain why, contracts, cleanup, or non-obvious behavior
- comments do not restate obvious code
- concurrency or cleanup obligations are documented when non-obvious

## Review red flags

Flag these strongly:

- Java or TypeScript naming imported into Go
- `GetX`, `Util`, `Helper`, `Manager`, or other vague names
- interface-per-struct patterns with no second implementation
- `panic` for ordinary control flow
- string matching on errors
- contexts stored on structs
- hidden global dependencies
- broad, generic abstractions that obscure simple behavior
- comments that explain what the code already says

## Output expectations

When using this skill, report findings in terms of:

1. naming issues
2. interface design issues
3. error handling issues
4. context or dependency-flow issues
5. documentation or comment issues
6. the smallest safe refinement

Prefer small, concrete fixes over broad rewrites.
