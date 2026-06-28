# OpenCode Project Configuration

[![Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fpereirawe%2Fopencode-flow%2Fmain%2Fpackage.json&query=%24.version&label=version&color=blue)](https://github.com/pereirawe/opencode-flow/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)
[![GitHub stars](https://img.shields.io/github/stars/pereirawe/opencode-flow?style=social)](https://github.com/pereirawe/opencode-flow/stargazers)
[![GitHub last commit](https://img.shields.io/github/last-commit/pereirawe/opencode-flow)](https://github.com/pereirawe/opencode-flow/commits/main)
[![GitHub Discussions](https://img.shields.io/badge/discussions-welcome-brightgreen)](https://github.com/pereirawe/opencode-flow/discussions)

**Version:** 1.4.2 — [License](LICENSE) (MIT)

Generic, language-agnostic configuration for AI-assisted development workflow.
This config lives in `~/.config/opencode/` and is automatically loaded by OpenCode as the **global config**.

## Installation

### Quick install (curl | bash)

```bash
curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/main/install.sh | bash
```

With options:

```bash
curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/main/install.sh | bash -s -- --branch=v1.0.0 --dir=$HOME/.config/opencode
```

### Manual

```bash
git clone --depth 1 https://github.com/pereirawe/opencode-flow ~/.config/opencode
```

## Updating

```bash
bash ~/.config/opencode/scripts/update.sh          # update to latest
bash ~/.config/opencode/scripts/update.sh --check   # check only
```

Or via Make:

```bash
make -C ~/.config/opencode update
```

## Structure

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Entrypoint instructions |
| `opencode.json` | OpenCode configuration |
| `workflow.md` | Development workflow pipeline |
| `architecture.md` | Technical vision and structural decisions |
| `conventions.md` | Development conventions and best practices |
| `decisions.md` | Architecture decision records |
| `known_issues.md` | Active issues tracker |
| `prioritization.md` | PO prioritization proposals (project backlog) |
| `resolved_issues.md` | Resolved issues archive (compact) |
| `VERSION` | Current version |
| `LICENSE` | MIT License |
| `agents/` | Subagent definitions (CTO, PO, Dev, Committer, etc.) |
| `commands/` | Slash command documentation |
| `skills/` | Reusable skills (issue-manager, locale-loader, graphify) |
| `scripts/` | Shell helpers for issue lifecycle |
| `standards/` | Development patterns (branching, commits, PR, issues, code-review) + locale translations. Auto-loaded via `instructions` in `opencode.json` |
| `.opencode/` | Project bootstrap template (copy to other projects) |
| `wip/` | Planning artifacts |

## Usage

```bash
make scan-issues        # static analysis + prompt /ocf:scan-issues
make review             # show git diff + prompt /ocf:review-branch
make promote id=<n>     # promote backlog item to open
make close-issue id=<n> # close + archive issue
make maintain           # scan for stale entries + prompt /ocf:maintain
make bootstrap target=<path>  # copy .opencode/ template to project
make init target=<path> # init project with repo context
```

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/ocf:init` | Initialize `.opencode/` project config |
| `/ocf:scan-issues` | Deep codebase analysis and issue detection |
| `/ocf:review-branch` | Full PR/MR-style code review |
| `/ocf:review-external` | External branch/MR review with structured report |
| `/ocf:plan-feature` | Feature breakdown with risk assessment |
| `/ocf:promote <id>` | Promote backlog item + create remote issue |
| `/ocf:develop [id]` | Start or resume development on a promoted issue |
| `/ocf:commit` | Create structured commit with status trailers |
| `/ocf:sync-issues` | Sync known_issues with remote tracker |
| `/ocf:archive-issue <id>` | Archive resolved issue to compact format |
| `/ocf:close-issue <id>` | Close remote issue and archive after PR merge |
| `/ocf:check-pr [id]` | Check PR merge status and auto-archive merged |
| `/ocf:maintain` | Full maintenance of tracker files |
| `/ocf:backup` | Create timestamped backup excluding junk |
| `/ocf:bump-version` | Calculate version bump, update changelog, commit, tag, and publish to main |

## Pipeline in Action

This project dogfoods its own pipeline. Here's a real cycle (v1.4.2 release):

```
# 1. DISCOVERY — identify improvement (remove unused locale dirs)
→ PO identifies the need (fr/de/ja/zh standards are stale)
→ CTO/Tech Lead validate minimal impact
→ QA confirms no breaking changes
→ PM promotes: issue registered in known_issues.md

# 2. DEVELOPMENT — implement + auto-proceed to review
→ Developer removes 4 locale dirs, updates opencode.json
→ Tests run, self-review passes
→ Status → in-review (no pause, no asking)

# 3. PUBLISHING — gate → MR → release
→ Committer verifies: senior review done, QA passed, tests passing
→ Publish Requester creates MR (chore: remove unused locales)
→ MR merged to main
→ Maintainer runs: /ocf:bump-version
```

```
$ /ocf:bump-version
  Current VERSION: 1.4.1
  Last tag: v1.4.1
  Commits since tag: 1 (chore)
  Suggested: 1.4.2 (patch)
  
  Confirm bump to 1.4.2? [Y/n]: Y
  
  ✓ VERSION updated: 1.4.1 → 1.4.2
  ✓ README.md version badge updated
  ✓ CHANGELOG.md entry added
  ✓ Commit: chore: bump version to 1.4.2
  ✓ Tag: v1.4.2
  ✓ Push to origin/main --tags
  ✓ GitHub Release created: v1.4.2
  → https://github.com/pereirawe/opencode-flow/releases/tag/v1.4.2
```

Every change in this repo follows the same lifecycle. See `workflow.md` for the complete pipeline definition.

## Pipeline Overview

The development pipeline has three phases:

1. **Discovery** (PO → CTO → Tech Lead → QA → PM): refine requirements, define business rules, branch base, and reviewer profiles. PM asks to create remote issue at the end.
2. **Development** (Developer → Senior Reviewers → QA → Developer corrections): implement, self-review, run tests, then auto-proceed to senior review without pausing.
3. **Publishing** (Committer → Publish Requester → Close Requester): verify gates, create MR, close issue on merge.

The pipeline runs continuously after promotion — no user confirmation needed between steps.
See `workflow.md` for complete details.

## Bootstrap a New Project

```bash
make bootstrap target=../my-project
```

This copies `.opencode/` template into the target project root.
See `.opencode/README.md` for details.

## License

MIT — see [LICENSE](LICENSE).
