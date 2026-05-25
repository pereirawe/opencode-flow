## /roc:init

---
description: Initialize opencode project config with repo context and locale
---

Initialize the `.opencode/` project configuration in the current working directory.

### Flow

1. Ask the user which locale they want: `pt` (Português), `es` (Español), or `en` (English)
2. Run the init script with the chosen locale
3. Review the generated files

!`bash $HOME/.config/opencode/scripts/init.sh "$PWD" "$LOCALE"`

Responsibilities:
- Generate `.opencode/` directory with AGENTS.md, workflow.md, opencode.json
- Inject repository context (default branch, remotes) into templates
- Write chosen locale to `.opencode/locale`
- Create project-level `known_issues.md`

Review the generated files. If the project is not a git repository, the Repository Context section will show `<not a git repo>`.
Verify everything looks correct. The project's `known_issues.md` at `.opencode/known_issues.md` is for project-specific issues;
global config issues go in `~/.config/opencode/known_issues.md`. Locale is stored in `.opencode/locale` — **not** in `opencode.json`.
