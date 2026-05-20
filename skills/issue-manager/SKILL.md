---
name: issue-manager
description: Maintain the tracked work register with code-backed evidence
compatibility: opencode
---
## What I do

- Maintain `.config/opencode/known_issues.md` as the tracked issue register
- Prefer updating existing entries over creating duplicates
- Keep issue descriptions concise, actionable, and backed by code evidence

## What to look for

- Security: input handling, external calls, randomness, secrets
- Concurrency: shared state, race windows, goroutine/thread safety
- Reliability: timeouts, retries, resource cleanup, config drift
- Architecture: mixed concerns, dead code, workflow drift

## Rules

- Do not speculate without code evidence
- Prefer file and line references when possible
- Remove or mark resolved issues when the code already fixes them
- Keep fields normalized:
  - `Status`: `backlog`, `ready`, `open`, `in-progress`, `resolved`
  - `Type`: `bug`, `feat`, `doc`, `chore`
  - `Severity`: `critical`, `high`, `medium`, `low`
  - `Reported by`: user name for human-reported items, model name for AI-reported items
