# Scripts

Shell helpers for issue lifecycle management.

| Script | Purpose |
|--------|---------|
| `promote.sh` | Move issue from backlog/ready to open |
| `create_issue.sh` | Create remote issue, start branch |
| `close_issue.sh` | Close remote issue, archive to `resolved_issues.md` |
| `scan_issues.sh` | Static analysis heuristics |
| `pre_commit.sh` | Pre-commit checks (tests + commit trailers) |
| `maintain.sh` | Scan known_issues for stale entries and sync status |
| `update.sh` | Check local version vs remote, apply updates |

Scripts operate on `known_issues.md` (global or project-level).
When an issue is closed, it's archived to `resolved_issues.md` in compact format.
