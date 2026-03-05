---
name: wando-review
description: "Run quality review on completed work: check architectural invariants, run tests, validate Golden Answers, calculate Quality Score, and assign severity (S1-S4). Supports NORMAL (checkpoint) and THOROUGH (phase-end) modes."
version: "1.0.0"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
---

# /wando:review

> **Quality gate for every phase.** 9-step review pipeline that evaluates code,
> architecture, tests, and Golden Answers — then outputs a severity assessment
> (S1-S4) that drives the `/wando:close` decision.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-review
category: quality
complements: [wando-close, wando-checkpoint]

### Triggers — when the agent invokes automatically
trigger_keywords: [review, quality, check, code review, ellenorzes, minoseg, quality check, review code]
trigger_files: [GOLDEN_PRINCIPLES.md, QUALITY_SCORE.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke after significant code changes or at phase completion.
  NORMAL mode: at checkpoints — runs a subset of review steps (1-3, 4, 7).
  THOROUGH mode: at phase end — runs all 9 review steps including
  Golden Answers validation, lint, Quality Score calculation, and severity assessment.
  Called by /wando:close as a mandatory step before phase completion.
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Mode | Auto-invoke? |
|---------|---------|------|-------------|
| After checkpoint (Level 2) | `/wando:checkpoint` SMART completed | NORMAL | No — agent decides |
| Before phase close | `/wando:close` calls it | THOROUGH | Yes — close triggers it |
| Significant code change | Large refactor, new module, API redesign | NORMAL | No — agent decides |
| Explicit user request | "Run a review" / "Check quality" | THOROUGH | User-invoked |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Small change (1-2 lines) | Overhead exceeds value | Run tests directly |
| No Exit Criteria defined yet | Nothing to measure against | First run `/wando:plan` |
| Project-level assessment | Audit READS project state, review EVALUATES phase work | `/wando:audit` |
| No code changes (docs only) | Review pipeline is code-oriented | Manual review |

---

## SKILL LOGIC

> **9-step review pipeline + severity assessment.**
> Two modes: NORMAL (steps 1-3, 4, 7) and THOROUGH (all 9 steps).
> The output is a structured Review Report with a severity rating.

### Input Requirements

Before starting the review, the agent MUST have access to:

| Required | Source | Purpose |
|----------|--------|---------|
| Phase file | `plans/PHASE_XX_*.md` | Exit Criteria, Golden Answers, Verification Commands |
| GOLDEN_PRINCIPLES.md | Project root | Architectural invariants to check |
| QUALITY_SCORE.md | Project root | Current score baseline |
| Git repository | Working directory | diff, log, status for change analysis |

If any required file is missing, the agent notes it as a CONCERN (not FAIL) and continues.

---

### Mode Selection

```
IF called by /wando:close → THOROUGH (always)
IF called at checkpoint → NORMAL
IF called by user without specifying → THOROUGH
IF called by agent after code change → NORMAL
```

**NORMAL mode** runs: Steps 1, 2, 3, 4, 7
**THOROUGH mode** runs: Steps 1, 2, 3, 4, 5, 6, 7, 8, 9

---

### Step 1: Collect Changes

**Purpose:** Establish the scope of what needs reviewing.

**Actions:**
1. Run `git diff` against the baseline (last checkpoint commit or phase start)
2. Count changed files, added lines, deleted lines
3. Categorize changes:
   - `code` — source files (.ts, .py, .js, .rs, etc.)
   - `test` — test files
   - `config` — configuration files
   - `docs` — documentation files
   - `other` — everything else
4. If no git repository, use file modification timestamps and the Phase file's Progress Log to identify changed files

**Output format:**
```
## Change Summary
- Files changed: X (code: Y, test: Z, config: W, docs: V)
- Lines added: +NNN
- Lines deleted: -NNN
- Baseline: [commit hash or "phase start"]
```

**Skip condition:** If no changes detected, STOP and report "No changes to review."

---

### Step 2: Pre-Submission Checklist (8 points)

**Purpose:** Systematic quality gate before deeper review.

Run through each item. Mark PASS, FAIL, or N/A:

```
□ 0. AC verified — Is there EVIDENCE (test output, screenshot, log) for EVERY exit criteria?
□ 1. Approach alignment — Does the implementation match the architectural invariants?
□ 2. Clean code — No TODO, FIXME, HACK, or commented-out code in the commit?
□ 3. Config hygiene — No hardcoded secrets, no .env files committed?
□ 4. Docs updated — ARCHITECTURE.md, API docs, README updated (if affected)?
□ 5. Tests pass — ALL tests green (not just new ones, OLD ones too)?
□ 6. Pattern reuse — Is there an existing solution in the codebase that could be reused?
□ 7. Architecture guard — Does the change violate any Golden Principle?
```

**Scoring:**
- Each FAIL → counted as a FAIL in the Quality Score formula
- Each "uncertain" → counted as a CONCERN
- N/A items are excluded from scoring

**Output format:**
```
## Pre-Submission Checklist
| # | Check | Result | Notes |
|---|-------|--------|-------|
| 0 | AC verified | PASS | All 5 exit criteria have test output |
| 1 | Approach alignment | PASS | Matches ARCHITECTURE.md layer diagram |
| ... | ... | ... | ... |
```

---

### Step 3: Architectural Invariant + Pattern Compliance Check

**Purpose:** Verify that GOLDEN_PRINCIPLES.md rules AND embedded engineering patterns are followed.

**Actions:**
1. Read `GOLDEN_PRINCIPLES.md` (if it exists)
2. For EACH golden principle, check:
   - Does the current change TOUCH files related to this principle?
   - If yes: does it COMPLY or VIOLATE?
3. Also check `references/ARCHITECTURE_INVARIANTS.md` (if exists — plugin-level invariants)
4. **Pattern compliance check** (from `references/KNOWLEDGE_PATTERNS.md`):
   - Decision Waterfall (P2): Do user-facing features have fallback/error handling? → CONCERN if missing
   - Layered Architecture (P3): Do dependencies flow downward only? → FAIL if violated
   - Mechanical Enforcement (P5): Were Golden Principle violations caught by automation or only by review? → If only by review: CONCERN + recommend promotion to lint rule
   - Evidence (P7): Are completion claims backed by verification command output? → FAIL if no evidence
5. For each violation found, record:
   - Which principle/pattern was violated
   - Which file(s) violate it
   - Severity estimate (CONCERN or FAIL)

**If GOLDEN_PRINCIPLES.md does not exist:**
- Note as a CONCERN: "No GOLDEN_PRINCIPLES.md found — cannot validate architectural invariants"
- Continue with remaining steps

**Output format:**
```
## Architectural Invariant Check
| # | Principle | Status | Affected Files | Notes |
|---|-----------|--------|----------------|-------|
| GP-1 | "Route handler max 50 lines" | FAIL | routes/admin/*.ts (8 files) | 8/10 routes > 100 lines |
| GP-2 | "All PII encrypted at rest" | PASS | — | No PII fields touched |
| ... | ... | ... | ... | ... |
```

---

### Step 4: Run Tests (Exit Criteria Verification Commands)

**Purpose:** Execute the phase's Verification Commands and any project-level test suite.

**Actions:**
1. Read the active phase file's "Exit Criteria" section
2. Extract all Verification Commands (bash commands in the code block)
3. Execute EACH command and record PASS/FAIL
4. If the project has a test suite (`npm test`, `pytest`, `cargo test`, etc.), run it too
5. Record test results with actual output

**Output format:**
```
## Test Results
| # | Command | Result | Output (if FAIL) |
|---|---------|--------|------------------|
| 1 | test -s skills/wando-review/SKILL.md | PASS | — |
| 2 | grep "severity" skills/wando-review/SKILL.md | PASS | — |
| 3 | npm test | FAIL | 3 tests failed: user-crud.test.ts:42,89, role-crud.test.ts:15 |
```

---

### Step 5: Lint Check (THOROUGH mode only)

**Purpose:** Run project-level code quality tools.

**Actions:**
1. Detect linter configuration:
   - `.eslintrc*` → `npx eslint .`
   - `pyproject.toml` with `[tool.ruff]` or `[tool.flake8]` → `ruff check .` or `flake8`
   - `.rustfmt.toml` → `cargo fmt --check`
   - `.prettierrc*` → `npx prettier --check .`
   - If no linter found, skip with note: "No linter configured"
2. Run the detected linter(s)
3. Count errors vs warnings
4. Errors → FAIL, Warnings → CONCERN

**Output format:**
```
## Lint Results
- Linter: eslint
- Errors: 0
- Warnings: 2
- Details: [warning details if any]
```

---

### Step 6: Golden Answers Validation (THOROUGH mode only)

**Purpose:** Verify that the phase's expected outputs match reality.

**Actions:**
1. Read the active phase file's "Golden Answers" table
2. For EACH Golden Answer row:
   - Read the "Input" column — what scenario to test
   - Read the "Expected Output" column — what should happen
   - Read the "Test Method" column — how to verify
   - Execute the test method
   - Record PASS/FAIL with actual output

**If no Golden Answers defined:** Skip with note "No Golden Answers defined for this phase."

**Output format:**
```
## Golden Answers Validation
| # | Input | Expected | Actual | Result |
|---|-------|----------|--------|--------|
| GA-05-01 | All tests PASS, 0 invariant violations | S1 or PASS, score >= 90 | Score 95, PASS | PASS |
| GA-05-02 | 2 tests FAIL | S2, user decision required | S2, 3 options presented | PASS |
```

---

### Step 7: Quality Score Calculation

**Purpose:** Compute an objective quality metric.

**Formula (FIXED — do not modify):**
```
score = 100 - (20 × FAIL_count) - (10 × CONCERN_count)

Where:
  FAIL = Exit Criteria failure, Golden Principle violation, test failure
  CONCERN = Warning, sub-optimal but not broken, missing optional item
```

**Counting rules:**
- Step 2 (Pre-Submission): each FAIL item → +1 FAIL_count, each uncertain → +1 CONCERN_count
- Step 3 (Invariants): each VIOLATED principle → +1 FAIL_count, each "partially" → +1 CONCERN_count
- Step 4 (Tests): each FAILED test group → +1 FAIL_count
- Step 5 (Lint): errors → +1 FAIL_count per group, warnings → +1 CONCERN_count per group
- Step 6 (Golden Answers): each FAILED answer → +1 FAIL_count

**Score interpretation:**
| Range | Meaning |
|-------|---------|
| 90-100 | Excellent — ready for close |
| 70-89 | Good but has issues — review findings |
| 50-69 | Significant problems — likely S2+ |
| 0-49 | Major rework needed — likely S3+ |
| < 0 | Catastrophic — many failures |

**Output format:**
```
## Quality Score
- FAIL count: X
- CONCERN count: Y
- Score: 100 - (20 × X) - (10 × Y) = ZZ
- Previous score: [from QUALITY_SCORE.md or "N/A"]
- Trend: [↑ improved / ↓ declined / → stable]
```

---

### Step 8: Severity Assessment (THOROUGH mode only)

**Purpose:** Determine the appropriate response based on review findings.

**Decision logic:**

```
IF score >= 90 AND 0 FAIL:
  → PASS (no severity — phase can be closed)

IF score >= 90 AND minor FAIL (test edge cases):
  → SEVERITY 1: MINOR
  → Action: Auto-generate remediation items, append to phase checklist
  → Phase status: remains IN PROGRESS
  → User decision: NOT required

IF score 70-89 OR architectural problem (GP violation):
  → SEVERITY 2: MODERATE
  → Action: Present 3 options to user
  → Options: (A) Fix now — remediation sub-phase
             (B) Accept with tech debt — log to TECH_DEBT.md, score reduced
             (C) Reject — phase FAILED, new approach needed
  → User decision: REQUIRED

IF score < 70 OR approach fundamentally wrong:
  → SEVERITY 3: MAJOR
  → Action: FAILED status recommended, Phase Memory MANDATORY
  → Phase status: FAILED — REQUIRES REDESIGN
  → User decision: REQUIRED (approve new plan)

IF regression detected (other phase tests broken):
  → SEVERITY 4: CATASTROPHIC
  → Action: Impact analysis + rollback/fix-forward decision
  → Run ALL phase test suites (not just current phase)
  → Phase status: FAILED — REQUIRES REDESIGN
  → User decision: REQUIRED
```

**Cross-phase impact check (S4 detection):**
1. If the current phase modified shared files (shared/, common/, lib/, schemas/)
2. OR if the current phase modified config files that affect other phases
3. THEN: run test suites from OTHER completed phases
4. If any fail → escalate to S4 CATASTROPHIC

**Output format:**
```
## Severity Assessment
- Severity: S2 MODERATE
- Reason: GP-3 and GP-7 violated (route handlers > 50 lines, no service layer)
- Affected files: backend/routes/admin/*.ts (8 files)
- Estimated fix: 4-6 hours
- Recommended action: Present options to user
```

---

### Step 9: Generate Review Report (THOROUGH mode only)

**Purpose:** Compile all findings into a structured, actionable report.

**Report structure:**

```markdown
# Review Report — Phase XX: [Phase Name]
**Date:** YYYY-MM-DD
**Mode:** THOROUGH
**Reviewer:** /wando:review (automated)

## Summary
- Quality Score: XX/100 (trend: ↑/↓/→)
- Severity: [PASS / S1 MINOR / S2 MODERATE / S3 MAJOR / S4 CATASTROPHIC]
- FAIL count: X | CONCERN count: Y

## Issues Found
| # | Step | Severity | Description | Affected Files | Fix Estimate |
|---|------|----------|-------------|----------------|-------------|
| 1 | Step 3 | FAIL | GP-3 violated: routes > 50 lines | routes/admin/*.ts | 4-6h |
| 2 | Step 5 | CONCERN | 2 lint warnings | utils/format.ts | 15min |

## Recommendations
[One of the following based on severity:]

### PASS — Ready for /wando:close
No blocking issues found. Phase can proceed to close.

### S1 MINOR — Auto-remediation
The following items have been added to the phase checklist:
- [ ] FIX-1: [description]
- [ ] FIX-2: [description]
Phase continues — re-run /wando:review after fixes.

### S2 MODERATE — User decision required
Three options:
1. **Fix now** — Remediation sub-phase: [description] (~Xh)
2. **Accept with debt** — Log to TECH_DEBT.md, Quality Score reduced to XX
3. **Reject** — Phase FAILED, new approach needed

### S3 MAJOR — Redesign recommended
The current approach is fundamentally flawed: [reason].
Phase Memory MUST be completed before any changes.
Reusable code: [list of salvageable files]
New approach needed: [guidance from findings]

### S4 CATASTROPHIC — Regression detected
Impact analysis: [list of affected phases and broken tests]
Decision needed: ROLLBACK or FIX-FORWARD?
Post-mortem required for GOLDEN_PRINCIPLES.md update.

## Raw Results
[Include Step 1-7 outputs as sub-sections for reference]
```

---

## NORMAL MODE — Abbreviated Review

When running in NORMAL mode (at checkpoints or after code changes), execute ONLY:

| Step | What | Time |
|------|------|------|
| 1 | Collect changes (git diff) | ~30s |
| 2 | Pre-Submission Checklist (8 points) | ~1min |
| 3 | Architectural invariant check | ~1min |
| 4 | Run tests (Verification Commands) | ~1-2min |
| 7 | Quality Score calculation | ~30s |

**NORMAL mode does NOT produce:**
- Lint results (Step 5)
- Golden Answers validation (Step 6)
- Severity assessment (Step 8) — instead, simply report issues
- Full review report (Step 9) — instead, output a brief summary

**NORMAL mode output format:**
```
## Quick Review — [date]
- Changes: X files, +Y/-Z lines
- Pre-Submission: X/8 PASS
- Invariants: X/Y PASS
- Tests: X/Y PASS
- Quality Score: XX/100
- Issues: [brief list or "None"]
```

---

## REQUESTING-CODE-REVIEW ORCHESTRATION

> This skill COMPOSES the `requesting-code-review` superpowers skill.
> The orchestration logic is BUILT IN — not referenced externally.

**How the composition works:**

The `requesting-code-review` superpowers skill provides:
- Code-level review with Critical/Important/Minor severity categories
- Line-by-line analysis of changed code
- Code smell detection and naming convention checks

`/wando:review` ADDS on top of this:
- Architectural invariant validation (GOLDEN_PRINCIPLES.md)
- Golden Answers verification (expected outputs vs actual)
- Quality Score calculation (formula-based, not subjective)
- Severity assessment (S1-S4) with structured decision flow
- Cross-phase impact detection (S4 regression check)
- Structured Review Report output

**Integration flow:**
```
/wando:review
  ├── Steps 1-3: wando:review's own logic (changes, checklist, invariants)
  ├── Step 4: Run tests (wando:review)
  ├── Step 5: Lint (wando:review)
  ├── [Code-level review]: requesting-code-review logic
  │     └── Critical/Important/Minor findings → feed into FAIL/CONCERN counts
  ├── Step 6: Golden Answers validation (wando:review)
  ├── Step 7: Quality Score (wando:review — incorporates all findings)
  ├── Step 8: Severity assessment (wando:review)
  └── Step 9: Review report (wando:review — includes code-level findings)
```

The code-level findings from requesting-code-review are counted as:
- Critical findings → FAIL count
- Important findings → CONCERN count
- Minor findings → noted but not counted

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Review DONE → severity output | `/wando:close` consumes it | Review output feeds directly into close decision |
| Checkpoint Level 2 → optional review | `/wando:checkpoint` can trigger it | Agent decides if NORMAL review is needed |
| S3/S4 → need new plan | `/wando:plan` | After FAILED status, new phase plan needed |
| S2 → accept with debt | TECH_DEBT.md | Manually log the accepted debt |

---

## VERIFICATION

### Success Indicators
- Review report generated with structured format (issues list + severity + recommended action)
- Quality Score calculated using the EXACT formula: `100 - (20 × FAIL) - (10 × CONCERN)`
- Severity determined: one of PASS, S1, S2, S3, S4
- All tests executed and results recorded (none silently skipped)
- GOLDEN_PRINCIPLES.md checked (or noted as missing if absent)
- In THOROUGH mode: Golden Answers validated (or noted as absent if none defined)

### Failure Indicators (STOP and fix!)
- Subjective "looks good" / "looks bad" without Quality Score
- Tests not executed (skipped or ignored)
- No severity assessment — just a vague pass/fail
- Review report missing affected files or fix estimates
- Score calculated with wrong formula
- NORMAL mode used when /wando:close requires THOROUGH

---

## EXAMPLES

### Example 1: THOROUGH Review — All PASS

```
Agent runs /wando:review (THOROUGH mode, called by /wando:close)

Step 1: Collect Changes
  - 12 files changed: code 8, test 3, docs 1
  - +340 lines, -45 lines
  - Baseline: commit a1b2c3d

Step 2: Pre-Submission Checklist
  - 8/8 PASS

Step 3: Architectural Invariant Check
  - 5 principles checked, 5/5 PASS

Step 4: Run Tests
  - Verification Commands: 6/6 PASS
  - npm test: 142/142 PASS

Step 5: Lint Check
  - eslint: 0 errors, 0 warnings

Step 6: Golden Answers Validation
  - GA-01: PASS
  - GA-02: PASS
  - GA-03: PASS

Step 7: Quality Score
  - FAIL: 0, CONCERN: 0
  - Score: 100 - 0 - 0 = 100
  - Trend: → stable (was 100)

Step 8: Severity Assessment
  → PASS — no blocking issues

Step 9: Review Report
  Summary: Quality Score 100/100, PASS. Phase ready for close.
```

### Example 2: THOROUGH Review — S2 MODERATE (GP violation)

```
Agent runs /wando:review (THOROUGH mode, called by /wando:close)

Step 1: Collect Changes
  - 45 files changed: code 32, test 10, config 2, docs 1
  - +3200 lines, -180 lines

Step 2: Pre-Submission Checklist
  - 7/8 PASS
  - FAIL: #7 Architecture guard — GP-3 violated

Step 3: Architectural Invariant Check
  - GP-3 "Route handler max 50 lines" → FAIL (8/10 routes > 100 lines)
  - GP-7 "Business logic in service layer" → FAIL (routes call Prisma directly)
  - GP-1 "All PII encrypted at rest" → PASS
  - GP-4 "Zod schema FIRST" → PASS
  - GP-9 "Error boundary on every page" → PASS

Step 4: Run Tests
  - Verification Commands: 5/5 PASS
  - npm test: 242/242 PASS

Step 5: Lint Check
  - eslint: 0 errors, 2 warnings → 1 CONCERN

Step 6: Golden Answers Validation
  - GA-01: PASS
  - GA-02: PASS

Step 7: Quality Score
  - FAIL: 3 (PSC #7 + GP-3 + GP-7)
  - CONCERN: 1 (lint warnings)
  - Score: 100 - (20 × 3) - (10 × 1) = 30
  - Trend: ↓ declined (was 85)

Step 8: Severity Assessment
  → SEVERITY 2: MODERATE
  → Reason: GP-3 and GP-7 violated — route handlers oversized, no service layer
  → Affected: backend/routes/admin/*.ts (8 files)
  → Estimated fix: 4-6 hours

Step 9: Review Report
  "The phase EXIT CRITERIA all PASS, but the quality review found
   two GOLDEN PRINCIPLE violations. Route handlers are oversized
   (8/10 > 100 lines) and there is no service layer.

   Three options:
   1. Fix now — Remediation sub-phase: service layer extraction (~4-6h)
   2. Accept with debt — Log to TECH_DEBT.md, Quality Score drops to 30
   3. Reject phase — New approach needed (drastic, not recommended)"
```

### Example 3: NORMAL Review — At Checkpoint

```
Agent runs /wando:review (NORMAL mode, at checkpoint Level 2)

## Quick Review — 2026-03-02
- Changes: 5 files, +120/-30 lines
- Pre-Submission: 8/8 PASS
- Invariants: 3/3 PASS (only checked principles relevant to changed files)
- Tests: 4/4 PASS
- Quality Score: 100/100
- Issues: None
```

### Example 4: THOROUGH Review — S4 CATASTROPHIC (Regression)

```
Agent runs /wando:review (THOROUGH mode)

Step 1-7: Current phase looks OK (score 85)

Step 8: Severity Assessment — Cross-phase impact check
  → Current phase modified shared/schemas/user.ts (renamed field)
  → Running Phase 04 (UI Shell) tests...
  → FAIL: 12 component tests broken (field name changed)
  → Running Phase 03 (API) tests...
  → FAIL: 5 endpoint tests broken

  → SEVERITY 4: CATASTROPHIC — Regression detected!
  → Affected phases: Phase 03 (API), Phase 04 (UI Shell)
  → Root cause: shared schema field rename without backward compatibility
  → Decision needed: ROLLBACK or FIX-FORWARD?

Step 9: Review Report
  "CATASTROPHIC: Schema change in shared/schemas/user.ts broke
   17 tests across 2 other phases.

   Options:
   A. ROLLBACK: git revert phase commits, redesign with backward compatibility
   B. FIX-FORWARD: make schema change backward-compatible, fix all 17 tests

   Post-mortem required: add to GOLDEN_PRINCIPLES.md:
   'Before modifying shared schemas, run ALL phase test suites.'"
```

---

## REFERENCES (optional)

- `references/ARCHITECTURE_INVARIANTS.md` — Plugin-level invariants
- `GOLDEN_PRINCIPLES.md` (project root) — Project-specific architectural rules
- `QUALITY_SCORE.md` (project root) — Score tracking across phases
- `TEMPLATES.md` Section 9 — Severity assessment scale (S1-S4)
- `TEMPLATES.md` Section 10 — Pre-Submission Checklist (8 points)
