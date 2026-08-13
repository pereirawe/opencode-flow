---
name: auth-architecture
description: Authentication and authorization architecture — JWT, OAuth 2.0, OIDC, RBAC/ABAC, multi-tenancy, session management, token lifecycle, database design for auth, and security hardening for SaaS/CRM/ERP systems.
---

# Auth Architecture

Use this skill when the task involves designing, implementing, or reviewing authentication and authorization systems. Covers login flows, token management, permission models, multi-tenant data isolation, and security hardening.

## When to use

- Designing login/registration flows
- Implementing JWT access + refresh token systems
- Building OAuth 2.0 / OIDC integrations
- Designing RBAC, ABAC, or ReBAC permission models
- Building multi-tenant auth with data isolation
- Reviewing auth code for security vulnerabilities
- Designing auth database schemas
- Implementing SSO/SAML for enterprise
- Building passwordless auth (WebAuthn, magic links)
- Auditing existing auth systems

## JWT Architecture

### Token structure

Standard JWT claims:
- `iss` — issuer (your auth service URL)
- `sub` — subject (user ID, stable identifier)
- `aud` — audience (intended recipient, API gateway)
- `exp` — expiration (short-lived: 5–15 min for access)
- `nbf` — not before
- `iat` — issued at
- `jti` — unique token ID (for revocation)
- `scope` — granted permissions

Custom claims (add sparingly):
- `tenant_id` — multi-tenant context
- `roles` — role identifiers (not full permission lists)
- `plan` — subscription tier (for feature gating)

### Signing algorithms

| Algorithm | Use when | Notes |
|-----------|----------|-------|
| RS256 | Microservices, third-party verification | Public key can be shared; private key stays in auth service |
| ES256 | Mobile, high-performance | Smaller key sizes, faster verification |
| HS256 | Single-service, monolith | Simpler but secret must be shared with all verifiers |

**Never** use `none` algorithm. Always validate `alg` header matches expectations.

### Access token lifetime

- **API access**: 5–15 minutes (short enough to limit exposure)
- **Session cookie**: 30 min – 2 hours (balance security vs UX)
- **Machine-to-machine**: 5–60 minutes (depends on refresh capability)

### Refresh token rotation

```
Client                Auth Service             Token Store
  |                       |                        |
  |-- refresh(token_r1) ->|                        |
  |                       |-- validate(token_r1) ->|
  |                       |<- valid, family=fam1 --|
  |                       |-- rotate: invalidate   |
  |                       |   token_r1, create     |
  |                       |   token_r2             |
  |<- {access, refresh_r2} |                        |
```

Rules:
- Each refresh token is single-use (rotation on every refresh)
- Token family tracking detects reuse (compromised token → revoke entire family)
- Store refresh tokens server-side (DB or Redis with TTL)
- Access tokens remain stateless (validated without DB lookup)

### Token storage strategies

| Strategy | Security | XSS risk | CSRF risk | Use case |
|----------|----------|----------|-----------|----------|
| httpOnly cookie | High | Low | Yes (mitigate with SameSite) | Web SPAs, server-rendered |
| Memory (JS variable) | Medium | High | No | SPAs with short-lived tokens |
| Secure cookie (not httpOnly) | Medium | Medium | Yes | When JS needs to read token |
| Bearer header | Medium | High | No | API-to-API, mobile |

**Recommended for web**: httpOnly + Secure + SameSite=Strict cookie for refresh token; short-lived access token in memory or httpOnly cookie.

## OAuth 2.0 / OIDC

### Flows

| Flow | Client type | Use case |
|------|-------------|----------|
| Authorization Code + PKCE | SPA, mobile, CLI | Most common; always use PKCE |
| Client Credentials | Server-to-server | No user context; machine auth |
| Device Code | TV, IoT, CLI | Input-constrained devices |

**Never** use Implicit flow (deprecated, token in URL fragment).

### PKCE flow

```
Client                    Auth Server
  |                           |
  |-- generate code_verifier |
  |   code_challenge =       |
  |   SHA256(code_verifier)  |
  |                           |
  |-- /authorize?             |
  |   response_type=code&     |
  |   code_challenge=...&     |
  |   code_challenge_method=S256
  |                           |
  |<- redirect with code ----|
  |                           |
  |-- /token                  |
  |   code=...&               |
  |   code_verifier=...       |
  |                           |
  |<- {access, id_token} ----|
```

### OIDC additional tokens

- **ID Token**: JWT with user identity claims (`sub`, `email`, `name`, `picture`)
- **UserInfo endpoint**: Additional profile data
- **Discovery document**: `/.well-known/openid-configuration`

## Authorization Models

### RBAC (Role-Based)

```sql
-- Core tables
CREATE TABLE roles (
    id UUID PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY,
    resource VARCHAR(100) NOT NULL,    -- e.g., "contacts", "deals"
    action VARCHAR(50) NOT NULL,       -- e.g., "read", "write", "delete"
    description TEXT,
    UNIQUE(resource, action)
);

CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id),
    permission_id UUID REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    tenant_id UUID NOT NULL,
    PRIMARY KEY (user_id, role_id, tenant_id)
);
```

### ABAC (Attribute-Based)

Evaluate policies based on attributes:
- **Subject**: user role, department, clearance level
- **Resource**: owner, classification, type
- **Action**: read, write, approve
- **Environment**: time, IP, device trust level

Policy example (rego/OPA):
```rego
allow {
    input.user.role == "manager"
    input.resource.type == "report"
    input.action == "read"
    input.user.department == input.resource.department
}
```

### ReBAC (Relationship-Based — Zanzibar/SpiceDB)

Model permissions as relationships:
```
document:readme#viewer@user:alice
document:readme#editor@group:eng
group:eng#member@user:bob
```

