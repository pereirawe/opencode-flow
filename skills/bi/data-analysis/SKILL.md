---
name: data-analysis
description: Exploratory and statistical data analysis — descriptive statistics, hypothesis testing, cohort analysis, funnel analysis, regression, segmentation.
---

# Data Analysis Skill

Extract actionable insights from data with statistical rigor.

## Analysis Framework

### 1. Define Question
- What business decision will this analysis inform?
- What specific metrics answer the question?
- What data sources are available?

### 2. Collect & Prepare
- Data source identification and extraction
- Missing value treatment
- Outlier detection (IQR method, z-score)
- Feature engineering for analysis

### 3. Exploratory Analysis
- Summary statistics (mean, median, distribution, variance)
- Trend and seasonality decomposition
- Correlation matrix of key variables
- Segment drill-downs (by cohort, channel, region)

### 4. Statistical Methods

| Method | Use Case |
|--------|----------|
| T-test / Mann-Whitney | Compare two groups (A/B, test vs control) |
| ANOVA | Compare three+ groups |
| Chi-square | Test categorical associations |
| Linear regression | Continuous outcome prediction |
| Logistic regression | Binary outcome prediction |
| Time series (ARIMA, Prophet) | Forecasting with seasonality |
| Clustering (K-means, RFM) | Customer segmentation |

### 5. Insight Generation
- **What**: Observation (the data says X)
- **So what**: Implication (this means Y for the business)
- **Now what**: Recommendation (therefore we should do Z)

## Cohort Analysis
- Time-based: users grouped by signup month
- Behavior-based: grouped by first action
- Metric: retention, revenue, engagement over time
- Format: heatmap (cohorts × time periods)

## Related Skills
- `analytics-engineering` — data access
- `dashboard-design` — visualization
- `marketing-analytics` — marketing analysis
- `revenue-analytics` — revenue analysis
