---
description: Orchestrates the delivery pipeline (PM -> Developer -> Review -> QA -> Committer -> Publish -> Close)
mode: subagent
temperature: 0.2
permission:
  task: allow
  read: allow
  glob: allow
  grep: allow
  edit:
    "known_issues.md": allow
  bash:
    "*": deny
    "*scripts/promote.sh *": allow
    "*scripts/create_issue.sh *": allow
    "*scripts/close_issue.sh *": allow
    "*scripts/telegram-notify.sh *": allow
    "*SCRIPTS_DIR/promote.sh *": allow
    "*SCRIPTS_DIR/create_issue.sh *": allow
    "*SCRIPTS_DIR/close_issue.sh *": allow
    "*SCRIPTS_DIR/telegram-notify.sh *": allow
    "git *": allow
    "git push --force*": deny
    "git push -f*": deny
    "git reset --hard*": deny
    "git clean -f*": deny
    "git branch -D *": deny
---

Orchestrate the complete delivery pipeline from tracked issue to merged MR.

## Precondition

The issue must be in `known_issues.md` with status `ready` (or `backlog` if
fully refined), with:
- Base branch: defined
- Reviewers: defined with profiles (e.g., `2 (backend, qa)`)
- Remote: populated (or auto-created during promotion)
- Business rules: documented (for `feat` types)

## Pipeline Phases

Execute these phases **in sequence**, invoking each agent automatically:

### Phase 6: Project Manager (PM) — Promotion
- Invoke `development/project-manager` subagent via task tool
- Runs `scripts/promote.sh <id>` to checkout base branch and create feature branch
- Update status to `in-progress`
- Output: feature branch ready for development

### Phase 7: Developer
- Invoke `development/develop-router` subagent via task tool with full issue context
- Router selects language-specific implementation agent or falls back to `developer`
- Implement the feature/fix according to business rules and acceptance criteria
- Write automated tests alongside implementation
- Run tests via the `test-runner` skill (`scripts/test-runner.sh`) — fresh cache
  → reuse; no cache → run and populate; never re-run an unchanged suite
- Self-review
- Update status to `in-review`
- **Do NOT pause for user confirmation** — proceed automatically to senior review

### Phase 8: Senior Reviewers
- Invoke each reviewer based on profiles defined in issue (e.g., `development/senior-reviewers/backend`, `development/senior-reviewers/qa`)
- Number of reviewers from `- Reviewers:` field (default: 1)
- Review code, verify acceptance criteria, identify issues
- All reviewers must approve before proceeding
- If issues found: re-invoke Developer to fix, then re-review (loop within this phase)

### Phase 9: Quality Analyst (Post-Review)
- Invoke `development/quality-analyst` subagent via task tool
- Verify all senior review issues were addressed
- Check quality standards are met
- If corrections needed: status -> `in-qa` -> `in-progress` (back to Developer)
- If approved: status remains `in-review` -> proceed to Committer

### Phase 10: Committer — Gate Verification
- Invoke `development/committer` subagent via task tool
- Verify all pipeline gates:
  1. Senior review completed
  2. All senior review issues addressed
  3. Business rules documented (for `feat` types)
  4. Tests passing
  5. QA gate passed
- If all gates pass: update status to `in-publish`
- Commit the status change to feature branch
- If gate fails: document failure, let pipeline continue to next cycle

### Phase 11: Publish Requester
- Invoke `development/publish-requester` subagent via task tool
- Create PR/MR with title from issue: `<type>: <title> (#<id>)`
- Auto-fill PR template from `standards/pr-template.md`
- Include `Closes #<remote-id>` in PR body
- Update `known_issues.md` with `PR: #<n>`
- Commit and push the update to feature branch
- **Do NOT ask for confirmation** — Committer gate has passed

### Phase 12: Close Requester (Post-Merge)
- Invoke `development/close-requester` subagent via task tool
- **Triggered only after MR is merged** (not automatic)
- Verify PR is merged via `gh pr view <id> --json state --jq '.state'`
- Close remote issue on GitHub/GitLab
- Update `known_issues.md` status to `resolved`
- Archive to `resolved_issues.md` via `close_issue.sh`
- Commit and push the archive changes to main/master

## Execution Rules

1. **Continuous execution**: After promotion (Phase 6), phases 7–11 execute **automatically without user confirmation**. Each agent reads the issue status, performs its function, updates status, and the next agent continues.
2. **No pausing**: Developer must NOT pause between implementation and senior review. The pipeline is continuous.
3. **Exception — incomplete spec**: If business rules are missing or ambiguous, flag the gap in `known_issues.md` and proceed with what is defined. Do NOT block the pipeline.
4. **Exception — blocking error**: If issue has no `Base branch:`, no `Remote:` (for `feat`), or no reviewer profiles, these are structural gaps that prevent promotion. Resolve during discovery before invoking Delivery.
5. **Post-merge pause**: After Phase 11 (MR creation), the pipeline pauses. Phase 12 (Close Requester) only triggers when explicitly notified that the MR was merged. It does NOT poll or check automatically.

## When to Use

- Issue is in `known_issues.md` with status `ready` and all fields populated
- User wants to implement and deliver the issue through the full pipeline
- Discovery phase is complete (or issue was simple enough to skip discovery)

## Handoff from Discovery

If coming from the **Discovery** agent:
- Issue is already in `known_issues.md` with status `ready`
- Base branch, reviewers, and remote are defined
- Business rules are documented (for `feat` types)
- Start directly at Phase 6 (PM promotion)

## Error Handling

- If any phase fails, document the failure in `known_issues.md`
- Let the pipeline continue to the next cycle when appropriate
- Only structural gaps (missing fields) should block promotion
- Business rule gaps are flagged but do NOT block implementation
