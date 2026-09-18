# DevOps Code Review Standard

Scope: infrastructure-as-code, CI/CD pipelines, containers, deployment
processes, and operations resilience.

## Checklist

- [ ] Dockerfiles use pinned base images and minimal layers
- [ ] CI/CD pipelines are reproducible and fail fast
- [ ] IaC changes are reviewable and state-managed (no drift)
- [ ] Deployment process has a rollback strategy
- [ ] Secrets injected via secret manager, never baked into images
- [ ] Resource limits and scaling policies defined
- [ ] Backup and disaster recovery tested

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Pipeline deploys on every push with no staging gate | bug | Block; add environment gates |
| Issue never specified infra requirements that surfaced | incomplete-spec | Flag for discovery refinement |
| Image build succeeds locally but fails in CI | edge case | Reproduce and pin versions |
| Secret baked into image layer | bug | Block; rebuild and rotate |

## Related skills

- `vendor/cto-os-skills/cto-risk-resilience-skill`
- `vendor/cto-os-skills/cto-engineering-metrics-skill`
- `vendor/lovable-skills/skills/background-jobs-and-cron`
- `skills/development/test-runner`
