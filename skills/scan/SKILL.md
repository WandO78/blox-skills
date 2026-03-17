---
name: blox-scan
description: "Assess any project's current state without modifying it: tech stack, lifecycle zone, gap analysis (20 standards), quality baseline. Use when you need to understand a project's health or readiness."
user-invocable: true
argument-hint: "[project path]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(report output, gap analysis notes, recommendations) MUST be written in the user's
language. The skill logic instructions below are in English for maintainability,
but all OUTPUT facing the user follows THEIR language.

---

# PROJECT AUDIT TASK

You are an Explore agent tasked with auditing the project at: $ARGUMENTS (or current directory if not specified).
Your job is to assess the project's state WITHOUT modifying any files.
Produce a structured AUDIT REPORT in markdown format as your final response.
You have access to: Read, Glob, Grep, Bash (read-only commands only).

> **Read-only project assessment — the "X-ray" skill.**
> Looks at everything, touches nothing. Outputs a structured AUDIT REPORT
> that serves as input for `/blox:idea` retrofit mode or standalone health checks.

---

## Project Snapshot (auto-detected)

Root files:
!`ls -la 2>/dev/null | head -20`

Package manager (Node.js):
!`cat package.json 2>/dev/null | head -15`

Python config:
!`cat pyproject.toml 2>/dev/null | head -15`

Git history:
!`git log --oneline -5 2>/dev/null`

Existing blox docs:
!`ls CLAUDE.md START_HERE.md CONTEXT_CHAIN.md ARCHITECTURE.md GOLDEN_PRINCIPLES.md QUALITY_SCORE.md TECH_DEBT.md README.md 2>/dev/null`

Existing directories:
!`ls -d plans/ completed/ docs/ .blox/ .claude/ .github/ src/ app/ test/ tests/ __tests__/ 2>/dev/null`

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-scan
category: init
complements: [blox-idea, _internal/cleanup]

### Triggers — when the agent invokes automatically
trigger_keywords: [audit, assessment, health, gap, diagnose, status, scan, check]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when assessing a project's current state: what's there, what's missing,
  what zone it's in, what tech stack it uses. Read-only — NEVER modifies files.
  Output is a structured AUDIT REPORT used as input for /blox:idea retrofit mode.
  Also useful for periodic health checks and phase-end quality assessment.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Existing project assessment | "What's the state of this project?" | No — user invokes |
| Before retrofit | Input for `/blox:idea` retrofit mode | No — user invokes |
| Periodic health check | "Has anything degraded?" | No — user or `/blox:done` invokes |
| Phase-end quality check | "How's our quality trending?" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Need to modify the project | Audit is READ-ONLY | `/blox:idea` (creates/modifies) |
| Code quality review | Different purpose — evaluates code changes | `/blox:check` |
| Brand new empty project | Nothing to audit | `/blox:idea` (greenfield) |
| Mid-phase progress check | Different granularity | `_internal/checkpoint` |

---

## CRITICAL INVARIANT

> **The audit is read-only by default.**
> It reads, scans, runs test commands, analyzes git history — but writes NOTHING
> unless the user explicitly approves a legacy migration (Step 2b).
> The output is a structured report delivered as agent output (or saved to a
> user-specified location if requested).

---

## SKILL LOGIC

> **6-step read-only assessment pipeline.**
> Each step produces a section of the final AUDIT REPORT.

### Step 1: Tech Stack Scan

> **Goal:** Identify what technologies the project uses — dynamically, with no predefined categories.

**Scan these files (in order of priority):**

