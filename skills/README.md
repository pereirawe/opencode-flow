# Skills

Reusable capabilities organized by business sector.

> **External skills** (design, motion, color, etc.) are NOT copied here — they
> live as git clones in `~/.config/opencode/vendor/` and are loaded in-place
> via `skills.paths` in `opencode.json`. Manage them with
> `scripts/skill-vendor.sh` (add/update/list/remove).

## Design

### Native (`skills/design/` — the Adorable pipeline)

| Skill | Purpose |
|-------|---------|
| `design-tokens` | Canonical token system — palette (6 functional layers + 2 accents + semantic), typography (2 families), 4pt spacing, radius/shadow tiers, motion durations |
| `reference-library` | Canonical component pattern library — concrete UI patterns; every component resolves to `design-tokens` |
| `component-patterns` | Component contract rules — props/states/events, accessibility, responsive, motion (150ms) |
| `visual-hierarchy` | Layout/typography hierarchy rules — visual weight, contrast; 3 density modes for data-dense surfaces |

External (vendor clone of `Leonxlnx/taste-skill`):

| Skill | Purpose |
|-------|---------|
| `design-taste-frontend` | Anti-slop UI — landing pages, portfolios, redesigns. Reads brief, infers design direction, ships non-templated interfaces (default) |
| `redesign-existing-projects` | Audit-first redesign — upgrades existing sites/apps to premium quality |
| `minimalist-ui` | Notion/Linear-style — clean editorial, warm monochrome, typographic contrast |

Other design skills from vendor: `motion-design` (LottieFiles/motion-design-skill),
`color-expert` (meodai/skill.color-expert), `icon-generator` (anhao/icon-generator-skill),
`brand-to-design-md` (shaom/brand-to-design-md-skill), `responsive-craft`
(kylezantos/responsive-craft), `ux-flow-designer` (ThomasPraun/ux-flow-designer),
`frontend-designer` (kozz36/frontend-designer-skill, sparse `versions/v3.0`),
`poster-design-generation` (eachlabs/skills, sparse `skills/poster-design-generation`).

Use-case → skill mapping:

| Use case | Skill |
|---|---|
| New landing / portfolio | `design-taste-frontend` (default) |
| Redesign an existing site | `redesign-existing-projects` |
| Notion/Linear-style minimal UI | `minimalist-ui` |
| Soft UI / glassmorphism | no dedicated skill — follow `design-taste-frontend` with a "glassy"/"soft" vibe |

## External batch (issue #44)

