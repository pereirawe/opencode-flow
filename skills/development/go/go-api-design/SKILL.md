---
name: go-api-design
description: Exported Go APIs, constructors, options, call-site shape, backward compatibility, and public contract decisions. Use when changing exported functions, public types, return surfaces, config patterns, or when an API choice may affect callers.
---

# Go API Design

Use this skill when the task is primarily about Go API surface, especially:

- what should be exported
- what should remain private
- whether a change breaks callers
- whether a new function improves or worsens call sites
- whether returning a concrete type creates an accidental contract
- whether a choice should be a plain argument, config struct, variadic option, or separate method/function

## Authoritative references

Treat these as the primary source of truth:

1. Google Go Style Guide
2. Google Go Best Practices
3. Package names
4. Organizing a Go module
5. Effective Go
6. Uber Go Style Guide

Pay special attention to the highlighted sections provided by the user:

- style principles
- function argument lists
- option structure
- variadic options
- avoid unnecessary interfaces
- interface ownership and visibility
- designing effective interfaces
- package size
- package names
- generality
- constructors and composite literals
- avoid mutable globals
- avoid `init()`
- no goroutines in `init()`
- copy slices and maps at boundaries
- verify interface compliance

## Core stance

Every exported Go symbol is a compatibility promise.

API design must optimize for:

1. clarity at the call site
2. simplicity of use
3. maintainability over time
4. minimal accidental coupling
5. explicit contracts and predictable evolution

Think from the caller's point of view first.

If the call site, package name, constructor, return surface, or option shape reads awkwardly, the API likely needs redesign.

## Export surface

Export only what external callers need.

Prefer keeping these private unless there is a real external need:

- helper functions
- implementation structs
- internal configuration details
- glue interfaces used only inside one package
- background workers and lifecycle machinery
- mutable registries and shared state

Export when one or more of these are true:

- the symbol is part of the intended package contract
- external callers must construct, call, or implement it
- the interface itself is the product or protocol
- callers need to match a documented error type or sentinel
- compile-time interface conformance is part of the supported behavior

Remember:

- returning or accepting an exported symbol makes it part of the API story
- exporting a concrete type may freeze fields, methods, and semantics more than intended
- exporting an interface commits you to its method set and documentation burden

## Private by default

Default to unexported until there is a concrete caller benefit.

Ask:

- will another package use this directly?
- is the exported name needed now, or only hypothetically later?
- does exporting this simplify usage, or merely expose implementation details?
- would keeping this private preserve future refactor freedom?

If the answer is unclear, prefer private.

## Caller compatibility and breakage

Assume exported API changes can break users even when the compiler does not immediately show it.

High-risk changes include:

- renaming or removing exported functions, methods, types, fields, vars, or errors
- changing the type returned by an exported constructor or function
- changing whether a returned value is concrete vs interface
- adding methods to exported interfaces
- removing methods from exported concrete types relied upon by callers
- exposing an embedded public type and later trying to remove or replace it
- changing mutability or ownership expectations at package boundaries
- changing option shapes in ways that worsen existing call sites
- changing struct tags or serialized field names that act as contracts

Before changing public API, check:

- are there obvious internal callers that would break?
- is this package likely imported by other modules?
- is the new surface strictly better for users, or only nicer internally?
- can the change be additive instead of replacing existing behavior?

## Call-site design

Design from the call site backward.

Prefer APIs that read naturally and make important decisions obvious.

Review whether the proposed API:

- reduces repetition
- avoids long confusing signatures
- avoids adjacent same-typed arguments that are easy to swap
- makes required values obvious
- lets defaults be omitted cleanly
- helps the reader predict behavior from naming alone

Bad signals:

- callers need comments to explain argument positions
- names repeat package or type context noisily
- several booleans appear in one signature
- the API only looks clean inside the package, not when imported

## Choosing the API shape

Choose the simplest shape that keeps call sites clear.

### Plain arguments

Prefer plain arguments when:

- the function has a small number of required inputs
- the meaning of each argument is obvious
- the signature is stable and unlikely to grow much
- the call site stays readable without extra ceremony

Avoid plain arguments when:

- many inputs are optional
- multiple arguments have the same type and are easy to swap
- the function has started to accumulate knobs

### Config struct

Prefer a config or option struct when:

- many callers set one or more options
- several options are commonly used together
- field names improve readability at call sites
- per-field documentation matters
- the API needs room to grow without breaking calls

Rules:

- export the struct only if exported callers use it
- keep `context.Context` out of config structs
- keep required and optional values easy to distinguish in docs and naming

### Variadic / functional options

Prefer variadic options when:

- most callers use defaults
- optional knobs are numerous or infrequent
- options need arguments of their own
- you need extensibility without a huge struct literal at simple call sites

Rules:

- use this only when the extra machinery is justified
- option functions should accept values, not presence-only toggles
- the last option should win for conflicting non-cumulative settings
- keep the underlying mutable options state unexported by default

