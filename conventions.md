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

## Skill Management

- External skills are kept as git clones in `~/.config/opencode/vendor/` and
  loaded in-place via `skills.paths` in `opencode.json` — never copied into `skills/`.
- Import/update/remove via `scripts/skill-vendor.sh` (add/update/list/remove);
  updates are plain `git pull` (no re-import).
- Repos with multiple skills use sparse checkout (`--sparse <paths...>`) so only
  the desired skills load.
- Skill identity is the frontmatter `name` of each `SKILL.md`, not the folder name.
- `vendor/**` is gitignored — third-party content is never versioned in this repo.
- Skills curated natively for this config live in `skills/<sector>/`.
- See `decisions.md` (ADR 2026-08-05) for rationale.
