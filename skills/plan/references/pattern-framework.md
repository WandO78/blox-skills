# /blox:plan — 9-Section Pattern Framework (Step 2)

Each section contains a PATTERN that the agent APPLIES to the phase — not a question to
answer, but a template to fill in. The user does NOT need to know these patterns exist;
the skill DELIVERS quality results automatically by applying them. (Deeper engineering
rationale: `references/patterns/knowledge-patterns.md`.)

> Not every section needs a detailed table — use judgment based on task complexity.
> For a simple feature, Sections 1-2 might be a single line each.
> For a complex Evolution (Z7) phase, all sections get full tables.

---

## Section 0: Repo Knowledge Check
*(Done in Step 1 — RK-1 through RK-5)*

## Section 1: Context Layers
**Pattern:** Build the 6-layer context table for this phase.

For EACH layer, identify what exists and what's missing:

| Layer | What exists | What's missing | Action |
|-------|------------|----------------|--------|
| 1. Code & Schema | [list relevant files/modules] | [gaps] | Read before coding |
| 2. Documentation | [ARCHITECTURE, specs, design docs] | [gaps] | Create if missing |
| 3. Project Memory | [completed phases, GOLDEN_PRINCIPLES] | [gaps] | Read for lessons |
| 4. Tacit Knowledge | [anything NOT yet in the repo] | [gaps] | **WRITE IT DOWN NOW** |
| 5. Runtime Context | [logs, metrics, current state] | [gaps] | Include data-gather tasks |
| 6. External Refs | [API docs, framework docs] | [gaps] | Add to references/ |

**Layer 4 is the most dangerous gap.** If knowledge exists only in someone's head,
a Slack thread, or a Google Doc — create a checklist item to write it into the repo
BEFORE coding begins. "What can't be seen doesn't exist."

## Section 2: Decision Layers
**Pattern:** For every significant decision point in this feature, generate a 4-layer waterfall table.

| Decision Point | Primary (happy path) | Degraded (constrained) | Fallback (minimum viable) | Error state (never crash) |
|----------------|---------------------|----------------------|--------------------------|--------------------------|
| [e.g., API call] | Normal response | Cached/stale data | User-friendly error msg | Loading skeleton |
| [e.g., auth] | Full access | Read-only mode | Login redirect | Offline notice |
| [e.g., save] | Instant save | Queued background save | Local draft retained | "Unsaved" indicator |

**Rules the agent follows automatically:**
- Every user-facing feature gets at least ONE decision waterfall row
- The "Error state" column is MANDATORY — the system must NEVER crash or show a blank screen
- Internal/backend features: at minimum Primary + Fallback
- The fallback should be the SIMPLEST working version, not a complex alternative
- When the developer doesn't specify: API fail -> cached data or friendly error; auth unclear -> login redirect; save fail -> save locally + retry

## Section 3: Architecture Invariants
**Pattern:** Apply the layered architecture. Define dependency directions.

Identify the layers in this project and enforce one-way dependencies:

```
Layer N: [name] — depends on: [layers below] — NEVER depends on: [layers above]

Default layers (adapt to project):
  Types/Schemas  -> depends on: nothing
  Config         -> depends on: Types
  Data/Repo      -> depends on: Types, Config
  Service        -> depends on: Types, Config, Data
  API/Routes     -> depends on: Types, Service
  UI/Frontend    -> depends on: Types, API (via Service interface)
```

For EACH layer touched by this phase:
- What is the dependency direction?
- What cross-cutting concerns apply? (auth, logging, error handling -> via Providers)
- Can this be checked mechanically? -> If YES: add lint rule or structural test
  - Lint error messages MUST contain remediation instructions for the agent
  - Example: "Route handler > 50 lines. Extract logic to services/[domain].ts"

## Section 4: Agent Readability & Progressive Disclosure
**Pattern:** Apply progressive disclosure to documentation and context.

```
CLAUDE.md (~100 lines) = map, NOT encyclopedia
  -> Points to: ARCHITECTURE.md, docs/, references/
```

Checklist (the agent fills this in automatically):
- [ ] Every piece of knowledge the agent needs IS in the repo
- [ ] If NOT -> add a checklist item to create the missing doc/reference
- [ ] CLAUDE.md doesn't exceed ~100 lines (if growing -> extract to docs/)
- [ ] External library docs -> add LLM-friendly version to references/
- [ ] Complex code -> self-documenting naming (no magic numbers, no unclear abbreviations)
- [ ] Worktree needed? (if parallel work, apply Pattern 11)

## Section 5: Review & Quality Loop
**Pattern:** Apply the automated review pipeline.

