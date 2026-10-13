## Known Issues

Project-level issue tracker.
Use `$HOME/.config/opencode/known_issues.md` for opencode config-level issues.

### 1. test
- Status: backlog
- Type: feat
- Severity: medium
- Priority: medium

- Report: model
- Base branch: -
- Reviewers: 1 (backend)
- Remote: -
- Jira: -
- PR: -
- Location: -
- Description: 
- Impact: 
- Business rules: -
- Acceptance criteria: 
- Tests: -
- Suggested fix: -

### 2. Add platform-aware agent frontmatter review skill
- Status: in-publish
- Opened: 2026-10-12
- Ready: 2026-10-12T21:00
- Started: 2026-10-12T21:00
- In review: 2026-10-12T21:04
- In QA: 2026-10-12T21:04
- In publish: 2026-10-12T21:06
- Type: chore
- Severity: low
- Priority: medium

- Report: william_pereira
- Base branch: main
- Reviewers: 1 (runtime)
- Remote: #205
- Jira: -
- PR: #206
- Location: skills/shared/agent-frontmatter/SKILL.md
- Description: Add an English skill for creating, reviewing, and validating Markdown agents configured with YAML frontmatter across OpenCode, Claude Code, and GitHub Copilot.
- Impact: Users get a reliable workflow to audit existing/new agent profiles, route creation through an available specialist, and validate platform-specific metadata and prompts against current official guidance.
- Business rules: 1. Detect the target platform from user intent, file paths/extensions, and repository configuration; clarify only when genuinely ambiguous. 2. Use the platform-specific current official source of truth and never apply another platform’s field names, paths, defaults, or schema. 3. For agent creation, discover and invoke a suitable existing agent creator when available, then independently validate its output; otherwise create directly. 4. Support review-only, creation, revision, and batch audit; preserve unrelated user work. 5. Report findings with file/line, severity, evidence, recommended fix, actual checks performed, and source links; never claim validation not performed.
- Acceptance criteria: 1. `skills/shared/agent-frontmatter/SKILL.md` exists with valid skill frontmatter and is written in English. 2. The workflow covers OpenCode, Claude Code, and GitHub Copilot’s Markdown/frontmatter conventions with official documentation links and platform-specific differences. 3. The skill directs the agent to discover/use an existing agent creator if one exists, then independently validate the created agent; review-only and batch auditing are also covered. 4. The skill provides practical metadata/body/tool-permission checks and an evidence-based report format without pretending unperformed checks passed. 5. Skill validates successfully with the repository skill validator and issue pipeline checks.
- Committer gate blocker cleared (2026-10-12): preserved the runtime reviewer’s PASS and no-findings report at `.opencode/reviews/runtime-issue-2-20261012.md`; the canonical committer gate passed and the issue transitioned to `in-publish`.
- Tests: -
- Suggested fix: -
