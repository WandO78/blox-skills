# /blox:plan — Worked Examples

Reference walkthroughs of the phase-file generation pipeline. Decision logic lives in SKILL.md.

## Example 1: Standard Phase (new feature)

**User says:** "Plan the user dashboard feature."

**Agent runs `/blox:plan`:**

1. Repo Knowledge Check -> reads ARCHITECTURE.md (frontend layer, API routes), GOLDEN_PRINCIPLES.md (Zod schema first), etc.
2. Context -> Tech stack: Next.js + React + TypeScript + Prisma + PostgreSQL. Zone: Building (Z3).
3. Template -> Standard (not production, not > 50 items)
4. AUTO-DISCOVERY -> matches: `/test-driven-development` (mandatory), `/react-best-practices` (trigger: "dashboard", "component"), `/frontend-design` (trigger: "UI", "page"), `_internal/checkpoint` (mandatory), `/blox:check` (mandatory)
5. Skill-to-phase mapping -> Phase 05: Dashboard Build -> `/blox:build` + `/blox:design`
6. Checklist -> ~30 items in 3 sections (Schema + API, Frontend Components, Integration)
7. Exit Criteria -> Dashboard renders, API returns data, tests PASS, lint PASS
8. Invariants -> "Zod schema FIRST", "Route handler max 50 lines"
9. START_HERE.md -> new row added
10. Present to user -> approved

## Example 2: Evolution Phase (production system)

**User says:** "Add date range filter to all report listing pages."

**Agent detects Evolution:** CLAUDE.md says "Status: PRODUCTION", 15 active users -> Evolution (Z7)

**Agent runs `/blox:plan`:**

1. Standard phase generated PLUS 4 Evolution extra sections
2. Impact Analysis (IA-1..IA-8) added as FIRST section
3. Rollback Plan: feature flag OFF < 5 min
4. Feature Flag: FEATURE_BUDGET_YEAR_FILTER, default OFF
5. Regression Checkpoint: existing test count recorded, EVERY COMMIT regression check
6. Checklist includes: EVOLVE-PRE (Impact Analysis) -> EVOLVE-BUILD (implementation) -> EVOLVE-VALIDATE -> EVOLVE-RELEASE

## Example 3: Sub-phase Split (large scope)

**Agent generates checklist -> counts 75 items**

**Agent proposes:** "This phase has 75 items, exceeding the 50-item limit. I recommend splitting into:
- Phase 05a: Database Schema + Backend API (35 items)
- Phase 05b: Frontend Components + Integration (40 items)

Phase 05b depends on Phase 05a. Approve this split?"

## Example 4: Skill-to-phase mapping in a greenfield project

**User says:** "Plan the full MVP for this SaaS app."

**Agent detects:** Tech stack: Next.js + Tailwind + Supabase + Vercel. Zone: Foundation (Z2).

**Agent generates master plan with skill mapping:**

```
Phase 01: Brand Identity           -> /blox:brand
Phase 02: System Architecture      -> /blox:design
Phase 03: Auth + Database Setup    -> /blox:build
Phase 04: Core Feature Build       -> /blox:build
Phase 05: Testing + Security Audit -> /blox:test + /blox:secure
Phase 06: Deployment Pipeline      -> /blox:deploy
Phase 07: User Documentation       -> /blox:docs
```

Each phase file includes the primary skill in its Skills & Tools table.
