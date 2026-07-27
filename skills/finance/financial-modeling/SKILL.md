---
name: financial-modeling
description: Financial modeling and projections — 3-statement models, SaaS unit economics, DCF valuation, scenario analysis, sensitivity tables, fundraising models.
---

# Financial Modeling Skill

Build rigorous financial models for strategic decisions.

## Model Architecture

### 3-Statement Model
- **Income Statement**: Revenue (by stream), COGS, gross margin, OpEx, EBITDA, net income
- **Balance Sheet**: Cash, AR, AP, deferred revenue, equity, debt
- **Cash Flow**: Operating (net income + D&A - working capital), Investing (CapEx), Financing (equity/debt)
- Cross-foot checks: BS = prior BS + cash flow, net income flows to retained earnings

### SaaS Growth Model
| Input | Example |
|-------|---------|
| Starting ARR | $5M |
| New sales/month | $200K |
| NRR (net revenue retention) | 115% |
| Gross margin | 80% |
| Churn (monthly logo) | 3% |
| CAC | $15K |
| Sales cycle | 90 days |

### Unit Economics
| Metric | Formula |
|--------|---------|
| ARPU | MRR / total customers |
| LTV | ARPU / monthly churn rate |
| CAC | (Sales + marketing spend) / new customers |
| LTV/CAC | LTV / CAC (target >3x) |
| Payback | CAC / (ARPU × gross margin) (target <12 months) |
| Magic Number | (Net new ARR) / (prior quarter S&M spend) |

### DCF Valuation
1. Project FCF (free cash flow) for 5 years
2. Terminal value = FCF_5 × (1 + g) / (WACC - g)
3. Discount rate = WACC
4. NPV = sum of discounted FCF + discounted terminal value
5. Sensitivity table: vary WACC and terminal growth rate

## Best Practices
- Hardcode all assumptions as inputs (blue cells)
- One row per assumption, no magic numbers in formulas
- Scenario switching via dropdown (data validation)
- Circular reference settings for interest/debt
- Error checks: balance sheet balances, cash flow ties
