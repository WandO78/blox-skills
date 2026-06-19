---
name: blox-deploy
description: "Deploy to production — multi-platform support. Pre-deploy checks, deployment, post-deploy verification."
user-invocable: true
argument-hint: "[platform or environment]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(deployment logs, check results, verification reports, status messages) MUST be
written in the user's language. The skill logic instructions below are in English
for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:deploy

> **Purpose:** Deploy the project to production with a structured process:
> auto-detect the deployment platform, run mandatory pre-deploy checks,
> execute the deployment, and verify the result with post-deploy smoke tests.
> Basic mode provides step-by-step deployment guides; premium mode (vercel
> plugin or platform-specific MCP) enables one-command deployment.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-deploy
category: domain
complements: [blox-build, blox-check, blox-secure]

### Triggers — when the agent invokes automatically
trigger_keywords: [deploy, ship, release, launch, production, publish, hosting, telepites, kiadas]
trigger_files: [vercel.json, netlify.toml, fly.toml, Dockerfile, serverless.yml]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the project is ready for deployment: all features built, tests
  passing, security audit done (or acknowledged). Handles platform detection,
  pre-deploy validation, deployment execution, and post-deploy verification.
  Do NOT use for building features (use /blox:build), for quality review
  (use /blox:check), or for security audit (use /blox:secure).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Ready to ship | "Deploy to production" | No — user invokes |
| `/blox:idea` autopilot Launch phase | Idea pipeline chains to deploy for shipping | Yes — idea calls it |
| First deployment setup | "Set up deployment for this project" | No — user invokes |
| Redeploy after fixes | "Redeploy with the latest changes" | No — user invokes |
| Environment promotion | "Deploy staging to production" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Features still being built | Not ready for deploy | `/blox:build` |
| Tests failing | Fix first, deploy second | `/blox:fix` |
| Security issues unresolved | Audit first | `/blox:secure` |
| Quality review needed | Review first | `/blox:check` |
| No code exists | Nothing to deploy | `/blox:plan` |

---

## BASIC vs PREMIUM MODE

The skill auto-detects available plugins and adjusts its capabilities:

| Feature | Basic (no plugin) | Premium (vercel plugin / platform MCP) |
|---------|-------------------|----------------------------------------|
| Platform detection | Auto-detect from config files | Same |
| Pre-deploy checks | Full checklist verification | Same |
| Deployment | Step-by-step guide with commands | One-command automated deploy |
| Post-deploy verify | Manual URL check guidance | Automated health check + Lighthouse |
| Rollback | Manual rollback instructions | One-command rollback |

**Plugin detection (runs at start):**
```
IF vercel MCP/plugin installed AND vercel.json detected:
  -> Enable one-command: vercel deploy --prod
  -> Enable automatic preview deployments
  -> Note: "Vercel plugin detected — one-click deployment available"

IF playwright MCP installed:
  -> Enable automated post-deploy smoke tests
  -> Enable Lighthouse performance check
  -> Note: "Playwright detected — automated post-deploy testing available"

IF chrome-devtools MCP installed:
  -> Enable Lighthouse performance auditing
  -> Note: "Chrome DevTools detected — Lighthouse performance check available"

IF no plugins:
  -> Basic mode — step-by-step guides, manual verification
  -> Note: "Running in basic mode — deployment guides provided"
```

---

## SKILL LOGIC

> **4-step deployment pipeline.** Each step has clear pass/fail criteria.
> The deployment NEVER proceeds if pre-deploy checks fail.

### Step 1: Detect Platform

> **Goal:** Identify the deployment target from project configuration files.
> If multiple platforms detected, ask the user which to use.

**Detection rules (check in order — first match wins unless multiple found):**

