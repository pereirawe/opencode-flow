---
name: go-package-design
description: Go package layout, internal/cmd usage, package naming, and boundary decisions. Use when working in Go codebases with go.mod, internal/, cmd/, new packages, package splits, or doubts about directory and package organization.
---

# Go Package Design

Use this skill when the task is primarily about Go package boundaries, package names, directory layout, `internal/`, `cmd/`, or deciding whether code should stay in one package or move into another.

## Authoritative references

Treat these as the primary source of truth:

1. Organizing a Go module
2. Package names
3. Effective Go
4. Google Go Style Guide
5. Google Go Style Decisions
6. Google Go Best Practices
7. Go Code Review Comments
8. Go Proverbs

## Core stance

In Go, a directory is usually a package boundary, not a visual grouping only.

Package design is API design. Optimize for what import sites and call sites look like.

Prefer:

- one cohesive package split across multiple files
- small, informative package names
- explicit boundaries only when they buy something real
- `internal/` for non-exported supporting packages when the project uses it
- `cmd/` for commands when the repository mixes commands and packages

Avoid:

- splitting packages to mimic controller/service/repository layers
- generic packages like `util`, `helper`, `common`, `model`, `types`, `api`
- creating a new package for every role or file
- one-type-per-file thinking imported from other ecosystems

## Package naming rules

Package names should be:

- lowercase
- concise
- usually a single word
- free of underscores and mixed caps
- descriptive at the call site

Good examples:

- `agentconfig`
- `stringset`
- `auth`
- `metrics`

Bad examples:

- `agent_config`
- `agentConfig`
- `AgentConfig`
- `util`
- `common`
- `interfaces`

Remember:

- callers always see `package.Symbol`
- exported names should not repeat the package name
- if the package name and exported names look awkward together, the package boundary may be wrong

## Layout guidance

Use the current module shape first.

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
    shared/
  cmd/
    worker/
      main.go
  agentconfig/
    config.go
    handler.go
```

## Decision rules

When deciding whether something should become a new package, ask:

1. Is this a distinct concept that deserves its own import path?
2. Will another package reasonably import it as-is?
3. Does `internal/` provide a useful privacy boundary here?
4. Is the current package too large or unfocused?
5. Would splitting reduce coupling rather than just move it?
6. Will the call sites read better after the split?
7. Is this solving a real dependency direction problem?
8. Is the split needed by the current project, not by another ecosystem's habits?

If most answers are no, keep the code in the current package and split by file instead.

## File organization inside a package

Within one package, prefer grouping by responsibility across files, for example:

```text
platform/agentconfig/
  config.go
  prompt.go
  handler.go
  middleware.go
  store.go
  registrar.go
  handler_test.go
```

This is often better than creating extra packages only to separate roles.

Files should be focused enough that maintainers can guess where code lives, but there is no one-type-per-file rule.

## Red flags

These usually signal bad Go package design:

- a package named `util`, `helper`, `common`, `model`, `types`, or `api`
- a feature split into `controller`, `service`, and `repository` packages with one implementation each
- a new package created only because a file got longer
- two packages that always need to be imported together to do anything useful
- exported identifiers repeating the package name
- excessive local import renaming caused by weak package names
- package splits made only to match visual symmetry

## Decision questions

When package design is non-obvious, ask the user instead of assuming.

This is appropriate when there are multiple plausible package boundaries and the choice changes import paths, visibility, reuse expectations, or future refactor freedom.

Ask the user in Brazilian Portuguese.

Ask a short conceptual question when any of these are unclear:

- should this stay in the current package or become a new one?
- should this package live under `internal/` or be importable by other packages?
- is this meant for local project use only or as a reusable boundary?
- should we optimize for current cohesion or future reuse?
- is this split solving a real dependency problem or only organizing visually?

Prefer questions that present the tradeoff rather than implementation trivia.

Good examples:

- "Isso deve ficar no package atual por coesao, ou ir para um package novo para reuse entre modulos?"
- "Esse package deve ficar privado em `internal/`, ou voce espera imports externos depois?"
- "Voce quer preservar a boundary atual e manter o refactor local, ou introduzir um novo import path agora?"

## Output expectations

When using this skill, produce a package design recommendation that states:

1. the current module shape
2. the current package boundary involved
3. whether code should stay in the package or move
4. the proposed package and file shape
5. the naming rationale
6. the tradeoffs and risks

Prefer the smallest package change that makes the design clearer.
