# /blox:deploy — Worked Examples

> End-to-end walkthroughs of the 4-step deployment pipeline. SKILL.md holds the
> decision logic; these illustrate it across platforms and outcomes.

## Example 1: Vercel deployment — Full pipeline (standalone)

```
User: /blox:deploy

STEP 1 — Detect Platform:
  Found: vercel.json + next.config.mjs
  Platform: VERCEL
  Deploy command: vercel deploy --prod
  "Detected Vercel deployment (Next.js project)."

STEP 2 — Pre-deploy Checklist:
  1. Tests pass: PASS (42/42 green)
  2. Build succeeds: PASS (next build - 0 errors)
  3. Lint clean: PASS (0 errors, 2 warnings)
  4. Security audit: PASS (docs/security-audit.md — risk: LOW)
  5. ENV vars configured: PASS (12/12 vars set in Vercel Dashboard)
  6. Git clean: PASS (clean, on main branch)

  "Pre-deploy: ALL PASS. Deploying to Vercel..."

STEP 3 — Deploy:
  Running: vercel deploy --prod
  -> Build started...
  -> Build completed (45s)
  -> Deployed to: https://my-app.vercel.app

STEP 4 — Post-deploy Verification:
  A. URL accessible: PASS (HTTP 200)
  B. Smoke test: PASS (/, /login, /dashboard — all render)
  C. Console errors: PASS (0 errors)
  D. Performance: PASS (Lighthouse 92/100)

  "Deployment verified! https://my-app.vercel.app is live and healthy.

   Lighthouse scores:
   - Performance: 92
   - FCP: 1.2s
   - LCP: 1.8s
   - CLS: 0.02

   CONTEXT_CHAIN.md updated with deployment entry."
```

## Example 2: First deployment — No config found

```
User: /blox:deploy

STEP 1 — Detect Platform:
  No deployment configuration found.
  Tech stack detected: Next.js + React + TypeScript

  "No deployment config found. Which platform?
   a) Vercel (recommended for Next.js)
   b) Netlify
   c) Fly.io
   d) Docker
   e) Other"

User: "a"

  Creating vercel.json:
  {
    "$schema": "https://openapi.vercel.sh/vercel.json",
    "framework": "nextjs"
  }

  "Vercel config created. Continuing with pre-deploy checks..."

STEP 2 — Pre-deploy Checklist:
  1. Tests pass: N/A (no test framework) -> WARN
  2. Build succeeds: PASS
  3. Lint clean: PASS
  4. Security audit: N/A -> WARN
  5. ENV vars: WARN (3 vars in .env.example not yet on Vercel)
  6. Git clean: PASS

  "Pre-deploy has warnings (no failures):
   - No tests found
   - No security audit run
   - 3 env vars missing on Vercel: DATABASE_URL, JWT_SECRET, NEXT_PUBLIC_API_URL

   Set env vars: vercel env add DATABASE_URL
   Deploy anyway? (y/n)"

User: "let me set the env vars first"

  "Set these on Vercel:
   vercel env add DATABASE_URL
   vercel env add JWT_SECRET
   vercel env add NEXT_PUBLIC_API_URL

   Then re-run /blox:deploy."
```

## Example 3: Deploy blocked — Tests failing

```
User: /blox:deploy "production"

STEP 1 — Detect Platform:
  Found: fly.toml
  Platform: FLY.IO

STEP 2 — Pre-deploy Checklist:
  1. Tests pass: FAIL (38/42 — 4 tests failing)
     - test_user_crud: AssertionError at line 89
     - test_payment_flow: timeout at line 234
     - test_email_send: mock not configured
     - test_admin_access: 403 instead of 200

  STOP: "4 tests failing. Fix before deploying.

   Failing tests:
   1. test_user_crud — AssertionError at line 89
   2. test_payment_flow — timeout at line 234
   3. test_email_send — mock not configured
   4. test_admin_access — 403 instead of 200

   Run /blox:fix to debug these failures, then re-run /blox:deploy."
```

## Example 4: Post-deploy failure — Rollback needed

```
User: /blox:deploy

STEP 1-3 — Platform: Vercel, pre-deploy PASS, deployed successfully.

STEP 4 — Post-deploy Verification:
  A. URL accessible: PASS (HTTP 200)
  B. Smoke test: FAIL
     - / renders OK
     - /login renders OK
     - /dashboard: HTTP 500 (Internal Server Error)
  C. Console errors: FAIL (3 errors on /dashboard)
  D. Performance: N/A (skipped due to errors)

  "Post-deploy issues detected!

   /dashboard returns 500 — likely a missing environment variable
   or database connection issue in production.

   Console errors:
   1. TypeError: Cannot read properties of undefined (reading 'user')
   2. Error: ECONNREFUSED 127.0.0.1:5432
   3. Unhandled promise rejection

   Likely cause: DATABASE_URL pointing to localhost instead of production DB.

   Options:
   a) Fix ENV vars and redeploy
      -> Check: vercel env ls | grep DATABASE_URL
      -> Fix: vercel env rm DATABASE_URL && vercel env add DATABASE_URL
   b) Rollback to previous deployment
      -> Run: vercel rollback
   c) Investigate further with /blox:fix"
```

## Example 5: Docker + Cloud Run deployment

```
User: /blox:deploy "cloud run"

STEP 1 — Detect Platform:
  Found: Dockerfile + cloudbuild.yaml
  Platform: DOCKER (Google Cloud Run)
  Project: my-saas-app
  Region: us-central1

STEP 2 — Pre-deploy Checklist:
  1. Tests pass: PASS (142/142)
  2. Build succeeds: PASS (docker build - 0 errors)
  3. Lint clean: PASS
  4. Security audit: PASS (risk: LOW)
  5. ENV vars: PASS (all secrets in Secret Manager)
  6. Git clean: PASS

  "Pre-deploy: ALL PASS. Deploying to Cloud Run..."

STEP 3 — Deploy:
  "Step-by-step deployment:

   1. Build container:
      docker build -t gcr.io/my-saas-app/api .

   2. Push to registry:
      docker push gcr.io/my-saas-app/api

   3. Deploy to Cloud Run:
      gcloud run deploy api \
        --image gcr.io/my-saas-app/api \
        --platform managed \
        --region us-central1 \
        --allow-unauthenticated

   Run these commands in order."

  [After user runs commands]
  -> Deployed to: https://api-abc123.run.app

STEP 4 — Post-deploy Verification:
  A. URL: PASS
  B. Smoke test: PASS
  C. Console: N/A (backend API)
  D. Performance: N/A (API, not web page)

  "Deployed and verified! https://api-abc123.run.app is live.

   Rollback: gcloud run deploy api --image [previous-image-tag]"
```
