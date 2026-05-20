## /roc:promote <id>

Promote a tracked backlog item inside `known_issues.md`.

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root, **not** to the global opencode config.

Responsibilities:
- Change `Status` from `backlog` or `ready` to `open`
- Reset `Remote` to `-` until the remote issue is created
- Prepare for remote issue creation

Usage:
```
/promote 2
```

Flow:
1. Promote tracked item inside `$PWD/.config/opencode/known_issues.md`
2. Create remote issue:
   `$PWD/.config/opencode/scripts/create_issue.sh 2`
3. Start development on generated branch

Status rules:
- `backlog` and `ready` are planning states
- `open` is the pre-remote execution state
- `in-progress` requires a remote issue id
- `resolved` is the terminal state unless manually reopened
