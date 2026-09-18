# Performance Code Review Standard

Scope: algorithmic complexity, caching, query optimization, memory/CPU usage,
concurrency, and load behavior.

## Checklist

- [ ] Hot paths profiled; no obvious O(n²) or worse regressions
- [ ] Caching strategy defined with invalidation and TTL
- [ ] Database queries optimized (indexes, no N+1)
- [ ] Bundle size and asset weight within budget
- [ ] Concurrency safe; no contention or deadlock risks
- [ ] LCP/INP/CLS targets respected for web surfaces
- [ ] Pagination/virtualization for large datasets

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Endpoint latency regressed >2x vs baseline | bug | Block; profile and fix |
| Issue never set a performance target for the feature | incomplete-spec | Flag for discovery refinement |
| Slow path only under unusual data volume | edge case | Add load test scenario |
| Cache returns stale data after update | bug | Fix invalidation |

## Related skills

- `vendor/lovable-skills/skills/performance-budget`
- `vendor/lovable-skills/skills/seo-core-web-vitals`
- `vendor/lovable-skills/skills/tanstack-infinite-queries`
- `vendor/lovable-skills/skills/postgres-full-text-search`
