# /blox:done — Worked Examples

Concrete walk-throughs of the 9-step pipeline. Referenced from `SKILL.md`.

## Example 1: Happy path — COMPLETED

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
         9e (autopilot): Next phase resolved from START_HERE Phase Tracker →
             Phase 06 (Deploy) unblocked. Chaining into /blox:deploy automatically.
         _internal/chain: session entry written
         _internal/cleanup: GC run, no stale docs found
```

## Example 2: S2 MODERATE — User decides

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

## Example 3: S3 MAJOR — Phase FAILED

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
