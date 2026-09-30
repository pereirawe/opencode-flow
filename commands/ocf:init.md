## /ocf:init

---
description: Initialize opencode project config with repo context, locale, and LSP detection
---

Initialize the `.opencode/` project configuration in the current working directory.

### Flow

1. Ask the user which locale they want: `pt` (Português), `es` (Español), or `en` (English)
2. Run the init script with the chosen locale
3. The script detects project programming languages by scanning for characteristic files (e.g., `package.json`, `*.py`, `Cargo.toml`)
4. For each detected language, LSP and VS Code extension suggestions are shown from the catalog (`standards/lsp-catalog.json`)
5. The user is prompted to auto-configure VS Code with the detected LSP settings
6. If approved, settings are merged into `.vscode/settings.json` (preserving existing settings)
7. Review the generated files

!`bash $HOME/.config/opencode/scripts/init.sh "$PWD" "$LOCALE"`

Responsibilities:
- Generate `.opencode/` directory with AGENTS.md, workflow.md, opencode.json
- Inject repository context (default branch, remotes) into templates
- Write chosen locale to `.opencode/locale`
- Create project-level `known_issues.md`
- Detect project languages and suggest VS Code LSP configuration (interactive)
- Merge LSP settings into `.vscode/settings.json` when approved

Explicit copy criteria (no blind `cp -r`):
- Whitelist (the ONLY files/dirs init copies into the target `.opencode/`):
  `AGENTS.md`, `workflow.md`, `opencode.json`, `locale`, `known_issues.md`
  (created from a skeleton when absent, never overwritten), `env-manifest.md`,
  `.gitignore` — each copied file-by-file from the global template.
- NEVER copied: real secrets (`*.env` with values — only `*.env.example`
  models would be allowed, and the whitelist contains none, so effectively no
  `.env` at all), `node_modules/`, `preflight/`, `reviews/`, `skills/`,
  `agents/`, `commands/`, `adorable-proposal/`, `package.json` /
  `package-lock.json`, `README.md`, `resolved_issues.md`, and the full
  `standards/` tree (the LSP flow reads `lsp-catalog.json` from the global
  config at runtime; nothing in the generated project needs a local copy).
- Safety net: after copying, init sweeps stale template-pollution artifacts
  from previous blind-copy runs (`node_modules/`, `preflight/`, `reviews/`,
  `adorable-proposal/`, `standards/`, `package.json`, `package-lock.json`,
  `README.md`, `resolved_issues.md`). `skills/`, `agents/`, `commands/` and
  project-owned `*.env` files are preserved — they are legitimate project
  extension points / user data, init just never copies them in.
- Idempotent: re-running init re-applies the whitelist + locale +
  branch/remotes substitution cleanly; the project `known_issues.md` and any
  project-owned `*.env` are never overwritten or deleted.

Review the generated files. If the project is not a git repository, the Repository Context section will show `<not a git repo>`.
Verify everything looks correct. The project's `known_issues.md` at `.opencode/known_issues.md` is for project-specific issues;
global config issues go in `~/.config/opencode/known_issues.md`. Locale is stored in `.opencode/locale` — **not** in `opencode.json`.
