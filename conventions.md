## Conventions

- Keep handlers thin
- Business logic belongs in services
- Always pass context with timeout to external calls
- Prefer explicit error handling
- Use structured logging
- Validate all inputs strictly

## Locale System

- Standards documents are available in multiple languages via `standards/{locale}/`
- The active locale is defined in `~/.config/opencode/locale` (single line, e.g., `pt`)
- Supported: `en` (English, default), `pt` (Português), `es` (Español)
- The `locale-loader` skill resolves the correct locale and loads the appropriate files
- Resolution order: project `.opencode/locale` → global `~/.config/opencode/locale` → `en` fallback
- New standards should always include `pt` and `es` translations