```
# Package managers & language markers
package.json          → Node.js / JavaScript / TypeScript
requirements.txt      → Python
pyproject.toml        → Python (modern)
Pipfile               → Python (Pipenv)
go.mod                → Go
Cargo.toml            → Rust
Gemfile               → Ruby
pom.xml / build.gradle → Java
composer.json         → PHP
*.csproj              → C# / .NET
CMakeLists.txt        → C/C++

# Frameworks (inside package.json or requirements.txt)
next / react / vue / angular / svelte   → Frontend framework
fastapi / django / flask / express      → Backend framework
prisma / sqlalchemy / typeorm           → ORM / Database

# Infrastructure
Dockerfile / docker-compose.yml  → Containerized
.github/workflows/               → GitHub Actions CI
.gitlab-ci.yml                   → GitLab CI
vercel.json / netlify.toml       → Serverless deploy
terraform/ / pulumi/             → Infrastructure as Code
.clasp.json                      → Google Apps Script

# Databases
supabase/config.toml              → Supabase
prisma/schema.prisma              → Prisma + PostgreSQL/MySQL/SQLite
*.sqlite / *.db                   → SQLite
docker-compose.yml (postgres/mysql/redis services) → Database services

# IoT
configuration.yaml    → Home Assistant
custom_components/    → HA custom integration

# Claude / AI
.claude/              → Claude Code config
CLAUDE.md             → Claude project instructions
.blox/                → blox-skills state
```

**Dynamic Tech Stack Detection:**

Do NOT assign predefined categories (no T1-T7). Instead, list every detected technology:

1. **Scan all marker files** from the list above
2. **Read dependency manifests** (package.json, requirements.txt, pyproject.toml, etc.) for specific libraries
3. **Compile a detailed tech stack list**, for example:
   - "Next.js + React + TypeScript + Tailwind + Prisma + PostgreSQL + Vercel"
   - "FastAPI + SQLAlchemy + Alembic + React + Docker + GitHub Actions"
   - "Python + pandas + dbt + Airflow (data pipeline)"
   - "Markdown only (research/planning, no code)"
   - "Home Assistant + YAML + custom Python integration"

**Output for report:** `Tech Stack: [detailed list]` — no category label, just what's actually there.

---

### Step 2: Zone Detection

> **Goal:** Determine where the project is in its lifecycle.
> Zones are detected top-down — check the highest zone first.
> Use human-readable labels in the report, with Z-codes in parentheses for reference.

**Zone Detection Heuristic (check from Evolution down to Ideation):**

```
Evolution (Z7) — Is this a live system getting new features?
  Check: Is it deployed AND has recent feature branches/PRs?
  Evidence: production URL + feature branches in last 30 days

Maintenance (Z6) — Is this a live system in maintenance?
  Check: Is it deployed AND has recent bug fixes/dependency updates?
  Evidence: production URL + bugfix/chore commits + no new features

Launch (Z5) — Is there a deployment?
  Check: Is there a working deploy pipeline or live URL?
  Evidence: vercel.json + deployed, Dockerfile + cloud config, CI/CD with deploy step

Hardening (Z4) — Are there quality measures?
  Check: Are there tests, lint, CI, documentation?
  Evidence: test files + CI config + lint config + >60% coverage

Building (Z3) — Is there working code?
  Check: Is there application code beyond scaffolding?
  Evidence: src/ or app/ with substantial files, API routes, business logic

Foundation (Z2) — Is the infra set up?
  Check: Is there a repo with basic setup?
  Evidence: package.json + basic config files, DB schema, auth setup

Planning (Z1) — Is there a design/plan?
  Check: Are there architecture docs, wireframes, specs?
  Evidence: ARCHITECTURE.md, design files, spec documents

Ideation (Z0) — Just research?
  Check: Only notes, research, brainstorm docs?
  Evidence: markdown files only, no code, no infra
```

**Important:** A project can be BETWEEN zones. Report the primary zone AND note partial progress in adjacent zones.

Example: "Building (Z3) — partial Foundation (has DB but no auth), Hardening absent (no tests)"

**Output for report:** `Current Zone: [Human Label] (Z[X])` + zone detail notes.

---

### Step 2b: Legacy Migration Check

> **Goal:** Detect and migrate references from older skill libraries (wando-skills v1/v2)
> to the current blox-skills format. This is the ONLY step that may modify files,
> and ONLY with explicit user approval.

**Scan for legacy references:**

