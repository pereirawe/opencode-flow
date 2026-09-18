# Runtime Code Review Standard

Scope: environment configuration, build tooling, packaging, startup/shutdown,
logging, and resource limits.

## Checklist

- [ ] Environment variables validated at startup with clear defaults/docs
- [ ] Build scripts reproducible and deterministic
- [ ] Graceful shutdown and startup ordering handled
- [ ] Logging structured, leveled, and free of secrets
- [ ] Resource limits (memory, CPU, timeouts) set for services and jobs
- [ ] Scheduled/background jobs idempotent and overlap-safe
- [ ] Configuration changes do not require code deploys

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| App crashes on missing env var with opaque error | bug | Add validation with actionable message |
| Issue never specified a runtime config knob that is needed | incomplete-spec | Flag for discovery refinement |
| Job runs twice under retry and duplicates work | edge case | Add idempotency or overlap guard |
| Logs contain tokens or PII | bug | Block; redact and rotate |

## Related skills

- `skills/development/test-runner`
- `vendor/lovable-skills/skills/background-jobs-and-cron`
- `vendor/lovable-skills/skills/rate-limiting-edge`
- `vendor/lovable-skills/skills/edge-functions-and-webhooks`
