## /ocf:sync-issues

---
description: Synchronize known_issues status with remote issue tracker
---

Sync the local `known_issues.md` with remote issues on GitHub/GitLab.

The working directory (`$PWD`) determines the target project.

### Responsibilities

- For each issue with a `Remote: #<id>` reference:
  - Fetch remote issue state (open/closed) via `gh` or `glab`
  - If remote is closed but local is `in-progress`, update local to `resolved` and archive
  - If remote is open but local is `resolved`, reopen in remote
- For issues without a remote reference:
  - Create remote issue if local status is `open`
  - Link with `Remote: #<id>`
- Report sync results (created, updated, conflicts)

### Flow

1. Scan `$PWD/.opencode/known_issues.md`
2. For each issue with `Remote: #<id>`, check remote state
3. For each issue with `Status: open` and no `Remote:`, create remote issue
4. Apply updates
5. Report summary

### Remote detection

- Uses `git remote -v` to detect GitHub or GitLab
- Falls back to `gh` or `glab` CLI availability
