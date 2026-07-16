---
name: python-typing
description: Python type hints, annotations, generics, aliases, callables, ClassVar, and typing compatibility. Use when designing or reviewing Python typing using the stdlib typing docs, typing.python.org, PEP 484, and PEP 526.
---

# Python Typing

Use this skill when Python work is primarily about type-hint design, typing
compatibility, or annotation quality.

## Sources of truth

1. `typing` module documentation
2. typing.python.org specification
3. PEP 484
4. PEP 526

## Core stance

- Type hints primarily support static analysis and maintainability.
- Python remains dynamically typed.
- Prefer the current canonical typing documentation and spec over older habits.
- Respect the project's supported Python versions before choosing syntax.

## Checkpoints

- Public APIs use coherent parameter and return annotations when the project is typed.
- Variable and attribute annotations use modern syntax when compatible.
- `Any` is used intentionally, not as a default escape.
- `object` is preferred when unknown values should remain type-safe.
- Optional values are modeled explicitly when `None` is a valid value.
- Type aliases and generics simplify signatures rather than obscuring them.
- `ClassVar` is used only for actual class variables.
- Forward references and import cycles are handled deliberately.
- Stub or `.pyi` work matches the runtime module contract.

## Guidance

- Keep annotations readable.
- Avoid unnecessary generic complexity.
- Avoid adding typing churn to unrelated code.
- If the repo is only lightly typed, improve the touched surface instead of
  trying to annotate everything.