```
vercel.json OR next.config.* (without Dockerfile)
  -> Platform: VERCEL
  -> Deploy command: vercel deploy --prod
  -> Environment: Vercel Dashboard or .env.production
  -> URL pattern: https://[project].vercel.app

netlify.toml OR _redirects in public/
  -> Platform: NETLIFY
  -> Deploy command: netlify deploy --prod
  -> Environment: Netlify Dashboard or netlify.toml [build.environment]
  -> URL pattern: https://[project].netlify.app

fly.toml
  -> Platform: FLY.IO
  -> Deploy command: fly deploy
  -> Environment: fly secrets set KEY=VALUE
  -> URL pattern: https://[project].fly.dev

Dockerfile OR docker-compose.yml (with cloud deploy config)
  -> Platform: DOCKER
  -> Sub-detect:
     - cloudbuild.yaml / app.yaml -> Google Cloud Run
     - ecs-task-definition.json / buildspec.yml -> AWS ECS
     - azure-pipelines.yml -> Azure Container Apps
     - Generic Docker -> ask user for target
  -> Deploy command: varies by sub-platform
  -> URL pattern: varies

serverless.yml OR serverless.ts
  -> Platform: AWS LAMBDA (Serverless Framework)
  -> Deploy command: serverless deploy --stage production
  -> Environment: AWS SSM / .env.production
  -> URL pattern: https://[id].execute-api.[region].amazonaws.com

Procfile OR app.json (Heroku-style)
  -> Platform: HEROKU or similar PaaS
  -> Deploy command: git push heroku main
  -> Environment: heroku config:set KEY=VALUE

render.yaml
  -> Platform: RENDER
  -> Deploy command: git push (auto-deploy) or manual trigger
  -> Environment: Render Dashboard

railway.toml OR railway.json
  -> Platform: RAILWAY
  -> Deploy command: railway up
  -> Environment: railway variables set KEY=VALUE

NO CONFIG FILES FOUND:
  -> Ask user: "No deployment configuration detected. Which platform?
     a) Vercel (recommended for Next.js / React)
     b) Netlify (static sites, JAMstack)
     c) Fly.io (full-stack, Docker)
     d) AWS Lambda (serverless functions)
     e) Docker (generic containerized)
     f) Other (describe your setup)"
  -> Based on answer, generate the initial configuration file
```

**Multi-platform detection:**
```
IF multiple configs found (e.g., vercel.json AND Dockerfile):
  -> Ask user: "I detected multiple deployment targets:
     a) Vercel (vercel.json)
     b) Docker (Dockerfile)
     Which one should I deploy to?"
  -> Use the selected platform for Steps 2-4
```

**Output from Step 1:**
```
## Platform Detection
- Detected: [platform name]
- Config file: [path]
- Deploy command: [command]
- Environment: [where env vars are managed]
```

---

### Step 2: Pre-deploy Checklist

> **Goal:** Run mandatory checks before deployment. ALL must pass (or be
> explicitly acknowledged) before proceeding to Step 3.

**Mandatory checks (run ALL):**

```
CHECK 1: ALL TESTS PASS
  -> Run the project's test command (npm test / pytest / cargo test / etc.)
  -> PASS: all tests green
  -> FAIL: list failing tests -> STOP: "Tests failing. Fix before deploying."
  -> N/A: no test framework -> WARN: "No tests found. Deploying without test coverage."

CHECK 2: BUILD SUCCEEDS
  -> Run the project's build command (npm run build / python -m build / etc.)
  -> PASS: build exits 0
  -> FAIL: list build errors -> STOP: "Build failing. Fix before deploying."
  -> N/A: no build step -> PASS (skip)

CHECK 3: LINT CLEAN
  -> Run the project's lint command (npm run lint / ruff check / etc.)
  -> PASS: 0 errors (warnings OK)
  -> FAIL: list lint errors -> WARN: "Lint errors found. Recommended to fix."
  -> N/A: no linter configured -> PASS (skip with note)

CHECK 4: SECURITY AUDIT PASSED (or acknowledged)
  -> Check if docs/security-audit.md exists and was generated recently
  -> Check the report's Overall Risk Level
  -> PASS: report exists AND risk is LOW or CLEAN
  -> WARN: report exists AND risk is MEDIUM -> ask user: "Medium security risk. Deploy anyway?"
  -> FAIL: report exists AND risk is HIGH or CRITICAL -> STOP: "Security issues unresolved."
  -> N/A: no report -> WARN: "No security audit found. Run /blox:secure first."

CHECK 5: ENV VARS CONFIGURED
  -> Read .env.example (if exists) to know what vars are needed
  -> Check if the deployment platform has them configured:
     - Vercel: vercel env ls (or check Vercel Dashboard)
     - Netlify: netlify env:list
     - Fly.io: fly secrets list
     - Docker: check docker-compose.yml environment section
     - AWS Lambda: check serverless.yml environment
  -> PASS: all required vars present
  -> FAIL: list missing vars -> STOP: "Missing environment variables: [list]"
  -> N/A: no .env.example -> WARN: "No .env.example found — cannot verify env vars"

  -> ALSO CHECK: .env.production values are NOT the same as .env (development)
     Common mistakes: localhost URLs, debug flags, test API keys in production

CHECK 6: GIT CLEAN
  -> Run: git status --short
  -> PASS: working directory clean (no uncommitted changes)
  -> FAIL: uncommitted changes exist -> WARN: "Uncommitted changes:
     [list]. Commit or stash before deploying."
  -> N/A: no git repo -> PASS (skip)

  -> ALSO CHECK: current branch is main/master (or the expected deploy branch)
     If on a feature branch -> WARN: "You're on branch [name], not main.
     Deploy from this branch, or switch to main first?"
```