```bash
# Search all markdown files for old wando: references
grep -rl "wando:" *.md plans/*.md completed/*.md docs/*.md .claude/*.md 2>/dev/null
```

**If legacy references found:**

1. List all occurrences with file and line:
```
Legacy wando-skills references found:
  CLAUDE.md:12      — /wando:plan → /blox:plan
  CLAUDE.md:15      — /wando:review → /blox:check
  START_HERE.md:8   — /wando:close → /blox:done
  plans/Phase_01.md — /wando:checkpoint → (auto, remove reference)
```

2. Show the migration mapping:
```
Migration map:
  /wando:plan       → /blox:plan
  /wando:audit      → /blox:scan
  /wando:review     → /blox:check
  /wando:close      → /blox:done
  /wando:init       → /blox:idea
  /wando:checkpoint → (now automatic — remove reference)
  /wando:gc         → (now automatic — remove reference)
  /wando:chain      → (now automatic — remove reference)
  /wando:dispatch   → (advanced — keep as note in TECH_DEBT)
  /wando:extract    → (not yet available — keep as note)
  /wando:analyze    → (not yet available — keep as note)
```

3. Ask user for approval:
```
"I found [N] legacy wando-skills references in [M] files.
 Shall I update them to blox-skills format? (y/n)"
```

4. If user approves (y):
   - Execute the replacements
   - For removed skills (checkpoint, gc, chain): remove the reference line or replace with a note
   - For dispatch/extract/analyze: add a note to TECH_DEBT.md
   - Commit: "chore: migrate wando-skills references to blox-skills"

5. If user declines (n):
   - Add to audit report as a CONCERN: "Legacy wando-skills references found — migration recommended"
   - Continue with the rest of the audit

**If no legacy references found:** Skip silently, continue to Step 3.

**Also check for old global skill installations:**
```bash
ls ~/.claude/skills/wando-* 2>/dev/null
```
If found, note in the report: "Old wando-skills global installation detected. Consider removing with: `rm -rf ~/.claude/skills/wando-*` after installing the blox plugin."

---

### Step 3: Gap Analysis

> **Goal:** Compare current project state against standard elements.
> Uses project-scaffold.md as the reference checklist.

**Standard Elements Checklist:**

| # | Element | How to check | Status values |
|---|---------|-------------|---------------|
| G-01 | `CLAUDE.md` | File exists + has Relevant Skills section | PRESENT / PARTIAL / MISSING |
| G-02 | `START_HERE.md` | File exists + has Phase Tracker + Resumption Protocol | PRESENT / PARTIAL / MISSING |
| G-03 | `CONTEXT_CHAIN.md` | File exists + has entries | PRESENT / PARTIAL / MISSING |
| G-04 | `ARCHITECTURE.md` | File exists + has layer diagram or structure description | PRESENT / PARTIAL / MISSING |
| G-05 | `GOLDEN_PRINCIPLES.md` | File exists + has at least 1 principle | PRESENT / PARTIAL / MISSING |
| G-06 | `QUALITY_SCORE.md` | File exists + has at least 1 entry | PRESENT / PARTIAL / MISSING |
| G-07 | `TECH_DEBT.md` | File exists | PRESENT / MISSING |
| G-08 | `plans/` directory | Directory exists + has phase files | PRESENT / PARTIAL / MISSING |
| G-09 | `completed/` directory | Directory exists | PRESENT / MISSING |
| G-10 | `docs/` directory | Directory exists + has content | PRESENT / PARTIAL / MISSING |
| G-11 | Test files | Test directory or test files exist | PRESENT / PARTIAL / MISSING |
| G-12 | CI/CD config | Any CI/CD pipeline config detected | PRESENT / MISSING |
| G-13 | Lint config | `.eslintrc` / `ruff.toml` / `pyproject.toml [tool.ruff]` etc. | PRESENT / MISSING |
| G-14 | Pre-commit hooks | `.husky/` or `.pre-commit-config.yaml` or `.git/hooks/` | PRESENT / MISSING |
| G-15 | README.md | File exists + is not default template | PRESENT / PARTIAL / MISSING |
| G-16 | .gitignore | File exists + covers common patterns | PRESENT / PARTIAL / MISSING |
| G-17 | Environment config | `.env.example` or documented env vars | PRESENT / MISSING |
| G-18 | AI attribution leaks | No `Co-Authored-By`, `Claude`, `Opus`, `Generated by` etc. in code/commits | CLEAN / FOUND |
| G-19 | Phase marker consistency | Active phase files have `>>> CURRENT <<<` marker, completed phases don't | CONSISTENT / INCONSISTENT / N/A |
| G-20 | Curated plugins | Check blox curated plugins from `registry/curated-plugins.yaml` against installed plugins | ALL / PARTIAL / NONE |

