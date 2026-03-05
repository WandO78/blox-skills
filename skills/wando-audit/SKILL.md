---
name: wando-audit
description: "Assess any project's current state without modifying it: detect tech stack, zone (Z0-Z7), run gap analysis against standards, measure quality baseline. Output is a structured report for /wando:init retrofit mode."
version: "1.0.0"
user-invocable: true
allowed-tools: [Read, Glob, Grep, Bash, Agent]
---

# /wando:audit

> **Read-only project assessment — the "X-ray" skill.**
> Looks at everything, touches nothing. Outputs a structured AUDIT REPORT
> that serves as input for `/wando:init` retrofit mode or standalone health checks.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-audit
category: init
complements: [wando-init, wando-gc]

### Triggers — when the agent invokes automatically
trigger_keywords: [audit, assessment, health, gap, diagnose, status, check, felmeres, allapot]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when assessing a project's current state: what's there, what's missing,
  what zone it's in, what tech stack it uses. Read-only — NEVER modifies files.
  Output is a structured AUDIT REPORT used as input for /wando:init retrofit mode.
  Also useful for periodic health checks and phase-end quality assessment.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Existing project assessment | "What's the state of this project?" | No — user invokes |
| Before retrofit | Input for `/wando:init` retrofit mode | No — user invokes |
| Periodic health check | "Has anything degraded?" | No — user or `/wando:gc` invokes |
| Phase-end quality check | "How's our quality trending?" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Need to modify the project | Audit is READ-ONLY | `/wando:init` (creates/modifies) |
| Code quality review | Different purpose — evaluates code changes | `/wando:review` |
| Brand new empty project | Nothing to audit | `/wando:init` (greenfield) |
| Mid-phase progress check | Different granularity | `/wando:checkpoint` |

---

## CRITICAL INVARIANT

> **The audit NEVER modifies any file. EVER.**
> It reads, scans, runs test commands, analyzes git history — but writes NOTHING.
> The output is a structured report delivered as agent output (or saved to a
> user-specified location if requested).

---

## SKILL LOGIC

> **6-step read-only assessment pipeline.**
> Each step produces a section of the final AUDIT REPORT.

### Step 1: Tech Stack Scan

> **Goal:** Identify what technologies the project uses → determine Project Type (T1-T7).

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
.clasp.json                      → Google Apps Script (T4)

# HA / IoT (T5)
configuration.yaml    → Home Assistant
custom_components/    → HA custom integration

# Claude / AI
.claude/              → Claude Code config
CLAUDE.md             → Claude project instructions
```

**Project Type Heuristic (T1-T7):**

| Type | Heuristic |
|------|-----------|
| T1: Corporate full-stack | Python BE + React/Next FE + Docker + SQL DB + cloud deploy config |
| T2: Personal full-stack | Next.js (or similar) + Vercel/AWS deploy + simpler infra |
| T3: Research/Planning | Markdown files only, no code, no package manager |
| T4: Apps Script | `.clasp.json` present, Google APIs |
| T5: Home Assistant IoT | `configuration.yaml`, `custom_components/` |
| T6: One-off task | Minimal files, no project structure, no package manager |
| T7: Data Pipeline | Python + ETL patterns, no frontend, data processing focus |

**Output for report:** `Project Type: T[X] — [label]` + tech stack details.

---

### Step 2: Zone Detection (Z0-Z7)

> **Goal:** Determine where the project is in its lifecycle.
> Zones are detected top-down — check the highest zone first.

**Zone Detection Heuristic (check from Z7 down to Z0):**

```
Z7 EVOLVE — Is this a live system getting new features?
  Check: Is it deployed AND has recent feature branches/PRs?
  Evidence: production URL + feature branches in last 30 days

Z6 MANAGE — Is this a live system in maintenance?
  Check: Is it deployed AND has recent bug fixes/dependency updates?
  Evidence: production URL + bugfix/chore commits + no new features

