---
name: python-style-review
description: Python naming, imports, exceptions, comprehensions, decorators, properties, and readability tradeoffs. Use when reviewing or refining idiomatic Python style, especially around PEP 8, PEP 20, and the Google Python Style Guide.
---

# Python Style Review

Use this skill when Python work is mainly about idiomatic style and language
choices, not type-system design or docstring contracts.

## Sources of truth

1. PEP 20
2. PEP 8
3. Google Python Style Guide

## Review priorities

- readability over cleverness
- explicit behavior over hidden magic
- project consistency over isolated local preference
- simple control flow over dense expressions

## Checkpoints

- Names follow established Python conventions.
- Imports are explicit, grouped clearly, and avoid wildcard imports.
- Comprehensions stay readable; expand to loops when density hurts clarity.
- Mutable default arguments are not used.
- `None` checks use `is` / `is not`.
- `assert` is not used for required runtime validation.
- `try` blocks are narrow and catches are specific.
- Properties are only used when attribute-like access is genuinely appropriate.
- Decorators are justified and do not hide surprising behavior.
- Comments explain non-obvious intent rather than restating code.

## Guidance

- Prefer the simplest code that is easy to explain.
- If a style rule conflicts with surrounding coherent code, prefer local
  consistency unless the existing pattern is clearly harmful.
- Prefer plain loops over nested comprehensions when the loop is easier to
  scan.
- Prefer module-level functions over `@staticmethod` unless an external API
  forces the method shape.
