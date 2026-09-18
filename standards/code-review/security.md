# Security Code Review Standard

Scope: authentication, authorization, input validation, injection, crypto,
secrets, SSRF, deserialization, and dependency risk. Aligned with OWASP
Top 10 (2021) and ASVS 4.0.

## Checklist

- [ ] Input validation and output encoding prevent injection (SQL, XSS, command)
- [ ] AuthN/AuthZ enforced server-side; no client-only access control
- [ ] Secrets stored in env/secret manager, never in code or logs
- [ ] Rate limiting on login, signup, and abuse-prone endpoints
- [ ] Dependencies scanned for known CVEs; no vulnerable pinned versions
- [ ] CSRF protection on state-changing requests
- [ ] Security headers and CORS configured per policy
- [ ] Error messages do not leak internals (stack traces, SQL, paths)

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| SQL injection via string interpolation | bug | Block; parameterize queries |
| Issue never specified auth requirements for an endpoint | incomplete-spec | Flag for discovery refinement |
| Unusual input encoding not covered by validation tests | edge case | Add test scenario or refinement |
| Secrets committed to the repo | bug | Block; rotate and remove from history |

## Related skills

- `skills/development/security/owasp-top10`
- `skills/development/security/owasp-asvs`
- `skills/development/security/secure-code-review`
- `skills/development/security/threat-modeling`
- `skills/development/auth/auth-architecture`
- `vendor/lovable-skills/skills/rate-limiting-edge`
