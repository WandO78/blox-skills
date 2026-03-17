---
name: blox-secure
description: "Security audit — OWASP Top 10, dependency scan, secrets detection, auth review. Basic: checklist review. Premium: real-time detection with security-guidance plugin."
user-invocable: true
argument-hint: "[scope or focus area]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(security findings, severity ratings, remediation steps, report text) MUST be
written in the user's language. The skill logic instructions below are in English
for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Project identity: !`head -20 CLAUDE.md 2>/dev/null`
- Tech stack: !`cat package.json 2>/dev/null | head -5 || cat requirements.txt 2>/dev/null | head -5 || cat Cargo.toml 2>/dev/null | head -5`
- Auth files: !`find . -maxdepth 4 -name "*auth*" -o -name "*session*" -o -name "*csrf*" -o -name "*token*" 2>/dev/null | grep -v node_modules | grep -v .git | head -10`
- Environment files: !`ls .env .env.* .env.example 2>/dev/null`
- Gitignore coverage: !`grep -i "env\|secret\|key\|credential" .gitignore 2>/dev/null`
- Dependency audit: !`npm audit --json 2>/dev/null | head -20 || pip audit --format=json 2>/dev/null | head -20 || echo "No audit tool detected"`
- Active phase: !`grep -l ">>> CURRENT <<<" plans/PHASE_*.md 2>/dev/null`

# /blox:secure

> **Purpose:** Run a structured security audit against the OWASP Top 10, scan
> dependencies for known vulnerabilities, detect hardcoded secrets, review
> authentication and authorization patterns, and produce an actionable security
> report with severity ratings and remediation steps. Basic mode performs
> checklist-based code review; premium mode (security-guidance plugin) adds
> real-time PreToolUse hook detection for ongoing protection.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-secure
category: domain
complements: [blox-check, blox-build, blox-deploy]

### Triggers — when the agent invokes automatically
trigger_keywords: [security, audit, OWASP, vulnerability, secrets, auth, injection, XSS, CSRF, biztonsag]
trigger_files: [.env, .env.example, docker-compose.yml, Dockerfile]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when a security audit is needed: before deployment, after adding
  authentication, after introducing new API endpoints, or at any phase
  that touches security-sensitive code. Produces a structured security report
  with OWASP Top 10 coverage, dependency vulnerability scan, secrets detection,
  and auth/authz review.
  Do NOT use for general code quality review (use /blox:check), for fixing
  bugs (use /blox:fix), or for deployment itself (use /blox:deploy).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Pre-deployment security check | "Run a security audit before we deploy" | No — user invokes |
| `/blox:idea` autopilot Hardening phase | Idea pipeline chains to secure for security phase | Yes — idea calls it |
| New auth system added | "We just added JWT auth — check for issues" | No — user invokes |
| New API endpoints created | "Review the new payment endpoints for security" | No — user invokes |
| Periodic security review | "Run a security check on the codebase" | No — user invokes |
| Post-incident review | "We had a security issue — audit everything" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| General code quality review | Quality, not security | `/blox:check` |
| Bug fixing | Debugging, not auditing | `/blox:fix` |
| Deployment | Deploy, not audit | `/blox:deploy` |
| Brand/design review | Different domain | `/blox:brand` or `/blox:design` |
| No code exists yet | Nothing to audit | `/blox:plan` |

---

## BASIC vs PREMIUM MODE

The skill auto-detects available plugins and adjusts its capabilities:

| Feature | Basic (no plugin) | Premium (security-guidance plugin) |
|---------|-------------------|-------------------------------------|
| OWASP review | Manual code review against checklist | Automated pattern matching |
| Dependency scan | `npm audit` / `pip audit` / `cargo audit` | Enhanced CVE database + fix suggestions |
| Secrets detection | Regex pattern scanning | Real-time PreToolUse hook blocks secrets from being committed |
| Auth review | Manual pattern review | Automated auth flow analysis |
| Ongoing protection | One-time audit | Continuous PreToolUse/PostToolUse hooks |
| Report | Markdown report | Markdown report + live monitoring |