**Pre-deploy report:**

```
## Pre-deploy Checklist
| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Tests pass | PASS/FAIL/N/A | [X/Y tests green] |
| 2 | Build succeeds | PASS/FAIL/N/A | [build output] |
| 3 | Lint clean | PASS/WARN/N/A | [0 errors, N warnings] |
| 4 | Security audit | PASS/WARN/FAIL/N/A | [risk level] |
| 5 | ENV vars configured | PASS/FAIL/N/A | [X/Y vars present] |
| 6 | Git clean | PASS/WARN/N/A | [clean / N uncommitted] |

RESULT: [ALL PASS -> proceed] / [FAIL found -> blocked] / [WARN only -> ask user]
```

**Decision logic:**
```
IF any FAIL:
  -> STOP deployment
  -> List all failures with fix instructions
  -> "Fix these issues and re-run /blox:deploy"

IF only WARN (no FAIL):
  -> Ask user: "Pre-deploy has warnings (no failures). Deploy anyway?
     Warnings: [list]
     (y) Deploy with warnings
     (n) Fix warnings first"

IF all PASS:
  -> Proceed to Step 3 automatically
  -> "Pre-deploy checks: ALL PASS. Deploying..."
```

---

### Step 3: Deploy

> **Goal:** Execute the deployment using the detected platform and method.
> Basic mode provides step-by-step commands; premium mode automates.

**Basic mode — step-by-step guide:**

Provide the exact commands and expected output for the detected platform.
Full per-platform command sequences (Vercel, Netlify, Fly.io, Docker/Cloud Run,
AWS Lambda) + rollback commands are in `references/platform-guides.md` — load it
and follow the matching section.

**Premium mode — automated deployment:**

```
IF vercel plugin available:
  -> Direct API call: vercel deploy --prod
  -> Capture deployment URL automatically
  -> Monitor build progress in real-time
  -> Note: "Deployment started. Monitoring progress..."

IF platform CLI available:
  -> Run the deploy command directly
  -> Parse output for deployment URL
  -> Report: "Deployed to [URL]"
```

**After deployment — capture the URL:**
```
DEPLOYMENT_URL = [captured from deploy command output]

IF URL captured:
  -> Pass to Step 4 for verification
  -> "Deployed to: [URL]. Running post-deploy verification..."

IF URL not captured:
  -> Ask user: "What's the deployment URL?"
  -> Use provided URL for Step 4
```

---

### Step 4: Post-deploy Verification

> **Goal:** Verify the deployment is working correctly. Check URL accessibility,
> run smoke tests, and optionally run performance checks.

**Verification checks:**

