# Data Code Review Standard

Scope: database schemas, queries, migrations, indexes, and data integrity
across relational stores (Postgres/Supabase) and ORM layers.

## Checklist

- [ ] Queries use indexes; EXPLAIN on hot paths; no full scans on large tables
- [ ] Migrations are reversible and safe (no destructive steps without a plan)
- [ ] Foreign keys, constraints, and unique indexes enforce integrity
- [ ] N+1 avoided; batch loading used where applicable
- [ ] Connection pooling and transaction boundaries correct
- [ ] Soft-delete/archiving consistent with the domain model
- [ ] RLS policies scoped per tenant/user where applicable

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Migration drops a column still referenced by code | bug | Block; split migration and deploy order |
| Schema lacks a constraint the issue never mentioned | incomplete-spec | Flag for discovery refinement |
| Query returns correct rows but is slow on large datasets | edge case | Add index or test with realistic volume |
| Soft-deleted rows leak into unique indexes | bug | Require partial index or filter |

## Related skills

- `vendor/agent-skills/skills/supabase-postgres-best-practices`
- `vendor/lovable-skills/skills/supabase-database-design`
- `vendor/lovable-skills/skills/supabase-rls-and-auth`
- `vendor/lovable-skills/skills/migration-playbook`
- `vendor/lovable-skills/skills/postgres-full-text-search`
- `vendor/lovable-skills/skills/soft-delete-and-archiving`