**Plugin detection (runs at start):**
```
IF security-guidance plugin installed:
  -> Enable real-time detection hooks (PreToolUse blocks unsafe patterns)
  -> Enable enhanced CVE database lookup
  -> Note: "Security guidance plugin detected — enhanced mode active"

IF no plugin:
  -> Basic mode — full OWASP checklist review, all scans work
  -> Note: "Running in basic mode — full security audit included"
```

---

## SKILL LOGIC

> **5-step security audit pipeline.** Each step produces findings with severity
> ratings. Step 5 assembles the final report. All findings use the same
> severity scale: CRITICAL, HIGH, MEDIUM, LOW, INFO.

### Step 1: OWASP Top 10 Review

> **Goal:** Systematically check the codebase against each OWASP Top 10 (2021) category.
> For each category, scan relevant files, identify patterns, and classify findings.

**Check each category in order:**

#### A01: Broken Access Control

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

#### A02: Cryptographic Failures

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

#### A03: Injection

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

#### A04: Insecure Design

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

#### A05: Security Misconfiguration

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

#### A06: Vulnerable and Outdated Components

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

#### A07: Identification and Authentication Failures

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

#### A08: Software and Data Integrity Failures

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

#### A09: Security Logging and Monitoring Failures

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

#### A10: Server-Side Request Forgery (SSRF)

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

**Output from Step 1:** A table of findings per OWASP category with severity, affected files, and line references.

---

### Step 2: Dependency Scan

> **Goal:** Run the appropriate dependency audit tool and report known vulnerabilities.

**Auto-detect and run the correct tool:**

```
IF package.json exists (Node.js):
  -> Run: npm audit --json 2>/dev/null || yarn audit --json 2>/dev/null
  -> Parse output for: severity (critical, high, moderate, low), package name,
     CVE ID, fixed version
  -> Also check: npx audit-ci (if available) for CI-friendly output

IF requirements.txt or pyproject.toml exists (Python):
  -> Run: pip audit 2>/dev/null || safety check 2>/dev/null
  -> Parse output for: package name, installed version, fixed version, CVE ID

IF Cargo.toml exists (Rust):
  -> Run: cargo audit 2>/dev/null
  -> Parse output for: crate name, advisory ID, severity

IF go.mod exists (Go):
  -> Run: govulncheck ./... 2>/dev/null
  -> Parse output for: package, vulnerability ID, description

IF Gemfile exists (Ruby):
  -> Run: bundle audit check 2>/dev/null
  -> Parse output for: gem name, advisory, severity

IF none of the above:
  -> Note: "No supported package manager detected — skipping dependency scan"
```

**If audit tool is not installed:**
- Note which tool is needed: "Install `npm audit` / `pip-audit` / `cargo-audit` for dependency scanning"
- Continue with other steps — do NOT block

**Output format:**

```
## Dependency Scan
- Package manager: [npm / pip / cargo / go / gem]
- Tool: [npm audit / pip-audit / cargo audit / ...]
- Total vulnerabilities: [N]
  - Critical: [N]
  - High: [N]
  - Medium: [N]
  - Low: [N]

| Package | Installed | Fixed In | Severity | CVE | Description |
|---------|-----------|----------|----------|-----|-------------|
| lodash  | 4.17.15   | 4.17.21  | HIGH     | CVE-2021-23337 | Prototype pollution |
```

**Remediation:** For each vulnerability, include:
- The exact command to fix (`npm audit fix`, `pip install --upgrade [pkg]`)
- Whether the fix is a breaking change (major version bump)
- If no fix available: note the workaround or mitigation

---

### Step 3: Secrets Detection

> **Goal:** Scan the codebase for hardcoded secrets, API keys, passwords, and tokens.
> Also verify .gitignore covers sensitive files.

**Pattern scanning — search for these patterns in ALL source files:**