**PARTIAL means:** File exists but is incomplete, outdated, or doesn't meet the standard.

**How to determine PARTIAL:**
- `CLAUDE.md` exists but has no Relevant Skills → PARTIAL
- Tests exist but cover <30% of code → PARTIAL
- README exists but is the default npm/create-next-app template → PARTIAL

**How to check G-18 (AI attribution leaks):**
Search across ALL source files and git history for:
```bash
# In source files
grep -ri "co-authored-by" --include="*.{ts,tsx,js,jsx,py,md,yml,yaml,json}" .
grep -ri "generated by claude\|generated by ai\|claude opus\|anthropic" --include="*.{ts,tsx,js,jsx,py,md,yml,yaml,json}" .

# In git commit messages
git log --all --grep="Co-Authored-By" --grep="Claude" --grep="Opus" --grep="noreply@anthropic"
```
If ANY match found → status = **FOUND** (list files/commits with matches).
If no matches → status = **CLEAN**.

**Cleanup guidance (if FOUND):**
- **Source files:** Remove the lines manually or via sed/grep
- **Git commit messages:** Use `FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --msg-filter 'sed "/^Co-Authored-By:.*$/d"' --force -- --all` then force push
- **Protected branches (GitLab/GitHub):** Temporarily unprotect → force push → re-protect
- **IMPORTANT:** This rewrites git history — solo project only, or coordinate with team

**How to check G-19 (Phase marker consistency):**
```bash
# Find all phase files
find plans/ -name "PHASE_*.md" 2>/dev/null

# Check active phases have >>> CURRENT <<<
grep -l ">>> CURRENT <<<" plans/PHASE_*.md 2>/dev/null

# Check completed phases in completed/ do NOT have >>> CURRENT <<<
grep -l ">>> CURRENT <<<" completed/PHASE_*.md 2>/dev/null  # should be empty

# Cross-reference with START_HERE.md phase tracker statuses
```
Rules:
- Active/IN PROGRESS phases MUST have `>>> CURRENT <<<` marker
- COMPLETED phases in `completed/` SHOULD NOT have `>>> CURRENT <<<`
- If no phase files exist → N/A
- If START_HERE.md says "IN PROGRESS" but phase file has no marker → INCONSISTENT
- If multiple phases claim `>>> CURRENT <<<` but START_HERE.md shows only one active → INCONSISTENT

**How to check G-20 (Curated plugins):**

Read the blox curated plugin registry and check which plugins are installed:

```bash
# Read the curated plugin registry
cat ~/.claude/skills/*/registry/curated-plugins.yaml 2>/dev/null | head -100

# Check installed plugins
ls ~/.claude/plugins/ 2>/dev/null
ls ~/.claude/plugins/cache/ 2>/dev/null
ls ~/.claude/plugins/marketplaces/ 2>/dev/null

# Check blox plugin state
cat .blox/plugin-state.yaml 2>/dev/null
```

**Evaluation:**
1. Load `registry/curated-plugins.yaml` — extract all `curated` tier plugins
2. Match plugins against project tech stack (same trigger logic as `/blox:setup`)
3. Check which relevant plugins are installed vs missing