Z5 SHIP — Is there a deployment?
  Check: Is there a working deploy pipeline or live URL?
  Evidence: vercel.json + deployed, Dockerfile + cloud config, CI/CD with deploy step

Z4 HARDEN — Are there quality measures?
  Check: Are there tests, lint, CI, documentation?
  Evidence: test files + CI config + lint config + >60% coverage

Z3 BUILD — Is there working code?
  Check: Is there application code beyond scaffolding?
  Evidence: src/ or app/ with substantial files, API routes, business logic

Z2 FOUNDATION — Is the infra set up?
  Check: Is there a repo with basic setup?
  Evidence: package.json + basic config files, DB schema, auth setup

Z1 DESIGN — Is there a design/plan?
  Check: Are there architecture docs, wireframes, specs?
  Evidence: ARCHITECTURE.md, design files, spec documents

Z0 UNDERSTAND — Just research?
  Check: Only notes, research, brainstorm docs?
  Evidence: markdown files only, no code, no infra
```

**Important:** A project can be BETWEEN zones. Report the primary zone AND note partial progress in adjacent zones.

Example: "Zone: Z3 (BUILD) — partial Z2 (has DB but no auth), Z4 absent (no tests)"

**Output for report:** `Current Zone: Z[X] — [label]` + zone detail notes.

---

### Step 3: Gap Analysis

> **Goal:** Compare current project state against standard elements.
> Uses TEMPLATES.md Section 3 as the reference checklist.

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

This is a ROUGH estimate — not the same as the `/wando:review` Quality Score.
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
> **Auditor:** /wando:audit v1.0.0
> **Duration:** [X minutes]

---

## 1. Project Identity

- **Project Type:** T[X] — [label]
- **Current Zone:** Z[X] — [label]
- **Tech Stack:** [detailed list]
- **Repository:** [git status — clean/dirty, branch, remote]

## 2. Project Description

[2-3 sentences: what it is, what it does, where it's headed]

## 3. Zone Detail

| Zone | Status | Evidence |
|------|--------|----------|
| Z0 UNDERSTAND | [Done/Partial/N/A] | [evidence] |
| Z1 DESIGN | [Done/Partial/N/A] | [evidence] |
| Z2 FOUNDATION | [Done/Partial/N/A] | [evidence] |
| Z3 BUILD | [Done/Partial/N/A] | [evidence] |
| Z4 HARDEN | [Done/Partial/N/A] | [evidence] |
| Z5 SHIP | [Done/Partial/N/A] | [evidence] |
| Z6 MANAGE | [Active/N/A] | [evidence] |
| Z7 EVOLVE | [Active/N/A] | [evidence] |

## 4. Gap Analysis

| # | Element | Status | Notes |
|---|---------|--------|-------|
| G-01 | CLAUDE.md | [PRESENT/PARTIAL/MISSING] | [details] |
| G-02 | START_HERE.md | [PRESENT/PARTIAL/MISSING] | [details] |
| ... | ... | ... | ... |

**Summary:** X/18 PRESENT, Y/18 PARTIAL, Z/18 MISSING

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

## 7. Recommended Next Steps

Based on the audit findings:

1. [If G-18 FOUND: "Remove AI attribution from code and git history" — always first priority]
2. [Most urgent action — usually CLAUDE.md or test setup]
3. [Second priority]

**Recommended approach:**
- [ ] Run `/wando:init` in retrofit mode (pass this report as input)
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

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Audit complete → user wants retrofit | `/wando:init` (retrofit mode) | User decides after seeing report |
| Periodic health check | Called BY `/wando:gc` | As part of garbage collection |
| Quality comparison needed | Compare with `/wando:review` output | Different scope but complementary |

---

## EXAMPLES

### Example 1: Corporate FastAPI Project (T1, Z3)

```
Agent: Running /wando:audit on current project.

