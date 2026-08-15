# MCP Registry

Recommended Model Context Protocol (MCP) servers for projects using this OpenCode library.

## MCPs enabled in this project

This project uses only:

| MCP | Purpose |
|-----|---------|
| **GitHub** | Issues, PRs, repo operations, releases |
| **Notion** | Documentation, knowledge base, internal wiki |

## MCPs for SaaS projects

### Development & DevOps

| MCP | Purpose | When to use |
|-----|---------|-------------|
| **GitHub** | Code, issues, PRs, releases, actions | Always |
| **GitLab** | Code, issues, MRs, CI/CD | When using GitLab |
| **Jira** | Issue tracking, sprint management | When using Atlassian stack |
| **Linear** | Modern issue tracking | When using Linear |
| **Sentry** | Error monitoring and crash reporting | Always for production apps |
| **Datadog** | Observability, metrics, APM | Medium/large SaaS |
| **New Relic** | Observability and APM | Alternative to Datadog |
| **Grafana** | Dashboards and metrics | When using Prometheus/Loki |
| **Vercel** | Deployments, previews, edge config | MVP and frontend-heavy SaaS |
| **AWS** | Infrastructure, S3, Lambda, RDS, ECS | Production-grade backend |
| **GCP** | Cloud Run, BigQuery, Pub/Sub, GKE | Google-cloud native stacks |
| **Azure** | App Service, Azure DevOps, Entra ID | Microsoft-cloud stacks |
| **Dependabot / Snyk** | Dependency vulnerability scanning | Always |
| **1Password / HashiCorp Vault** | Secrets management | Production |

### Product & Design

| MCP | Purpose | When to use |
|-----|---------|-------------|
| **Notion** | Docs, wikis, product specs | Always |
| **Figma** | Design files, design systems | When design is part of workflow |
| **Amplitude** | Product analytics, funnels, cohorts | Growth and product teams |
| **Mixpanel** | Event analytics and user journeys | Alternative to Amplitude |
| **Segment** | Event collection and routing | Complex event pipelines |
| **Intercom** | Customer messaging and support | Customer-facing SaaS |
| **Zendesk** | Support tickets and help center | Larger support teams |
| **Crisp** | Lightweight chat and support | Early-stage SaaS |

### Business & Revenue

| MCP | Purpose | When to use |
|-----|---------|-------------|
| **Stripe** | Payments, subscriptions, billing | SaaS with paid plans |
| **Chargebee** | Subscription management | Complex billing needs |
| **HubSpot** | CRM, marketing, support | Mid-market B2B |
| **Salesforce** | CRM and sales pipeline | Enterprise B2B |
| **Google Workspace** | Docs, sheets, calendar, email | Team collaboration |
| **Slack** | Team notifications and decisions | Always for async comms |
| **Discord** | Community, support, alerts | Community-led products |
| **Teams** | Microsoft-centric collaboration | Microsoft shops |

### Collaboration

| MCP | Purpose | When to use |
|-----|---------|-------------|
| **Slack** | Alerts, approvals, daily updates | Always |
| **Discord** | Community and async support | Community-driven SaaS |
| **Loom** | Async video updates and demos | Remote teams |
| **Google Workspace** | Docs, sheets, slides, calendar | General collaboration |
| **Microsoft 365** | Office suite and Teams | Microsoft environments |

## Recommended starter stack

For a new SaaS project, start with:

1. **GitHub** + **Notion** (this project)
2. Add **Sentry** as soon as you ship to production
3. Add **Stripe** when you add payments
4. Add **Intercom** or **Crisp** for customer conversations
5. Add **Amplitude** or **Mixpanel** for product analytics
6. Add **Datadog** or **Vercel** monitoring as you scale
7. Add **Slack** for team alerts and approvals
8. Add **Dependabot** or **Snyk** for security scanning

## Configuration

MCP servers are configured in `opencode.json` under the `mcpServers` key. Example:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "notion": {
      "command": "npx",
      "args": ["-y", "@mcp-notion/server"],
      "env": {
        "NOTION_TOKEN": "${NOTION_TOKEN}"
      }
    }
  }
}
```

## Jira Cloud sync (issue #48)

The pipeline mirrors `known_issues.md` into Jira Cloud (cards, status
transitions, one-way repo→Jira comments) via `scripts/sync-jira.sh` — a
deterministic, headless, CI-testable REST v3 client. It is **the** sync
path for the pipeline: hooks in `create_issue.sh` (card creation),
`promote.sh` (status transitions) and `close_issue.sh` (resolved→Done), plus
the `ocf:sync-jira` command for full reconciliation. Sync is non-blocking and
the local `Status:` always wins.

Configuration: `.opencode/jira.json` (`baseUrl`, `email`, `projectKey`,
optional `statusMap`/`authMode`) or env vars `JIRA_BASE_URL`,
`JIRA_PROJECT_KEY`, `JIRA_EMAIL`; the API token comes **exclusively** from the
`JIRA_API_TOKEN` environment variable — never committed, never logged.

```json
{
  "baseUrl": "https://your-domain.atlassian.net",
  "email": "you@example.com",
  "projectKey": "DEV",
  "statusMap": {
    "backlog": "To Do",
    "ready": "To Do",
    "in-progress": "In Progress",
    "in-review": "In Review",
    "in-qa": "QA/Testing",
    "in-publish": "Ready for Release",
    "resolved": "Done"
  }
}
```

An optional Jira **MCP server** can be registered per-project for agent-side
backlog queries (agent reads; the pipeline sync always lives in the script):

```json
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["-y", "@atlassian/mcp-atlassian"],
      "env": {
        "JIRA_BASE_URL": "${JIRA_BASE_URL}",
        "JIRA_EMAIL": "${JIRA_EMAIL}",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
      }
    }
  }
}
```

Store tokens in environment variables. Never commit secrets to the repository.
