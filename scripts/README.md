# Scripts

Shell helpers for issue lifecycle management.

| Script | Purpose |
|--------|---------|
| `promote.sh` | Move issue from backlog→ready or ready→in-progress + branch |
| `create_issue.sh` | Create remote issue on GitHub/GitLab, populate `Remote:` field |
| `close_issue.sh` | Close remote issue, archive to `resolved_issues.md` |
| `scan_issues.sh` | Static analysis heuristics |
| `pre_commit.sh` | Pre-commit checks (tests + commit trailers) |
| `maintain.sh` | Scan known_issues for stale entries and sync status |
| `update.sh` | Check local version vs remote, apply updates |
| `backup.sh` | Intelligent timestamped backup excluding junk and preventing recursion |
| `init.sh` | Initialize `.opencode/` project config with locale and LSP detection |
| `sync_github_issues.sh` | Sync GitHub issues with local known_issues.md |
| `import_claude_skill.sh` | Import skills from claude-code-templates |
| `config.sh` | Shared configuration sourced by other scripts |

Scripts operate on `known_issues.md` (global or project-level).
When an issue is closed, it's archived to `resolved_issues.md` in compact format.
