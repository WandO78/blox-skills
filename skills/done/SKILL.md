---
name: blox-done
description: "Complete a phase with severity-aware verification, Phase Memory, and meta-file updates. Use to formally close a finished development phase. Phase Memory is mandatory even on FAIL."
user-invocable: true
argument-hint: "[phase number or name]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(phase status updates, Phase Memory entries, severity reports, Quality Score entries,
Tech Debt entries, CONTEXT_CHAIN entries) MUST be written in the user's language.
The skill logic instructions below are in English for maintainability, but all
OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Active phase: !`grep -l ">>> CURRENT <<<" plans/PHASE_*.md 2>/dev/null`
- Phase status: !`grep "Status:" plans/PHASE_*.md 2>/dev/null | head -5`
- Exit criteria: !`grep -A20 "Exit Criteria" plans/PHASE_*.md 2>/dev/null | head -30`
- Done/remaining: !`grep -c "\[x\]" plans/PHASE_*.md 2>/dev/null` / !`grep -c "\[ \]" plans/PHASE_*.md 2>/dev/null`

# /blox:done

> **Phase completion gate — severity-aware.**
> Verifies quality, records lessons, updates meta-files, and transitions phase status.
> Phase Memory is MANDATORY — even on FAIL, **especially** on FAIL.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-done
category: quality
complements: [blox-check, _internal/checkpoint]

