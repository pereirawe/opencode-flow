## Technical Decisions

- Mandatory full pipeline for all implementations (2026-06-01): Every implementation
  request, direct or planned, MUST go through issue tracking → promotion (branch) →
  development → senior review → QA → committer gates → commit → MR. Rationale:
  consistency, traceability, and quality. Enforced via `AGENTS.md` instructions
  and `workflow.md` pipeline.

- Folder-based agent/command/skill separation for scalability
- `known_issues.md` as single source of truth for tracked work
- Shell scripts for issue lifecycle (avoid language lock-in)
- Generic conventions (no language/framework assumptions)
- Prefer explicit configuration over implicit behavior

- ADR 2026-08-05: External skills via vendor clone + `skills.paths`, no copy.
  External/third-party skills are kept as git clones in
  `~/.config/opencode/vendor/` (one clone per upstream repo, gitignored) and
  loaded in-place via `"skills": { "paths": [...] }` in `opencode.json`. They
  are NEVER copied into `skills/`. Updates are plain `git pull` via
  `scripts/skill-vendor.sh update` — never a re-import. Repos with multiple
  skills use sparse checkout so only the desired skills load. Skill identity
  is the frontmatter `name` of each `SKILL.md`, not the folder name. Rationale:
  copy-based installs (npx skills add / import_claude_skill.sh) diverge from
  upstream and require manual re-import to update; in-place clones eliminate
  divergence and maintenance. Enforced via AGENTS.md (loaded every session),
  conventions.md, the `skill-importer` skill, the `ocf:import-skill` command,
  and `scripts/skill-vendor.sh`. Native/curated skills continue to live in
  `skills/<sector>/`. Tracked as issue #43.
