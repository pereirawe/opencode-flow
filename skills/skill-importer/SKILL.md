---
name: skill-importer
description: Import skills from claude-code-templates (npx) into opencode's skill system. Copies SKILL.md to ~/.config/opencode/skills/ and registers in opencode.json.
compatibility: opencode
---

## What I do

Import a skill from the `claude-code-templates` registry into opencode's local
skill system so it becomes available via the `skill` tool.

## Workflow

1. **Ask the user** which skill path to import (e.g. `business-marketing/seo-optimizer`)
2. **Run** `scripts/import_claude_skill.sh <skill-path>` to:
   - Fetch the SKILL.md from claude-code-templates
   - Copy the entire skill directory (SKILL.md + supporting files) to `~/.config/opencode/skills/<name>/`
   - Register `"<name>": "allow"` in `opencode.json` under `permission.skill`
3. **Report** the installed path and tell the user to start a new session
   for the skill to appear in `available_skills`

## Import script

The helper is at `scripts/import_claude_skill.sh`. Call it directly:

```bash
scripts/import_claude_skill.sh business-marketing/seo-optimizer
```

## Example skills from claude-code-templates

| Category | Path |
|----------|------|
| Business/Marketing | `business-marketing/seo-optimizer` |
| Document Processing | `pdf-processing-pro`, `docx`, `xlsx`, `pptx` |
| Development | `mcp-builder`, `skill-creator`, `webapp-testing` |
| Creative | `algorithmic-art`, `canvas-design` |
| Official Anthropic | See `anthropics/skills` in the registry |

Browse all available skills at https://aitmpl.com

## Rules

- Always use `--yes` flag to skip prompts during install
- Only import skills (not agents, commands, MCPs — use `--skill` flag)
- Preserve the original SKILL.md content — do not modify
- Register in opencode.json so the skill permission is granted
- Clean up temp files after import
