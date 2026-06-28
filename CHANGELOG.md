# Changelog

## 1.4.2 (2026-06-28)

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