Status values:
- **ALL** — All relevant curated plugins are installed
- **PARTIAL** — Some relevant plugins missing (list which ones)
- **NONE** — No curated plugins installed (blox-skills still works, but experience is degraded)

Include in report: which plugins are missing + suggestion to run `/blox:setup`.

**Output for report:** Gap Analysis table with status for each element.

---

### Step 4: Quality Baseline

> **Goal:** Measure the current quality level — tests, lint, build status.
> This gives a starting point for tracking improvement.

**Run these checks (skip if not applicable to tech stack):**

```
4a. Tests
    - Find test command: check package.json scripts, pytest, etc.
    - Run tests (if safe — read-only! tests that modify external state: SKIP)
    - Record: X/Y passing, coverage % if available
    - If no test framework: record "No test framework detected"

4b. Lint
    - Find lint command: eslint, ruff, pylint, etc.
    - Run lint (read-only — no --fix!)
    - Record: X warnings, Y errors
    - If no lint config: record "No lint configuration detected"

4c. Build
    - Find build command: npm run build, python -m build, etc.
    - Run build (if quick — skip if build takes >2 minutes)
    - Record: SUCCESS / FAIL + error summary
    - If no build step: record "No build step detected"

4d. Type checking (if applicable)
    - tsc --noEmit, mypy, pyright, etc.
    - Record: X errors
```

**4e. Automation Opportunities (informational)**

Based on the detected tech stack, suggest relevant MCP servers and hooks the project could benefit from.
This is INFORMATIONAL only — include as a report section, not a gap penalty.

**MCP Server recommendations — match against detected tech stack:**

| Detected Signal | Recommended MCP Server | Why |
|----------------|----------------------|-----|
| PostgreSQL / Prisma / SQLAlchemy | `postgres-mcp` or `supabase-mcp` | Direct DB queries from Claude |
| React / Next.js / Vue / Angular | `playwright-mcp` (Microsoft) | Browser automation + E2E testing |
| Rapidly changing libraries (Next.js, Prisma, FastAPI) | `context7` (Upstash) | Live docs lookup — prevents stale API usage |
| GitHub remote (.git/config → github.com) | `github-mcp` | PR management, issue tracking |
| GitLab remote (.git/config → gitlab) | `gitlab-mcp` | MR management, CI pipeline |
| Docker / docker-compose.yml | `docker-mcp` | Container management |
| AWS SDK / boto3 / aws-cdk | `aws-mcp` | Cloud resource management |
| Sentry / error tracking | `sentry-mcp` | Error debugging context |
| Slack integration / notifications | `slack-mcp` | Team notifications |

**Hook recommendations — match against detected tooling:**

| Detected Signal | Recommended Hook | Type | Trigger |
|----------------|-----------------|------|---------|
| `.prettierrc` / prettier in deps | Auto-format on edit | PostToolUse | `npx prettier --write $FILE` |
| `.eslintrc` / eslint in deps | Auto-lint on edit | PostToolUse | `npx eslint --fix $FILE` |
| `ruff.toml` / ruff in deps | Auto-format Python | PostToolUse | `ruff format $FILE && ruff check --fix $FILE` |
| `tsconfig.json` | Type-check on edit | PostToolUse | `npx tsc --noEmit` |
| `.env` files present | Block .env edits | PreToolUse | Deny Write/Edit to `.env*` files |
| `package-lock.json` / lock files | Block lock file edits | PreToolUse | Deny Write/Edit to lock files |
| `jest.config` / vitest.config | Auto-test on edit | PostToolUse | Run related tests after file change |
| `pytest.ini` / conftest.py | Auto-test Python | PostToolUse | `pytest $FILE_DIR -x --no-header -q` |

**Rules:**
- Only suggest MCP servers/hooks for detected tech — do NOT suggest everything
- Maximum 3 MCP suggestions + 3 hook suggestions per project
- Include install commands/config snippets in the report
- This section has NO impact on Quality Score — purely informational

