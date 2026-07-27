---
name: locale-loader
description: Use when you need to access or reference standards documents (code-review, branching, commits, issues, PR template). Loads locale-appropriate versions from standards/{locale}/ based on the locale file in .opencode/locale or ~/.config/opencode/locale.
compatibility: opencode
---
## What I do

- Read the locale from `.opencode/locale` (project) first; fall back to `~/.config/opencode/locale` (global)
- Load standards from `standards/{locale}/` instead of `standards/` when a localized version exists
- Fall back to English (`standards/`) when the locale is not set, not available, or the specific file doesn't exist in the locale directory
- Support `pt` (Português) and `es` (Español) out of the box

## Resolution Order (STRICT)

1. **If** the project has `.opencode/locale` → use that locale, **ignore global**
2. **Else** if `~/.config/opencode/locale` exists → use global locale
3. **Else** → default to English (`standards/`)
4. For a given locale, check `standards/{locale}/<file>` first
5. Fall back to `standards/<file>` (English) if the localized file doesn't exist

## Rules

- **The agent MUST read `.opencode/locale` first when deciding the response language**
- If the project's `.opencode/locale` exists, the agent MUST use it and IGNORE the global config
- Always prefer the localized version when available
- Never modify the English originals in `standards/`
- When creating new standards documents, always provide translations in `standards/pt/` and `standards/es/`
- The `standards/README.md` in each locale documents what's available
