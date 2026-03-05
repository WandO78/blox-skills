# Knowledge Patterns — Embedded Engineering Principles

> **Source:** Distilled from SYNTHESIS.md (4 OpenAI Engineering articles)
> **Used by:** `/wando:plan` (Step 2), `/wando:init` (Stage 3), `/wando:review` (Step 3)
> **Purpose:** These patterns are APPLIED AUTOMATICALLY by the skills — the user
> does NOT need to know the underlying theory. The system delivers quality results.

---

## Pattern 1: Layered Context Model

> *Source: Data Agent — 6-layer context pyramid*

**What it is:** Every feature needs context organized in layers, from concrete (code) to abstract (decisions). Missing layers = agent produces garbage.

**The agent APPLIES this pattern by building a context table for every phase:**

```
| Layer | What exists | What's missing | Action |
|-------|------------|----------------|--------|
| 1. Code & Schema | [list files/modules] | [gaps] | Read before coding |
| 2. Documentation | [ARCHITECTURE, specs] | [gaps] | Create if missing |
| 3. Project Memory | [completed phases, GP] | [gaps] | Read for lessons |
| 4. Tacit Knowledge | [anything NOT in repo] | [gaps] | WRITE IT DOWN NOW |
| 5. Runtime Context | [logs, metrics, state] | [gaps] | Fetch if needed |
| 6. External Refs | [API docs, framework] | [gaps] | Add to references/ |
```

**Key rule:** Layer 4 (Tacit Knowledge) is the most dangerous gap. If knowledge exists only in someone's head, Slack, or a Google Doc — it MUST be written into the repo before the phase starts. "What can't be seen doesn't exist."

**Default action for missing layers:**
- Layer 1-3: Read what exists, note gaps in the phase plan
- Layer 4: ASK the user and write it to docs/
- Layer 5: Include data-gathering tasks at phase start
- Layer 6: Add LLM-friendly reference docs to references/

---

## Pattern 2: Decision Waterfall

> *Source: Rate Limits — hybrid access control with layered fallbacks*

**What it is:** Every decision point in a feature needs 4 layers. Most bugs happen because developers only code the happy path and forget what happens when things go wrong.

**The agent APPLIES this pattern by generating a decision table for every significant behavior:**

```
| Decision Point | Primary (happy path) | Soft Limit (degraded) | Fallback (minimum) | Graceful Degradation |
|----------------|---------------------|----------------------|--------------------|--------------------|
| [e.g., API call] | Normal response | Cached/stale data | User-friendly error | Loading skeleton |
| [e.g., auth check] | Full access | Read-only mode | Login redirect | Offline notice |
| [e.g., data save] | Instant save | Queued save | Local draft | "Unsaved" indicator |
```

**Key rules:**
- EVERY user-facing feature gets at least one decision waterfall row
- The "Graceful Degradation" column is MANDATORY — the system must NEVER crash or show a blank screen
- Internal/backend features: at minimum Primary + Fallback
- The fallback should be the SIMPLEST working version, not a complex alternative

**Default behaviors when the developer doesn't specify:**
- API fails → show cached data or friendly error, never raw error
- Auth unclear → redirect to login, never show unauthorized data
- Data save fails → save locally, retry later, never lose user's work

---

## Pattern 3: Progressive Disclosure

> *Source: Harness Engineering — CLAUDE.md as map, not encyclopedia*

**What it is:** Start with the minimum context needed, deepen on demand. Applies to documentation, UI, and code architecture.

**The agent APPLIES this pattern in three areas:**

**Documentation:**
```
CLAUDE.md (~100 lines)     → Map: "for X, see docs/Y"
├── ARCHITECTURE.md        → Layer diagram + tech stack
├── docs/design-docs/      → Feature-specific decisions
├── docs/references/       → External API docs (LLM-friendly)
└── GOLDEN_PRINCIPLES.md   → Invariants
```
Rule: CLAUDE.md NEVER exceeds ~100 lines. It is a table of contents, not a manual.