**Quality Score estimation:**
```
Initial score = 100
- No tests:        -30
- Tests failing:   -20 per failing test (max -40)
- No lint:         -10
- Lint errors:     -5 per 10 errors (max -20)
- Build failing:   -20
- No CI/CD:        -5 (suggestion, not critical)
- No CLAUDE.md:    -5
- AI attribution found: -5 per occurrence (max -15)
```

This is a ROUGH estimate — not the same as the `/blox:check` Quality Score.
It gives a starting baseline for tracking.

**Output for report:** Quality Baseline section with test/lint/build results + estimated score.

---

### Step 5: Retroactive Context

> **Goal:** Understand the project's history — what happened before the audit.

**5a. Git History (if git repo):**
```bash
git log --oneline -20                    # Last 20 commits
git log --oneline --since="3 months ago" # Recent activity
git shortlog -sn --no-merges            # Contributors
git log --diff-filter=A --name-only --format="" | head -30  # First files added
```

Summarize:
- When was the project started? (first commit date)
- How active is it? (commits per week/month)
- Who works on it? (contributors)
- What was the last significant change?

**5b. Existing Documentation:**
- Read README.md (if exists) — project description, goals
- Read any ARCHITECTURE.md, DESIGN.md, spec files
- Read existing CLAUDE.md (if exists) — prior instructions
- Read any plan files, TODO files, CHANGELOG

Summarize in 3-5 sentences: what the project is about, where it's headed, what's been done.

**5c. If no git repo:**
- Note: "No git repository detected"
- Rely on file timestamps and existing docs for context
- Recommend: "Initialize git repository as first retrofit step"

**Output for report:** Retroactive Context section with history summary.

---

### Step 6: Structured Report Assembly

> **Goal:** Combine all findings into a single structured AUDIT REPORT.

**Report Template:**

```markdown
# AUDIT REPORT: [project name]

> **Date:** [YYYY-MM-DD]
> **Auditor:** /blox:scan
> **Duration:** [X minutes]

---

## 1. Project Identity

- **Tech Stack:** [detailed list — dynamically detected, no category labels]
- **Current Zone:** [Human Label] (Z[X])
- **Repository:** [git status — clean/dirty, branch, remote]

## 2. Project Description

[2-3 sentences: what it is, what it does, where it's headed]

## 3. Zone Detail

| Zone | Status | Evidence |
|------|--------|----------|
| Ideation (Z0) | [Done/Partial/N/A] | [evidence] |
| Planning (Z1) | [Done/Partial/N/A] | [evidence] |
| Foundation (Z2) | [Done/Partial/N/A] | [evidence] |
| Building (Z3) | [Done/Partial/N/A] | [evidence] |
| Hardening (Z4) | [Done/Partial/N/A] | [evidence] |
| Launch (Z5) | [Done/Partial/N/A] | [evidence] |
| Maintenance (Z6) | [Active/N/A] | [evidence] |
| Evolution (Z7) | [Active/N/A] | [evidence] |

## 4. Gap Analysis

| # | Element | Status | Notes |
|---|---------|--------|-------|
| G-01 | CLAUDE.md | [PRESENT/PARTIAL/MISSING] | [details] |
| G-02 | START_HERE.md | [PRESENT/PARTIAL/MISSING] | [details] |
| ... | ... | ... | ... |

**Summary:** X/20 PRESENT, Y/20 PARTIAL, Z/20 MISSING

## 5. Quality Baseline

| Check | Result | Details |
|-------|--------|---------|
| Tests | [X/Y pass, Z% coverage] | [framework, command] |
| Lint | [X warnings, Y errors] | [tool, config] |
| Build | [SUCCESS/FAIL] | [command, errors if any] |
| Type check | [X errors] | [tool] |

**Estimated Quality Score:** [X/100]

## 6. Retroactive Context

[3-5 sentence project history summary]

- **Started:** [date]
- **Last active:** [date]
- **Contributors:** [count and names]
- **Recent activity:** [summary]

## 7. Automation Opportunities

> Informational — no quality score impact. Based on detected tech stack.

### MCP Servers
| MCP Server | Why | Install |
|------------|-----|---------|
| [matched server] | [reason based on tech stack] | [install command or config] |

### Hooks
| Hook | Type | Trigger | Config |
|------|------|---------|--------|
| [matched hook] | [Pre/PostToolUse] | [when] | [command] |

*Skip this section if no relevant MCP servers or hooks detected.*

## 8. Recommended Next Steps

Based on the audit findings:

1. [If G-18 FOUND: "Remove AI attribution from code and git history" — always first priority]
2. [Most urgent action — usually CLAUDE.md or test setup]
3. [Second priority]

**Recommended approach:**
- [ ] Run `/blox:idea` (passes this report as context)
- [ ] OR: Address gaps manually in priority order
```