### Separate method or separate function

Prefer a separate method or function when:

- behavior is materially different, not just one more knob
- splitting improves discoverability and naming
- the specialized path deserves a clear name
- one overload-like function would hide important semantics

Examples of good splits:

- `Marshal` vs `MarshalText`
- `New` vs `NewWithX` when the distinction is meaningful and common
- `WriteTo` vs `WriteBinaryTo` when behavior differs in a user-visible way

## Constructors and returned surfaces

Use constructors to make valid values easy to create, not to hide weak design.

Prefer:

- `New` for the primary exported type of the package
- `NewX` when multiple important exported types exist
- zero-value-friendly types where possible
- composite literals and straightforward construction when they keep the API obvious

Be careful when returning concrete types:

- callers may start depending on extra methods, fields, or identity semantics
- a public concrete type can become an accidental long-term contract
- exposing internal mutability may limit future redesign

Be careful when returning interfaces:

- do not return interfaces by rote
- return an interface when the interface is the product, a runtime choice is required, or a limited default surface truly protects the design
- otherwise prefer accept interfaces, return concrete types

Use Effective Go's generality guidance deliberately:

- if a type exists only to implement an interface and has no interesting exported behavior beyond that interface, returning the interface can be appropriate
- otherwise, do not hide concrete types without a clear contract reason

## Interfaces as API contracts

Interfaces are expensive API commitments.

Prefer:

- no interface until a real need exists
- consumer-defined interfaces when only a small behavior slice is needed
- producer-defined interfaces when the interface itself is the protocol or product
- documented, small interfaces with clear expectations

Avoid:

- interface-per-struct
- exported interfaces used only for mocking
- wide interfaces that weaken abstraction
- returning interfaces just because future implementations are imaginable

If interface conformance is part of the supported contract, verify it at compile time.

Examples:

- `var _ http.Handler = (*Handler)(nil)`
- `var _ io.Reader = (*MyReader)(nil)`

## Boundaries and ownership

Be explicit about data ownership at API boundaries.

If a package stores or returns slices or maps, decide whether callers must observe shared state or independent copies.

Prefer copying at boundaries when:

- retaining caller-owned slices or maps would create aliasing surprises
- returning internal slices or maps would expose mutable internal state
- the API would otherwise leak concurrency hazards or hidden coupling

If shared ownership is intentional, it should be obvious and justified.

## Global state and initialization

Public APIs should avoid mutable globals and init-time magic.

Prefer:

- explicit dependency injection
- constructors or factory functions
- deterministic setup called from `main` or explicit lifecycle entrypoints

Avoid:

- mutable package-level registries as the only API surface
- exporting globals that control behavior for all callers
- hidden work in `init()`
- background goroutines launched from `init()`

If a background worker is part of the contract, expose an object that owns its lifetime and provides explicit stop or close semantics.

## Package-level API fit

Package and API shape must reinforce each other.

Review whether:

- exported names read well with the package prefix
- the package is cohesive enough that its exported API belongs together
- callers likely need multiple types from the package together
- the package boundary helps or harms clarity

If the package name forces awkward exported names, the package boundary may be wrong.

## Decision questions

When an API decision is non-obvious, ask the user instead of assuming.

This is mandatory when the task may change public contract shape and the codebase does not already provide a clear precedent.

Ask the user in Brazilian Portuguese.

Ask a short conceptual question when any of these are unclear:

- should this be part of the public contract at all?
- is preserving compatibility more important than simplifying the API now?
- should callers get more power and flexibility, or a smaller safer surface?
- should the common case be optimized for brevity, or should configuration be made more explicit?
- should this boundary favor local implementation freedom, or a stronger caller-facing contract?
- should ownership be isolated to protect internals, or shared to maximize caller control?

Prefer questions that present the tradeoff, not implementation trivia.

Good examples:

- "Isso deve mesmo fazer parte do contrato publico, ou e melhor manter privado para preservar liberdade de evolucao?"
- "Voce quer priorizar compatibilidade com callers atuais, ou simplificar a API mesmo que a transicao fique mais custosa?"
- "Nesse caso, faz mais sentido dar mais poder ao caller, ou manter uma superficie menor e mais segura por padrao?"
- "Voce quer otimizar o caso comum para um call site mais curto, ou prefere deixar a configuracao mais explicita mesmo com mais verbosidade?"

When offering options, prefer a recommended option first and keep the choices conceptual.

## Output expectations

When using this skill, produce an API recommendation that states:

1. what is part of the intended public contract
2. what should remain private
3. whether the proposed change risks breaking callers
4. whether the call site becomes clearer or noisier
5. whether the returned surface should be concrete or interface-based
6. which option shape fits best: args, config struct, variadic options, or separate method/function
7. which assumptions were confirmed from existing project patterns
8. which unresolved contract decisions require asking the user

Prefer the smallest API surface that keeps the call site clear and the package evolvable.
