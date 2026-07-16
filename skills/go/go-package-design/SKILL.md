---
name: go-package-design
description: analyze and recommend idiomatic go package boundaries, directory layout, internal/cmd usage, package naming, subpackage extraction, and dependency direction. use when working in go codebases with go.mod, internal/, cmd/, new packages, package splits, import cycles, generic utility packages, or doubts about whether code should stay in one package, move to a child package, or become a sibling package.
---

# Go Package Design

## Authoritative references

Treat these as the primary source of truth, in this order:

1. Organizing a Go module
2. Package names
3. Effective Go
4. Google Go Style Guide
5. Google Go Style Decisions
6. Google Go Best Practices
7. Go Code Review Comments
8. Uber Go Style Guide

Use Go Proverbs only as a secondary heuristic, not as a normative source.

When sources differ, prefer official Go documentation, then Google guidance, then Uber guidance. Distinguish compiler-enforced rules from conventions and style recommendations.

## Core stance

In Go, a directory containing Go source files is a package boundary, not merely a visual grouping.

A nested directory creates a separate package with its own import path. It does not gain privileged access to the parent package and has no special parent-child relationship beyond path organization.

Package design is API design. Optimize for import sites, call sites, visibility, dependency direction, and the concepts exposed to callers.

Remember:

- files organize an implementation
- packages organize concepts, APIs, visibility, and dependencies
- package size may reveal a design problem, but size alone is not a reason to split
- reuse is not required for a package boundary, and hypothetical future reuse is not sufficient justification for one

Prefer:

- one cohesive package split across multiple files
- conceptually distinct packages with small, understandable APIs
- explicit boundaries only when they provide a concrete benefit
- unidirectional dependencies between packages
- `internal/` when compiler-enforced import visibility is useful
- `cmd/` for commands when the repository contains multiple commands or mixes commands and importable packages

Avoid:

- splitting packages to mimic controller/service/repository layers
- creating a package for every role, type, or file
- generic dumping-ground packages such as `util`, `helper`, `common`, `shared`, `lib`, `models`, `types`, `interfaces`, or `api`
- one-type-per-file thinking imported from other ecosystems
- extracting packages only because a directory or file became large
- designing boundaries around speculative future reuse

## Package naming rules

Name packages after the concept or capability they provide, not their architectural role or implementation mechanism.

Package names should be:

- lowercase
- concise
- usually a single word
- usually singular
- free of underscores and mixed caps
- descriptive at the call site
- unlikely to require import aliases at most call sites

Good examples:

- `summary`
- `transcript`
- `auth`
- `metrics`
- `stringset`
- `agentconfig`

Bad examples:

- `agent_config`
- `agentConfig`
- `AgentConfig`
- `supportchatutils`
- `util`
- `common`
- `shared`
- `interfaces`

Remember:

- callers see `package.Symbol`
- exported names should not repeat the package name
- the last import-path element should normally match the package name
- if the package name is not a meaningful prefix for its exported identifiers, the boundary may be wrong

Prefer:

```go
summary.Generate(...)
stringset.New(...)
http.Server{}
```

Avoid:

```go
summary.GenerateSummary(...)
utils.GenerateSummary(...)
http.HTTPServer{}
```

## Layout guidance

Use the current module shape before introducing a new layout.

Common valid layouts include:

### Single package module

```text
project/
  go.mod
  project.go
  project_test.go
  auth.go
  hash.go
```

### Server module

```text
project/
  go.mod
  internal/
    auth/
    metrics/
    agentconfig/
  cmd/
    api-server/
      main.go
```

### Mixed commands and packages

```text
project/
  go.mod
  internal/
    telemetry/
  cmd/
    worker/
      main.go
  agentconfig/
    config.go
    handler.go
```

Treat `internal/` as a visibility boundary enforced by the Go toolchain. Do not describe it as equivalent to unexported identifiers: identifiers can still be exported from an `internal` package, but imports are restricted by directory ancestry.

Treat `cmd/` as a useful convention, not a language requirement.

## Package boundary test

Before creating a package, test whether it forms a real boundary.

Ask:

1. Is there a distinct concept that deserves its own API and import path?
2. Can its purpose be stated precisely as `Package X provides Y`?
3. Can it expose a small, coherent API while keeping implementation details private?
4. Can it stand on its own without importing its parent package or exposing the parent's internals?
5. Will dependencies remain unidirectional and free of import cycles?
6. Can callers use it meaningfully without always importing another tightly coupled package?
7. Does the split isolate a dependency, optional implementation, integration, privacy boundary, ownership boundary, or dependency-direction problem?
8. Do import sites and call sites become clearer after the split?
9. Is the split needed by the current design rather than speculative future reuse?
10. Would separating files inside the existing package solve the problem just as well?

