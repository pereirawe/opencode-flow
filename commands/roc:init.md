## /roc:init

---
description: Initialize opencode project config with repo context
---

Initialize the `.opencode/` project configuration in the current working directory.

The initialization script ran with these results:

!`bash $HOME/.config/opencode/scripts/init.sh`

Responsibilities:
- Generate `.opencode/` directory with AGENTS.md, workflow.md, opencode.json
- Inject repository context (default branch, remotes) into templates
- Create project-level `known_issues.md`

Review the generated files. If the project is not a git repository, the Repository Context section will show `<not a git repo>`.
Verify everything looks correct. The project's `known_issues.md` at `.opencode/known_issues.md` is for project-specific issues;
global config issues go in `~/.config/opencode/known_issues.md`.
