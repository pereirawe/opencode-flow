## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <user-name> | <model-name>
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Suggested fix: <approach or next step>
```

### Status Lifecycle

- `backlog`: item captured but not yet refined or prioritized
- `ready`: item is clear enough to be picked up
- `open`: item selected locally and awaiting remote issue creation
- `in-progress`: remote issue exists and work has started
- `resolved`: completed or closed item (removed from active list)

### 4. Add tech-lead agent role to pipeline
- Status: backlog
- Type: feat
- Severity: low
- Reported by: explore
- Remote: -
- Location: workflow.md:5-14, agents/
- Description: wip/list.md step 5 describes a Tech Lead role providing technical guidance, but no agents/tech-lead.md exists and workflow.md pipeline steps skip this role
- Impact: Missing architectural guidance layer between CTO (strategy) and Developer (implementation)
- Suggested fix: Either create agents/tech-lead.md agent definition and add it to workflow.md pipeline, or update wip/list.md to remove the Tech Lead references

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

### 9. Multi-locale standards system
- Status: in-progress
- Type: feat
- Severity: medium
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Location: standards/pt/, standards/es/, skills/locale-loader/, conventions.md, architecture.md
- Description: Create locale-based standards system with Portuguese and Spanish translations of all review documents, plus a locale-loader skill that resolves the correct language based on locale setting in locale file
- Impact: Enables per-project language configuration for review documents, making the config accessible to Portuguese and Spanish speakers
- Suggested fix: Create standards/pt/ and standards/es/ with translations, locale-loader skill, add locale to config, document in conventions.md and architecture.md

---

Resolved issues move to `resolved_issues.md` (same directory as this file). See `standards/resolved-issue.md` for the archive format.
