# OWASP Top 10 (2021) — Grep-Pattern Catalog

> Reference catalog for `/blox:secure` Step 1 (OWASP Top 10 Review).
> For each category: what to scan for, how to check it (grep guidance), and
> finding severity. Severity scale: CRITICAL, HIGH, MEDIUM, LOW, INFO.
> Check every category in order, even if N/A for some.

## A01: Broken Access Control

```
SCAN FOR:
  - Endpoints without authorization middleware
  - Direct object references (user IDs in URLs without ownership check)
  - Missing role-based access control (RBAC)
  - Privilege escalation paths (user accessing admin endpoints)
  - CORS misconfiguration (wildcard origins, missing credentials flag)
  - Directory traversal in file access (../ in user-supplied paths)
  - Missing HTTP method restrictions (GET vs POST enforcement)

HOW TO CHECK:
  - grep for route definitions -> verify auth middleware applied
  - grep for req.params.id, req.query.id -> verify ownership check
  - grep for CORS config -> verify origin whitelist, not '*'
  - grep for file read/write operations -> verify path sanitization
  - grep for role/permission checks -> verify on every protected route

FINDING SEVERITY:
  - No auth on sensitive endpoints -> CRITICAL
  - Missing ownership check -> HIGH
  - CORS wildcard on API with credentials -> HIGH
  - Missing role check on admin routes -> CRITICAL
  - Directory traversal possible -> CRITICAL
```

## A02: Cryptographic Failures

```
SCAN FOR:
  - Weak hashing algorithms (MD5, SHA1 for passwords)
  - Missing encryption for sensitive data at rest
  - HTTP (not HTTPS) for sensitive data in transit
  - Weak or default encryption keys
  - Sensitive data in logs (passwords, tokens, PII in console.log/print)
  - Cookies without Secure/HttpOnly/SameSite flags

HOW TO CHECK:
  - grep for md5, sha1 in password contexts
  - grep for bcrypt, argon2, scrypt -> should be used for passwords
  - grep for console.log, print, logger -> check for sensitive data
  - grep for cookie settings -> verify Secure, HttpOnly, SameSite flags
  - grep for encryption -> verify AES-256 or equivalent

FINDING SEVERITY:
  - MD5/SHA1 for password hashing -> CRITICAL
  - Sensitive data in logs -> HIGH
  - Cookies without Secure/HttpOnly -> MEDIUM
  - No encryption at rest for PII -> HIGH
```

## A03: Injection

```
SCAN FOR:
  - SQL injection: raw SQL with string concatenation/interpolation
  - NoSQL injection: unsanitized user input in MongoDB queries
  - Command injection: unsafe process invocation with user input
  - XSS: innerHTML, dangerouslySetInnerHTML, v-html with user data
  - LDAP injection: unsanitized user input in LDAP queries
  - Template injection: user input in server-side template strings
  - Code injection: dynamic code evaluation with user-controlled input

HOW TO CHECK:
  - grep for raw SQL (SELECT, INSERT, UPDATE, DELETE) with template literals
  - grep for unsafe process invocation functions -> check for user input
  - grep for innerHTML, dangerouslySetInnerHTML -> check for user data
  - grep for $where, $regex in MongoDB queries with user input
  - Verify ORM/parameterized queries are used everywhere

FINDING SEVERITY:
  - SQL injection possible -> CRITICAL
  - Command injection possible -> CRITICAL
  - XSS in user-generated content -> HIGH
  - NoSQL injection -> HIGH
  - Template injection -> CRITICAL
  - Dynamic code evaluation with user input -> CRITICAL
```

## A04: Insecure Design

```
SCAN FOR:
  - Missing rate limiting on auth endpoints
  - No account lockout after failed attempts
  - Password reset without proper token validation
  - Missing CAPTCHA on public forms
  - Business logic that trusts client-side validation only
  - Missing input length limits

HOW TO CHECK:
  - grep for rate-limit, rateLimit, throttle -> verify on auth routes
  - Check login endpoint for attempt counting/lockout logic
  - Check password reset flow for token expiry and single-use
  - Check forms for server-side validation (not just client-side)

FINDING SEVERITY:
  - No rate limiting on login -> HIGH
  - No account lockout -> MEDIUM
  - Client-side only validation -> MEDIUM
  - Missing input length limits -> LOW
```

## A05: Security Misconfiguration

