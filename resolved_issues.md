# Resolved Issues

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 8. Move locale from opencode.json to .opencode/locale file
- Resolved: 2026-05-25
- Type: bug
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: critical
- Summary: `"locale": "pt"` in opencode.json caused ConfigInvalidError. Moved locale to `.opencode/locale` file. Created `standards/locale.md` documentation. Updated `roc:init` to ask for locale and pass it to init script. Added reviewer count question to `roc:review-branch` and `roc:promote` (interactive, not from opencode.json). Updated locale-loader skill description and Makefile bootstrap target.

### 9. Multi-locale standards system
- Resolved: 2026-05-25
- Type: feat
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: medium
- Summary: Created standards/pt/ and standards/es/ with Portuguese and Spanish translations, locale-loader skill for locale resolution, locale file with pt, documented in conventions.md and architecture.md

### 11. Distinguish bugs from missing business rules in reviews
- Resolved: 2026-05-25
- Type: feat
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: high
- Summary: Added `Business rules:` field to issue format (required for feat), type classification guide in issues.md, bug vs incomplete-spec distinction in code-review.md, mandatory discovery rule in workflow.md, and updated all agents to enforce business rule documentation before promotion

### 10. Discovery flow with typed issue creation and QA gate
- Resolved: 2026-05-25
- Type: feat
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: medium
- Summary: Created agents/tech-lead.md, standards/prioritization.md, updated workflow.md pipeline with TL and QA-after-review steps, marked wip/ as obsolete, updated opencode.json

### 7. Align global config with latest OpenCode documentation
- Resolved: 2026-05-25
- Type: chore
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Summary: Fixed instruction paths, added $schema, normalized agent frontmatter, updated locale-loader skill, added senior reviewer locale-awareness via locale-loader, added reviewer count question to roc:review-branch and roc:promote, updated roc:init with locale prompt, cleaned up .gitignore and stale artifacts

### 4. Add tech-lead agent role to pipeline
- Resolved: 2026-05-25
- Type: feat
- Reported by: explore
- Remote: -
- Severity: low
- Summary: Created agents/tech-lead.md agent definition and added it to workflow.md pipeline — provides technical guidance between CTO (strategy) and Developer (implementation)
