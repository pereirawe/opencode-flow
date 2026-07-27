---
name: data-governance
description: Data governance and quality — data catalog, lineage, quality frameworks, metadata management, compliance (LGPD/GDPR), data policies.
---

# Data Governance Skill

Establish trust in data through governance and quality.

## Governance Framework

### Data Catalog
- Business glossary: canonical definitions for every metric
- Technical metadata: source, schema, transformation logic
- Ownership: data owner and steward per domain
- Tags: PII, sensitive, critical, experimental

### Data Lineage
- Source → staging → transformation → consumption
- Impact analysis: "what breaks if this source changes?"
- Root cause: "why did this report change?"

### Data Quality Dimensions

| Dimension | Definition | Check |
|-----------|------------|-------|
| Accuracy | Data reflects reality | Cross-reference with source |
| Completeness | All required data present | Null checks, row count |
| Consistency | Same values across systems | Cross-system reconciliation |
| Timeliness | Data is current | Freshness SLA monitoring |
| Uniqueness | No duplicate records | Primary key validation |
| Validity | Data conforms to format | Schema validation |

### Quality Rules
- Freshness SLA per table
- Row count expectations (minimum, maximum, % change)
- Null rate thresholds per critical column
- Referential integrity checks
- Custom business rules

## Compliance
- PII classification and masking
- Retention policies by data type
- Access controls (read, write, admin per role)
- Audit logging for sensitive data access
- LGPD/GDPR: right to deletion workflow

## Related Skills
- `analytics-engineering` — data pipeline governance
- `report-automation` — data quality reporting