```
PATTERNS (regex — scan all non-binary, non-node_modules files):

API Keys:
  - /[A-Z0-9_]*(API_KEY|APIKEY|API_SECRET)[A-Z0-9_]*\s*[:=]\s*['"]\S+/i
  - /sk[-_](live|test)[-_][a-zA-Z0-9]{20,}/  (Stripe)
  - /AIza[0-9A-Za-z\-_]{35}/  (Google API)
  - /AKIA[0-9A-Z]{16}/  (AWS Access Key)
  - /ghp_[a-zA-Z0-9]{36}/  (GitHub token)
  - /xox[bpras]-[a-zA-Z0-9-]+/  (Slack token)

Passwords:
  - /password\s*[:=]\s*['"][^'"]{3,}/i  (excluding .env.example with placeholders)
  - /passwd\s*[:=]\s*['"][^'"]{3,}/i

Connection strings:
  - /mongodb(\+srv)?:\/\/[^'"]+:[^'"]+@/  (MongoDB with credentials)
  - /postgres(ql)?:\/\/[^'"]+:[^'"]+@/  (PostgreSQL with credentials)
  - /mysql:\/\/[^'"]+:[^'"]+@/  (MySQL with credentials)
  - /redis:\/\/:[^'"]+@/  (Redis with password)

Private keys:
  - /-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----/
  - /-----BEGIN OPENSSH PRIVATE KEY-----/

JWT secrets:
  - /jwt[-_]?secret\s*[:=]\s*['"][^'"]{8,}/i
  - /secret[-_]?key\s*[:=]\s*['"][^'"]{8,}/i

Generic tokens:
  - /token\s*[:=]\s*['"][a-zA-Z0-9\-_.]{20,}['"]/i
  - /bearer\s+[a-zA-Z0-9\-_.]{20,}/i
```

**Exclusions (reduce false positives):**
- Ignore files in: node_modules/, .git/, vendor/, dist/, build/, __pycache__/
- Ignore .env.example files with placeholder values like `YOUR_KEY_HERE`, `changeme`, `xxx`
- Ignore test fixtures with obviously fake values (test_secret, mock_token)
- Ignore comments that describe patterns without containing real values

**Gitignore verification:**

```
CHECK .gitignore covers:
  - [ ] .env (and all .env.* variants except .env.example)
  - [ ] *.pem, *.key (private key files)
  - [ ] credentials.json, service-account.json
  - [ ] .aws/, .gcloud/ (cloud credentials)
  - [ ] *.sqlite, *.db (local databases with potential PII)

IF .gitignore does not exist:
  -> CRITICAL finding: "No .gitignore — all files could be committed including secrets"

IF .gitignore exists but missing patterns:
  -> MEDIUM finding: list each missing pattern
```

**Git history check (if git repo):**

```
Search recent commits for accidentally committed secrets:
  git log --diff-filter=A --name-only --format="" -- "*.env" "*.pem" "*.key" 2>/dev/null
  git log -p --all -S "password" -S "secret" -S "api_key" -- "*.ts" "*.js" "*.py" 2>/dev/null | head -50

IF found:
  -> HIGH finding: "Secret was committed to git history — even if removed from
     current files, it exists in history. Use git filter-branch or BFG Repo Cleaner
     to purge, then rotate ALL affected credentials."
```

**Output format:**

```
## Secrets Detection
- Files scanned: [N]
- Secrets found: [N]
- .gitignore coverage: [PASS / PARTIAL / MISSING]

| # | Type | File | Line | Pattern | Severity |
|---|------|------|------|---------|----------|
| 1 | AWS Key | src/config.ts | 42 | AKIA... (redacted) | CRITICAL |
| 2 | Missing .gitignore | .gitignore | — | .env.local not covered | MEDIUM |
```

---

### Step 4: Auth/Authz Review

> **Goal:** Review authentication and authorization patterns for common weaknesses.
> Focus on token handling, session management, CSRF protection, and permission models.

**Authentication review:**