```
CHECK A: URL ACCESSIBLE (health check)
  -> Attempt to fetch the deployment URL
  -> PASS: HTTP 200 (or 301/302 redirect to valid page)
  -> FAIL: HTTP 4xx/5xx or timeout
  -> Method: curl -sI [URL] or fetch() if MCP available

  IF health endpoint exists (/health, /api/health, /healthz):
    -> Check that too — should return 200 with status OK

CHECK B: SMOKE TEST (key pages load)
  -> Verify critical pages return valid HTML:
    - Home page (/)
    - Login page (/login or /auth)
    - Main feature page (e.g., /dashboard, /app)
    - API health (/api/health)
  -> PASS: pages return HTML with expected content
  -> FAIL: pages return errors or empty content

  IF playwright MCP available:
    -> Automated browser smoke test:
      - Navigate to each page
      - Check for JavaScript errors in console
      - Verify key elements are visible
      - Take screenshots for verification

CHECK C: NO CONSOLE ERRORS
  -> If browser testing is available (playwright/chrome-devtools MCP):
    - Open each key page
    - Check browser console for errors
    - PASS: no console errors
    - WARN: console warnings (not errors)
    - FAIL: console errors present (likely broken functionality)

  IF no browser testing available:
    -> Skip with note: "Install playwright MCP for automated console error checking"

CHECK D: PERFORMANCE CHECK (optional)
  -> If chrome-devtools MCP or Lighthouse available:
    - Run Lighthouse on the deployed URL
    - Report key metrics:
      - Performance score (target: >= 80)
      - First Contentful Paint (target: < 2s)
      - Largest Contentful Paint (target: < 2.5s)
      - Time to Interactive (target: < 3s)
      - Cumulative Layout Shift (target: < 0.1)
    - PASS: Performance >= 80
    - WARN: Performance 50-79
    - FAIL: Performance < 50

  IF no Lighthouse available:
    -> Skip with note: "Install chrome-devtools MCP for Lighthouse performance auditing"
    -> Suggest: "Run Lighthouse manually: https://pagespeed.web.dev/"
```

**Post-deploy report:**

```
## Post-deploy Verification
- Deployment URL: [URL]
- Deployed at: [timestamp]

| # | Check | Status | Details |
|---|-------|--------|---------|
| A | URL accessible | PASS/FAIL | HTTP [status code] |
| B | Smoke test | PASS/FAIL | [N]/[N] pages OK |
| C | Console errors | PASS/WARN/FAIL/N/A | [N] errors found |
| D | Performance | PASS/WARN/FAIL/N/A | Score: [N]/100 |

RESULT: [ALL PASS] / [ISSUES FOUND]
```

**Decision after verification:**
```
IF all checks PASS:
  -> "Deployment verified! [URL] is live and healthy."
  -> Update project tracking files

IF any check FAIL:
  -> "Deployment issues detected:
     [list of failures]

     Options:
     a) Fix and redeploy — address the issues and run /blox:deploy again
     b) Rollback — revert to previous deployment
     c) Investigate — the deployment might need debugging (/blox:fix)"

  -> Provide rollback command for the platform:
     - Vercel: vercel rollback
     - Netlify: netlify deploy --prod --dir=[previous-build]
     - Fly.io: fly deploy --image [previous-image]
     - Docker/Cloud Run: gcloud run deploy --image [previous-image]
```

**Update project tracking files (on successful deploy):**

```
UPDATE (if exists):
  GOLDEN_PRINCIPLES.md — Add deploy-relevant principles (if first deploy):
    - "Always run pre-deploy checklist before shipping"
    - "Post-deploy smoke test on every deployment"
    - "Never deploy with failing tests"

UPDATE (if exists):
  CONTEXT_CHAIN.md — Add entry:
    "[date] — Deployed by /blox:deploy"
    Platform: [platform]
    URL: [deployment URL]
    Pre-deploy: ALL PASS
    Post-deploy: [verification result]
    Next session task: monitor and iterate
```

**Integration with autopilot flow:**
```
IF called from /blox:idea autopilot (Launch phase):
  -> Report completion: "Deployment complete. [URL] is live."
  -> The autopilot flow in /blox:idea handles the phase transition prompt.

IF called standalone:
  -> Report completion with URL and verification results.
  -> Suggest: "Monitor the deployment. Run /blox:check periodically for quality."
```

**Git commit (if git active and deploy config was created):**
```
git add [new config files: vercel.json, netlify.toml, fly.toml, etc.]
git commit -m "chore: deployment configuration for [platform]"
```

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| No deploy config found | Ask user which platform, generate config | "No deployment config found. Which platform?" |
| Deploy CLI not installed | Provide installation instructions | "Install [CLI] first: [install command]. Then re-run /blox:deploy." |
| Deploy command fails | Show error output, suggest fix | "Deployment failed: [error]. Here's how to fix it: [steps]" |
| URL not accessible after deploy | Check if deploy is still in progress, retry | "URL not reachable yet. Deployment might still be building (retry in 30s)." |
| ENV vars missing on platform | List exactly which vars and how to set them | "Missing env vars on [platform]: [list]. Set them with: [command]" |
| No write permission | Output everything in chat | "Cannot update files. Here is the deployment status." |
| Multiple platforms detected | Ask user which one | "Multiple deploy targets found. Which one?" |
| Rollback needed | Provide platform-specific rollback command | "To rollback: [rollback command]" |

