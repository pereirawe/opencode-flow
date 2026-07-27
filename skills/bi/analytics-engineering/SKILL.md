---
name: analytics-engineering
description: Data pipeline and warehouse engineering — ETL/ELT, dbt modeling, data modeling (star/snowflake), orchestration, data quality testing.
---

# Analytics Engineering Skill

Build reliable data infrastructure for analytics and reporting.

## Data Modeling Patterns

### Star Schema
- **Fact tables**: Measures, metrics, events (sales, clicks, signups)
- **Dimension tables**: Descriptive attributes (customer, product, time, location)
- Grain: one row per event at the most atomic level

### Slowly Changing Dimensions (SCD)
- Type 1: Overwrite (no history)
- Type 2: Add row with date range (full history)
- Type 3: Add column (limited history)

### dbt Best Practices
- Models: staging → intermediate → marts (gold layer)
- Staging: 1:1 with source, minimal transformations
- Intermediate: business logic, joins, aggregations
- Marts: ready-for-consumption, documented with descriptions
- Tests: not null, unique, accepted values, relationships, custom

## Pipeline Design
- **Extract**: Incremental where possible, full refresh for dimensions
- **Load**: Raw layer preserves source structure
- **Transform**: dbt for SQL transformations, Python for complex logic
- **Orchestrate**: Airflow/Dagster — DAG per domain, alerts on failure
- **Monitor**: Row count checks, freshness, schema drift detection

## Quality Gates
- Freshness SLA: how recent must data be?
- Completeness: no nulls in key fields
- Uniqueness: primary keys unique
- Referential integrity: foreign keys match existing records
