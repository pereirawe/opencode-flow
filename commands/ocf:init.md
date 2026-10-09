## /ocf:init

---
description: Initialize opencode project config with repo context, locale, and LSP detection
---

Initialize the `.opencode/` project configuration in the current working directory.
Safe to re-run: project-owned files are never overwritten or deleted.

### Flow

1. Ask the user which locale they want: `pt` (Português), `es` (Español), or `en` (English). If they don't answer, omit it — the script resolves the locale (project `.opencode/locale` → global `~/.config/opencode/locale` → `en`).
2. Run the init script non-interactively with the chosen locale:
   `bash $HOME/.config/opencode/scripts/init.sh "$PWD" "$LOCALE"`
3. The script copies the whitelist templates only when absent, injects repo context (default branch, remotes), creates a project `known_issues.md` skeleton when absent, and preserves every project-owned file.
4. It detects project languages by scanning characteristic files (e.g. `package.json`, `*.py`, `Cargo.toml`) and prints LSP / VS Code extension suggestions from the catalog (`standards/lsp-catalog.json`).
5. VS Code configuration is opt-in: set `INIT_CONFIGURE_LSP=1` (or pass `--lsp`) to merge the detected LSP settings into `.vscode/settings.json` (existing settings preserved). Without it, the script only prints suggestions.
6. Review the generated files.

### Flags & env

- `init.sh [target] [locale]` — target defaults to CWD; locale is resolved when omitted.
- `--force` — overwrite project-owned templates (`AGENTS.md`, `workflow.md`, `opencode.json`, `env-manifest.md`, `.gitignore`, `locale`). Without it, existing files are kept.
- `--dry-run` — print what would happen and write nothing.
- `INIT_CONFIGURE_LSP=1` (or `--lsp`) — apply VS Code LSP settings; `--no-lsp` forces skip.
- `--locale <l>` / `--locale=<l>` — explicit locale.

Responsibilities:
- Generate `.opencode/` with AGENTS.md, workflow.md, opencode.json
- Inject repository context (default branch, remotes) into templates
- Write the resolved locale to `.opencode/locale` (only when absent, unless `--force`)
- Create project-level `known_issues.md` only when absent
- Detect languages and suggest (or, opt-in, apply) VS Code LSP configuration

Explicit copy criteria (no blind `cp -r`):
- Whitelist (the ONLY files init copies, each file-by-file, and only when absent):
  `AGENTS.md`, `workflow.md`, `opencode.json`, `env-manifest.md`, `.gitignore`,
  `locale`, `known_issues.md` (skeleton when absent).
- NEVER copied: real secrets (`*.env`), `node_modules/`, `preflight/`, `reviews/`,
  `skills/`, `agents/`, `commands/`, `adorable-proposal/`, `package.json` /
  `package-lock.json`, `README.md`, `resolved_issues.md`, and the full
  `standards/` tree (the LSP flow reads `lsp-catalog.json` from the global
  config at runtime; nothing in the generated project needs a local copy).
- Project-owned (never overwritten or deleted): `.opencode/known_issues.md`,
  `.opencode/resolved_issues.md`, `.opencode/standards/`, `.opencode/README.md`,
  `.opencode/*.env`, and the whitelist templates above once they exist.
- Safety-net sweep: removes only stale blind-copy artifacts —
  `node_modules/`, `preflight/`, `reviews/`, `adorable-proposal/`,
  `package.json`, `package-lock.json`. It NEVER removes `standards/`,
  `README.md` or `resolved_issues.md`.
- Atomic: all required templates are validated before any write; a missing
  required template aborts without leaving a half-initialized project.
- Portability: works on GNU and BSD/macOS (portable in-place sed, `mktemp`,
  `LC_ALL=C`).
- Idempotent: re-running init preserves project files and the `locale` (unless
  `--force`), re-applies the whitelist and branch/remotes substitution cleanly.

If the project is not a git repository, the Repository Context section shows `<not a git repo>`.
The project's `known_issues.md` at `.opencode/known_issues.md` is for project-specific issues;
global config issues go in `~/.config/opencode/known_issues.md`. Locale is stored in `.opencode/locale` — **not** in `opencode.json`.
