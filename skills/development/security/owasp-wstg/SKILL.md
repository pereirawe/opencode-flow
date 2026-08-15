---
name: owasp-wstg
description: OWASP Web Security Testing Guide (WSTG) — testing categories and concrete test cases per category, with technique and expected result. Use when performing manual web application security testing, planning penetration test coverage, or deriving test scenarios for specific vulnerability classes.
---

# OWASP WSTG

The Web Security Testing Guide (WSTG) is the de facto standard for manual web
application security testing. Use this skill to plan test coverage and to run
concrete test cases per vulnerability class.

## Testing categories

| ID | Category | What it covers |
|----|----------|----------------|
| WSTG-INFO | Information Gathering | Recon, fingerprinting, search engine discovery, exposed files, error codes |
| WSTG-CONF | Configuration and Deployment | Network infrastructure, platform/application config, file extensions, old/backup files, HTTP methods, headers |
| WSTG-IDNT | Identity Management | Role definitions, user registration, account enumeration, weak/unenforceable policies |
| WSTG-ATHN | Authentication | Credentials transport, default credentials, weak lockout, bypass, remember-password, browser cache, logout, password reset, CAPTCHA |
| WSTG-ATHZ | Authorization | Path traversal, privilege escalation (horizontal/vertical), IDOR, missing function-level access control |
| WSTG-SESS | Session Management | Session ID entropy, fixation, cookie flags, CSRF, logout, session puzzle, SSO/remember-me |
| WSTG-INPV | Input Validation | Reflected/stored/DOM XSS, HTTP parameter pollution, SQL/NoSQL/LDAP/OS/XML injection, SSRF, command injection, template injection |
| WSTG-ERRH | Error Handling | Error codes, stack traces, verbose error disclosure |
| WSTG-CRYP | Cryptography | Weak TLS, weak encryption, sensitive data in transit |
| WSTG-BUSL | Business Logic | Business limit bypass, anti-automation, process timing, function ordering, integrity, payment tampering |
| WSTG-CLNT | Client-side | DOM-based XSS, JavaScript execution, HTML5 storage, cross-origin resource sharing, client-side SQLi, postmessage, browser API abuse |
| WSTG-APIT | API Testing | API discovery, endpoint authentication, HTTP methods, JSON injection, rate limiting, error handling |

## Representative test cases per category

| Category | Test case | Technique / evidence |
|----------|-----------|----------------------|
| WSTG-INFO | Directory/filename enumeration | Crawl for backup files, `.git/`, `.env`, `robots.txt`, admin panels |
| WSTG-CONF | HTTP methods allowed | `OPTIONS *`; verify PUT/DELETE/TRACE not exposed |
| WSTG-CONF | Security headers | Check HSTS, CSP, X-Frame-Options, X-Content-Type-Options |
| WSTG-IDNT | Account enumeration | Timing/response-difference analysis on login and password reset |
| WSTG-ATHN | Default/weak credentials | Attempt common defaults; test password policy strength |
| WSTG-ATHN | Authentication bypass | Modify cookies, JWT alg, session tokens; test SQLi on auth |
| WSTG-ATHZ | IDOR | Replace object IDs in URLs/params across user contexts |
| WSTG-ATHZ | Path traversal | `../../etc/passwd`, URL-encoded variants, null bytes |
| WSTG-SESS | Session fixation/entropy | Set session before login; analyze session ID randomness |
| WSTG-SESS | CSRF | Craft cross-origin form/request with no token and observe state change |
| WSTG-INPV | SQL injection | `' OR 1=1--`, time-based and error-based payloads |
| WSTG-INPV | XSS | `<script>`, event handlers, SVG payloads; reflected, stored, DOM |
| WSTG-INPV | SSRF | Point internal URLs at 127.0.0.1/metadata endpoints; test scheme/file redirects |
| WSTG-ERRH | Verbose errors | Trigger errors, capture stack traces, SQL errors, framework dumps |
| WSTG-CRYP | Weak TLS | Test protocol versions, cipher suites, cert validation |
| WSTG-BUSL | Business limit bypass | Repeated operations without limits; negative/zero quantities |
| WSTG-CLNT | DOM XSS | Inspect client-side sinks (`innerHTML`, `eval`, `document.write`) and source flows |
| WSTG-APIT | Rate limiting / auth | Call API endpoints without token; burst requests beyond limits |

## Execution guidance

1. **Plan**: select categories based on the application's attack surface and
   the target ASVS level.
2. **Test**: run the representative test cases above; adapt payloads to the
   tech stack (language, framework, DB, ORM).
3. **Record**: for each finding — category ID, test case, evidence
   (request/response), severity, and remediation.
4. **Scope discipline**: only test what is in scope; never perform
   destructive actions against production without authorization.

## Output format

1. Test plan (categories selected + rationale)
2. Per category: executed tests, results (pass/fail/inconclusive)
3. Findings with WSTG-ID references and severity
