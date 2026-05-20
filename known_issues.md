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
- `resolved`: completed or closed item

### 1. Reconstruct OpenCode configuration structure
- Status: in-progress
- Type: chore
- Severity: medium
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Location: .config/opencode/
- Description: Reorganize project config into generic structure with separated agents/, commands/, skills/, standards/ directories as defined in wip/list.md and Plan.png
- Impact: Enables scalability and reuse across different projects and languages
- Suggested fix: Complete remaining cleanup: (a) remove node_modules/, (b) remove package.json/package-lock.json, (c) remove stale wip/list.md and wip/Plan.png, (d) remove self-referencing .gitignore entries for bun.lock and .gitignore itself, (e) ensure no project-specific references remain

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

### 8. Create project bootstrap template
- Status: in-progress
- Type: feat
- Severity: high
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Location: .opencode/ (new), scripts/, README.md
- Description: Create reusable `.opencode/` project template structure that can be copied into any project. Include project-level AGENTS.md, workflow.md, opencode.json, and subdirectories for agents/commands/skills overrides
- Impact: Enables quick bootstrapping of new projects with the full OpenCode agent pipeline
- Suggested fix: Create `.opencode/` directory with template files, add bootstrap script/Make target, document in README.md
