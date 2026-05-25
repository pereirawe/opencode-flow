## /roc:review-branch

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

### Responsibilities

- Analyze `git diff`
- Check `review.reviewers` in `opencode.json` (global or project-level) for
  the number of Senior Engineer reviewers to use (default: 1)
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
