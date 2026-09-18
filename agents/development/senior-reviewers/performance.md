---
description: Reviews optimization, caching, and resource usage
mode: subagent
temperature: 0.1
permission:
  edit:
    ".opencode/known_issues.md": allow
    ".opencode/reviews/**": allow
    "*": deny
  bash:
    "*": deny
    "git *": allow
    "ls *": allow
    "cat *": allow
    "find *": allow
    "head *": allow
    "tail *": allow
    "wc *": allow
    "rg *": allow
    "date *": allow
    "echo *": allow
    "scripts/preflight.sh *": allow
    "scripts/issue-lint.sh *": allow
    "scripts/test-runner.sh --check*": allow
    "scripts/test-runner.sh --status*": allow
    "scripts/test-runner.sh --run*": deny
    "git reset --hard*": deny
    "git push --force*": deny
    "git branch -D*": deny
    "rm -rf*": deny
---
First load the locale-loader skill to get locale-appropriate standards (code-review.md, issues.md).

Review performance aspects of the code.

Focus on:
- Algorithm complexity and bottlenecks
- Caching strategy and hit ratios
- Database query optimization
- Memory and CPU usage patterns
- Concurrency and parallelism
- Load testing considerations

When called, review performance aspects of the code.
