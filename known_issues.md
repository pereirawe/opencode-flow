## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <user-name> | <model-name>
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.

### Status Lifecycle

- `backlog`: item captured but not yet refined or prioritized
- `ready`: item is clear enough to be picked up
- `open`: item selected locally and awaiting remote issue creation
- `in-progress`: remote issue exists and work has started
- `in-review`: senior review done, QA verified, awaiting merge
- `resolved`: completed or closed item (removed from active list)

### 7. Align global config with latest OpenCode documentation
- Status: in-progress
- Type: chore
- Severity: high
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Location: opencode.json, AGENTS.md, README.md
- Description: Review and update all config files to match latest OpenCode docs patterns: fix instruction paths, add $schema, fix agent frontmatter format, update skill SKILL.md descriptions, remove stale references
- Impact: Config will not load correctly if not aligned with schema; agents/skills may not be discoverable
- Suggested fix: Fix instruction paths (critical), normalize agent frontmatter with proper description/mode fields, update skill descriptions with trigger context, clean up .gitignore and stale artifacts

---

Resolved issues move to `resolved_issues.md` (same directory as this file). See `standards/resolved-issue.md` for the archive format.
