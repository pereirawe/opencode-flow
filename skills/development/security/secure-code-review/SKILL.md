---
name: secure-code-review
description: Secure code review checklist and severity classification — injection, auth, access control, crypto, secrets, SSRF, deserialization, file handling, error handling, logging, and dependency review. Use when reviewing code for security vulnerabilities, classifying findings by severity, or producing a security review report.
---

# Secure Code Review

Structured checklist for reviewing code with a security focus. Use this skill
when acting as security reviewer (profile `security`) or auditing code.

## Review checklist

### Input validation and injection (OWASP A03)

- [ ] All external input is validated (type, length, charset, range) server-side
- [ ] SQL/NoSQL queries use parameterization or an ORM — no string concatenation
- [ ] OS commands are not built from user input; no shell interpolation
- [ ] Output is encoded for the correct context (HTML, attribute, JS, URL)
- [ ] Template injection and expression injection surfaces are closed
- [ ] File paths derived from user input are canonicalized and contained

### Authentication and session (OWASP A07)

- [ ] Passwords stored with a strong adaptive hash (argon2id, bcrypt, scrypt)
- [ ] MFA supported for privileged/administrative accounts
- [ ] Session IDs are random, HttpOnly, Secure, SameSite; rotated on privilege change
- [ ] Account lockout / rate limiting on authentication endpoints
- [ ] No hardcoded credentials, default passwords, or backdoors (CWE-798)

### Access control (OWASP A01)

- [ ] Authorization checked on every endpoint/function (server-side), not only UI
- [ ] Object-level access control prevents IDOR (CWE-639)
- [ ] Least privilege: role/scope checks, function-level controls (CWE-862)
- [ ] Mass assignment / over-posting of unexpected fields is prevented

### Cryptography (OWASP A02)

- [ ] TLS enforced; no weak protocols/ciphers; certs validated
- [ ] Data at rest encrypted with modern algorithms (AES-256-GCM etc.)
- [ ] No weak/predictable randomness (CWE-330) for security-sensitive values
- [ ] Keys/secrets managed via secret manager, never in code or config (CWE-798)
- [ ] Hash/signature verification uses secure comparison (CWE-347)

### SSRF (OWASP A10)

- [ ] User-supplied URLs validated against an allowlist of schemes/hosts
- [ ] Private/loopback/link-local ranges blocked (CWE-918)
- [ ] Redirects followed with restrictions; no file:// or metadata endpoints

### Deserialization and integrity (OWASP A08)

- [ ] No unsafe deserialization (CWE-502); object-type allowlists when needed
- [ ] Signed/verified artifacts and updates (CWE-345)
- [ ] CI/CD pipeline trust: no untrusted code execution in builds

### Files and resources (OWASP A05)

- [ ] Upload validation: type sniffing, size limits, content inspection, safe storage
- [ ] Path traversal and zip-slip prevented
- [ ] Resource limits prevent DoS (payload size, concurrency, timeouts)

### Error handling and logging (OWASP A09)

- [ ] No sensitive data in error messages or stack traces (CWE-209)
- [ ] Security events logged (auth, authorization failures, admin actions)
- [ ] Logs do not contain secrets, PII, or tokens (CWE-532)

### Dependencies (OWASP A06)

- [ ] Third-party dependencies inventoried and free of known critical/high CVEs
- [ ] Lockfiles used and dependency update policy in place

## Severity classification

| Severity | Definition |
|----------|------------|
| critical | Remotely exploitable without significant preconditions; data breach, RCE, auth bypass, or full compromise |
| high | Likely exploitable; significant confidentiality/integrity/availability impact |
| medium | Exploitable under preconditions or with limited impact |
| low | Defense-in-depth / hardening gap with marginal impact |
| nit | Style or robustness suggestion without security impact |

**Blocking rule**: any critical or high finding blocks approval of the
review. Report with evidence and remediation. The review is NOT approved
until they are resolved.

## Report format

For each finding:

1. Severity (critical/high/medium/low/nit)
2. Location (file:line, endpoint, or component)
3. Vulnerability class (OWASP category + CWE)
4. Evidence (code excerpt, request/response)
5. Exploitation scenario (how it can be abused)
6. Remediation (concrete, actionable fix)

## Verification guidance

- Prefer `scripts/test-runner.sh --check` (via the `test-runner` skill) to
  confirm tests pass; fresh cache suffices. Do not re-run an unchanged suite.
- Missing business rules are `incomplete-spec`, NOT bugs (see
  standards/code-review.md) — register a new issue for discovery refinement.
