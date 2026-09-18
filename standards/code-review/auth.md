# Auth Code Review Standard

Scope: authentication, authorization, session/token lifecycle, multi-tenancy,
and identity flows. Consumed by the security reviewer and by a future auth
reviewer profile.

## Checklist

- [ ] Passwords hashed with a strong KDF (bcrypt/argon2); no plaintext
- [ ] Tokens (JWT/session) have expiry, revocation, and rotation
- [ ] RBAC/ABAC enforced server-side on every protected resource
- [ ] Multi-tenancy scoping prevents cross-tenant data access
- [ ] Rate limiting and lockout on login/signup/reset
- [ ] OAuth/OIDC flows follow spec (state, PKCE, redirect validation)
- [ ] Session fixation and CSRF mitigated

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Token never expires | bug | Block; add expiry and rotation |
| Issue never specified authz model for a resource | incomplete-spec | Flag for discovery refinement |
| Login flow breaks only with unusual email formats | edge case | Add test scenario |
| Tenant A can read tenant B data | bug | Block; enforce tenant scoping |

## Related skills

- `skills/development/auth/auth-architecture`
- `skills/development/security/owasp-asvs`
- `skills/development/security/threat-modeling`
- `vendor/lovable-skills/skills/supabase-auth-flows`
- `vendor/lovable-skills/skills/supabase-rls-and-auth`
- `vendor/lovable-skills/skills/multi-tenant-backend`
- `vendor/lovable-skills/skills/rate-limiting-edge`