```
CHECK TOKEN HANDLING:
  - Where are tokens stored? (localStorage = BAD, httpOnly cookie = GOOD)
  - Token expiration: access token < 15 min, refresh token < 7 days
  - Token refresh mechanism: is there one? Is it secure?
  - Token validation: verified on every request? Signature checked?
  - Token revocation: can tokens be invalidated? (logout, password change)

CHECK SESSION MANAGEMENT:
  - Session ID regeneration after login (prevents session fixation)
  - Session timeout (idle timeout + absolute timeout)
  - Session storage (server-side = GOOD, client-only = RISKY)
  - Concurrent session handling (limit? alert?)

CHECK PASSWORD HANDLING:
  - Password hashing: bcrypt/argon2/scrypt with appropriate cost factor
  - Salt: unique per user (bcrypt/argon2 do this automatically)
  - Password requirements: minimum 8 chars, complexity optional but length > all
  - Password reset: time-limited token, single-use, sent via secure channel
  - No password in URL params (GET requests)
```

**Authorization review:**

```
CHECK PERMISSION MODEL:
  - Is there a permission model? (RBAC, ABAC, or ad-hoc)
  - Are permissions checked at every endpoint? (not just UI hiding)
  - Is there a centralized authorization middleware?
  - Can users escalate privileges? (horizontal or vertical)

CHECK CSRF PROTECTION:
  - State-changing requests (POST, PUT, DELETE) have CSRF tokens
  - CSRF token is NOT in a cookie (double-submit pattern or synchronizer token)
  - SameSite cookie attribute set (Lax or Strict)
  - Custom headers required for API requests (X-Requested-With)

CHECK API SECURITY:
  - Rate limiting on all endpoints (especially auth)
  - Input validation on all request parameters and body
  - Output encoding on all responses (prevent XSS in API responses)
  - Error responses don't leak internal details
  - API versioning strategy (breaking changes handled)
```

**Output format:**

```
## Auth/Authz Review

### Authentication
| Check | Status | Details |
|-------|--------|---------|
| Token storage | PASS/FAIL | [where tokens are stored] |
| Token expiration | PASS/FAIL | [expiry values] |
| Password hashing | PASS/FAIL | [algorithm used] |
| Session management | PASS/FAIL | [details] |

### Authorization
| Check | Status | Details |
|-------|--------|---------|
| Permission model | PASS/FAIL | [RBAC/ABAC/ad-hoc/none] |
| CSRF protection | PASS/FAIL | [method used] |
| Rate limiting | PASS/FAIL | [limits configured] |
| Input validation | PASS/FAIL | [framework/approach] |
```

---

### Step 5: Security Report

> **Goal:** Assemble all findings from Steps 1-4 into a structured, actionable report.
> Save to `docs/security-audit.md`.

**Report structure:**

