## /roc:promote <id>

---
description: Promote a backlog item to open for execution
---

Promote a tracked backlog item inside `known_issues.md` and create a remote issue.

The project issue tracker is at `$PWD/.opencode/known_issues.md`.
Shell scripts live at `$HOME/.config/opencode/scripts/`.

Responsibilities:
- Change `Status` from `backlog` or `ready` to `open`
- Reset `Remote` to `-` until the remote issue is created
- Prepare for remote issue creation

Usage:
```
/promote 2
```

Flow:
1. Promote tracked item inside `$PWD/.opencode/known_issues.md`
2. Create remote issue:
   `$HOME/.config/opencode/scripts/create_issue.sh 2`
3. Start development on generated branch

Status rules:
- `backlog` and `ready` are planning states
- `open` is the pre-remote execution state
- `in-progress` requires a remote issue id
- `resolved` is the terminal state unless manually reopened