Create the package only when there is a distinct concept, a workable API, healthy dependency direction, and a concrete benefit.

Do not require every answer to be yes. One consumer does not invalidate a good package boundary, and reuse is not mandatory. However, size, file count, or visual organization alone are never sufficient.

## Child package or sibling package

After deciding that a new package is justified, decide where it belongs.

Use a child package when the concept belongs specifically to the parent domain and the full import path adds useful context:

```text
internal/supportchat/
internal/supportchat/summary/
internal/supportchat/transcript/
```

Use a sibling package when the concept is independent, shared across domains, represents infrastructure, or wraps an external system:

```text
internal/supportchat/
internal/digesac/
internal/openai/
internal/postgres/
```

Do not create a child package merely to group files visually.

Reconsider the boundary when:

- the child package imports its parent package
- the parent and child must always be imported together
- extracting the child requires exporting many parent implementation details
- several adapter interfaces exist only to repair an import cycle introduced by the split

## Example: `supportchat`

Keep closely collaborating responsibilities in one package when they collectively provide one capability:

```text
internal/supportchat/
  handler.go
  service.go
  store.go
  closure.go
  summary.go
  activity_note.go
  jobs.go
```

Do not automatically transform this into:

```text
internal/supportchat/handler/
internal/supportchat/service/
internal/supportchat/store/
internal/supportchat/utils/
```

Extract a package such as `internal/supportchat/summary` only when summary generation becomes a distinct capability with:

- its own input and output
- a small API
- isolated prompt, schema, parsing, or provider dependencies
- independent tests
- no dependency on `supportchat` implementation details
- a clear call site such as `summary.Generate(...)`

A reasonable extracted shape may be:

```text
internal/supportchat/
  handler.go
  service.go
  store.go
  closure.go

internal/supportchat/summary/
  generator.go
  prompt.go
  schema.go
  generator_test.go
```

## File organization inside a package

Within one package, prefer grouping implementation responsibilities across files:

```text
internal/supportchat/
  handler.go
  service.go
  store.go
  closure.go
  summary.go
  activity_note.go
  jobs.go
  handler_test.go
  service_test.go
```

Files should be focused enough that maintainers can predict where code lives, but there is no one-type-per-file rule.

Moving code between files in the same package is usually a low-cost refactor because it does not change imports, visibility, or callers.

## Red flags

These usually signal bad package design:

- a generic package that cannot be described beyond containing helpers, shared code, models, interfaces, or types
- a feature split into `controller`, `service`, and `repository` packages with one tightly coupled implementation each
- a new package created only because a file or directory became long
- two packages that must always be imported together to do anything useful
- a child package that imports its parent
- a split that requires exporting implementation details previously kept private
- interfaces introduced only to repair cycles caused by premature package extraction
- exported identifiers repeating the package name
- frequent local import renaming caused by weak package names
- package splits made only for visual symmetry
- boundaries justified mainly by possible future reuse

## Decision questions

Inspect the existing module, imports, call sites, tests, and dependency direction before asking the user.

Ask only when the intended visibility, ownership, or reuse cannot be inferred and the answer would materially change import paths or API commitments.

Ask the user in Brazilian Portuguese.

Good examples:

- "Esse conceito pertence especificamente ao domínio de `supportchat`, ou deve existir como uma capacidade independente do projeto?"
- "Esse package deve ficar protegido por `internal/`, ou existe a intenção real de permitir imports por outros módulos?"
- "A separação precisa isolar uma dependência concreta agora, ou seria apenas uma preparação para possível reutilização futura?"

Prefer questions about design intent and tradeoffs rather than implementation trivia.

## Output expectations

Produce a package design recommendation that states:

1. the current module shape
2. the current package boundary involved
3. the concepts and dependencies currently present
4. whether the code should stay in the package or move
5. whether a new package should be a child or sibling
6. the proposed package and file shape
7. the dependency direction before and after the change
8. one or more representative import-site or call-site examples
9. the naming rationale
10. the tradeoffs and risks

Ground the recommendation in observed code whenever code is available. Separate current evidence from future speculation.

Never present a convention or style preference as a compiler-enforced Go rule.

Prefer the smallest package change that makes the design clearer.
