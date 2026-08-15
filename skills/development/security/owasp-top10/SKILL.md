---
name: owasp-top10
description: OWASP Top 10 (2021) web application security risks — categories, CWE mapping table, risk factors, detection guidance, and mitigation. Use when reviewing or auditing web application security, classifying vulnerabilities, or mapping findings to OWASP Top 10 categories and CWEs.
---

# OWASP Top 10 (2021)

Reference framework for the most critical web application security risks.
Use this skill to classify findings, map them to CWE IDs, and recommend
mitigations aligned with the OWASP Top 10 (2021).

## The ten categories

| # | Category | Description (short) |
|---|----------|---------------------|
| A01 | Broken Access Control | Restrictions on authenticated users are not properly enforced |
| A02 | Cryptographic Failures | Weak or missing cryptography for data at rest or in transit |
| A03 | Injection | Untrusted data sent to an interpreter (SQL, NoSQL, OS, LDAP) |
| A04 | Insecure Design | Missing or ineffective security design controls |
| A05 | Security Misconfiguration | Insecure defaults, verbose errors, open storage, misconfigured headers |
| A06 | Vulnerable and Outdated Components | Known-vulnerable or outdated libraries and components |
| A07 | Identification and Authentication Failures | Broken auth, weak credentials, missing MFA, session issues |
| A08 | Software and Data Integrity Failures | CI/CD trust, deserialization, unsigned updates, tampered data |
| A09 | Security Logging and Monitoring Failures | Missing or insufficient logging, detection, and response |
| A10 | Server-Side Request Forgery (SSRF) | Server fetches attacker-controlled URLs without validation |

## CWE mapping by category (2021)

Official mapping from the OWASP Top 10 (2021) document. Use the CWE IDs to
reference findings precisely.

| OWASP category | Mapped CWEs |
|----------------|-------------|
| A01 Broken Access Control | CWE-200, CWE-201, CWE-352, CWE-425, CWE-538, CWE-639, CWE-862, CWE-863 |
| A02 Cryptographic Failures | CWE-261, CWE-296, CWE-310, CWE-319, CWE-321, CWE-322, CWE-323, CWE-324, CWE-325, CWE-326, CWE-327, CWE-328, CWE-329, CWE-330, CWE-331, CWE-335, CWE-336, CWE-337, CWE-338, CWE-340, CWE-347, CWE-523, CWE-720, CWE-757 |
| A03 Injection | CWE-74, CWE-75, CWE-77, CWE-78, CWE-88, CWE-89, CWE-90, CWE-91, CWE-209, CWE-346, CWE-359, CWE-943 |
| A04 Insecure Design | CWE-1188, CWE-1357 |
| A05 Security Misconfiguration | CWE-16, CWE-209, CWE-213, CWE-266, CWE-388, CWE-402, CWE-538, CWE-550, CWE-560, CWE-598, CWE-732, CWE-749, CWE-770, CWE-1004 |
| A06 Vulnerable and Outdated Components | CWE-937, CWE-1035 |
| A07 Identification and Authentication Failures | CWE-255, CWE-259, CWE-287, CWE-288, CWE-290, CWE-294, CWE-295, CWE-297, CWE-300, CWE-302, CWE-304, CWE-306, CWE-307, CWE-346, CWE-384, CWE-521, CWE-613, CWE-620, CWE-640, CWE-798 |
| A08 Software and Data Integrity Failures | CWE-345, CWE-353, CWE-426, CWE-494, CWE-502, CWE-565, CWE-784, CWE-829, CWE-830 |
| A09 Security Logging and Monitoring Failures | CWE-117, CWE-223, CWE-532, CWE-778 |
| A10 Server-Side Request Forgery | CWE-918 |

## Risk factors

| Factor | Notes |
|--------|-------|
| Exploitability | Ease of exploiting the vulnerability |
| Prevalence | How common the weakness is in production code |
| Detectability | How easy it is to discover the weakness |
| Technical impact | Data loss, compromise, availability impact |
| Business impact | Direct consequence to the business and users |

## Detection guidance

- **Access control**: test IDORs (CWE-639), missing function-level controls
  (CWE-862), forced browsing, path traversal (CWE-425).
- **Crypto**: check for HTTP, weak ciphers, hardcoded secrets (CWE-798),
  missing TLS, weak hashing (CWE-326/327), non-random values (CWE-330).
- **Injection**: test all interpreter boundaries — SQL (CWE-89), OS command
  (CWE-78), LDAP (CWE-90), XPath (CWE-643 — see ASVS V5), template injection.
- **Design**: review threat models, trust boundaries, rate limits, and
  fail-safe defaults (CWE-1357).
- **Misconfiguration**: verbose errors (CWE-209), open cloud storage
  (CWE-538), missing security headers, default credentials.
- **Components**: inventory third-party deps, scan for known CVEs, check
  patch cadence.
- **Auth**: weak password policy, missing MFA, credential stuffing, session
  fixation, weak session IDs (CWE-384).
- **Integrity**: verify CI/CD pipeline trust, signed artifacts, safe
  deserialization (CWE-502).
- **Logging**: audit trails, anomaly detection, alerting coverage.
- **SSRF**: validate URLs, block private ranges, enforce egress allowlists
  (CWE-918).

## Output format

When using this skill, classify each finding as:

1. OWASP category (A01–A10)
2. CWE ID(s)
3. Severity (critical/high/medium/low/nit)
4. Evidence (file, line, request/response when applicable)
5. Mitigation aligned with the category guidance