```markdown
# Security Audit Report

> **Date:** YYYY-MM-DD
> **Auditor:** /blox:secure
> **Scope:** [full project / specific files / specific area from argument]
> **Mode:** [Basic / Premium]

## Executive Summary

- **Overall Risk Level:** [CRITICAL / HIGH / MEDIUM / LOW / CLEAN]
- **Total Findings:** [N]
  - Critical: [N] — Immediate action required
  - High: [N] — Fix before deployment
  - Medium: [N] — Fix in next sprint
  - Low: [N] — Address when convenient
  - Info: [N] — Best practice recommendations
- **OWASP Coverage:** [X/10 categories reviewed]
- **Dependency Vulnerabilities:** [N total]
- **Secrets Found:** [N]

## Risk Level Determination

The overall risk level is the HIGHEST severity finding:
  CRITICAL found -> Overall = CRITICAL
  No CRITICAL but HIGH found -> Overall = HIGH
  No HIGH but MEDIUM found -> Overall = MEDIUM
  Only LOW/INFO -> Overall = LOW
  No findings -> Overall = CLEAN

## OWASP Top 10 Results

| # | Category | Status | Findings | Highest Severity |
|---|----------|--------|----------|-----------------|
| A01 | Broken Access Control | [PASS/FAIL] | [N] | [severity] |
| A02 | Cryptographic Failures | [PASS/FAIL] | [N] | [severity] |
| A03 | Injection | [PASS/FAIL] | [N] | [severity] |
| A04 | Insecure Design | [PASS/FAIL] | [N] | [severity] |
| A05 | Security Misconfiguration | [PASS/FAIL] | [N] | [severity] |
| A06 | Vulnerable Components | [PASS/FAIL] | [N] | [severity] |
| A07 | Auth Failures | [PASS/FAIL] | [N] | [severity] |
| A08 | Data Integrity Failures | [PASS/FAIL] | [N] | [severity] |
| A09 | Logging Failures | [PASS/FAIL] | [N] | [severity] |
| A10 | SSRF | [PASS/FAIL] | [N] | [severity] |

## Dependency Scan Results

[From Step 2 — full vulnerability table]

## Secrets Detection Results

[From Step 3 — findings + gitignore coverage]

## Auth/Authz Review Results

[From Step 4 — authentication + authorization tables]

## All Findings (sorted by severity)

| # | Severity | Category | Description | File:Line | Remediation |
|---|----------|----------|-------------|-----------|-------------|
| 1 | CRITICAL | A03 | SQL injection in user search | src/api/users.ts:42 | Use parameterized query |
| 2 | HIGH | A07 | JWT stored in localStorage | src/lib/auth.ts:15 | Move to httpOnly cookie |
| ... | ... | ... | ... | ... | ... |

## Remediation Plan

### Immediate (CRITICAL — fix now)
1. [Finding #] — [description] — [specific fix steps]

### Before Deployment (HIGH — fix before shipping)
1. [Finding #] — [description] — [specific fix steps]

### Next Sprint (MEDIUM — schedule fix)
1. [Finding #] — [description] — [specific fix steps]

### Best Practices (LOW/INFO — improve over time)
1. [Finding #] — [description] — [recommendation]
```

**Save the report:**

```
CREATE:
  docs/security-audit.md — Full security report

UPDATE (if exists):
  GOLDEN_PRINCIPLES.md — Add security-relevant principles based on findings:
    - "All SQL queries use parameterized statements or ORM (no string concatenation)"
    - "Auth tokens in httpOnly secure cookies (never localStorage)"
    - "No hardcoded secrets — all via environment variables"
    - "Rate limiting on all authentication endpoints"
    (Only add principles relevant to findings — not all of these every time)

UPDATE (if exists):
  CONTEXT_CHAIN.md — Add entry:
    "[date] — Security audit by /blox:secure"
    Findings: [N] total ([N] critical, [N] high, [N] medium, [N] low)
    Overall risk: [level]
    Next session task: fix critical findings
```

**Integration with autopilot flow:**
```
IF called from /blox:idea autopilot (Hardening phase):
  -> Report completion: "Security audit complete. [N] findings. Ready for next phase."
  -> The autopilot flow in /blox:idea handles the phase transition prompt.

IF called standalone:
  -> Report completion with summary of findings.
  -> If CRITICAL findings: "CRITICAL security issues found. Fix before deployment."
  -> If no CRITICAL: "Security audit complete. See docs/security-audit.md for details."
  -> Suggest: "Run /blox:deploy after addressing findings."
```

**Git commit (if git repo exists):**
```
git add docs/security-audit.md
git commit -m "chore: security audit report — [N] findings ([risk level])"
```

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| No package manager detected | Skip dependency scan, continue with other steps | "No dependency manifest found — skipping dependency scan." |
| Audit tool not installed | Note the gap, suggest installation | "Install `pip-audit` for Python dependency scanning. Continuing with other checks." |
| No auth code found | Skip auth review, note as finding | "No authentication code detected — if this app needs auth, that is a CRITICAL gap." |
| No write permission (docs/) | Output report in chat | "Cannot create files here. Here is the security report." |
| Very large codebase | Scope to changed files or specific directories | "Large codebase — scoping to [scope]. Run with specific scope for targeted audit." |
| Git not available | Skip git history checks | "No git repository — skipping commit history scan for leaked secrets." |
| Plugin detection fails | Continue in basic mode | "Running in basic mode — full security audit included." |

