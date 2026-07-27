---
name: go-doc-contract
description: Go doc comments, package docs, examples, deprecations, doc links, and caller-facing contracts. Use when writing or refining Go documentation for exported symbols, package comments, examples, or non-obvious caller obligations.
---

# Go Doc Contract

Use this skill when the task is primarily about Go documentation, especially:

- package comments
- command comments
- exported symbol doc comments
- examples in `*_test.go`
- deprecation notices
- doc links
- caller-facing contracts that should be documented
- Godoc formatting and readability

## Authoritative references

Treat these as the primary source of truth:

1. Go Doc Comments
2. Google Go Style Decisions
3. Google Go Best Practices
4. Godoc: documenting Go code
5. Testable Examples in Go
6. Effective Go
7. Go Code Review Comments

Pay special attention to the sections highlighted by the user:

- Packages
- Commands
- Types
- Funcs
- Consts
- Vars
- Syntax
- Deprecations
- Doc links
- Common mistakes and pitfalls
- Commentary
- Doc comments
- Comment sentences
- Examples
- Documentation conventions
- Parameters and configuration
- Contexts
- Concurrency
- Cleanup
- Preview
- Godoc formatting
- Introduction
- Examples are tests
- Output comments
- Example function names
- Larger examples
- Package comments
- Named result parameters

## Core philosophy

Do not comment more.

Document the contracts that the caller must know.

Prefer elegant, idiomatic Go documentation that:

- explains what a package, type, function, method, const, or var means to its user
- captures non-obvious obligations, guarantees, edge cases, and limitations
- stays tightly coupled to the code
- improves pkg.go.dev and editor presentation
- avoids narrating obvious implementation details

The goal is not a comment-heavy codebase. The goal is a codebase whose caller-facing contracts are documented cleanly and precisely.

## What deserves documentation

Prioritize documenting information the caller cannot safely infer from code alone.

High-value documentation includes:

- package purpose and scope
- command behavior and usage shape
- what a type represents
- what a function returns or does
- required cleanup by the caller
- non-obvious context semantics
- concurrency guarantees or restrictions when they are not obvious
- significant error behavior callers may handle
- zero-value meaning when it is useful but not obvious
- special cases and boundary conditions relevant to callers
- deprecations and replacement guidance
- runnable examples when usage benefits from one

Low-value documentation includes:

- repeating what the code already makes obvious
- enumerating every obvious parameter mechanically
- restating default behavior that Go users already assume
- documenting internal algorithm steps in public doc comments

## Package and command docs

Every package should have a package comment.

Package docs should:

- introduce the package
- set expectations for scope and usage
- mention important boundaries or limitations
- give a brief API overview when the package is large enough to need orientation

For commands:

- describe the program's behavior, not package internals
- begin with the command name as the first sentence
- include usage blocks when that materially helps the reader

If a package needs extensive introductory documentation, prefer a dedicated `doc.go`.

## Symbol doc comments

Exported top-level names should have doc comments.

Non-trivial unexported types or functions may also deserve them when behavior is not obvious.

Rules:

- start with the symbol name
- write full sentences
- write for the user of the API, not the implementer of the code
- focus on what the symbol represents, returns, or requires

Examples:

- types: what an instance represents or guarantees
- funcs: what they return, do, or require
- consts/vars: what the value means or how callers should use it

## Contract-first documentation

Document caller-facing obligations and semantics when they are non-obvious.

### Parameters and configuration

Do not mechanically document every parameter.

Document parameters, fields, and options when they are:

- error-prone
- non-obvious
- semantically constrained
- easy to misuse
- relevant to compatibility or safety

### Contexts

Do not restate standard context behavior.

Document context only when behavior is non-obvious, such as:

- cancellation returns something other than `ctx.Err()`
- lifecycle interacts with `Stop`, `Close`, or shutdown behavior
- the API has special expectations about context lifetime or attached values

### Concurrency

Do not document obvious assumptions.

Go users already assume:

- read-only operations are safe unless mutation is hidden
- mutating operations require caller awareness of synchronization

Document concurrency when:

- an operation mutates behind an apparently read-only call
- the API is explicitly safe for concurrent use
- the interface consumer must satisfy concurrency requirements

### Cleanup

Document required cleanup explicitly.

If the caller must:

- call `Close`
- call `Stop`
- drain or close something
- release resources in a specific way

say so clearly, and show the usage pattern when helpful.

### Errors

Document significant caller-relevant error behavior.

Examples:

- a sentinel or error type callers may match
- `io.EOF` or similar special cases
- error type shape such as `*PathError`
- package-wide error conventions worth knowing

## Examples

Use runnable examples when they materially improve understanding of intended usage.

Rules:

- examples belong in `*_test.go`
- examples are tests
- use `// Output:` when the example should execute and be verified
- omit the output comment only when the example should compile but not run
- use proper example naming so Godoc attaches examples to the correct symbol

Prefer examples for:

- public APIs whose usage is easier to show than to explain
- idiomatic call sequences
- subtle behaviors that benefit from concrete demonstration

Use whole-file examples when the example needs supporting declarations and that context helps the reader.

## Deprecations

Use `Deprecated:` paragraphs for deprecated packages or symbols.

Good deprecations:

- say that the symbol is deprecated
- explain why briefly when useful
- point to what should be used instead when applicable

Deprecation text is part of the caller contract and should be explicit.

## Doc links and Godoc syntax

Use Go doc syntax cleanly and intentionally.

Prefer:

- doc links like `[io.Reader]`, `[json.Decoder]`, `[MyType.Method]`
- blank lines between paragraphs
- indented blocks for code, lists, and usage fragments
- minimal decoration beyond what Godoc understands

Avoid:

- ad hoc formatting that renders poorly in Godoc
- nested list tricks that become noisy or fragile
- comments whose indentation accidentally creates malformed code blocks

Be aware of common pitfalls:

- indented wrapped lines can accidentally become code blocks
- unindented multiline command or JSON snippets often render incorrectly
- nested lists are not a strong fit for Go doc comments

## Elegant style rules

Keep documentation elegant by following these constraints:

- comments should be sparse but high-signal
- doc comments should stand on their own
- comment sentences should be capitalized and punctuated
- use line comments by default
- prefer code or naming improvements over explanatory comments when possible
- do not bury the contract under prose volume
- do not turn documentation into a second implementation

If a comment is only compensating for unclear code, first consider rewriting the code.

## Preview and review

Preview documentation output when doc changes are meaningful.

Review whether:

- pkg.go.dev rendering will be clear
- headings, lists, links, and code blocks render correctly
- examples are attached to the intended symbol
- the first sentence reads well in summaries and IDE tooltips

## What not to do

Do not:

- add comments to every function mechanically
- explain what a line of code obviously does
- duplicate implementation details in public docs
- document normal context cancellation semantics unless behavior differs
- add concurrency notes that merely restate the default expectation
- use comments as a substitute for naming or structure
- add examples that do not teach anything meaningful

## Output expectations

When using this skill, produce documentation or review guidance that states:

1. what contract the caller needs to know
2. which symbols need documentation and which do not
3. which obligations, guarantees, special cases, or deprecations should be documented
4. whether an example would materially improve understanding
5. whether the documentation renders cleanly in Godoc/pkg.go.dev

Prefer the smallest amount of documentation that fully communicates the public contract.
