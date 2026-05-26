# Locale System

Locale is stored as a **plain text file**, not in `opencode.json`, to avoid
`ConfigInvalidError` (the schema rejects unknown top-level keys).

## File locations

| Scope  | Path                       | Default content |
|--------|----------------------------|-----------------|
| Global | `~/.config/opencode/locale`  | `pt`            |
| Project| `.opencode/locale`           | `en`            |

Project locale overrides global locale.

## Resolution order

1. `.opencode/locale` in the project directory
2. `~/.config/opencode/locale` (global fallback)
3. If neither exists, defaults to `en` (English)

## Supported values

- `pt` — Português
- `es` — Español
- `en` — English

Localized standards are loaded from `standards/{locale}/` (e.g., `standards/pt/`).
When a localized file does not exist, the English version in `standards/` is used.

## Setup for new projects

The `/ocf:init` command asks the user which locale to use and writes it to
`.opencode/locale`. Alternatively, create or edit the file manually:

```bash
echo "pt" > .opencode/locale
```