**UI/UX (when building frontend):**
```
Initial load → minimum data (list view, top 10)
User action  → progressive detail (open item → full data)
Deep dive    → on-demand fetch (history, analytics, related)
```

**Code architecture:**
```
Types     → pure definitions, no logic
Config    → values only, no business rules
Data      → queries and persistence
Service   → business logic (THIS is where decisions live)
API       → thin handlers that delegate to services
UI        → renders data, sends actions
```
Rule: Each layer sees ONLY the layer below it. Never skip layers.

---

## Pattern 4: Fix the Environment, Not the Agent

> *Source: Harness Engineering — "The fix was never 'try harder'"*

**What it is:** When a task fails, DON'T retry with a stronger prompt. Instead, add the missing tool, guardrail, or documentation so the failure CAN'T happen again.

**The agent APPLIES this pattern by asking after every failure:**

```
FAILURE ANALYSIS:
1. What failed? → [specific error or wrong output]
2. WHY? → [root cause — missing context? wrong assumption? unclear spec?]
3. What's missing from the ENVIRONMENT? →
   □ Missing documentation → write it to docs/
   □ Missing test → write the test
   □ Missing lint rule → add it (with remediation message!)
   □ Missing tool/script → create it
   □ Unclear spec → write it down, ask user to confirm
4. ACTION: Add the missing piece to the repo BEFORE retrying
```

**Key rule:** The environment fix becomes PERMANENT. Future phases benefit from it. This is how the project gets better over time — every failure improves the system.

**Lint rules with remediation messages:**
When adding a lint rule, the error message MUST tell the agent HOW to fix it:
```
BAD:  "Error: route handler too long"
GOOD: "Error: route handler exceeds 50 lines. Extract business logic into
       a service function in services/[domain].ts, keep the route handler
       as a thin wrapper that calls the service."
```

---

## Pattern 5: Mechanical Enforcement Over Documentation

> *Source: Harness Engineering — rules as code*

**What it is:** If a rule CAN be checked by a machine, DON'T rely on documentation. Create a test, lint rule, or CI check instead.

**The agent APPLIES this pattern by evaluating every Golden Principle:**

```
For each Golden Principle:
├── Can it be checked by a linter? → CREATE lint rule
├── Can it be checked by a test? → CREATE structural/integration test
├── Can it be checked by CI? → ADD CI step
├── Can it be checked by a pre-commit hook? → ADD hook
└── None of the above? → Keep as documentation (but flag as "soft rule")
```

**Default enforcement levels by project type:**
- T1 (Corporate): CI + lint + pre-commit hooks (maximum enforcement)
- T2 (Personal): lint + tests (moderate enforcement)
- T3 (Research): documentation only (minimal enforcement)
- T4-T7: lint + tests (moderate enforcement)

**Key rule:** Every time a Golden Principle is VIOLATED and caught by review (not by automation), the review should ask: "Can we promote this to a machine-enforceable rule?"

---

## Pattern 6: Sync Decision + Async Accounting

> *Source: Rate Limits — real-time access + async credit tracking*

**What it is:** Decide FAST on things that block the user. Track, reconcile, and refine in the background.

**The agent APPLIES this pattern when designing features:**

```
| Operation | Sync (blocks user) | Async (background) |
|-----------|-------------------|-------------------|
| Save data | Acknowledge save immediately | Validate, index, sync replicas |
| Submit form | Show success/failure | Send notifications, update reports |
| API request | Return response | Log analytics, update rate limits |
| Deploy | Confirm deploy started | Run smoke tests, notify team |
```

**Key rule:** If the user is WAITING → make it sync and FAST. If the user doesn't need the result NOW → make it async. Never make the user wait for something they don't need immediately.

**Default:** When unsure, make the user-facing action sync (immediate feedback) and the system-side accounting async.

---

## Pattern 7: Automated Review Loop

> *Source: Harness Engineering — agent-to-agent review*

**What it is:** The agent reviews its OWN work before presenting it. Quality gates are automated, not optional.