Default review flow (agent applies automatically):
```
Code written -> Run tests -> Run linter -> Check Golden Principles
  -> ALL PASS? -> Mark task complete
  -> ANY FAIL? -> Fix specific issue -> Re-run (max 3 iterations)
  -> Still failing? -> STOP, explain the blocker, ask for help
```

For this phase, determine:
- Test framework: [project's existing framework, or vitest/pytest default]
- Lint tool: [project's existing linter, or eslint/ruff default]
- Human review needed at: [S2+ severity only, or at specific milestones]
- Agent self-review: ALWAYS (default — never skip)

**Iron Law (built in):** NEVER claim "done" without running verification commands
and confirming the output shows success. Evidence before assertions.

## Section 6: Provability — Golden Answers
**Pattern:** Define expected input-output pairs BEFORE coding.

Generate a Golden Answers table for this phase:

| # | Input/Scenario | Expected Output | Test Method |
|---|---------------|-----------------|-------------|
| GA-01 | [specific input or scenario] | [exact expected result] | [command/test/check] |
| GA-02 | [edge case] | [expected handling] | [command/test/check] |
| GA-03 | [error case] | [expected error response] | [command/test/check] |

**Minimum counts (agent enforces automatically):**
- Simple phase (< 20 items): 3 Golden Answers
- Standard phase (20-40 items): 5 Golden Answers
- Complex phase (40-50 items): 7 Golden Answers

**Key rule:** Test BEHAVIOR, not implementation. "The output is X" not "the code calls function Y." Functionally equivalent outputs are acceptable.

## Section 7: Knowledge Lifecycle
**Pattern:** Plan what knowledge this phase will produce.

The agent generates a knowledge plan:
```
This phase will produce:
+-- Phase Memory -> MANDATORY (even on fail — especially on fail)
+-- Golden Principles -> [list patterns worth capturing, if any]
|   +-- Promotable to lint/CI? -> [yes/no for each]
+-- Architecture updates -> [if layer structure changes]
+-- Tech Debt entries -> [known compromises]
+-- Docs to update/create -> [list specific files]
```

**Key rule:** If a Golden Principle is violated AND caught only by manual review
(not by automation), add a checklist item: "Promote GP-X to lint rule / CI check."

## Section 8: Momentum Protection
**Pattern:** Apply reasonable defaults, never block for perfection.

Defaults the agent applies automatically:
```
| Situation | Default Action | Document Where |
|-----------|---------------|----------------|
| Unclear requirement | Most common pattern, note assumption | Phase file "Assumptions" |
| Missing API spec | Build interface, mock impl | TECH_DEBT.md |
| Two valid approaches | Pick simpler one, note alternative | Phase Memory |
| Edge case unclear | Handle gracefully (no crash), log | TECH_DEBT.md |
| User not responding | Continue with defaults | CONTEXT_CHAIN.md |
```

**Key rules:**
- Checkpoints protect against loss -> the agent can move FAST
- "Corrections are cheap, waiting is expensive" — ship at 80%, fix at next checkpoint
- NEVER block for perfection — good enough NOW beats perfect LATER

**Exceptions (DO block for these):**
- Security vulnerabilities -> STOP immediately
- Data loss risk -> STOP, ensure backup
- Breaking change to production (Evolution zone) -> STOP, user decision required

## Section 9: Security Awareness
**Pattern:** Auto-inject security checklist items when the phase touches security-sensitive areas.

The agent DETECTS security-relevant scope and ADDS checklist items automatically:

| Phase touches... | Auto-add checklist items |
|-----------------|------------------------|
| New API endpoints | "Input validation on all request params/body", "Rate limiting configured" |
| User authentication | "Auth tokens in httpOnly secure cookies (not localStorage)", "CSRF protection on state-changing routes" |
| Database queries | "All queries use parameterized statements or ORM (no string concat SQL)" |
| File uploads | "File type + size validation server-side", "Uploaded files stored outside webroot" |
| User-generated content display | "Output encoding/sanitization before rendering (prevent XSS)" |
| Environment/secrets | "No hardcoded secrets — all via env vars", ".env in .gitignore" |
| Payment/financial data | "PCI compliance review", "Sensitive data encrypted at rest + in transit" |
| External API calls | "API keys in env vars", "Timeout + error handling on all external calls" |
| Admin/privileged operations | "Authorization check on every privileged endpoint (not just auth)", "Audit logging for admin actions" |

**Rules:**
- Only add items relevant to the phase scope (not all 9 categories every time)
- Items go into the EXISTING sections — not a separate "Security" section
- Each security item is a regular checklist `[ ]` item alongside the feature it protects
- If the phase has NO security-sensitive scope: skip this section entirely
