# /blox:check — Worked Examples

Worked review walkthroughs. The verification + code-review rigor comes from
`superpowers:verification-before-completion` and `superpowers:requesting-code-review`;
these illustrate how the blox pipeline (13 steps, Quality Score, S1-S4 severity,
domain checks) wraps that rigor.

---

## Example 1: THOROUGH Review — Healthy, All PASS

```
Agent runs /blox:check (THOROUGH mode, called by /blox:done)

Step 1: Collect Changes
  - 12 files changed: code 5, test 3, ui 3, docs 1
  - +340 lines, -45 lines
  - Baseline: commit a1b2c3d

Step 2: Pre-Submission Checklist — 9/9 PASS
Step 3: Architectural Invariant Check — 5 principles checked, 5/5 PASS
Step 4: Run Tests
  - Verification Commands: 6/6 PASS
  - npm test: 142/142 PASS
Step 5: Lint & Type Check — eslint: 0 errors, 0 warnings; tsc: PASS
Step 5a: Brand Voice — PASS (8 UI strings checked, all match brand guidelines)
Step 5b: Accessibility — PASS (3 UI files scanned, 0 WCAG issues)
Step 5c: Design Consistency — PASS (components follow patterns, spacing tokens used)
Step 5d: Performance Metrics — Bundle size 245KB (no change), no anti-patterns
Step 5e: Security Scan — No security-sensitive patterns detected
Step 6: Golden Answers — GA-01/02/03 PASS
Step 7: Quality Score — FAIL 0, CONCERN 0 → max(0, 100-0-0) = 100 (Healthy), trend stable
Step 8: Severity — PASS (no blocking issues)
Step 9: Review Report — "Quality Score 100/100 (Healthy), PASS. Phase ready for close."
```

---

## Example 2: THOROUGH Review — S2 MODERATE (GP violation + design concerns)

```
Agent runs /blox:check (THOROUGH mode, called by /blox:done)

Step 1: 45 files changed: code 25, test 10, ui 7, config 2, docs 1; +3200/-180
Step 2: Pre-Submission — 7/9 PASS; FAIL #7 Architecture guard — GP-3 violated
Step 3: Architectural Invariant Check
  - GP-3 "Route handler max 50 lines" → FAIL (8/10 routes > 100 lines)
  - GP-7 "Business logic in service layer" → FAIL (routes call Prisma directly)
  - GP-1 / GP-4 / GP-9 → PASS
Step 4: Verification Commands 5/5 PASS; npm test 242/242 PASS
Step 5: eslint 0 errors, 2 warnings → 1 CONCERN
Step 5a: Brand Voice — N/A (no guidelines)
Step 5b: Accessibility — CONCERN (2 missing aria-labels on custom buttons)
Step 5c: Design Consistency — CONCERN (3 hardcoded px values bypassing spacing tokens)
Step 5d: Performance — N/A
Step 5e: Security — none detected
Step 6: Golden Answers — GA-01/02 PASS
Step 7: Quality Score
  - FAIL 3 (PSC #7 + GP-3 + GP-7), CONCERN 3 (lint + a11y + design)
  - max(0, 100 - 60 - 30) = 10 (Blocked); trend declined (was 85)
Step 8: Severity → S2 MODERATE
  - GP-3 and GP-7 violated; affected backend/routes/admin/*.ts (8 files); est. 4-6h
Step 9: Review Report — three options:
  1. Fix now — service layer extraction (~4-6h)
  2. Accept with debt — log to TECH_DEBT.md, score drops to 10
  3. Reject phase — new approach needed
```

---

## Example 3: NORMAL Review — At Checkpoint

```
Agent runs /blox:check (NORMAL mode, at checkpoint)

## Quick Review — 2026-03-17
- Changes: 5 files, +120/-30 lines
- Pre-Submission: 9/9 PASS
- Invariants: 3/3 PASS (only checked principles relevant to changed files)
- Tests: 4/4 PASS
- Quality Score: 100/100 (Healthy)
- Issues: None
```

---

## Example 4: THOROUGH Review — S4 CATASTROPHIC (Regression)

```
Agent runs /blox:check (THOROUGH mode)

Step 1-7: Current phase looks OK (score 85, Healthy)

Step 8: Severity Assessment — Cross-phase impact check
  → Current phase modified shared/schemas/user.ts (renamed field)
  → Running Build phase tests... FAIL: 12 component tests broken (field name changed)
  → Running Foundation phase tests... FAIL: 5 endpoint tests broken
  → SEVERITY 4: CATASTROPHIC — Regression detected!
  → Affected phases: Foundation, Build
  → Root cause: shared schema field rename without backward compatibility

Step 9: Review Report
  "CATASTROPHIC: Schema change in shared/schemas/user.ts broke 17 tests across 2 phases.
   Options:
   A. ROLLBACK: git revert phase commits, redesign with backward compatibility
   B. FIX-FORWARD: make schema change backward-compatible, fix all 17 tests
   Post-mortem required: add to GOLDEN_PRINCIPLES.md:
   'Before modifying shared schemas, run ALL phase test suites.'"
```

---

## Example 5: THOROUGH Review — S1 with Accessibility Issues

```
Agent runs /blox:check (THOROUGH mode)

Steps 1-4: All PASS
Step 5: Lint — PASS

Step 5b: Accessibility Review
  - FAIL: 1 missing alt text on hero image (meaningful content)
  - CONCERN: 2 buttons with icon-only, no aria-label

Step 7: Quality Score
  - FAIL 1 (missing alt text), CONCERN 2 (icon buttons)
  - max(0, 100 - 20 - 20) = 60 (Needs Work)

Step 8: Severity → S1 MINOR
  → Auto-remediation items added to phase checklist:
    - [ ] FIX-1: Add alt text to hero image in components/Hero.tsx
    - [ ] FIX-2: Add aria-label to icon buttons in components/Toolbar.tsx
```