**The agent APPLIES this pattern in every phase:**

```
Code written → Agent self-review (lint, tests, invariants) → Fix issues
            → If tests PASS and lint PASS → Present to user
            → If tests FAIL → Fix and re-check (max 3 iterations)
            → If still failing after 3 → STOP, explain what's wrong
```

**Default review pipeline:**
1. Run tests → all PASS?
2. Run linter → 0 errors?
3. Check Golden Principles → no violations?
4. If all PASS → proceed
5. If ANY FAIL → fix, re-run (not "try harder" — fix the specific issue)

**Key rule:** NEVER claim "done" without running verification commands. The Iron Law: "Evidence before assertions, always."

---

## Pattern 8: Provability Through Golden Answers

> *Source: Rate Limits + Data Agent — eval pipeline with golden SQL*

**What it is:** Define expected input-output pairs BEFORE coding. These are the objective test of correctness — not "looks right" but "produces the exact expected output."

**The agent APPLIES this pattern by generating Golden Answers in every phase:**

```
| # | Input/Scenario | Expected Output | Test Method |
|---|---------------|-----------------|-------------|
| GA-01 | [specific input] | [exact expected result] | [how to verify] |
| GA-02 | [edge case] | [expected handling] | [how to verify] |
| GA-03 | [error case] | [expected error response] | [how to verify] |
```

**Minimum Golden Answers per phase:**
- Simple phase (< 20 items): 3 Golden Answers
- Standard phase (20-40 items): 5 Golden Answers
- Complex phase (40-50 items): 7 Golden Answers

