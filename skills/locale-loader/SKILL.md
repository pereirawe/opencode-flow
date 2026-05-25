---
name: locale-loader
description: Use when you need to access or reference standards documents (code-review, branching, commits, issues, PR template). Loads locale-appropriate versions from standards/{locale}/ based on the locale field in opencode.json.
compatibility: opencode
---
## What I do

- Read the locale from `~/.config/opencode/locale` (global) or `.opencode/locale` (project)
- Load standards from `standards/{locale}/` instead of `standards/` when a localized version exists
- Fall back to English (`standards/`) when the locale is not set, not available, or the specific file doesn't exist in the locale directory
- Support `pt` (Português) and `es` (Español) out of the box

## Resolution Order

1. Check `.opencode/locale` in the project directory
2. If not set, check `~/.config/opencode/locale` (global)
3. If no locale is set, default to English (`standards/`)
4. For a given locale, check `standards/{locale}/<file>` first
5. Fall back to `standards/<file>` (English) if the localized file doesn't exist

## Rules

- Always prefer the localized version when available
- Never modify the English originals in `standards/`
- When creating new standards documents, always provide translations in `standards/pt/` and `standards/es/`
- The `standards/README.md` in each locale documents what's available
