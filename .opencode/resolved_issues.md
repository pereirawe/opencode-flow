# Resolved Issues

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 1. Resolved issue archive goes to global instead of project `.opencode/`
- Resolved: 2026-06-01
- Type: bug
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #7
- Severity: high
- Summary: Separated RESOLVED_FILE logic from PROJECT_ISSUES_DIR in config.sh — now checks for `.opencode/` directory independently, so resolved issues always go to the project's `.opencode/resolved_issues.md` when a project context exists, regardless of where active issues are tracked.
