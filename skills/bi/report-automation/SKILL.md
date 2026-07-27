---
name: report-automation
description: Automated reporting and alerting — scheduled report generation, anomaly detection, executive summaries, automated insight delivery.
---

# Report Automation Skill

Build systems that deliver insights on schedule.

## Report Types

| Type | Cadence | Audience | Content |
|------|---------|----------|---------|
| Daily snapshot | Daily | Ops team | Key metrics vs target, anomalies |
| Weekly digest | Weekly | Management | Trends, wins, risks, actions |
| Monthly review | Monthly | Leadership | Full performance, variance, forecast |
| Quarterly board | Quarterly | Board | Strategic narrative, financials, outlook |

## Automated Alert Design
- **Threshold-based**: metric falls outside acceptable range
- **Statistical**: z-score > 3 deviation from trailing mean
- **Trend-based**: N consecutive periods of decline/growth
- **Composite**: combination of signals (traffic drop + conversion drop)

## Summary Generation
- Section 1: Executive headline (1 sentence: "Revenue grew X% driven by Y")
- Section 2: Key metrics table (actual, target, variance, trend)
- Section 3: Anomalies and alerts (what changed, impact, investigations)
- Section 4: Actions (decisions needed, owners, deadlines)

## Pipeline
- Query → Transform → Render → Distribute
- Output formats: PDF, HTML email, Slack message, dashboard link
- Error handling: retry logic, fallback data, notification on failure

## Related Skills
- `analytics-engineering` — data pipeline
- `data-analysis` — insight generation
- `dashboard-design` — visual components