### Triggers — when the agent invokes automatically
trigger_keywords: [close, done, complete, phase done, finished, wrap up, lezaras, befejezve, kesz]
trigger_files: [QUALITY_SCORE.md, TECH_DEBT.md, GOLDEN_PRINCIPLES.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when all checklist items in a phase are [x] or the agent believes
  the phase is complete. Runs Pre-Submission Checklist FIRST, then Exit Criteria
  verification, then quality review (THOROUGH mode), then severity assessment.
  Phase Memory is MANDATORY — even on FAIL, especially on FAIL.
  Do NOT use mid-phase — use `_internal/checkpoint` instead.
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Phase checklist complete | All items [x] | No — agent invokes |
| FINAL CHECKPOINT reached | `--- FINAL CHECKPOINT ---` line in phase file | No — agent invokes |
| User explicitly asks | "Close this phase" / "Wrap up" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Mid-phase save | Done COMPLETES a phase, it does not save progress | `_internal/checkpoint` |
| Only need a code review | Done does much more than review | `/blox:check` |
| Project-level assessment | Different purpose entirely | `/blox:scan` |
| Phase not started | Nothing to close | — |

---

## SKILL LOGIC

> **9-step done pipeline — severity-aware decision.**
>
> The core principle: **NO phase gets COMPLETED status without verified evidence.**
> This is the Iron Law from `verification-before-completion` — INTEGRATED, not referenced.
>
> ```
> Iron Law: No completion claims without fresh verification evidence.
> NEVER say "done" / "fixed" / "passing" without FIRST running verification
> commands and confirming the output shows success.
> ```

### Step 1: Pre-Submission Checklist

> **THIS runs FIRST — before Exit Criteria, before review, before anything.**
> 8 mandatory checks. If ANY fails, it must be fixed before proceeding.

Read the active phase file and verify each item:

```
PSC-0: AC verified — Is there EVIDENCE (test output, screenshot, log) for EVERY exit criterion?
PSC-1: Approach alignment — Does the implementation follow the architectural invariants?
PSC-2: Clean code — No TODO, FIXME, HACK, or commented-out code in the commit?
PSC-3: Config hygiene — No hardcoded secrets, no .env files committed?
PSC-4: Docs updated — ARCHITECTURE.md, API docs, README updated (if affected)?
PSC-5: Tests pass — ALL tests GREEN (not just new ones — OLD ones too)?
PSC-6: Pattern reuse — Any existing pattern in the codebase that could be reused?
PSC-7: Architecture guard — Does the change violate any Golden Principle?
```

**How to check:**
- PSC-0: Look for Exit Criteria section → run each verification command → confirm output
- PSC-1: Read `references/ARCHITECTURE_INVARIANTS.md` → check each invariant
- PSC-2: `grep -rn "TODO\|FIXME\|HACK" [changed files]` — must return empty
- PSC-3: `grep -rn "password\|secret\|api_key\|token" [changed files]` — review matches
- PSC-4: Check if docs exist in project → verify they reflect current state
- PSC-5: Run the project's test command(s) → ALL must pass
- PSC-6: Skim similar patterns in codebase (agent judgment)
- PSC-7: Read `GOLDEN_PRINCIPLES.md` (if exists) → no violations

**If PSC fails:**
- Fix the issue immediately (if trivial — under 5 minutes)
- If non-trivial: note it and continue to Step 2 — the severity assessment will handle it

---

### Step 2: Exit Criteria Verification Commands

> **Run EVERY verification command from the phase file's Exit Criteria section.**
> Record the actual output for each.

1. Read the phase file → find `## Exit Criteria` section
2. Find all code blocks with verification commands
3. Run each command and record output
4. Mark each criterion as PASS or FAIL

```
Exit Criteria Results:
  EC-1: [criterion] → PASS/FAIL [evidence]
  EC-2: [criterion] → PASS/FAIL [evidence]
  ...
  Total: X/Y PASS
```

**If ALL PASS → proceed to Step 4 (Quality Review)**
**If ANY FAIL → proceed to Step 3 (Severity Assessment)**

---

### Step 3: Severity Assessment

> **Only reached when Exit Criteria or Quality Review has FAILs.**
> Use the Quality Score formula to determine severity level.

**Quality Score Formula:**
```
score = max(0, 100 - (20 × FAIL_count) - (10 × CONCERN_count))

FAIL    = Exit Criterion failed OR Golden Principle violated
CONCERN = Warning, sub-optimal but not broken
Floor: score NEVER goes below 0
```

**Score ranges:**
| Range | Label | Meaning |
|-------|-------|---------|
| 80-100 | Healthy | Ready for close, minimal issues |
| 50-79 | Needs Work | Has issues that should be addressed |
| 20-49 | Critical | Significant rework needed |
| 0-19 | Blocked | Major failures, cannot proceed |

**Severity mapping from score:**
| Score Range | Typical Severity |
|-------------|-----------------|
| 80-100, 0 FAIL | PASS or S1 MINOR |
| 80-100, some FAIL | S2 MODERATE |
| 50-79 | S2 MODERATE or S3 MAJOR |
| 20-49 | S3 MAJOR |
| 0-19 | S3 MAJOR or S4 CATASTROPHIC |

**Severity Levels:**

#### S1: MINOR (score >= 80, few FAILs)
- Few test failures, small gaps
- **Response:** Auto-generate remediation items → append to phase checklist end
- **User decision:** NOT needed — automatic
- **Phase status:** Stays IN PROGRESS (agent fixes and re-runs /blox:done)
- **Action:**
  1. Generate specific fix items (one per failure)
  2. Append items to the checklist (after FINAL CHECKPOINT)
  3. Set `>>> CURRENT <<<` marker at first new item
  4. Inform user: "S1 MINOR — X items added to checklist, fixing now"
  5. Agent fixes → re-runs /blox:done

#### S2: MODERATE (score 50-79)
- Architectural problems, Golden Principle concerns
- **Response:** Present to user with 3 options
- **User decision:** REQUIRED — agent MUST NOT decide alone
- **Phase status:** Depends on user choice
- **Action:**
  1. **Save severity report to file:** Write detailed report to `docs/review/SEVERITY_REPORT_PHASE_XX.md`
     - Include: all FAILs with evidence, all CONCERNs, score breakdown, context
  2. **Present decision to user:**
     ```
     Quality Score: X/100 (S2 MODERATE) — How to proceed?

     Options:
     A) Fix now — Status → IN PROGRESS — REMEDIATION. Fix items added to checklist.
     B) Accept with Tech Debt — Proceed to COMPLETED. Issues logged in TECH_DEBT.md.
     C) Reject phase — Status → FAILED — REQUIRES REDESIGN. New plan needed.
     ```
  3. Execute chosen option

#### S3: MAJOR (score 20-49)
- Fundamental approach is wrong
- **Response:** FAILED status + Phase Memory (MANDATORY!) + new plan needed
- **User decision:** REQUIRED (new plan approval)
- **Phase status:** FAILED — REQUIRES REDESIGN
- **Action:**
  1. Set phase status: `FAILED — REQUIRES REDESIGN`
  2. IMMEDIATELY write Phase Memory (Step 5) — DO NOT SKIP
  3. Update QUALITY_SCORE.md (score DECREASES)
  4. Update TECH_DEBT.md (new entry for the failure)
  5. Move phase file → `failed/PHASE_XX_[name]_[date].md`
  6. Inform user: "S3 MAJOR — phase failed. New plan needed via /blox:plan"

#### S4: CATASTROPHIC (score 0-19 OR regression — broke other phases)
- Changes broke something that previously worked
- **Response:** Rollback decision + impact analysis + post-mortem
- **User decision:** REQUIRED
- **Phase status:** FAILED — REQUIRES REDESIGN
- **Action:**
  1. Run ALL other phase verification commands (cross-phase impact)
  2. Identify what broke and when
  3. Present to user: rollback vs fix-forward analysis
     - Rollback: `git revert` — safer but loses work
     - Fix-forward: targeted fix — keeps work but riskier
  4. Wait for user decision
  5. Execute chosen approach
  6. Proceed with S3 actions (Phase Memory, meta-file updates, etc.)

---

### Step 4: Quality Review (/blox:check THOROUGH)

> **Only reached when Exit Criteria ALL PASS.**
> Delegates to /blox:check in THOROUGH mode.

1. Invoke `/blox:check` with mode: THOROUGH
2. Review returns a Quality Score and severity assessment
3. **If review PASS (S1 with score >= 80 and no critical findings):** → proceed to Step 5
4. **If review FAIL (S2/S3/S4):** → go back to Step 3 with review's severity

---

### Step 5: Phase Memory (MANDATORY — ALWAYS)

> **THIS STEP IS NEVER SKIPPED. Not on PASS. Not on FAIL. NEVER.**
> The lesson from failure is the MOST VALUABLE knowledge we can lose.

Write the Phase Memory section at the bottom of the phase file:

```markdown
## Phase Memory (Retrospective)

### Status: [COMPLETED | FAILED — REQUIRES REDESIGN]
### Quality Score: [X/100]

### Golden Principles (what worked)
- [Pattern or approach that proved effective]
- [Reusable insight for future phases]

### Antipatterns (what did NOT work)
- [Approach that failed and WHY]
- [Trap to avoid in similar phases]

### Patterns Applied (from knowledge-patterns.md)
- Decision Waterfall: [applied / skipped — if applied, which decision points]
- Layered Architecture: [maintained / violated — details]
- Mechanical Enforcement: [any new lint rules or CI checks created?]
- Momentum Protection: [any assumptions made? document them here]

### Tech Debt (what remains open)
- [Accepted compromise and its impact]
- [Deferred work and when to address it]

### Interim Memory (collected from checkpoints)
[CP-A lesson]
[CP-B lesson]
```

**On FAIL — write MORE, not less:**
- WHY did it fail? (root cause, not symptoms)
- What was the wrong assumption?
- What should the NEXT attempt do differently?
- What would you tell another agent about this failure?

---

### Step 6: GOLDEN_PRINCIPLES.md Update

> **Only on COMPLETED status.**

If the phase produced a reusable insight (a pattern that worked well):

1. Read existing `GOLDEN_PRINCIPLES.md` (create if doesn't exist)
2. Check if the insight is already captured
3. If new: append with source reference

```markdown
## GP-[XX]: [Short principle name]
- **Source:** Phase [XX] — [phase name]
- **Date:** [YYYY-MM-DD]
- **Principle:** [One clear sentence]
- **Evidence:** [Why this works — concrete example]
```

**Skip if:** No genuinely new principle emerged (don't force it).

---

### Step 7: QUALITY_SCORE.md Update

> **ALWAYS — both PASS and FAIL.**

1. Read existing `QUALITY_SCORE.md` (create if doesn't exist)
2. Append new entry:

```markdown
## Phase [XX]: [Name] — [YYYY-MM-DD]
- **Score:** [X/100]
- **Status:** [COMPLETED | FAILED]
- **FAIL count:** [X] — [list items]
- **CONCERN count:** [X] — [list items]
- **Trend:** [IMPROVING | STABLE | DECLINING] (compare with previous phases)
```

**On FAIL:** Score is recorded as-is. The trend shows decline. This is the POINT — making problems visible.

---

### Step 8: TECH_DEBT.md Update

> **ALWAYS — both PASS and FAIL.**

1. Read existing `TECH_DEBT.md` (create if doesn't exist)
2. If new debt exists (S2 "Accept with Tech Debt" OR known compromises):

```markdown
## TD-[XX]: [Short description]
- **Source:** Phase [XX] — [phase name]
- **Date:** [YYYY-MM-DD]
- **Severity:** [S1 | S2 | S3]
- **Description:** [What was deferred and why]
- **Impact:** [What happens if not addressed]
- **Resolution:** [When/how to fix — specific phase or trigger]
```

3. If FAIL: add entry for the failure itself (what needs redesign)
4. If no new debt: add a `No new debt` note for completeness
5. **Move resolved debt:** If this phase fixed any Active debt items, move them to the Resolved table:
```markdown
## Resolved
| ID | Description | Resolved in | Date |
|----|-------------|-------------|------|
| TD-XX | [description] | Phase [XX] | YYYY-MM-DD |
```

---

### Step 9: Status Transition + File Operations

> **The final step — update all tracking files and move the phase file.**

#### 9a: Phase file status update

In the phase file, update:
```
## Status: [COMPLETED | FAILED — REQUIRES REDESIGN]
## Last Updated: [YYYY-MM-DD]
```

#### 9b: START_HERE.md phase tracker

Update the Phase Tracker table row:
```
| XX | [Phase Name] | [COMPLETED/FAILED] | [start date] | [today] | [score/10] |
```

Quality Score mapping: score/100 → /10 (divide by 10, round).

#### 9c: CONTEXT_CHAIN.md new entry

Invoke `_internal/chain` to add a session entry:
```markdown
## [YYYY-MM-DD] Session: Phase XX [COMPLETED/FAILED] — [Phase Name]

**Phase:** Phase XX — [Name]
**Step:** [first] → [last] (complete)
**Status:** [completed/failed]

### What happened
- [Key accomplishments or failure reason]
- [Quality Score: X/100]
- [Severity: S1/S2/S3/S4 if applicable]

### Next session task
- [What comes next based on the dependency graph]
```

#### 9d: Phase file move

```bash
# On COMPLETED:
mkdir -p completed/
mv plans/PHASE_XX_[name].md completed/PHASE_XX_[name]_[YYYY-MM-DD].md

# On FAILED:
mkdir -p failed/
mv plans/PHASE_XX_[name].md failed/PHASE_XX_[name]_[YYYY-MM-DD].md
```

#### 9e: Next phase activation (COMPLETED only)

1. Check `plans/MASTER_PLAN.md` dependency graph
2. Identify which phases are now unblocked
3. Update START_HERE.md: `**Active phase file:** plans/PHASE_XX_[next].md`

#### 9f: Git branch close (if applicable)

If the project uses a feature branch for this phase:
- Invoke `/finishing-a-development-branch` (superpowers)
- Options: merge, PR, keep, discard — let the skill handle it

#### 9g: Post-completion cleanup

After all status transitions and file moves are complete:
1. Invoke `_internal/chain` (if not already done in 9c)
2. Invoke `_internal/cleanup` to run garbage collection on project docs

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Quality review needed (Step 4) | `/blox:check` THOROUGH mode | After Exit Criteria ALL PASS |
| Git branch exists for phase | `/finishing-a-development-branch` (superpowers) | Step 9f — at phase end |
| Phase FAILED, new plan needed | `/blox:plan` | After S3/S4, user approves |
| Checkpoint needed mid-remediation | `_internal/checkpoint` Level 2 | During S1/S2 remediation |
| Session entry needed | `_internal/chain` | Step 9c — phase completion entry |
| Post-completion cleanup | `_internal/cleanup` | Step 9g — after all transitions done |

---

## PHASE STATUS TRANSITIONS (definitive)

```
PENDING → IN PROGRESS                       (normal start)
IN PROGRESS → COMPLETED                     (EC PASS + Review PASS)
IN PROGRESS → IN PROGRESS — REMEDIATION     (S2 "Fix now")
IN PROGRESS — REMEDIATION → IN PROGRESS     (remediation done, re-run done)
IN PROGRESS → FAILED — REQUIRES REDESIGN    (S3/S4)
FAILED — REQUIRES REDESIGN → PENDING        (new plan created, new phase file)

FORBIDDEN transitions:
  COMPLETED → anything                      (irreversible)
  FAILED → IN PROGRESS                      (cannot "fix" — need new phase)
  PENDING → COMPLETED                       (cannot skip work)
```

---

## EXAMPLES

### Example 1: Happy path — COMPLETED

```
Agent: All 35 checklist items are [x]. Running /blox:done.

Step 1 — Pre-Submission Checklist:
  PSC-0: AC verified ✓ (test output for all 5 exit criteria)
  PSC-1: Approach alignment ✓ (3 invariants checked)
  PSC-2: Clean code ✓ (grep returns empty)
  PSC-3: Config hygiene ✓ (no secrets)
  PSC-4: Docs updated ✓ (README updated)
  PSC-5: Tests pass ✓ (14/14 green)
  PSC-6: Pattern reuse ✓ (reused existing validator)
  PSC-7: Architecture guard ✓ (no GP violations)
  → All 8 PASS

Step 2 — Exit Criteria:
  EC-1: SKILL.md exists and non-empty → PASS
  EC-2: YAML frontmatter valid → PASS
  EC-3: AUTO-DISCOVERY block present → PASS
  EC-4: No TODO/FIXME → PASS
  → 4/4 PASS

Step 4 — /blox:check THOROUGH:
  Quality Score: 95/100 (Healthy)
  1 CONCERN: long method at line 234
  Severity: S1 MINOR
  → PASS (score >= 80, no critical findings)

Step 5 — Phase Memory: Written (3 Golden Principles, 1 Antipattern, 0 Tech Debt)
Step 6 — GOLDEN_PRINCIPLES.md: Added GP-12 "TDD RED phase catches 80% of gaps"
Step 7 — QUALITY_SCORE.md: Score 95, trend STABLE
Step 8 — TECH_DEBT.md: No new debt
Step 9 — Status: COMPLETED
         File → completed/PHASE_05_quality_review_2026-03-02.md
         _internal/chain: session entry written
         _internal/cleanup: GC run, no stale docs found
```

### Example 2: S2 MODERATE — User decides

```
Agent: Running /blox:done.

Step 1 — Pre-Submission Checklist:
  PSC-7: Architecture guard → CONCERN (uses direct file writes instead of skill abstraction)
  → 7/8 PASS, 1 CONCERN

Step 2 — Exit Criteria:
  EC-1: PASS, EC-2: PASS, EC-3: FAIL (missing error handling for edge case), EC-4: PASS
  → 3/4 PASS, 1 FAIL

Step 3 — Severity Assessment:
  score = max(0, 100 - (20 × 1 FAIL) - (10 × 1 CONCERN)) = 70 (Needs Work)
  Severity: S2 MODERATE

  → Presenting to user:
  "Quality Score: 70/100 (S2 MODERATE)
   - FAIL: EC-3 missing error handling for empty input
   - CONCERN: PSC-7 direct file writes vs skill abstraction

   Options:
   A) Fix now — add error handling, refactor file writes (est. 15 min)
   B) Accept with Tech Debt — proceed to COMPLETED, log debt
   C) Reject — mark FAILED, requires new plan"

User: "B — accept with tech debt, the error handling is an edge case"

Step 5 — Phase Memory: Written (includes accepted compromise note)
Step 7 — QUALITY_SCORE.md: Score 70, trend DECLINING
Step 8 — TECH_DEBT.md: Added TD-04 "Missing error handling for empty input"
Step 9 — Status: COMPLETED (with debt), file → completed/
         _internal/chain: session entry written
         _internal/cleanup: GC run
```

### Example 3: S3 MAJOR — Phase FAILED

```
Agent: Running /blox:done.

Step 2 — Exit Criteria:
  EC-1: FAIL (core algorithm produces wrong output for 3/5 test cases)
  EC-2: FAIL (performance 10x slower than requirement)
  EC-3: PASS
  → 1/3 PASS, 2 FAIL

Step 3 — Severity Assessment:
  score = max(0, 100 - (20 × 2)) = 60 (Needs Work)
  Severity: S3 MAJOR

  → "Quality Score: 60/100 (S3 MAJOR)
     The algorithm approach is fundamentally wrong — both correctness and
     performance fail. A new approach is needed."

Step 5 — Phase Memory (CRITICAL — write extensively):
  Status: FAILED — REQUIRES REDESIGN
  Quality Score: 60/100

  Golden Principles:
  - The test harness design was solid — reuse in next attempt
  - Input validation layer is correct and complete

  Antipatterns:
  - Chose recursive approach for O(n²) problem — should have used DP
  - Did not benchmark before writing full implementation
  - ROOT CAUSE: skipped complexity analysis in planning phase

  Tech Debt:
  - None (phase is FAILED, clean slate for next attempt)

  What the next attempt should do differently:
  - Start with complexity analysis and benchmarks
  - Use dynamic programming, not recursion
  - Run performance tests after every 10 checklist items, not just at end

Step 7 — QUALITY_SCORE.md: Score 60, trend DECLINING
Step 8 — TECH_DEBT.md: Added entry for failed approach analysis
Step 9 — Status: FAILED — REQUIRES REDESIGN
         File → failed/PHASE_07_algorithm_2026-03-04.md
         Inform user: "Phase failed. Use /blox:plan to create a new approach."
         _internal/chain: session entry written
```

---

## VERIFICATION

### Success indicators
- Phase status is COMPLETED or FAILED — REQUIRES REDESIGN (**never** left as IN PROGRESS)
- Phase Memory section is FILLED (Golden Principles, Antipatterns, Tech Debt — all three)
- QUALITY_SCORE.md has a new entry with score and trend
- TECH_DEBT.md updated (new entry or "No new debt" note)
- START_HERE.md phase tracker row updated
- CONTEXT_CHAIN.md has a new session entry (via `_internal/chain`)
- Phase file moved to `completed/` or `failed/` directory
- On FAIL: Phase Memory is EXTENSIVE (root cause, wrong assumptions, advice for next attempt)
- `_internal/cleanup` invoked after completion

### Failure indicators (STOP and fix!)
- Phase status still "IN PROGRESS" after done attempted
- Empty Phase Memory (ESPECIALLY on FAIL — the most valuable knowledge!)
- QUALITY_SCORE.md not updated
- Phase file still in `plans/` directory (not moved)
- S2 decision made by agent without user input
- Verification commands not actually run (claimed PASS without evidence)
- AI attribution found in phase file, commits, or generated docs (Co-Authored-By, Claude, Opus, Anthropic, Generated by AI)

---

## REFERENCES (optional)

- `references/ARCHITECTURE_INVARIANTS.md` — Invariant checks for PSC-1
- `GOLDEN_PRINCIPLES.md` — Golden Principle checks for PSC-7
- `QUALITY_SCORE.md` — Historical quality scores for trend analysis
- `TECH_DEBT.md` — Existing tech debt for context
