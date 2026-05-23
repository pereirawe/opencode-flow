## /roc:review-branch

Full PR/MR-style review.

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root, **not** to the global opencode config.

Responsibilities:
- Analyze `git diff`
- Only review code changes, not docs or other files (unless docs are updated in the same commit)
- Only review code changes that are part of the current branch (not changes from other branches)
- Identify only Critical and Major issues (not Minor or Trivial)
- Validate:
  - tests exist
  - docs updated (if applicable)
- Sync `$PWD/.opencode/<branch>_issues.md` (project issue tracker)
- Follow the issue entry format from `standards/issues.md`
- Do not resolve issues, only create new ones
- Do not delete or modify existing issues in the issue tracker
- Do not create duplicate issues for the same code change
