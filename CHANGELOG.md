# Changelog

## 2.1.0 (2026-09-03)

- **feat(career): hub profile objective** — `hub.json` gains the optional
  top-level `profile_objective` (`job_search` | `connections` |
  `services_sales` | `personal_branding` + `target_role`/`note`), validated by
  `validate.py` (closed enum, no extra keys, fully backward compatible);
  `cv-hub` captures it only when the user declares it and mirrors it in the
  README (issue #222, PR #144)
- **feat(career): offline LinkedIn ↔ hub sync** — `scripts/cv/linkedin-sync.py`
  + `cv-linkedin-sync` skill diff the official Download My Data export
  (headline, positions, skills, education, languages, certifications) against
  `hub.json` into `linkedin-sync.md`/`.json` with add/promote/remove skill
  recommendations; never scrapes; OAuth limitation documented (issue #225,
  PR #146)
- **feat(career): objective-driven `ocf:cv-linkedin` report** — revamped into a
  six-section action report (objetivo confirmado, headline literal, Sobre com
  logros, experiência com bullets, skills, próximos passos) driven by
  `profile_objective`; no `[INFERIDO]` in the shareable file; consumes the
  issue-225 sync diff (issue #223, PR #148)
- **feat(career): `cv-optimize` integrates LinkedIn improvements** —
  `profile-analysis.md` gains the "Melhorias no LinkedIn" section (banner,
  headline, sobre, experiência, skills) integrated with the prioritized action
  plan and calibrated by the profile objective (issue #226, PR #150)
- **feat(career): LinkedIn profile banner** — `/ocf:cv-banner` +
  `cv-linkedin-banner` skill + `scripts/cv/banner-gen.sh` generate a 4:1
  (1584×396) banner via each::sense (eachlabs poster skill /
  `EACHLABS_API_KEY`), honoring the profile-photo safe zone and the mobile
  center-crop, with a text-legibility gate and a deterministic overlay
  fallback; outputs under `~/career/<candidate>/linkedin/banner/` (issue #224,
  PR #152)
- **feat(career): cv-tailor resume filename pattern** — generated resumes use
  the commercial `<First Last> - <Job Title>.pdf` pattern (issue #142)
- **fix(career): restore `summary_i18n` drafting base in the cv-linkedin
  skill** — regression from the issue-223 rewrite; `test_cv.sh` green again
  (issue #227, PR #154)

## 2.0.0 (2026-08-29)

- **refactor(pipeline): flatten delivery — agents only for judgment** — `/ocf:develop` and `/ocf:develop-full` now drive the pipeline directly via scripts; the `delivery` orchestrator and `develop-router` agents are legacy (manual `/ocf:delivery` path only). Engine: `promote.sh` → `preflight.sh` → `detect-lang.sh` → developer → **parallel senior reviewers** → `committer-check.sh` + `issue-lint.sh --strict` → `create-pr.sh` → `merge-and-close.sh`. Cuts the old 6+N agent chain to 1+N.
- **feat(develop): `scripts/detect-lang.sh`** — replaces `develop-router` for language routing (Go/Python/ fallback) from repo markers.
- **feat(develop): `scripts/committer-check.sh`** — mechanical gate verdict (test cache, status, business rules, security report) so the committer agent only applies judgment.
- **feat(develop): `scripts/create-pr.sh`** — replaces `publish-requester`; builds the MR body from issue fields and records `- PR: #<n>`.
- **feat(develop): `scripts/merge-and-close.sh`** — merges the MR, returns to the updated base branch, and archives via `close_issue.sh` (mechanical close; agent only adds a closing comment).
- **feat(develop): `scripts/preflight.sh`** — warms the issue file inventory so the developer skips re-exploration (used for the current and next issue).
- **feat(discovery): loop profiles by Type + Severity** — `feat-full` (PO + TL, full depth), `bug-expedite` (critical/high, 2 reviewers + security, high quality bar, fast), `bug-lean` (low/medium, 1 reviewer, fast), `chore` (script only). Bugs trade depth for speed but keep a higher quality bar; feats keep full depth.
- **feat(discovery): `scripts/issue-lint.sh`** — replaces the QA pre-development agent pass; enforces schema + `Tests:` severity floor + business rules + reviewer format. `--strict` for the Committer gate.
- **feat(discovery): `scripts/append-issue.sh`** — writes a canonical issue entry (no free-form PO/PM prose), removing format variance. PM/remote creation deferred to promotion.
- **feat(commands): `/ocf:discovery`** — runs discovery (loops) from a proposal or existing issue; `/ocf:plan-feature` is now an alias.
- **feat(tracking): timestamps with time** — `transition.sh`/`promote.sh`/`close_issue.sh` store `YYYY-MM-DDTHH:MM`; lifecycle durations render in hours for sub-day gaps (`Nh`), making reports precise.

## 1.9.0 (2026-08-13)

- **feat(career): resume optimization flow — hub + job-tailored resume** — `ocf:cv-hub` builds a candidate hub (`hub.json` canonical schema + `README.md`) from CV PDF + official LinkedIn export (Download My Data, never scraping) + extras; `ocf:cv-tailor` analyzes a job (multi-portal), gap analysis vs hub, and generates a tailored resume PDF (HTML → PDF via Chrome headless, LibreOffice fallback) in the job's language; `cv-optimize` issue #61 registered (agent pending merge). Backed by `agents/career/*`, `skills/career/*` (cv-hub, cv-tailor, cv-pdf), `scripts/cv/*` (schema.json, validate.py, pdf.sh) and 23 script tests
- **feat(auth): auth-architect skill + reviewer role** — dedicated skill for authentication/authorization architecture (JWT, OAuth 2.0, OIDC, RBAC/ABAC, multi-tenancy, token lifecycle, security hardening); README updated with the new senior reviewer role
- **feat(test-runner): single test entrypoint with fingerprint cache** — `scripts/test-runner.sh` (`--check`/`--run`/`--status`) with environment bootstrap, runner detection, and result cache keyed on git HEAD + changed files; developer, reviewers, QA, committer, and `pre_commit.sh` reuse fresh cache and never re-run unchanged suites
- **feat(nginx): reverse proxy with HTTPS via mkcert** — `setup-web.sh --with-nginx` configures nginx as reverse proxy to the opencode web service with local HTTPS, HTTP→HTTPS redirect, and WebSocket support

## 1.8.0 (2026-08-08)

- **feat(telegram): mandatory telegram notifications for all agents** — every agent now sends Telegram alerts on task completion (success/failure) and when user input is required, with no confirmation prompt; credentials from `.opencode/telegram.env`
- **feat(web): web service reset, stop, and full lifecycle management** — `ocf:reset-web` / `ocf:start-web` / `ocf:stop-web` commands with session DB cleanup; `reset-web.sh` archives old sessions and restarts cleanly
- **feat(skills): vendor clone strategy for external skills** — third-party skills now live in `~/.config/opencode/vendor/` as git clones, loaded via `skills.paths`; `skill-vendor.sh` manages import/update/remove; 7 new design skills imported
- **feat(design): designer agent + taste-skill integration** — `designer` agent creates polished UIs from descriptions following brief → explore → plan → build → review; 3 design-taste skills for landing pages, redesigns, and minimalist UI
- **feat(aibot): remote pipeline trigger via `@aibot:develop` comment** — watcher service detects comments on remote issues and fires full develop pipeline, ending with MR creation and automated aibot response messages
- **fix(web): ocf commands show sudo commands for terminal** — web service commands now display terminal instructions instead of attempting sudo from agent sessions
- **feat(tech-lead): enforce frontend reviewer profile** — tech lead now requires frontend reviewer when issues affect frontend components

## 1.7.1 (2026-08-04)

- **fix: preserve full `resolved_issues.md` archive on close** — replaced `tail -n +4` (which truncated 3 lines of existing content on every close, causing progressive data loss) with a prepend that always rewrites the 4-line header and appends all existing entries via awk, plus atomic `mktemp`/`mv` in the target directory; hardened to keep corrupted entries and clean orphaned temp files

## 1.7.0 (2026-08-03)

- **feat: add discovery and delivery orchestrator agents** — two meta-agents orchestrate the full pipeline phases (PO -> CTO -> Tech Lead -> PO -> QA -> PM for discovery; PM -> Developer -> Review -> QA -> Committer -> Publish -> Close for delivery), with `ocf:discovery` and `ocf:delivery` commands

## 1.6.0 (2026-07-28)

- **feat: add SaaS agent pack** — new agents: SRE, Technical Writer, Product Manager, Customer Success, Growth Engineer
- **feat: add MCP registry** — `standards/mcp-registry.md` with recommended MCP servers for SaaS projects
- **config: enable GitHub and Notion MCPs** — configured in `opencode.json` for this project

## 1.5.1 (2026-07-27)

- **fix: correct agent paths after sector restructuring** — updated `opencode.json` agent reference and `develop-router.md` fallback permissions to use `development/` prefix; fixed self-referential text in develop template

## 1.5.0 (2026-07-27)

- **refactor: restructure agents and skills into sector-based directories** — flat layout now organized under `development/`, `shared/`, `marketing/`, `bi/`, `sales/`, `finance/`, `commercial/`, `business-ops/`
- **feat: add marketing sector** — 23 agents and 25 skills for SEO, ads, CRO, copywriting, email, analytics, social, video, influencers, PR, and more
- **feat: add BI sector** — 5 agents and skills for analytics engineering, dashboards, data analysis, report automation, data governance
- **feat: add sales sector** — 10 agents with BANT/MEDDIC/SPICED/Challenger/Gap Selling frameworks, plus 6 skills
- **feat: add finance sector** — 6 agents for modeling, budgeting, cost/revenue analytics, reporting, CFO advisory
- **feat: add commercial sector** — 6 pricing, deal desk, partnerships, channel economics, forecasting, RFP agents
- **feat: add business-ops sector** — 6 agents for process mapping, vendor management, capacity planning, internal comms, knowledge ops, procurement
- **feat: add C-level executive agents** — CEO, CTO, CFO, CMO, COO for cross-sector orchestration
- **feat: add web service systemd setup** — `make setup-web` / `make restart-web`, `ocf:setup-web`, `ocf:restart-web`
- **docs: update READMEs** for multi-sector structure

## 1.4.2 (2026-06-28)

- **chore: remove unused locale dirs** — deleted `standards/fr`, `de`, `ja`, `zh` (not actively maintained)
- **chore: keep EN + PT + ES** — English is source of truth, Portuguese and Spanish are actively used
- **chore: update opencode.json** — instructions now load ES locale alongside PT
- **doc: update standards/README.md** — document available locales

## 1.4.1 (2026-06-28)

- **chore: add CONTRIBUTING.md** — contributor guide with conventions and local setup
- **chore: add ROADMAP.md** — short, medium, and long-term vision
- **chore: add GitHub issue templates** — bug report, feature request, and config
- **chore: add badges to README** — version, license, PRs welcome, last commit
- **chore: add GitHub topics** — opencode, ai-coding, pipeline, agent-framework, devops, productivity
- **fix(bump-version): add `gh release create` step** — now creates GitHub Release automatically

## 1.4.0 (2026-06-28)

- **feat: add `ocf:bump-version` command** — automatically calculates version bump from git log, updates VERSION/CHANGELOG/README, commits, tags, and publishes to main
- **fix: restructure `prioritization.md`** — moved from `standards/` to project root alongside `known_issues.md` and `resolved_issues.md` for easier access
- **fix: correct Agent Pipeline ordering** — QA pre-development now comes before PM promotion, matching the Discovery Pipeline
- **fix: resolve Issue Lifecycle contradictions** — removed "asks user" language from promotion step, clarified remote auto-creation fallback
- **fix: add PM re-invoke responsibility** — PM now re-invokes Developer when QA sends issue back from `in-qa` to `in-progress`
- **fix: update `standards/issues.md`** — corrected "Reviewers set during promotion" to "during discovery"; added missing fields to pt/issues.md
- **doc: update all READMEs** — main, agents, skills, scripts, standards, .opencode bootstrap template

## 1.3.0 (2026-06-28)

### Pipeline Changes

- **Agent Pipeline reordered**: QA pre-development (step 4) now comes before PM promotion (step 5), matching the Discovery Pipeline order
- **Developer auto-proceed**: Developer no longer pauses or asks for confirmation after implementation — updates status to `in-review` and proceeds to Senior Review automatically
- **Remote creation at end of discovery**: Moved from Tech Lead to PM step; PM asks user if they want to create the remote issue now. If declined, auto-created during promotion
- **Issue Lifecycle step 4 fixed**: No longer asks user about remote during promotion — promotion is purely mechanical
- **Discovery step 6 clarified**: Remote `-` now means "will be auto-created during promotion" instead of "must be created before promotion" (contradiction removed)
- **Tech Lead question 9 added**: "As regras de negócio e critérios de aceite são explícitos o suficiente para o Developer implementar sem precisar de esclarecimentos?"
- **QA ⇄ Developer correction loop**: PM now re-invokes Developer when QA sends issue back from `in-qa` to `in-progress`

### Structural Changes

- **`prioritization.md` moved** from `standards/` to project root, alongside `known_issues.md` and `resolved_issues.md` for easier access
- All references updated across 7 files (workflow.md, opencode.json, product-owner.md, architecture.md, commands/ocf:maintain.md, standards/README.md)

### Documentation

- **Main README.md**: Added missing commands (`ocf:close-issue`, `ocf:review-external`), Pipeline Overview section, `prioritization.md` in structure table
- **agents/README.md**: Developer described as "auto-proceeds without pausing"
- **skills/README.md**: Added `locale-loader` skill
- **scripts/README.md**: Added missing scripts (init.sh, sync_github_issues.sh, import_claude_skill.sh, config.sh)
- **standards/README.md**: Removed `prioritization.md` (moved to root), added `resolved-issue.md`
- **`.opencode/README.md`**: Added `prioritization.md`, `resolved_issues.md`, global config reference

### Bug Fixes

- **`standards/issues.md`**: Fixed "Reviewers set during promotion" → "set during discovery"; added `PR:` field to format
- **`standards/pt/issues.md`**: Added missing fields (`Base branch`, `Business rules`, `PR`, `Acceptance criteria`)
- **Global `prioritization.md`**: Removed 7 external project proposals — now contains only opencode config proposals
- **`scripts/promote.sh`**: Message updated from "Tech Lead should now create remote issue" to match new PM flow

## 1.2.1 (2026-06-26)

- Minor fixes and documentation updates

## 1.2.0 (2026-06-24)

- Added senior-reviewers agent pipeline
- Added review-external agent and command
- Added PR template translations (pt, es, fr, de, ja, zh)
- Issue tracking format expanded with `Base branch:`, `Reviewers:`, `Business rules:`, `PR:`, `Acceptance criteria:`

## 1.1.0 (2026-06-09)

- Added Tech Lead agent with discovery protocol
- Added pre-development QA gate
- Consolidated branch, reviewers, and remote decisions into discovery
- Updated workflow.md with full agent pipeline

## 1.0.0 (2026-05-30)

- Initial release
- Basic issue tracking pipeline (backlog → ready → open → in-progress → resolved)
- Core agents: CTO, PO, Developer, Committer, Publish Requester, Close Requester
- Scripts: promote.sh, create_issue.sh, close_issue.sh, maintain.sh
- Standards: branching.md, commits.md, issues.md, pr-template.md, code-review.md
