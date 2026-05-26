## /ocf:promote <id>

---
description: Promote a backlog item to open for execution
---

Promote a tracked backlog item inside `known_issues.md` and create a remote issue.

The project issue tracker is at `$PWD/.opencode/known_issues.md`.
Shell scripts live at `$HOME/.config/opencode/scripts/`.

### Flow

1. **Ask the user** how many Senior Reviewers should review after development (default: 1)
   — do **not** read from `opencode.json` to avoid config breakage
2. Promote tracked item: change `Status` from `backlog` or `ready` to `open`
3. Reset `Remote` to `-` (will be set by remote creation)
4. Create remote issue via `$HOME/.config/opencode/scripts/create_issue.sh <id>`
   - Detects GitHub (`gh`) or GitLab (`glab`) from `git remote`
   - Creates remote issue with title + body from `known_issues.md`
   - Updates `Remote: #<id>` and `Status: in-progress` in `known_issues.md`
   - Creates and checks out branch `issue-<remote-id>-<slug>`
5. Note the reviewer count for branch review phase (used later by `/ocf:review-branch`)
6. Development starts on the generated branch

### Usage

```
/ocf:promote 2
```

### Status rules

| Status | Description |
|--------|-------------|
| `backlog` / `ready` | Planning states — can be promoted |
| `open` | Pre-remote execution state — remote creation triggered |
| `in-progress` | Remote issue exists, work has started |
| `resolved` | Terminal state — issue moved to archive |