---

## STANDALONE USE CASES

The audit is not only for retrofit. It works as:

### Health Check
Run periodically to check if quality has degraded:
- Compare current Gap Analysis with previous audit
- Check if QUALITY_SCORE trend is stable
- Flag any new MISSING elements that were previously PRESENT

### Phase-End Assessment
Run at the end of a major phase to measure improvement:
- Compare Quality Baseline before/after
- Count gaps closed vs. new gaps introduced

### Quick Status
User asks "Where are we?" — run audit for a fast structured answer.

---

## SKILL INTEGRATIONS (informational — for the user, not for this agent)

> Note: As a forked Explore agent, you cannot invoke other skills. Include these as recommendations in the report.

| After audit... | Recommend to user |
|----------------|-------------------|
| Gaps found → retrofit needed | "Run `/blox:idea` in retrofit mode with this report as input" |
| Quality baseline low | "Run `/blox:check` for detailed code quality assessment" |
| Docs stale | "Run `_internal/cleanup` for documentation cleanup" |

---

## EXAMPLES

### Example 1: FastAPI + React Project (Building zone)

```
Agent: Running /blox:scan on current project.

Step 1 — Tech Stack Scan:
  Found: requirements.txt (FastAPI, SQLAlchemy, alembic, pytest)
  Found: Dockerfile, docker-compose.yml
  Found: .github/workflows/ci.yml
  Found: src/frontend/ (React, package.json with Next.js)
  → Tech Stack: FastAPI + SQLAlchemy + Alembic + React + Next.js + Docker + GitHub Actions

Step 2 — Zone Detection:
  Ideation (Z0): Done (README has project description)
  Planning (Z1): Partial (no ARCHITECTURE.md, but DB schema exists)
  Foundation (Z2): Done (repo, DB, auth, Docker)
  Building (Z3): In progress (15 API endpoints, 8 React pages, 3 TODO features)
  Hardening (Z4): Partial (CI exists but no quality gate, 23 tests)
  Launch (Z5): Not yet (Dockerfile but no deployment config)
  → Current Zone: Building (Z3) — partial Hardening

Step 3 — Gap Analysis:
  PRESENT: README.md, .gitignore, CI config, test files, docs/
  PARTIAL: CLAUDE.md (exists but outdated), lint config (ruff but not enforced)
  MISSING: START_HERE.md, CONTEXT_CHAIN.md, ARCHITECTURE.md,
           GOLDEN_PRINCIPLES.md, QUALITY_SCORE.md, TECH_DEBT.md,
           plans/, completed/, pre-commit hooks
  → 5/20 PRESENT, 2/20 PARTIAL, 13/20 MISSING

Step 4 — Quality Baseline:
  Tests: 23/25 passing (2 FAIL), 34% coverage
  Lint: 12 warnings, 0 errors
  Build: SUCCESS (Docker build + npm build)
  → Estimated score: 55/100

Step 4e — Automation Opportunities:
  MCP: context7 (FastAPI+Next.js versions change fast), playwright-mcp (E2E testing)
  Hooks: ruff format on edit (Python), eslint --fix on edit (TS), block .env writes

Step 5 — Retroactive Context:
  Started 2025-11-15, 347 commits, 2 contributors
  Last active: 2 days ago
  Active development on invoice module

Step 6 — Report assembled.
  Recommendation: Run /blox:idea retrofit — priority: CLAUDE.md → START_HERE → tests
```