User `bob` has `viewer` access to `readme` through group membership.

Use when: complex inheritance, team-based access, document-level permissions.

## Multi-Tenancy Auth Patterns

### Shared database, shared schema

```sql
-- Every table includes tenant_id
CREATE TABLE contacts (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(255),
    email VARCHAR(255)
);

-- Enforce via row-level security (PostgreSQL)
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON contacts
    USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

### Tenant context propagation

1. JWT contains `tenant_id` claim
2. Middleware sets `SET app.current_tenant = '<tenant_id>'` on connection
3. RLS policy filters automatically
4. Application code never manually filters by tenant

### Permission inheritance

```
Organization → Workspace → Project → Resource
    ↓              ↓           ↓          ↓
  org_admin    ws_member    proj_viewer  custom
```

Each level can grant or restrict; most specific wins.

## Database Design for Auth

### Users table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255),           -- NULL for passwordless/social
    full_name VARCHAR(255),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ               -- soft delete
);
```

### Refresh tokens table

```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    token_hash VARCHAR(255) NOT NULL,     -- hash, never store raw
    family_id UUID NOT NULL,              -- for rotation detection
    device_info JSONB,
    ip_address INET,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ               -- NULL = active
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens(family_id);
CREATE INDEX idx_refresh_tokens_expiry ON refresh_tokens(expires_at);
```

### Audit log

```sql
CREATE TABLE auth_audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID,
    tenant_id UUID,
    event_type VARCHAR(50) NOT NULL,     -- login_success, login_failure, token_refresh, password_change, role_change
    ip_address INET,
    user_agent TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON auth_audit_log(user_id);
CREATE INDEX idx_audit_event ON auth_audit_log(event_type);
CREATE INDEX idx_audit_time ON auth_audit_log(created_at);
```

## Security Hardening Checklist

### Password auth
- [ ] Hash with argon2id (preferred) or bcrypt (cost ≥12)
- [ ] Enforce minimum password length (12+ chars)
- [ ] Check against breached password databases (HaveIBeenPwned k-anonymity)
- [ ] Rate limit login attempts (5/15min per user, 20/15min per IP)
- [ ] Account lockout after 10 failures (progressive lockout, not permanent)
- [ ] Generic error messages ("Invalid email or password", never "User not found")

### Token security
- [ ] Access tokens: short lifetime (5–15 min)
- [ ] Refresh tokens: httpOnly + Secure + SameSite cookies
- [ ] Refresh token rotation on every use
- [ ] Token family tracking for reuse detection
- [ ] Validate `iss`, `aud`, `exp`, `nbf` on every request
- [ ] Reject tokens with `none` algorithm

### API security
- [ ] CORS restricted to known origins
- [ ] CSRF protection for cookie-based auth
- [ ] Rate limiting on all auth endpoints
- [ ] Input validation and sanitization
- [ ] Security headers (CSP, HSTS, X-Content-Type-Options)
- [ ] No sensitive data in URLs or logs

### Secrets management
- [ ] Never commit secrets to version control
- [ ] Use environment variables or secret managers
- [ ] Rotate signing keys periodically
- [ ] Have a key rotation procedure (old key validates, new key signs)

## Anti-Patterns

| Anti-pattern | Why it's bad | Correct approach |
|--------------|--------------|------------------|
| JWT in localStorage | XSS can steal token | httpOnly cookie or memory |
| HS256 in microservices | Shared secret everywhere | RS256/ES256 with key distribution |
| No refresh token rotation | Stolen token valid forever | Rotate on every refresh |
| Auth checks only in frontend | Backend is unprotected | Always enforce server-side |
| Logging JWT tokens | Token exposure in logs | Log only token IDs or user IDs |
| Permanent account lockout | DoS via malicious lockouts | Progressive delays + unlock mechanism |
| `none` algorithm allowed | Token forgery | Whitelist allowed algorithms |
| Overly long access tokens | Token bloat, parsing issues | Minimal claims, separate ID token |
| No tenant isolation in multi-tenant | Data leakage | RLS + middleware enforcement |
| Password hints or questions | Weak recovery vector | Email-based reset with time-limited codes |

## Framework-Specific Notes

### Node.js / Express
- `express-jwt` or `jose` for JWT validation
- `helmet` for security headers
- `express-rate-limit` for rate limiting
- `cookie-parser` + `csurf` for CSRF protection

### Go
- `golang-jwt/jwt` for JWT
- `gorilla/sessions` for session management
- `golang.org/x/crypto/bcrypt` for hashing

### Python / Flask
- `PyJWT` or `authlib` for JWT/OAuth
- `flask-limiter` for rate limiting
- `flask-login` for session management
- `argon2-cffi` for password hashing

### Java / Spring
- Spring Security for comprehensive auth
- `jjwt` for JWT
- `spring-session` for distributed sessions

## Decision Questions

When the auth approach is unclear, ask the user:

1. "O sistema é monolito ou microserviços? Isso afeta se JWT é validado localmente ou via introspecção."
2. "Quantos tenants/organizações o sistema terá? Multi-tenancy exige isolamento desde o início."
3. "Os usuários são internos (equipe) ou externos (clientes)? Isso define SSO/SAML vs social login."
4. "Qual o nível de granularidade das permissões? RBAC simples ou precisa de ABAC/ReBAC?"
5. "Exigência de audit trail? Regulatórios (LGPD, SOC2) ou apenas operacional?"

## Output

When using this skill, produce:
1. Recommended auth architecture (method + justification)
2. Database schema with tables, indexes, and RLS policies
3. Token lifecycle design (issuance → validation → refresh → revocation)
4. Security threat model for the auth flow
5. Implementation code with tests
6. Migration plan if modifying existing auth
