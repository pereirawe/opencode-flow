---
name: owasp-asvs
description: OWASP Application Security Verification Standard (ASVS) 4.0 — chapter guidance, verification levels L1/L2/L3, and how to apply them to application security verification and review. Use when verifying applications against ASVS, mapping controls to verification levels, or deciding which ASVS level applies to an application.
---

# OWASP ASVS 4.0

The Application Security Verification Standard (ASVS) defines a set of
security requirements and verification levels for modern web applications and
web services. Use this skill to structure security verification and to map
findings to ASVS chapters and levels.

## Verification levels (L1/L2/L3)

| Level | Name | Applies to | Depth |
|-------|------|------------|-------|
| L1 | Opportunistic | All applications — baseline | Low effort, automated + manual checks for easily discoverable weaknesses (injection, XSS, broken auth, secrets) |
| L2 | Standard | Applications handling sensitive data, business-critical, regulated (e.g. PCI DSS, GDPR) | Most controls; requires authenticated testing, secure design review |
| L3 | Advanced | High-value targets: financial, healthcare, military, critical infrastructure | All controls; defense-in-depth, source code review, penetration testing |

How to choose:

- **L1**: every application must meet L1 before release.
- **L2**: required when the app stores/processes sensitive data, is
  business-critical, or is subject to compliance obligations.
- **L3**: reserved for applications whose compromise would have catastrophic
  impact (money movement, PII at scale, public safety).

## Chapter map (V1–V14 + V15 in 4.0.3)

| Chapter | Title | Key controls to verify |
|---------|-------|------------------------|
| V1 | Architecture, Design and Threat Modeling | Secure SDLC, threat models, component inventory, trust boundaries, security controls placement |
| V2 | Authentication | Password policies, MFA, credential storage, account lockout, authentication bypass |
| V3 | Session Management | Session ID security, expiry, rotation on privilege change, logout semantics |
| V4 | Access Control | Authorization models, IDOR prevention, least privilege, function-level controls |
| V5 | Validation, Sanitization and Encoding | Input validation, output encoding, injection defense (SQL/XSS/OS/LDAP) |
| V6 | Stored Cryptography | Key management, algorithm selection, random values, secret handling |
| V7 | Cryptography at Rest | Data-at-rest protection, encryption for sensitive fields |
| V8 | Communication Security | TLS configuration, certificate validation, transport security |
| V9 | Malicious Code | Self-XSS, code integrity, unauthorized code execution |
| V10 | Business Logic | Business-flow abuse, race conditions, anti-automation, currency rounding |
| V11 | Data Protection | Sensitive data inventory, minimization, PII protection, retention |
| V12 | File and Resources | File upload validation, path traversal, SSRF, resource limits |
| V13 | API and Web Service | REST/graphQL contract security, schema validation, rate limiting |
| V14 | Configuration | Server hardening, headers, error handling, CORS, logging |
| V15 (4.0.3+) | Web Frontend Security | Client-side controls, DOM XSS, SPA security |

## Verification approach

1. **Determine the target level** (L1/L2/L3) from the application's data
   sensitivity and business criticality.
2. **Scope**: verify every chapter relevant to the app's attack surface
   (skip chapters not applicable — e.g. V7 for apps with no data at rest).
3. **For each control**: verify requirement exists, implementation is correct,
   and it resists the attack it is designed to stop.
4. **Record**: map each finding to chapter + requirement ID (e.g. `V2.1.1`),
   level it applies to, and severity.

## Output format

1. Target level (L1/L2/L3) and rationale
2. Per chapter: status (pass / fail / not applicable)
3. Findings mapped as `V<chapter>.<section>.<req>` with severity
4. Level-gating note: a failure at the target level blocks approval if
   critical/high
