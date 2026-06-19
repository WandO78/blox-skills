# /blox:scan — Worked Examples

Reference walkthroughs of the 6-step read-only audit pipeline. Decision logic lives in SKILL.md.

## Example 1: FastAPI + React Project (Building zone)

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

## Example 2: Empty Directory (Ideation zone)

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

## Example 3: Mature Next.js + Supabase Project (Maintenance zone)

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
