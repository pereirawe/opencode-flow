## Mandatory Telegram Notifications

**Every agent MUST send a Telegram notification in these two situations:**

1. **Task/command completed** — whether success or failure. Notify the result.
2. **User input needed** — when the agent asks a question and the user may be
   away from the terminal.

Use the `telegram-notifier` skill or run the script directly:

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh --title "Título" "Mensagem"
```

Credentials are loaded from `~/.config/opencode/.opencode/telegram.env`.
**Do NOT ask the user if they want a notification — just send it.**
If credentials are missing, the script fails gracefully and work continues.

## OpenCode Configuration

Entrypoints:
- `AGENTS.md`
- `opencode.json`
- `agents/` — subagent definitions
- `commands/` — slash command docs
- `skills/` — reusable skills (load via skill tool)
  - `locale-loader` — loads locale-appropriate standards based on `.opencode/locale`
- `.opencode/locale` — active language setting (`pt`, `es`, `en`) — **not** in `opencode.json`
- `scripts/` — shell helpers
- `standards/` — development patterns
- `architecture.md` — technical vision and structural decisions
- `conventions.md` — development conventions and best practices
- `decisions.md` — architecture decision records
- `workflow.md` — development workflow pipeline

## Tracked Work

Two-tier issue tracking:
- **Global**: `known_issues.md` — opencode config-level issues
- **Project**: `<project>/.opencode/known_issues.md` — project-specific issues

Status lifecycle: `backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved`

## Mandatory Pipeline Rule

**Every implementation request — regardless of how it's asked — MUST follow the
full pipeline defined in `workflow.md`.** No direct implementation without going
through the documented lifecycle: issue tracking → promotion (branch) →
development → senior review → QA → committer gate → commit → MR.

This rule exists to ensure consistency, traceability, and quality across all
changes. It applies to bugs, features, chores, and documentation alike.

For agents: if asked to implement something directly, first verify the issue
exists in `known_issues.md`, promote it, switch to the branch, then implement.

**After promotion, the pipeline runs automatically** (development → senior review →
QA → corrections → committer gate → MR) **without user confirmation.**
Only gaps found during discovery (missing business rules, ambiguous specs)
generate questions — everything else flows continuously.

## Commit Convention

Every commit MUST follow `standards/commits.md`:
- **Atomic**: one logical change per commit
- **Semantic**: `<type>(<scope>): <imperative description>`
- **Tracked**: always include `Issue: #<id>` trailer

Run `/ocf:commit` or `make commit` to create a properly structured commit.

## Skill Management (external skills)

**External (third-party) skills MUST be kept as git clones in
`~/.config/opencode/vendor/` and loaded in-place via `skills.paths` in
`opencode.json` — NEVER copied into `skills/`.**

- Import: `scripts/skill-vendor.sh add <git-url|owner/repo> [--sparse <paths...>]`
  (or `/ocf:import-skill` / `skill: skill-importer`).
- Update: `scripts/skill-vendor.sh update <name>` — plain `git pull`, no re-import.
- List: `scripts/skill-vendor.sh list`; remove: `scripts/skill-vendor.sh remove <name>`.
- Repos with many skills use sparse checkout (`--sparse <paths...>`) so only the
  desired skills load.
- Skill identity is the frontmatter `name` of each `SKILL.md` (not the folder name).
- `vendor/**` is gitignored; third-party content is never versioned in this repo.
- Skills written/curated natively for this config live in `skills/<sector>/`.

See `conventions.md` (Skill Management) and `decisions.md` (ADR 2026-08-05)
for rationale.

## Local Helpers

```
make scan-issues
make review
make promote id=<n>
make close-issue id=<n>
make commit
make bootstrap target=<path>
```

## Project Bootstrap

To use this template in another project:
```
make bootstrap target=/path/to/project
```
Or manually copy `.opencode/` to the target project root.