Step 1 — Tech Stack Scan:
  Found: requirements.txt (FastAPI, SQLAlchemy, alembic, pytest)
  Found: Dockerfile, docker-compose.yml
  Found: .github/workflows/ci.yml
  Found: src/frontend/ (React, package.json with Next.js)
  → Project Type: T1 — Corporate Full-Stack (Python BE + React FE)

Step 2 — Zone Detection:
  Z0 UNDERSTAND: Done (README has project description)
  Z1 DESIGN: Partial (no ARCHITECTURE.md, but DB schema exists)
  Z2 FOUNDATION: Done (repo, DB, auth, Docker)
  Z3 BUILD: In progress (15 API endpoints, 8 React pages, 3 TODO features)
  Z4 HARDEN: Partial (CI exists but no quality gate, 23 tests)
  Z5 SHIP: Not yet (Dockerfile but no deployment config)
  → Current Zone: Z3 (BUILD) — partial Z4

Step 3 — Gap Analysis:
  PRESENT: README.md, .gitignore, CI config, test files, docs/
  PARTIAL: CLAUDE.md (exists but outdated), lint config (ruff but not enforced)
  MISSING: START_HERE.md, CONTEXT_CHAIN.md, ARCHITECTURE.md,
           GOLDEN_PRINCIPLES.md, QUALITY_SCORE.md, TECH_DEBT.md,
           plans/, completed/, pre-commit hooks
  → 5/17 PRESENT, 2/17 PARTIAL, 10/17 MISSING

Step 4 — Quality Baseline:
  Tests: 23/25 passing (2 FAIL), 34% coverage
  Lint: 12 warnings, 0 errors
  Build: SUCCESS (Docker build + npm build)
  → Estimated score: 55/100

Step 5 — Retroactive Context:
  Started 2025-11-15, 347 commits, 2 contributors
  Last active: 2 days ago
  Active development on invoice module

Step 6 — Report assembled.
  Recommendation: Run /wando:init retrofit — priority: CLAUDE.md → START_HERE → tests
```

### Example 2: Empty Directory (T3/T6, Z0)

```
Agent: Running /wando:audit on current project.

Step 1 — Tech Stack Scan:
  No package manager, no code files, only 2 markdown files
  → Project Type: T3 — Research/Planning (or T6 if truly one-off)

Step 2 — Zone Detection:
  Z0 UNDERSTAND: Partial (some notes exist)
  Z1-Z7: N/A
  → Current Zone: Z0 (UNDERSTAND)

Step 3 — Gap Analysis:
  MISSING: 16/17 elements
  PRESENT: 1/17 (README.md — basic)
  → Almost everything missing

Step 4 — Quality Baseline:
  No tests, no lint, no build → N/A
  → Estimated score: 10/100

Step 5 — Retroactive Context:
  No git repo. 2 markdown files created 3 days ago.

Step 6 — Report assembled.
  Recommendation: Initialize git repo, then /wando:init greenfield mode
```

---

## VERIFICATION

### Success indicators
- Structured AUDIT REPORT generated (markdown format, not free text in chat)
- Project Type (T1-T7) identified with evidence
- Zone (Z0-Z7) determined with per-zone breakdown
- Gap Analysis table with status for all 18 standard elements (including G-18 AI attribution check)
- Quality Baseline measured (tests, lint, build — or noted as N/A)
- Retroactive Context with project history summary
- Recommended next steps included
- **NO files were modified** (read-only invariant!)

### Failure indicators (STOP and fix!)
- Report is informal chat text (not structured markdown)
- Files were created or modified (VIOLATES read-only invariant!)
- Missing project type or zone detection
- Gap analysis incomplete (fewer than 18 elements checked)
- No quality baseline attempted

---

## REFERENCES (optional)

- `references/ARCHITECTURE_INVARIANTS.md` — Standard elements the gap analysis checks against
- `PROJECT_LIFECYCLE.md` — Zone definitions (Z0-Z7) and project types (T1-T7)
- `TEMPLATES.md` Section 3 — Standard project structure for gap comparison
