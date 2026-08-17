---
name: locale-loader
description: Use when you need to access or reference standards documents (code-review, branching, commits, issues, PR template) or when deciding the response/output language for user-facing content. Loads locale-appropriate versions from standards/{locale}/ based on the locale file in .opencode/locale or ~/.config/opencode/locale, and resolves the canonical response-language rule (input language → project locale → global locale → English).
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

## Response-Language Rule (canonical)

Every agent MUST respond and produce user-facing outputs in the language the
user communicates in. Resolution order:

1. **Input language** — the language the user is writing/talking in (the
   session/input language always wins)
2. **Project locale** — `.opencode/locale` in the project directory
3. **Global locale** — `~/.config/opencode/locale` (global fallback)
4. **English** — when neither is applicable

This applies to chat responses, generated reports, Telegram notifications,
and remote issue comments. Exception: the aibot posts its standardized PT-BR
messages (`standards/aibot-messages.md`, issue #39) as a domain contract, and
career-sector tailored resumes follow the job offer's language (cv-tailor
rule).

## Rules

- **The agent MUST read `.opencode/locale` first when deciding the response language**
- If the project's `.opencode/locale` exists, the agent MUST use it and IGNORE the global config
- The user's input language overrides the locale resolution entirely — locale is the fallback, not the override
- Always prefer the localized version when available
- Never modify the English originals in `standards/`
- When creating new standards documents, always provide translations in `standards/pt/` and `standards/es/`
- The `standards/README.md` in each locale documents what's available
