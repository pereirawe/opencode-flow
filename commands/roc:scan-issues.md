## /roc:scan-issues

Deep analysis of the codebase.

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root, **not** to the global opencode config.

Responsibilities:
- Detect new issues (security, concurrency, architecture, reliability)
- Create (if absent) and update `$PWD/.config/opencode/known_issues.md`
- Normalize `Status`, `Type`, `Severity`, and `Reported by`
- Avoid duplication

Triggers:
- After major changes
- Before PR/MR
