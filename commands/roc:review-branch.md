## /roc:review-branch

Full PR/MR-style review.

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root, **not** to the global opencode config.

Responsibilities:
- Analyze `git diff`
- Detect bugs, regressions, missing tests
- Validate:
  - tests exist
  - docs updated (if applicable)
- Sync `$PWD/.opencode/known_issues.md` (project issue tracker)
- Follow the issue entry format from `standards/issues.md`
