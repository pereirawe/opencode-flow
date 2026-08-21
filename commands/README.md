# Slash Commands

These commands are available in the assistant.

| Command | Purpose |
|---------|---------|
| `ocf:init` | Initialize `.opencode/` project config with repo context |
| `ocf:scan-issues` | Deep codebase analysis; detect and register new issues |
| `ocf:review-branch` | Full PR/MR-style code review |
| `ocf:plan-feature` | Feature breakdown with risk assessment |
| `ocf:promote <id>` | Promote backlog item to open + create remote issue |
| `ocf:develop [id...]` | Run the full task lifecycle up to MR creation for one or more issues (promote → develop → review → QA → MR → wait for manual merge) |
| `ocf:develop-full [id...]` | Run the full task lifecycle end-to-end for one or more issues (promote → develop → review → QA → MR → auto-merge → archive) |
| `ocf:commit` | Create structured commit with `Status:` trailers |
| `ocf:sync-issues` | Sync known_issues with remote issue tracker |
| `ocf:archive-issue <id>` | Archive resolved issue to compact format |
| `ocf:check-pr [id]` | Check PR merge status and auto-archive merged |
| `ocf:maintain` | Full maintenance of known_issues.md |
| `ocf:backup` | Create intelligent timestamped backup excluding junk |
| `ocf:build-ui` | Orchestrate the 4-pass greenfield design pipeline (art-director → ui-architect → ui-implementer → ui-critic) with deterministic output files |
| `ocf:audit-ui` | Orchestrate the audit/refactor pipeline for existing codebases (ui-auditor → ui-refactor-planner, optionally → build pipeline) |
| `ocf:bump-version` | Calculate version bump, update changelog, commit, tag, and publish to main |

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
