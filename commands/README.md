# Slash Commands

These commands are available in the assistant.

| Command | Purpose |
|---------|---------|
| `ocf:init` | Initialize `.opencode/` project config with repo context |
| `ocf:scan-issues` | Deep codebase analysis; detect and register new issues |
| `ocf:review-branch` | Full PR/MR-style code review |
| `ocf:plan-feature` | Feature breakdown with risk assessment |
| `ocf:promote <id>` | Promote backlog item to open + create remote issue |
| `ocf:develop [id]` | Start or resume development on a promoted issue |
| `ocf:commit` | Create structured commit with `Status:` trailers |
| `ocf:sync-issues` | Sync known_issues with remote issue tracker |
| `ocf:archive-issue <id>` | Archive resolved issue to compact format |
| `ocf:check-pr [id]` | Check PR merge status and auto-archive merged |
| `ocf:maintain` | Full maintenance of known_issues.md |
| `ocf:backup` | Create intelligent timestamped backup excluding junk |

## Command Definition Rule

Every command has two parts that MUST be kept in sync:

1. **`opencode.json` → `command.<name>.template`** — executable instructions
   for the AI (source of truth, what actually runs)
2. **`commands/<name>.md`** — user-facing documentation

### Rules

- `opencode.json` is the **source of truth** — the template defines the
  executed behavior
- `commands/<name>.md` is the **user-facing documentation** that describes
  the flow, usage, and pre-conditions
- **Both MUST be created/updated together** — whenever a template changes in
  `opencode.json`, the corresponding `.md` must be synced
- The `.md` MUST reflect the flow described in the template, including
  conditional decisions, validations, and pre-conditions

### Checklist for new commands

- [ ] Add entry in `opencode.json` → `command.<name>` with `template` and
      `description`
- [ ] Create `commands/<name>.md` documenting flow, usage, and pre-conditions
- [ ] Add to the table in this `README.md`
- [ ] Verify if the command needs a script in `scripts/`
