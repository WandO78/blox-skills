# /blox:secure — Worked Examples

> Worked walkthroughs of the 5-step security audit pipeline. The SKILL.md holds
> the decision logic; these illustrate it end to end.

## Example 1: Full audit — Mixed findings (standalone)

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

## Example 2: Pre-deployment audit — Clean result

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

## Example 3: Focused audit — Auth only

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

## Example 4: Premium mode with security-guidance plugin

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