### Example 2: Empty Directory (Ideation zone)

```
Agent: Running /blox:scan on current project.

Step 1 — Tech Stack Scan:
  No package manager, no code files, only 2 markdown files
  → Tech Stack: Markdown only (research/planning, no code)

Step 2 — Zone Detection:
  Ideation (Z0): Partial (some notes exist)
  Planning–Evolution (Z1–Z7): N/A
  → Current Zone: Ideation (Z0)

Step 3 — Gap Analysis:
  MISSING: 19/20 elements
  PRESENT: 1/20 (README.md — basic)
  → Almost everything missing

Step 4 — Quality Baseline:
  No tests, no lint, no build → N/A
  → Estimated score: 10/100

Step 5 — Retroactive Context:
  No git repo. 2 markdown files created 3 days ago.

Step 6 — Report assembled.
  Recommendation: Initialize git repo, then /blox:idea greenfield mode
```

### Example 3: Mature Next.js + Supabase Project (Maintenance zone)

```
Agent: Running /blox:scan on current project.

Step 1 — Tech Stack Scan:
  Found: package.json (Next.js 14, React 18, TypeScript, Tailwind, @supabase/supabase-js)
  Found: supabase/config.toml, prisma/schema.prisma
  Found: vercel.json, .github/workflows/ci.yml
  → Tech Stack: Next.js + React + TypeScript + Tailwind + Supabase + Prisma + Vercel + GitHub Actions

Step 2 — Zone Detection:
  Ideation through Launch (Z0–Z5): Done (fully deployed, CI/CD active)
  Maintenance (Z6): Active (recent dependency updates, bugfix commits)
  Evolution (Z7): N/A (no new features in last 30 days)
  → Current Zone: Maintenance (Z6)

Step 3 — Gap Analysis:
  PRESENT: 16/20 elements
  PARTIAL: 2/20 (QUALITY_SCORE.md outdated, TECH_DEBT.md incomplete)
  MISSING: 2/20 (pre-commit hooks, GOLDEN_PRINCIPLES.md)
  → Strong foundation, minor gaps

Step 4 — Quality Baseline:
  Tests: 142/142 passing, 78% coverage
  Lint: 3 warnings, 0 errors
  Build: SUCCESS
  Type check: 0 errors
  → Estimated score: 85/100

Step 5 — Retroactive Context:
  Started 2025-06-20, 1,204 commits, 3 contributors
  Last active: yesterday (dependency update)
  Stable production system with regular maintenance

Step 6 — Report assembled.
  Recommendation: Add pre-commit hooks + update QUALITY_SCORE.md, run /blox:idea to backfill
```

---

## VERIFICATION

### Success indicators
- Structured AUDIT REPORT generated (markdown format, not free text in chat)
- Tech stack dynamically identified with specific technologies listed (no T1-T7 labels)
- Zone determined with human-readable label and Z-code, with per-zone breakdown
- Gap Analysis table with status for all 20 standard elements (including G-18 AI attribution check, G-19 phase marker consistency, G-20 curated plugins)
- Quality Baseline measured (tests, lint, build — or noted as N/A)
- Retroactive Context with project history summary
- Recommended next steps included
- **NO files were modified** (read-only invariant!)

### Failure indicators (STOP and fix!)
- Report is informal chat text (not structured markdown)
- Files were created or modified (VIOLATES read-only invariant!)
- Missing tech stack or zone detection
- Gap analysis incomplete (fewer than 20 elements checked)
- No quality baseline attempted
- Using T1-T7 category labels instead of dynamic tech stack detection
- Using bare Z0-Z7 codes without human-readable zone names

---

## REFERENCES (optional)

- `references/patterns/knowledge-patterns.md` — Standard patterns the gap analysis checks against
- `references/templates/project-scaffold.md` — Standard project structure for gap comparison
- `registry/curated-plugins.yaml` — Curated plugin registry for G-20 evaluation