---

## INVARIANTS

1. **OWASP Top 10 coverage is mandatory** — all 10 categories checked (even if N/A for some)
2. **Every finding has a severity rating** — CRITICAL, HIGH, MEDIUM, LOW, or INFO
3. **Every finding has a remediation step** — do not just report problems, suggest fixes
4. **Secrets are NEVER printed in full** — always redact (show first 4 chars + `...`)
5. **Report saved to docs/security-audit.md** — persistent artifact, not just chat output
6. **Dependency scan uses the correct tool** — auto-detect package manager, use its audit tool
7. **False positives are filtered** — exclude test fixtures, .env.example placeholders, node_modules
8. **Graceful degradation** — every error has a fallback, nothing blocks the flow
9. **No AI attribution in any generated file** — no Co-Authored-By, Claude, Opus, Anthropic

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Security audit complete (autopilot) | Next phase skill (typically `/blox:deploy`) | After Step 5 — via /blox:idea autopilot |
| Security audit complete (standalone) | Suggest `/blox:deploy` or `/blox:fix` | After Step 5 — user decides |
| CRITICAL findings found | Suggest `/blox:fix` | Immediate remediation needed |
| `/blox:check` Step 5e finds security issues | Suggest `/blox:secure` | For deeper security analysis |
| Pre-deployment check needed | `/blox:deploy` Step 2 references this | Deploy pre-checks include security |
| Auth patterns need redesign | `/blox:plan` | If auth architecture is fundamentally flawed |
| New security Golden Principles | GOLDEN_PRINCIPLES.md | After findings, add prevention rules |

---

## VERIFICATION

### Success Indicators
- All 10 OWASP categories reviewed (or noted as N/A with reason)
- Dependency scan executed with correct tool for the tech stack
- Secrets detection scanned all source files (excluding node_modules, .git, vendor)
- .gitignore coverage verified for sensitive file patterns
- Auth/authz review covered token handling, session management, CSRF, permissions
- Every finding has: severity, description, affected file:line, remediation
- Report saved to `docs/security-audit.md`
- Secrets in report are redacted (never full values)
- Overall risk level determined from highest severity finding
- Remediation plan organized by priority (Critical > High > Medium > Low)
- If GOLDEN_PRINCIPLES.md exists: security principles added based on findings
- If CONTEXT_CHAIN.md exists: audit entry added
- No AI attribution in generated report

### Failure Indicators (STOP and fix!)
- Fewer than 10 OWASP categories checked without N/A justification
- Finding without severity rating
- Finding without remediation step
- Full secret printed in report (INVARIANT 4 violation — NEVER do this)
- Report only in chat — not saved to file (INVARIANT 5 violation)
- Wrong audit tool used (e.g., npm audit on a Python project)
- Test fixtures flagged as real secrets (false positive not filtered)
- AI attribution found in generated report

---

## EXAMPLES

### Example 1: Full audit — Mixed findings (standalone)