---

## INVARIANTS

1. **NEVER deploy with failing tests** — tests must pass (or user explicitly acknowledges the risk)
2. **Always check ENV vars** — missing env vars cause silent failures in production
3. **Always verify after deploy** — a successful deploy command does not mean the app works
4. **Pre-deploy checklist is mandatory** — no shortcuts, no skipping
5. **Platform auto-detection before manual config** — detect first, ask second
6. **Rollback instructions always provided** — every deployment should be reversible
7. **Deployment URL captured and verified** — never claim "deployed" without a working URL
8. **Graceful degradation** — every error has a fallback, nothing blocks the flow
9. **No AI attribution in any generated file** — no Co-Authored-By, Claude, Opus, Anthropic

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Deploy complete (autopilot) | Next phase skill (typically `/blox:docs`) | After Step 4 — via /blox:idea autopilot |
| Deploy complete (standalone) | Suggest monitoring and iteration | After Step 4 — user decides |
| Pre-deploy fails (tests) | Suggest `/blox:fix` | Step 2 — tests failing |
| Pre-deploy fails (security) | Suggest `/blox:secure` | Step 2 — security issues |
| Post-deploy fails | Suggest `/blox:fix` or rollback | Step 4 — deployment broken |
| Performance issues | Suggest `/blox:check` Step 5d | Step 4 — Lighthouse low score |
| Deploy config needs planning | `/blox:plan` | If infrastructure setup is a full phase |
| First deploy — no config | Generate platform config file | Step 1 — auto-generate |

---

## VERIFICATION

### Success Indicators
- Platform correctly auto-detected (or user-selected) from config files
- Pre-deploy checklist: all 6 checks executed with clear PASS/FAIL/WARN/N/A
- No deployment attempted when pre-deploy has FAIL items
- Deployment executed with correct command for the detected platform
- Deployment URL captured from command output
- Post-deploy verification: URL accessible, smoke tests pass
- Rollback instructions provided with the deployment result
- Project tracking files updated (CONTEXT_CHAIN.md, GOLDEN_PRINCIPLES.md)
- If first deploy: platform configuration file generated and committed
- No AI attribution in generated files or commits

### Failure Indicators (STOP and fix!)
- Deployed despite failing tests (INVARIANT 1 violation)
- Deployed without checking ENV vars (INVARIANT 2 violation)
- Claimed "deployed" without post-deploy verification (INVARIANT 3 violation)
- Skipped pre-deploy checklist (INVARIANT 4 violation)
- Asked user for platform before checking config files (INVARIANT 5 violation)
- No rollback instructions provided (INVARIANT 6 violation)
- No deployment URL in output (INVARIANT 7 violation)
- AI attribution found in generated files

---

## EXAMPLES

See `references/examples.md` for 5 full worked walkthroughs:
1. Vercel deployment — full pipeline (standalone)
2. First deployment — no config found
3. Deploy blocked — tests failing
4. Post-deploy failure — rollback needed
5. Docker + Cloud Run deployment

---

## REFERENCES

- `references/platform-guides.md` — Per-platform deploy commands + rollback (Step 3 basic mode)
- `references/examples.md` — 5 worked deployment walkthroughs
- `references/patterns/knowledge-patterns.md` — Engineering patterns (momentum protection, mechanical enforcement)
- `skills/secure/SKILL.md` — Security audit (referenced in pre-deploy Check 4)
- `skills/check/SKILL.md` — Quality review (for post-deploy performance issues)
- `skills/build/SKILL.md` — Build skill (for fixing pre-deploy build failures)
- `skills/fix/SKILL.md` — Fix skill (for debugging post-deploy failures)
- `registry/requirements.yaml` — blox companions + media/build prerequisites (premium-mode tools)
