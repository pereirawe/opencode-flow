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

- ADR 2026-08-21: Per-project git credential cache — plaintext 0600 = git's
  standard store model; no encryption at rest (declared limit, issue #209).
  Credentials and commit identity live in `<project>/.opencode/cache/git/`
  (`credentials` in git credential-store format, `identity` as `name=`/`email=`),
  gitignored via `.opencode/.gitignore` (`cache/`), with the cache directory
  `0700` and files `0600` applied on every write regardless of umask. Access is
  ONLY through `scripts/git-cred-cache.sh` (single entrypoint with `--init` /
  `--set` / `--get` / `--erase` / `--identity` / `--status`); opencode.json
  denies read/edit of `.opencode/cache/**` (findLast rule) so agents under
  `--auto` cannot touch the files directly. Secrets are redacted centrally via
  `redact_secret()` in `scripts/config.sh` and are excluded from test-runner
  fingerprints (`EXCLUDE_RE`). Rationale: plaintext-at-0600 matches git's own
  `credential.helper store` model and keeps the cache host-side only (no
  container sync — see issue #74 coordination). Declared limit: no encryption
  at rest; protection relies on filesystem permissions (0700/0600), the
  gitignore, the read/edit-deny, and fail-silent behavior — secrets are never
  echoed, logged, or fingerprinted. Tracked as issue #209.
