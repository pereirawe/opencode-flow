---
name: python-docstrings
description: Python module, class, function, and method docstrings. Use when writing or refining public Python documentation using PEP 257, PEP 8 docstring guidance, and the Google Python Style Guide.
---

# Python Docstrings

Use this skill when Python work is mainly about docstrings and caller-facing
documentation.

## Sources of truth

1. PEP 257
2. PEP 8 docstring guidance
3. Google Python Style Guide

## Checkpoints

- Public modules, classes, functions, and methods are documented when the
  project documents public APIs.
- Docstrings use triple double quotes.
- One-line docstrings are a single summary line ending with punctuation.
- Multi-line docstrings have a summary line, a blank line, and then details.
- Public function docstrings describe behavior, arguments, return values, side
  effects, raised exceptions, and restrictions when relevant.
- Class docstrings explain behavior and notable public surface area.
- Script/module docstrings can serve as usage guidance when appropriate.
- Docstrings do not repeat signatures mechanically.

## Guidance

- Prefer command-style summaries such as `Return ...`.
- Keep the summary line tight enough for indexing tools and readers.
- Document contracts and caveats the caller must know, not obvious mechanics.