**Key rule:** Golden Answers should test BEHAVIOR, not implementation. "The output is X" not "the code calls function Y." Functionally equivalent outputs are acceptable (don't do naive string matching).

---

## Pattern 9: Knowledge Lifecycle

> *Source: Data Agent + Harness — memory, learning, garbage collection*

**What it is:** Knowledge flows through a lifecycle: discover → capture → validate → promote → maintain → retire. Every phase produces knowledge that must be managed.

**The agent APPLIES this pattern at every phase close:**

```
Phase produces knowledge:
├── Pattern worked well? → GOLDEN_PRINCIPLES.md (permanent)
│   └── Works 2+ times? → Promote to lint rule / CI check
├── Pattern failed? → Phase Memory antipatterns (permanent)
│   └── Can prevent recurrence? → Add test or guardrail
├── New decision made? → ARCHITECTURE.md update
├── Compromise accepted? → TECH_DEBT.md entry
│   └── With resolution plan and trigger condition
└── Documentation stale? → Update or delete (never leave stale docs)
```

**Garbage collection (applied by /wando:gc):**
- Docs older than the code they describe → FLAG as stale
- Cross-links to deleted files → REMOVE
- Tech debt items past their trigger → REMIND
- Golden Principles never violated → KEEP (they're working)
- Golden Principles frequently violated → PROMOTE to enforcement

---

## Pattern 10: Momentum Protection

> *Source: Rate Limits + Data Agent — "corrections are cheap, waiting is expensive"*

**What it is:** The system should NEVER block the user unnecessarily. When in doubt, apply a reasonable default and move forward. Document the assumption for later correction.

**The agent APPLIES this pattern with these defaults:**

```
| Situation | Default Action | Document As |
|-----------|---------------|-------------|
| Unclear requirement | Apply most common pattern, note assumption | Phase file "Assumptions" |
| Missing API spec | Build interface, mock implementation | TECH_DEBT.md "Pending spec" |
| Two valid approaches | Pick simpler one, note alternative | Phase Memory |
| Edge case unclear | Handle gracefully (no crash), log warning | TECH_DEBT.md |
| User not responding | Continue with reasonable defaults | CONTEXT_CHAIN.md note |
```

**Key rules:**
- Checkpoints protect against loss → the agent can move FAST because work is saved
- "Corrections are cheap, waiting is expensive" — merge fast, fix follow-up
- If something is 80% right, SHIP IT and fix the 20% in the next checkpoint
- NEVER block for perfection — good enough NOW beats perfect LATER

**Exceptions (DO block for these):**
- Security vulnerabilities → STOP, fix before proceeding
- Data loss risk → STOP, ensure backup
- Breaking change to production → STOP, S2 user decision required

---

## Pattern 11: Worktree Isolation

> *Source: Harness Engineering — worktree-per-change*

**What it is:** Every parallel task gets its own isolated copy of the codebase. Changes don't interfere with each other.

**The agent APPLIES this pattern when /wando:dispatch detects parallelizable work:**

```
Leader (main branch):
├── Worker A (worktree: .claude/worktrees/worker-a) → Section 1
├── Worker B (worktree: .claude/worktrees/worker-b) → Section 2
└── Worker C (worktree: .claude/worktrees/worker-c) → Section 3

Merge order: A → B → C (defined in Parallel Work Plan)
Post-merge: FULL test suite (MANDATORY)
```

**Key rules:**
- Workers NEVER modify shared files (config, barrel exports, shared types)
- Shared files are LEADER-ONLY
- Each worker runs its own tests before reporting done
- Post-merge full test suite catches integration issues

---

## Pattern 12: Workflows as Reusable Skills

> *Source: Data Agent — recurring analyses packaged as workflows*

**What it is:** When you do something more than twice, package it as a skill/workflow. Rögzített tudás + újrahasználható végrehajtási minta.

**The agent APPLIES this pattern by monitoring for repetition:**

```
IF (same pattern appears in 2+ phases):
  → Consider: should this become a skill or a documented pattern?
  → If it's a PROCESS (multi-step): create a skill
  → If it's a RULE (single check): add to GOLDEN_PRINCIPLES.md
  → If it's a CODE PATTERN: create a shared utility
```

**This is already embedded in the skill library itself** — the wando-skills ARE the packaged workflows. The agent doesn't need to create new skills, but should recognize when a project-specific pattern deserves promotion.

---

## Pattern 13: Agent-First Quality Standards

> *Source: Harness Engineering — "the discipline shows up in the scaffolding"*

**What it is:** Quality is measured by correctness, maintainability, and agent-legibility — NOT by human style preferences. The scaffolding (tools, tests, docs) matters more than code aesthetics.

**The agent APPLIES this pattern by prioritizing:**

```
QUALITY PRIORITY (highest to lowest):
1. CORRECT — tests pass, Golden Answers match, no regressions
2. SAFE — no security vulnerabilities, no data loss risk
3. MAINTAINABLE — other agents can work on this code
4. AGENT-LEGIBLE — clear naming, documented decisions, no magic
5. STYLE — follows project conventions (lowest priority)
```

**Key rule:** "Boring tech" is preferred. Simple, well-known patterns over clever solutions. The agent understands common libraries better because they're in the training data.

**Default tech choices (when not specified by user):**
- State management: simplest option that works (React state → Context → dedicated lib)
- API design: REST unless real-time needed → then WebSocket/SSE
- Database: PostgreSQL (unless specific reason for NoSQL)
- Frontend: React/Next.js (unless user specifies otherwise)
- Testing: project's existing framework, or vitest/pytest as defaults

---

## How Skills Use These Patterns

| Skill | Patterns Applied | How |
|-------|-----------------|-----|
| `/wando:plan` | ALL 13 | Step 2 generates pattern-based phase structure |
| `/wando:init` | 1, 3, 4, 5, 9, 13 | Seeds project files with pattern defaults |
| `/wando:checkpoint` | 10 | Momentum protection via automatic saves |
| `/wando:review` | 5, 7, 8 | Checks enforcement, review loop, Golden Answers |
| `/wando:close` | 4, 9 | Fix environment on failure, knowledge lifecycle |
| `/wando:audit` | 1, 3, 5 | Evaluates context layers, architecture, enforcement |
| `/wando:dispatch` | 11 | Worktree isolation for parallel work |
| `/wando:gc` | 9 | Knowledge lifecycle maintenance |
