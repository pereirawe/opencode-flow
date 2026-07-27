---
name: issue-manager
description: Maintain the tracked work register with code-backed evidence and remote sync
compatibility: opencode
---
## What I do

- Maintain `.config/opencode/known_issues.md` as the tracked issue register
- Prefer updating existing entries over creating duplicates
- Keep issue descriptions concise, actionable, and backed by code evidence
- Synchronize local issues with remote trackers (GitHub/GitLab)
- Archive resolved issues to `resolved_issues.md`

## What to look for

- Security: input handling, external calls, randomness, secrets
- Concurrency: shared state, race windows, goroutine/thread safety
- Reliability: timeouts, retries, resource cleanup, config drift
- Architecture: mixed concerns, dead code, workflow drift
- Remote drift: local status vs remote issue state mismatch

## Rules

- Do not speculate without code evidence
- Prefer file and line references when possible
- Remove or mark resolved issues when the code already fixes them
- Keep fields normalized:
  - `Status`: `backlog`, `ready`, `open`, `in-progress`, `in-review`, `in-qa`, `in-publish`, `resolved`
  - `Type`: `bug`, `feat`, `doc`, `chore`
  - `Severity`: `critical`, `high`, `medium`, `low`
  - `Reported by`: user name for human-reported items, model name for AI-reported items
- `Remote:` field is mandatory — use `-` when no remote exists
- When resolving an issue, archive it to `resolved_issues.md` in compact format

## Remote sync

- Use `/ocf:sync-issues` to synchronize local ↔ remote state
- When promoting (`ocf:promote`), create a remote issue via `create_issue.sh`
- When closing (`ocf:close-issue`), close remote issue and archive
- Prefer `gh` for GitHub, `glab` for GitLab — detect via `git remote -v`