Imported as vendor clones (issue #43 strategy) — full list via `scripts/skill-vendor.sh list`.

| Skill | Origin repo | Notes |
|-------|-------------|-------|
| `seo-geo` | whyashthakker/agent-skills-marketing | sparse `.claude/skills/seo-geo` |
| `senior-frontend` | alirezarezvani/claude-skills | sparse `engineering-team/skills/senior-frontend` (symlink target) |
| `google-search-console` | kostja94/marketing-skills | sparse `skills/analytics/seo/google-search-console` |
| `youtube-seo` | kostja94/marketing-skills | sparse `skills/platforms/youtube` |
| `next-best-practices` | laguagu/claude-code-nextjs-skills | sparse `skills/next-best-practices` |
| `nextjs-seo` | laguagu/claude-code-nextjs-skills | sparse `skills/nextjs-seo` |
| `python-expert-best-practices-code-review` | wispbit-ai/skills | sparse `skills/python-expert-best-practices-code-review` |
| `tailwind` | pproenca/dot-skills | sparse `skills/.curated/tailwind` |
| `poster-design-generation` | eachlabs/skills | sparse `skills/poster-design-generation` |
| `cto-architecture-decision` | rinaldofesta/cto-os-skills | full clone |
| `cto-engineering-metrics` | rinaldofesta/cto-os-skills | full clone |
| `cto-risk-resilience` | rinaldofesta/cto-os-skills | full clone |
| `cto-technology-roadmap` | rinaldofesta/cto-os-skills | full clone |

Not available (documented): `next-best-practices` from `vercel-labs/next-skills`
(moved to `vercel/next.js`, split into framework-bundled docs) and
`business-analyst` from `404kidwiz/claude-supercode-skills` (repo 404).

## Career

Native (`skills/career/` — resume optimization & LinkedIn flow; backed by
`agents/career/*` and `scripts/cv/*`):

| Skill | Purpose |
|-------|---------|
| `cv-hub` | Build/update the candidate hub (`hub.json` + `README.md`) from CV PDF + official LinkedIn export |
| `cv-optimizer` | Profile analysis — score, target profiles, salary ranges, action plan + integrated LinkedIn improvements |
| `cv-linkedin` | Objective-driven LinkedIn action report (literal headline, Sobre with logros, experience bullets, skills review) |
| `cv-linkedin-sync` | Offline hub ↔ LinkedIn diff from the official export (headline, positions, skills, education, languages, certifications) |
| `cv-linkedin-banner` | LinkedIn banner generation — 4:1 canvas, profile-photo safe zone, hub-sourced contact text, each::sense |
| `cv-tailor` | Job-tailored resume PDF (HTML → PDF) with gap analysis |
| `cv-cover-letter` | Tailored cover letter PDF for a job |
| `cv-interview-prep` | Interview preparation kit (questions + STAR answers from real hub experience) |
| `cv-ats-score` | ATS compatibility scoring of a generated resume |
| `cv-pdf` | HTML → A4 PDF rendering (Chrome headless, LibreOffice fallback) |

## Development

| Skill | Purpose |
|-------|---------|
| `go/*` | Go language idioms, package design, testing, API design |
| `python/*` | Python style, typing, docstrings, Flask API design |

## Marketing

| Skill | Purpose |
|-------|---------|
| `seo-optimizer` | SEO specialist — technical SEO, keyword research, content optimization |
| `ads-campaign` | Ad campaign strategy, copywriting, platform management |
| `landing-pages` | Landing page design, CRO, conversion optimization |
| `presentations` | Professional presentation design and data storytelling |
| `marketing-reports` | Marketing analytics reports, dashboards, KPI tracking |
| `market-research` | Market research, competitor analysis, audience research |
| `social-media` | Social media strategy, content, and analytics |
| `marketing-templates` | Reusable templates and brand asset management |
| `copywriting` | Marketing copy and copy-editing across all channels |
| `conversion-optimization` | CRO audits, funnel analysis, experiment design |
| `content-strategy` | Editorial planning, content ops, calendars, repurposing |
| `email-marketing` | Lifecycle email strategy, sequences, automation |
| `marketing-analytics` | Measurement, attribution, diagnostics, reporting |
| `marketing-psychology` | Cognitive biases, behavioral science, persuasion |
| `marketing-plan` | Campaign and GTM strategy, budget, channel mix |
| `customer-research` | ICP definition, personas, surveys, insight synthesis |
| `video-production` | Video scripts, storyboarding, AI video generation |
| `competitor-intelligence` | Competitor profiling, positioning gaps, comparison pages |
| `ab-testing` | Experiment design, statistical analysis, growth programs |
| `launch` | Product launch strategy, multi-channel distribution |
| `cold-email` | B2B outreach sequences, deliverability, reply optimization |
| `influencer-marketing` | Creator partnerships, ambassador programs, measurement |
| `public-relations` | Media outreach, press releases, crisis comms, thought leadership |

## BI (Business Intelligence)

| Skill | Purpose |
|-------|---------|
| `analytics-engineering` | Data pipelines, dbt models, data warehousing |
| `dashboard-design` | Visualization, KPI selection, BI tools |
| `data-analysis` | Exploratory analysis, statistical testing, cohorts |
| `report-automation` | Scheduled reporting, anomaly detection |
| `data-governance` | Data quality, catalog, lineage, compliance |

## Sales

| Skill | Purpose |
|-------|---------|
| `sales-pipeline` | CRM ops, forecasting, MEDDIC, velocity analysis |
| `prospecting` | Lead gen, account research, ICP targeting, social selling |
| `sales-enablement` | Collateral, decks, objection handling (LAER) |
| `proposals` | Proposal writing, pricing, negotiation strategy |
| `account-management` | Expansion, retention, QBRs, health scoring |
| `sales-psychology` | Buyer behavior, cognitive biases, rapport dynamics |

## Finance

| Skill | Purpose |
|-------|---------|
| `financial-modeling` | 3-statement models, unit economics, valuation |
| `budgeting` | Budget planning, variance analysis, forecasts |
| `cost-analytics` | Cost structure, efficiency metrics, optimization |
| `revenue-analytics` | MRR/ARR, churn, LTV, cohort analysis |
| `financial-reporting` | P&L, balance sheet, cash flow, board decks |
| `cfo-advisory` | Fundraising, cap table, M&A, strategic finance |

## Commercial

| Skill | Purpose |
|-------|---------|
| `pricing-strategist` | Pricing models, packaging, discount governance |
| `deal-desk` | Deal structuring, approval workflows, margin protection |
| `partnerships-architect` | Channel partnerships, alliances, co-selling |
| `channel-economics` | Partner margins, incentives, tier programs |
| `commercial-forecasting` | Pipeline-to-revenue, bookings forecast, scenario planning |
| `rfp-responder` | RFP responses, compliance matrices, bid/no-bid |

## Business Operations

| Skill | Purpose |
|-------|---------|
| `process-mapper` | Workflow design, SOPs, RACI, swimlane diagrams |
| `vendor-management` | Vendor selection, contracts, performance |
| `capacity-planner` | Resource allocation, demand forecasting, utilization |
| `internal-comms` | Announcements, change management, leadership messages |
| `knowledge-ops` | Knowledge bases, documentation systems, IA |
| `procurement-optimizer` | Strategic sourcing, spend analysis, consolidation |

## Shared (cross-sector)

| Skill | Purpose |
|-------|---------|
| `issue-manager` | Maintain tracked work register (`known_issues.md`) |
| `locale-loader` | Load locale-appropriate standards based on `.opencode/locale` |
| `graphify` | Generate Mermaid.js diagrams from code structure |
| `skill-importer` | Import external skills as git clones into `vendor/` (clone strategy — no copy) |
| `skill-creator` | Guide for creating high-quality, Anthropic-compatible skills |

To import an external skill from a git repo, use `skill: skill-importer` or
`scripts/skill-vendor.sh add <git-url|owner/repo>`.
