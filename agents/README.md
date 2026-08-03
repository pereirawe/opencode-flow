---
hidden: true
description: Agent directory index — all agents organized by business sector
---

# Agents

Subagent definitions organized by business sector.
The `ceo` agent orchestrates cross-sector execution.

## C-Level

| Agent | Function |
|-------|----------|
| `ceo` | Cross-sector strategy, planning, and executive orchestration |
| `cto` | Technical vision, architecture, engineering leadership |
| `cfo` | Financial strategy, fundraising, board, budgeting |
| `cmo` | Marketing, brand, demand gen, growth, market intelligence |
| `coo` | Operations, processes, resources, efficiency |

## Development
| Agent | Function |
|-------|----------|
| `discovery` | Orchestrates discovery pipeline (PO -> CTO -> Tech Lead -> PO -> QA -> PM) |
| `delivery` | Orchestrates delivery pipeline (PM -> Developer -> Review -> QA -> Committer -> Publish -> Close) |
| `cto` | Technical vision and guidelines |
| `product-owner` | Priorities and user stories |
| `project-manager` | Coordination and task assignment |
| `quality-analyst` | Quality standards and testability |
| `developer` | Feature implementation (auto-proceeds to senior review) |
| `develop-router` | Routes `/ocf:develop` to language-specific subagents |
| `committer` | Pre-MR gatekeeper |
| `publish-requester` | Merge/pull request creation |
| `close-requester` | Closes remote issues after MR merge |
| `documentation` | Docs maintenance |
| `test-automation` | Automated test suites |
| `backup` | Intelligent timestamped backups |
| `review-external` | External branch/MR review |
| `senior-reviewers/*` | Specialized domain reviewers (10 roles) |
| `devs/*` | Language-specific implementation agents |

## Marketing
| Agent | Function |
|-------|----------|
| `seo` | SEO — technical, keyword research, content optimization |
| `ads` | Ad campaigns — strategy, copy, platform management |
| `pages` | Landing pages — design, CRO, conversion optimization |
| `presentations` | Presentation design and data storytelling |
| `reports` | Marketing analytics, dashboards, KPI tracking |
| `research` | Market and audience research |
| `social` | Social media strategy, content, analytics |
| `templates` | Templates and brand asset management |
| `copywriting` | Copywriting and copy-editing across all channels |
| `cro` | Conversion rate optimization, funnel analysis |
| `content` | Content strategy, editorial planning, ops |
| `email` | Lifecycle email marketing and automation |
| `analytics` | Marketing measurement, attribution, diagnostics |
| `psychology` | Behavioral science and persuasion frameworks |
| `planning` | Campaign and GTM planning |
| `customer-research` | ICP, personas, surveys, insight synthesis |
| `video` | Video scripts, storyboarding, AI video production |
| `competitors` | Competitive intelligence and positioning |
| `ab-testing` | Experiment design and statistical analysis |
| `launch` | Product launch strategy and distribution |
| `cold-email` | B2B outreach and deliverability |
| `influencer` | Creator partnerships and ambassador programs |
| `pr` | Media relations, crisis comms, thought leadership |

## BI (Business Intelligence)
| Agent | Function |
|-------|----------|
| `analytics-engineering` | Data pipelines, dbt models, data warehousing |
| `dashboard-design` | Visualization, KPI selection, BI tools |
| `data-analysis` | Exploratory analysis, statistical testing, cohorts |
| `report-automation` | Scheduled reporting, anomaly detection |
| `data-governance` | Data quality, catalog, lineage, compliance |

## Sales
| Agent | Function |
|-------|----------|
| `sales-pipeline` | CRM ops, forecasting, MEDDIC, velocity analysis |
| `prospecting` | Lead gen, account research, ICP targeting, social selling |
| `sales-enablement` | Collateral, decks, objection handling (LAER) |
| `proposals` | Proposal writing, pricing, negotiation strategy |
| `account-management` | Expansion, retention, QBRs, health scoring |
| `discovery` | Needs assessment, BANT/MEDDIC/SPICED/SPIN/Gap/Challenger |
| `closing` | Buying signals, trial closes, urgency, decision-framing |
| `negotiation` | Value-based negotiation, concession strategy, anchoring |
| `sales-psychology` | Buyer behavior, cognitive biases, rapport dynamics |
| `deal-docs` | CRM hygiene, win/loss analysis, pipeline audits |

## Finance
| Agent | Function |
|-------|----------|
| `financial-modeling` | 3-statement models, unit economics, DCF, valuation |
| `budgeting` | Budget planning, variance analysis, rolling forecasts |
| `cost-analytics` | Cost structure, burn rate, efficiency metrics |
| `revenue-analytics` | MRR/ARR, churn, LTV, cohort analysis, ASC 606 |
| `financial-reporting` | P&L, balance sheet, cash flow, board decks |
| `cfo-advisory` | Fundraising, cap table, M&A, strategic finance |

## Commercial
| Agent | Function |
|-------|----------|
| `pricing-strategist` | Pricing models, packaging, discount governance |
| `deal-desk` | Deal structuring, approval workflows, margin protection |
| `partnerships-architect` | Channel partnerships, alliances, co-selling |
| `channel-economics` | Partner margins, incentives, tier programs |
| `commercial-forecasting` | Pipeline-to-revenue, bookings forecast, scenario planning |
| `rfp-responder` | RFP responses, compliance matrices, bid/no-bid |

## Business Operations
| Agent | Function |
|-------|----------|
| `process-mapper` | Workflow design, SOPs, RACI, swimlane diagrams |
| `vendor-management` | Vendor selection, contracts, performance |
| `capacity-planner` | Resource allocation, demand forecasting, utilization |
| `internal-comms` | Announcements, change management, leadership messages |
| `knowledge-ops` | Knowledge bases, documentation systems, IA |
| `procurement-optimizer` | Strategic sourcing, spend analysis, consolidation |

Each sector's agents are in `agents/<sector>/` and invoked via `task:` with
`subagent_type: <sector>/<agent-name>`.
