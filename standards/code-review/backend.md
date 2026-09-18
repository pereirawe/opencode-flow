# Backend Code Review Standard

Scope: server-side logic, HTTP APIs, service boundaries, business rules, and
data flow. Applies to Go, Python, and any backend language in the repo.

## Checklist

- [ ] N+1 queries and cartesian-product joins detected in ORM/query code
- [ ] HTTP error responses consistent with the API contract (status codes, error shape)
- [ ] Idempotency handled for POST/PUT/PATCH endpoints with side effects
- [ ] Input validation on the server, never trusting client payloads
- [ ] Business rules from the issue implemented exactly as documented
- [ ] Secrets never logged, committed, or returned in responses
- [ ] Concurrency safety reviewed (races, shared state, locks)
- [ ] Error paths return actionable messages and are not swallowed

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Endpoint returns 500 on invalid input instead of 4xx | bug | Flag as blocking; align with contract |
| Code implements the issue but a needed rule was never captured | incomplete-spec | Send back to discovery refinement, do not patch |
| Unusual payload size or encoding not covered by tests | edge case | Add test scenario or refinement |
| POST handler duplicates side effects on retry | bug | Require idempotency key or dedup |

## Related skills

- `skills/development/go/go-api-design`
- `skills/development/go/go-style-review`
- `skills/development/go/go-testing`
- `skills/development/python/flask-api-design`
- `skills/development/python/python-typing`
