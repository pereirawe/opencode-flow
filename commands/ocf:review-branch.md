## /ocf:review-branch

---
description: Full PR/MR-style code review
---

Full PR/MR-style review of the current branch.

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root, **not** to the global opencode config.

### Output naming convention

Review output is written to a branch-specific file, not a generic tracker:

```
<project>/.opencode/<model>_<branch>_issues.md
```

- `<model>` — AI model name that generated the review (e.g. `claude-4`, `deepseek-v4`)
- `<branch>` — current git branch name (e.g. `feat-add-auth`)
- This keeps each review isolated, traceable by model, and branch-scoped

Example: `.opencode/claude-4_feat-add-auth_issues.md`

### Flow

1. **Load locale-loader skill first** to get locale-appropriate standards
   (code-review.md, issues.md) — respect `.opencode/locale` in the project
2. **Read `- Reviewers:`** from the issue entry in `known_issues.md` — do
   **not** read from `opencode.json` to avoid config breakage. If the field
   is empty or missing, ask the user (default: 1)
3. Pass the resolved locale context to all Senior Reviewer agents
4. Analyze `git diff` and run the review with that many reviewers
5. Write review output to the branch-specific file

### Responsibilities

- Ask user for reviewer count (default 1) — never read from `opencode.json`
- Analyze `git diff`
- Use the specified number of Senior Engineer reviewers
- Only review code changes, not docs or other files (unless docs are updated in the same commit)
- Only review code changes that are part of the current branch (not changes from other branches)
- Identify only Critical and Major issues (not Minor or Trivial)
- Validate: tests exist, docs updated (if applicable)
- Sync issues to `<project>/.opencode/<model>_<branch>_issues.md`
- Follow the issue entry format from `standards/issues.md`
- Do not resolve issues, only create new ones
- Do not delete or modify existing issues in the issue tracker
- Do not create duplicate issues for the same code change
- If a remote PR/MR exists for this branch, post review comments via `gh` or `glab`
- Create a 'Recommended priority' section with a clear recommendation (Critical or Major) based on severity and potential impact