```
SCAN FOR:
  - Debug mode enabled in production configs
  - Default credentials in configuration
  - Verbose error messages exposed to users (stack traces)
  - Unnecessary HTTP headers (X-Powered-By, Server)
  - Directory listing enabled
  - Default/sample files in production

HOW TO CHECK:
  - grep for DEBUG=true, NODE_ENV=development in production configs
  - grep for admin/admin, password123, default in config files
  - Check error handlers -> verify they don't expose stack traces
  - Check HTTP response headers for information leakage
  - Check for README.md, CHANGELOG.md exposed via web server

FINDING SEVERITY:
  - Debug mode in production -> HIGH
  - Default credentials -> CRITICAL
  - Stack traces exposed -> MEDIUM
  - Information leakage headers -> LOW
```

## A06: Vulnerable and Outdated Components

```
SCAN FOR:
  - Known vulnerable dependencies
  - Outdated packages with security patches available
  - Unmaintained dependencies (no updates in 2+ years)
  - Dependencies with known CVEs

HOW TO CHECK:
  -> Delegated to Step 2 (Dependency Scan) for detailed analysis
  - Note: This OWASP category overlaps with Step 2 — list here, detail there

FINDING SEVERITY:
  - Critical CVE in dependency -> CRITICAL
  - High CVE in dependency -> HIGH
  - Outdated but no known CVE -> LOW
```

## A07: Identification and Authentication Failures

```
SCAN FOR:
  - Weak password requirements (no length, complexity check)
  - Tokens stored in localStorage (XSS-accessible)
  - Missing token expiration
  - Session fixation vulnerabilities
  - Missing MFA for sensitive operations
  - Credentials transmitted without encryption

HOW TO CHECK:
  - grep for password validation -> check min length (>= 8), complexity
  - grep for localStorage.setItem with token/jwt/session
  - grep for token expiry settings -> verify reasonable expiration
  - Check session handling -> verify session ID changes after login
  - Check for TLS/HTTPS enforcement

FINDING SEVERITY:
  - Tokens in localStorage -> HIGH
  - No password requirements -> MEDIUM
  - Missing token expiration -> HIGH
  - No session renewal after login -> MEDIUM
```

## A08: Software and Data Integrity Failures

```
SCAN FOR:
  - Deserialization of untrusted data (unsafe parsing of user-controlled input,
    pickle.loads, unsafe YAML.load)
  - Missing integrity checks on downloaded resources (no SRI, no checksum)
  - CI/CD pipeline without signed commits or verified sources
  - Auto-update mechanisms without signature verification
  - Dynamic code evaluation with user-controllable input

HOW TO CHECK:
  - grep for pickle.loads, yaml.load (unsafe), unserialize()
  - Check CDN includes for SRI (integrity="sha256-...") attributes
  - Check CI/CD config for pinned action versions (not @main/@latest)
  - grep for JSON.parse -> verify input source is trusted

FINDING SEVERITY:
  - Unsafe deserialization with user input -> CRITICAL
  - Missing SRI on CDN resources -> MEDIUM
  - Unpinned CI/CD actions -> MEDIUM
  - Dynamic code evaluation with user input -> CRITICAL
```

## A09: Security Logging and Monitoring Failures

```
SCAN FOR:
  - Missing logging for auth events (login, logout, failed attempts)
  - Missing logging for access control failures
  - No structured logging format (hard to analyze)
  - Sensitive data in log entries (passwords, tokens, PII)
  - No log rotation or retention policy
  - Missing alerting for security events

HOW TO CHECK:
  - grep for login/auth handlers -> verify logging present
  - grep for 401/403 responses -> verify failure logging
  - grep for console.log vs structured logger (winston, pino, loguru)
  - grep log entries for password, token, secret patterns

FINDING SEVERITY:
  - No auth event logging -> MEDIUM
  - Sensitive data in logs -> HIGH
  - No structured logging -> LOW
  - No failure alerting -> MEDIUM
```

## A10: Server-Side Request Forgery (SSRF)

```
SCAN FOR:
  - User-supplied URLs used in server-side HTTP requests
  - URL redirect based on user input without allowlist
  - Webhook URLs without validation
  - Image/file download from user-supplied URLs

HOW TO CHECK:
  - grep for fetch, axios, requests.get with dynamic URLs
  - grep for redirect with user-controllable destination
  - grep for webhook URL configuration -> verify allowlist
  - Check URL validation -> verify protocol and host restrictions

FINDING SEVERITY:
  - SSRF with unrestricted URL -> CRITICAL
  - Open redirect -> MEDIUM
  - Webhook without URL validation -> HIGH
```