```
User: /blox:secure

STEP 1 — OWASP Top 10 Review:
  A01: Broken Access Control -> 2 findings
    - HIGH: /api/users/:id endpoint has no ownership check (src/routes/users.ts:28)
    - MEDIUM: CORS allows all origins in development config (src/config/cors.ts:5)
  A02: Cryptographic Failures -> PASS
  A03: Injection -> 1 finding
    - CRITICAL: Raw SQL with template literal (src/services/search.ts:42)
  A04: Insecure Design -> 1 finding
    - MEDIUM: No rate limiting on /api/auth/login (src/routes/auth.ts:15)
  A05: Security Misconfiguration -> PASS
  A06: Vulnerable Components -> see Step 2
  A07: Auth Failures -> 1 finding
    - HIGH: JWT stored in localStorage (src/lib/auth.ts:23)
  A08: Data Integrity Failures -> PASS
  A09: Logging Failures -> 1 finding
    - LOW: No structured logging — using console.log throughout
  A10: SSRF -> PASS

STEP 2 — Dependency Scan:
  npm audit:
    - 1 critical: lodash prototype pollution (CVE-2021-23337) -> fix: npm audit fix
    - 2 moderate: axios SSRF (update to 1.6.0+)
    -> 3 total vulnerabilities

STEP 3 — Secrets Detection:
  - 0 hardcoded secrets found
  - .gitignore: PARTIAL — missing .env.local coverage
  - Git history: CLEAN — no secrets in commits

STEP 4 — Auth/Authz Review:
  - Token storage: FAIL (localStorage)
  - Token expiration: PASS (15min access, 7d refresh)
  - Password hashing: PASS (bcrypt, cost 12)
  - CSRF: FAIL (no CSRF tokens on POST endpoints)
  - Rate limiting: FAIL (no rate limiting on auth)
  - Input validation: PASS (Zod schemas on all endpoints)

STEP 5 — Security Report:
  Overall Risk: CRITICAL
  Total: 9 findings (1 critical, 3 high, 3 medium, 1 low, 1 info)

  Report saved to docs/security-audit.md
  2 principles added to GOLDEN_PRINCIPLES.md

  "CRITICAL: SQL injection found in search service. Fix immediately
   before deployment. Full report in docs/security-audit.md."
```

### Example 2: Pre-deployment audit — Clean result

```
User: /blox:secure "pre-deployment check"

STEP 1 — OWASP Top 10:
  A01-A10: All PASS — no findings

STEP 2 — Dependency Scan:
  npm audit: 0 vulnerabilities

STEP 3 — Secrets Detection:
  0 secrets found, .gitignore: PASS, git history: CLEAN

STEP 4 — Auth/Authz Review:
  All checks: PASS

STEP 5 — Security Report:
  Overall Risk: CLEAN
  Total: 0 findings

  Report saved to docs/security-audit.md

  "Security audit complete — no findings. Safe to deploy.
   Run /blox:deploy when ready."
```

### Example 3: Focused audit — Auth only

```
User: /blox:secure "authentication system"

Agent scopes to auth-related files only:
  - src/routes/auth.ts
  - src/middleware/auth.ts
  - src/lib/jwt.ts
  - src/lib/session.ts

STEP 1 — OWASP (scoped to A01, A02, A04, A05, A07):
  A07: Auth Failures -> 2 findings
    - HIGH: Refresh token has no rotation (reuse after refresh)
    - MEDIUM: No account lockout after failed attempts

STEP 4 — Auth/Authz Review (full depth):
  Token lifecycle: partial — missing rotation
  Session: PASS
  Password: PASS
  CSRF: PASS
  Permissions: PASS

STEP 5 — Report:
  Overall Risk: HIGH
  Total: 2 findings (0 critical, 1 high, 1 medium)

  "Auth system is mostly solid. Key issue: refresh token rotation
   missing — implement one-time-use refresh tokens. Report in
   docs/security-audit.md."
```

### Example 4: Premium mode with security-guidance plugin

```
User: /blox:secure

Plugin detected: security-guidance
-> Enhanced mode active — real-time hooks enabled

[Standard 5-step audit runs with enhanced detection]

Additional premium features:
  - PreToolUse hook installed: blocks Write/Edit if content contains secrets
  - PostToolUse hook installed: scans written files for security patterns
  - CVE database: enhanced lookup with fix suggestions

After audit:
  "Security audit complete. Premium hooks are now ACTIVE:
   - Secrets blocker: prevents committing hardcoded secrets
   - Pattern scanner: flags unsafe patterns as you code
   These stay active for the rest of this session."
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Engineering patterns (security awareness, mechanical enforcement)
- `skills/check/SKILL.md` — Quality review Step 5e (security pattern scan — lighter version)
- `skills/deploy/SKILL.md` — Deployment skill (references security audit in pre-deploy checks)
- `skills/build/SKILL.md` — Build skill (security checklist items auto-injected by /blox:plan Section 9)
- `registry/curated-plugins.yaml` — Plugin detection for premium mode
