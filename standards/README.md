# Standards

Project-wide conventions and patterns shared across all sectors.

## Development Standards

| Document | Purpose |
|----------|---------|
| `branching.md` | Branch naming and workflow |
| `commits.md` | Commit message conventions |
| `issues.md` | Issue tracking and lifecycle |
| `pr-template.md` | Pull request template |
| `code-review.md` | Code review guidelines |
| `locale.md` | Locale system — how to set project language |
| `resolved-issue.md` | Resolved issue archive format |

## Sector Agents

Each business sector has its own agents and skills under `agents/<sector>/` and
`skills/<sector>/`. Available sectors:

- `development` — Engineering, DevOps, code quality, language idioms
- `marketing` — Ads, SEO, social media, presentations, reports, research
- `bi` — Business intelligence, dashboards, analytics
- `sales` — Sales pipeline, CRM, proposals
- `finance` — Financial modeling, budgeting, reporting
- `commercial` — Pricing, partnerships, deal desk, channel economics
- `business-ops` — Process mapping, vendor management, capacity planning
- `shared` — Cross-sector utilities (graphify, issue-manager, locale-loader, skill-creator, skill-importer)
- `career` — Resume optimization: cv-hub (candidate hub from CV PDF + LinkedIn export), cv-optimize (profile analysis + improvement plan), cv-tailor (job-tailored resume PDF), cv-pdf (HTML→PDF generation)

When an agent or skill is sector-specific, file it under the corresponding
sector directory. Cross-cutting capabilities go under `shared/`.

## Locale

Localized versions are available in `pt/` (Português) and `es/` (Español).
Each project selects its language via `.opencode/locale`. See `locale.md` for details.
