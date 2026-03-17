---
name: blox-check
description: "Run quality review on completed work: architectural invariants, tests, Golden Answers, Quality Score (S1-S4 severity), plus domain checks (brand, a11y, design, metrics). Use after significant changes or at phase completion to evaluate quality."
user-invocable: true
argument-hint: "[normal|thorough] [phase or scope]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(review report, issue descriptions, recommendations, severity explanations) MUST
be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:check

> **Quality gate for every phase.** 13-step review pipeline that evaluates code,
> architecture, tests, Golden Answers, and domain quality (brand, accessibility,
> design, performance) — then outputs a severity assessment (S1-S4) that drives
> the `/blox:done` decision.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-check
category: quality
complements: [blox-done, _internal/checkpoint]

### Triggers — when the agent invokes automatically
trigger_keywords: [review, quality, check, code review, ellenorzes, minoseg, quality check, review code]
trigger_files: [GOLDEN_PRINCIPLES.md, QUALITY_SCORE.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke after significant code changes or at phase completion.
  NORMAL mode: at checkpoints — runs a subset of review steps (1-4, 7).
  THOROUGH mode: at phase end — runs all 13 review steps including
  domain quality checks, Golden Answers validation, lint, Quality Score,
  and severity assessment.
  Called by /blox:done as a mandatory step before phase completion.
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Mode | Auto-invoke? |
|---------|---------|------|-------------|
| After checkpoint (Level 2) | `_internal/checkpoint` SMART completed | NORMAL | No — agent decides |
| Before phase close | `/blox:done` calls it | THOROUGH | Yes — done triggers it |
| Significant code change | Large refactor, new module, API redesign | NORMAL | No — agent decides |
| Explicit user request | "Run a review" / "Check quality" | THOROUGH | User-invoked |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Small change (1-2 lines) | Overhead exceeds value | Run tests directly |
| No Exit Criteria defined yet | Nothing to measure against | First run `/blox:plan` |
| Project-level assessment | Audit READS project state, review EVALUATES phase work | `/blox:scan` |
| No code changes (docs only) | Review pipeline is code-oriented | Manual review |

---

## SKILL LOGIC

> **13-step review pipeline + severity assessment.**
> Two modes: NORMAL (steps 1-4, 7) and THOROUGH (all 13 steps).
> Steps 5a-5d are domain quality checks integrated from brand, accessibility,
> design, and metrics review disciplines.
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
IF called by /blox:done → THOROUGH (always)
IF called at checkpoint → NORMAL
IF called by user without specifying → THOROUGH
IF called by agent after code change → NORMAL
```

**NORMAL mode** runs: Steps 1, 2, 3, 4, 7
**THOROUGH mode** runs: Steps 1, 2, 3, 4, 5, 5a, 5b, 5c, 5d, 6, 7, 8, 9

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
   - `ui` — frontend/UI files (.tsx, .jsx, .vue, .svelte, .html, .css, .scss)
   - `docs` — documentation files
   - `other` — everything else
4. If no git repository, use file modification timestamps and the Phase file's Progress Log to identify changed files

**Output format:**
```
## Change Summary
- Files changed: X (code: Y, test: Z, config: W, ui: U, docs: V)
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
[] 0. AC verified — Is there EVIDENCE (test output, screenshot, log) for EVERY exit criteria?
[] 1. Approach alignment — Does the implementation match the architectural invariants?
[] 2. Clean code — No TODO, FIXME, HACK, or commented-out code in the commit?
[] 3. Config hygiene — No hardcoded secrets, no .env files committed?
[] 4. Docs updated — ARCHITECTURE.md, API docs, README updated (if affected)?
[] 5. Tests pass — ALL tests green (not just new ones, OLD ones too)?
[] 6. Pattern reuse — Is there an existing solution in the codebase that could be reused?
[] 7. Architecture guard — Does the change violate any Golden Principle?
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
4. **Pattern compliance check** (from `references/patterns/knowledge-patterns.md`):
   - Decision Waterfall: Do user-facing features have fallback/error handling? → CONCERN if missing
   - Layered Architecture: Do dependencies flow downward only? → FAIL if violated
   - Mechanical Enforcement: Were Golden Principle violations caught by automation or only by review? → If only by review: CONCERN + recommend promotion to lint rule
   - Evidence: Are completion claims backed by verification command output? → FAIL if no evidence
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
| 1 | npm test | PASS | — |
| 2 | pytest --tb=short | FAIL | 3 tests failed: test_user_crud.py:42,89,115 |
```

---

### Step 5: Lint & Type Check (THOROUGH mode only)

**Purpose:** Run project-level code quality tools.

**Actions:**
1. Detect linter configuration:
   - `.eslintrc*` or `eslint.config.*` → `npx eslint .`
   - `pyproject.toml` with `[tool.ruff]` or `[tool.flake8]` → `ruff check .` or `flake8`
   - `.rustfmt.toml` → `cargo fmt --check`
   - `.prettierrc*` → `npx prettier --check .`
   - If no linter found, skip with note: "No linter configured"
2. Detect type checker:
   - `tsconfig.json` → `npx tsc --noEmit`
   - `pyproject.toml` with `[tool.mypy]` → `mypy .`
3. Run the detected linter(s) and type checker(s)
4. Count errors vs warnings
5. Errors → FAIL, Warnings → CONCERN

**Output format:**
```
## Lint & Type Results
- Linter: eslint
- Errors: 0
- Warnings: 2
- Type check: tsc — PASS
- Details: [warning details if any]
```

---

### Step 5a: Brand Voice Consistency (THOROUGH mode only)

**Purpose:** Verify that user-facing text aligns with the project's brand voice guidelines.

**Trigger:** Only runs if brand guideline files exist:
- `GOLDEN_PRINCIPLES.md` with brand/voice/tone rules
- `brand-guidelines.md`, `BRAND_VOICE.md`, or similar
- `STYLE_GUIDE.md` with UI copy rules

**Actions:**
1. Identify user-facing text in changed files:
   - UI strings: labels, buttons, headings, error messages, tooltips
   - API responses: user-visible error messages, success messages
   - Notification text, email templates, onboarding copy
2. Check against brand guidelines:
   - **Tone match** — Does the copy match the documented tone? (e.g., formal vs. casual)
   - **Terminology** — Are brand-specific terms used correctly? (e.g., "workspace" not "project")
   - **Consistency** — Same concept described the same way across the codebase?
   - **Banned words** — Any words/phrases explicitly listed as "do not use"?
3. For each finding:
   - Mismatched tone → CONCERN
   - Wrong terminology → CONCERN
   - Banned word used → CONCERN

**If no brand guidelines exist:** Skip with note "No brand guidelines found — skipping brand voice check."

**Output format:**
```
### Brand Voice Consistency: [PASS | CONCERN | N/A]
- Guidelines source: [filename]
- User-facing strings checked: [N]
- Issues: [list or "None"]
```

---

### Step 5b: Accessibility Review (THOROUGH mode only)

**Purpose:** Check WCAG compliance in frontend code changes.

**Trigger:** Only runs if UI/frontend files were changed (detected in Step 1 `ui` category).

**Actions:**
1. Scan changed UI files for WCAG 2.1 AA compliance:
   - **Images:** All `<img>` tags have `alt` attributes (not empty for meaningful images)
   - **ARIA labels:** Interactive elements (`<button>`, `<a>`, `<input>`) have accessible labels
   - **Keyboard navigation:** Custom interactive components have `tabIndex`, `onKeyDown`/`onKeyPress` handlers
   - **Color contrast:** Check for hardcoded colors without sufficient contrast ratio documentation
   - **Form labels:** All `<input>`, `<select>`, `<textarea>` have associated `<label>` or `aria-label`
   - **Heading hierarchy:** `<h1>`-`<h6>` used in logical descending order, no skipped levels
   - **Focus indicators:** Custom `:focus` styles present (not removed with `outline: none` without replacement)
   - **Screen reader text:** Decorative elements marked with `aria-hidden="true"`
2. For each finding:
   - Missing alt text on meaningful image → FAIL
   - Missing ARIA label on interactive element → FAIL
   - No keyboard handler on custom interactive → CONCERN
   - Color contrast issue → CONCERN
   - Missing form label → FAIL
   - Heading hierarchy violation → CONCERN
   - Focus indicator removed → CONCERN

**If no UI files changed:** Skip with note "No frontend files changed — skipping accessibility review."

**Output format:**
```
### Accessibility: [PASS | CONCERN | FAIL | N/A]
- UI files scanned: [N]
- WCAG issues: [count] (FAIL: [n], CONCERN: [n])
- Details: [list or "None"]
```

---

### Step 5c: Design Consistency Review (THOROUGH mode only)

**Purpose:** Check that UI changes follow consistent design patterns.

**Trigger:** Only runs if UI component files were changed (detected in Step 1 `ui` category).

**Actions:**
1. Check component consistency in changed files:
   - **Component patterns** — Do new components follow the project's existing component structure?
   - **Spacing** — Consistent use of spacing tokens/variables (not arbitrary px/rem values)?
   - **Typography** — Font sizes, weights, and families from the design system?
   - **Color usage** — Colors from the palette/theme, not hardcoded hex values?
   - **Responsive design** — Breakpoints handled? Mobile-first or desktop-first consistent?
   - **Layout patterns** — Grid/flex usage consistent with existing patterns?
   - **State handling** — Loading, empty, error states implemented for dynamic content?
2. For each finding:
   - Hardcoded values bypassing design tokens → CONCERN
   - Missing responsive handling → CONCERN
   - Missing state handling (loading/empty/error) → CONCERN
   - Inconsistent component structure → CONCERN

**If no UI files changed:** Skip with note "No UI component changes — skipping design consistency review."

**Output format:**
```
### Design Consistency: [PASS | CONCERN | N/A]
- Components reviewed: [N]
- Issues: [list or "None"]
```

---

### Step 5d: Performance Metrics Review (THOROUGH mode only)

**Purpose:** Check measurable performance indicators where possible.

**Trigger:** Runs if any of these can be measured in the project.

**Actions:**
1. **Bundle size** (if applicable):
   - Run `npm run build` or equivalent and check output size
   - Compare to previous build if baseline exists
   - Flag if significantly larger (>10% increase without justification)
2. **Load/response time** (if measurable):
   - Check for obvious performance anti-patterns in changed files:
     - N+1 queries (loop with DB calls)
     - Missing pagination on list endpoints
     - Synchronous heavy operations on the main thread
     - Large unoptimized images or assets
     - Missing lazy loading for below-the-fold content
3. **API latency patterns:**
   - Unbatched sequential API calls that could be parallelized
   - Missing caching for repeated identical requests
   - Missing debounce/throttle on frequent events
4. For each finding:
   - Bundle size increase >10% → CONCERN
   - N+1 query pattern → CONCERN
   - Missing pagination → CONCERN
   - Performance anti-pattern → CONCERN

**If nothing measurable:** Skip with note "No measurable performance metrics — skipping metrics review."

**Output format:**
```
### Performance Metrics: [values if measurable | N/A]
- Bundle size: [current] ([change from baseline])
- Anti-patterns found: [count]
- Details: [list or "None"]
```

---

### Step 5e: Security Pattern Scan (THOROUGH mode only)

**Purpose:** Detect common security vulnerabilities in changed code (OWASP Top 10 patterns).

**Actions:**
1. Identify all files changed in this phase (from git diff or phase checklist scope)
2. Scan for high-risk patterns:
   - **Command/shell injection** — unsafe process execution with user input
   - **SQL injection** — raw SQL with string formatting (not parameterized/ORM)
   - **Unsafe deserialization** — loading serialized data from untrusted sources
   - **Cross-site scripting (XSS)** — raw HTML injection into DOM without sanitization
   - **Hardcoded secrets** — API keys, passwords, tokens in source code
   - **Missing auth/authz** — new endpoints without authentication or authorization checks
   - **Insecure redirect** — redirect URL from user input without allowlist validation
   - **Missing input validation** — endpoints accepting user input without schema validation

3. For EACH finding:
   - Note the file, line, and pattern category
   - Classify: CRITICAL (immediate fix) or CONCERN (review needed)
   - CRITICAL (injection, secrets, missing auth) → +1 FAIL_count
   - CONCERN (XSS, redirect, missing validation) → +1 CONCERN_count

**Output format:**
```
## Security Scan
- Files scanned: [N]
- Critical findings: [N] (immediate fix required)
- Concerns: [N] (review recommended)
- Details: [finding details with file:line references]
```

**If no security-sensitive code changed:** Skip with note "No security-sensitive patterns detected."

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
score = max(0, 100 - (20 * FAIL_count) - (10 * CONCERN_count))

Where:
  FAIL = Exit Criteria failure, Golden Principle violation, test failure, a11y FAIL
  CONCERN = Warning, sub-optimal but not broken, missing optional item, brand/design/perf issue
  Floor: score NEVER goes below 0
```

**Counting rules:**
- Step 2 (Pre-Submission): each FAIL item → +1 FAIL_count, each uncertain → +1 CONCERN_count
- Step 3 (Invariants): each VIOLATED principle → +1 FAIL_count, each "partially" → +1 CONCERN_count
- Step 4 (Tests): each FAILED test group → +1 FAIL_count
- Step 5 (Lint): errors → +1 FAIL_count per group, warnings → +1 CONCERN_count per group
- Step 5a (Brand): each brand voice issue → +1 CONCERN_count
- Step 5b (A11y): FAIL findings → +1 FAIL_count each, CONCERN findings → +1 CONCERN_count each
- Step 5c (Design): each design issue → +1 CONCERN_count
- Step 5d (Metrics): each anti-pattern → +1 CONCERN_count
- Step 5e (Security): CRITICAL findings → +1 FAIL_count each, CONCERN findings → +1 CONCERN_count each
- Step 6 (Golden Answers): each FAILED answer → +1 FAIL_count

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

**Output format:**
```
## Quality Score
- FAIL count: X
- CONCERN count: Y
- Score: max(0, 100 - (20 * X) - (10 * Y)) = ZZ ([Healthy|Needs Work|Critical|Blocked])
- Previous score: [from QUALITY_SCORE.md or "N/A"]
- Trend: [improved / declined / stable]

## Coverage Detail (if test coverage available)
- Statements: X% (N/M)
- Branches: X% (N/M)
- Functions: X% (N/M)
- Lines: X% (N/M)
- Well-covered: [list areas >80%]
- Uncovered: [list areas <30%]
```

---

### Step 8: Severity Assessment (THOROUGH mode only)

**Purpose:** Determine the appropriate response based on review findings.

**Decision logic:**

```
IF score >= 80 AND 0 FAIL:
  → PASS (no severity — phase can be closed)

IF score >= 80 AND minor FAIL (test edge cases):
  → SEVERITY 1: MINOR
  → Action: Auto-generate remediation items, append to phase checklist
  → Phase status: remains IN PROGRESS
  → User decision: NOT required

IF score 50-79 OR architectural problem (GP violation):
  → SEVERITY 2: MODERATE
  → Action: Present 3 options to user
  → Options: (A) Fix now — remediation sub-phase
             (B) Accept with tech debt — log to TECH_DEBT.md, score reduced
             (C) Reject — phase FAILED, new approach needed
  → User decision: REQUIRED

IF score 20-49 OR approach fundamentally wrong:
  → SEVERITY 3: MAJOR
  → Action: FAILED status recommended, Phase Memory MANDATORY
  → Phase status: FAILED — REQUIRES REDESIGN
  → User decision: REQUIRED (approve new plan)

IF score 0-19 OR regression detected (other phase tests broken):
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
# Review Report: [Phase/Feature Name]

> **Date:** YYYY-MM-DD
> **Mode:** [NORMAL | THOROUGH]
> **Reviewer:** /blox:check

## Summary
- **Quality Score:** [N]/100 ([Healthy|Needs Work|Critical|Blocked])
- **Severity:** [PASS | S1 MINOR | S2 MODERATE | S3 MAJOR | S4 CATASTROPHIC]
- **FAILs:** [count]
- **CONCERNs:** [count]

## Step Results
| Step | Check | Result | Notes |
|------|-------|--------|-------|
| 1 | Change Analysis | — | X files, +Y/-Z lines |
| 2 | Pre-Submission Checklist | X/8 PASS | [details] |
| 3 | Architectural Invariants | X/Y PASS | [details] |
| 4 | Tests | X/Y PASS | [details] |
| 5 | Lint & Type Check | PASS/FAIL | [details] |
| 5a | Brand Voice | PASS/CONCERN/N/A | [details] |
| 5b | Accessibility | PASS/CONCERN/FAIL/N/A | [details] |
| 5c | Design Consistency | PASS/CONCERN/N/A | [details] |
| 5d | Performance Metrics | values/N/A | [details] |
| 5e | Security Scan | PASS/CONCERN/FAIL | [details] |
| 6 | Golden Answers | X/Y PASS | [details] |
| 7 | Quality Score | NN/100 | [label] |
| 8 | Severity | [level] | [recommendation] |

## Issues Found
| # | Step | Severity | Description | Affected Files | Fix Estimate |
|---|------|----------|-------------|----------------|-------------|
| 1 | Step 3 | FAIL | GP-3 violated: routes > 50 lines | routes/admin/*.ts | 4-6h |
| 2 | Step 5 | CONCERN | 2 lint warnings | utils/format.ts | 15min |

## Domain Quality (THOROUGH only)
### Brand Consistency: [PASS | CONCERN | N/A]
[details if applicable]
### Accessibility: [PASS | CONCERN | FAIL | N/A]
[details if applicable]
### Design Consistency: [PASS | CONCERN | N/A]
[details if applicable]
### Performance Metrics: [values if measurable | N/A]
[details if applicable]

## Recommendation
[One of the following based on severity:]

### PASS — Ready for /blox:done
No blocking issues found. Phase can proceed to close.

### S1 MINOR — Auto-remediation
The following items have been added to the phase checklist:
- [ ] FIX-1: [description]
- [ ] FIX-2: [description]
Phase continues — re-run /blox:check after fixes.

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
[Include Step 1-8 outputs as sub-sections for reference]
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
- Lint & type results (Step 5)
- Domain quality checks (Steps 5a-5d)
- Security scan (Step 5e)
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
- Quality Score: XX/100 ([Healthy|Needs Work|Critical|Blocked])
- Issues: [brief list or "None"]
```

---

## CODE-LEVEL REVIEW INTEGRATION

> This skill includes deep code-level review as part of the pipeline.
> Critical/Important/Minor findings feed into the FAIL/CONCERN counts.

**How the code-level review works:**

During Steps 2-4, the agent performs line-by-line analysis of changed code:
- Code smell detection and naming convention checks
- Critical/Important/Minor severity categorization per finding
- Pattern compliance against the project's established conventions

**Finding classification:**
- Critical findings → FAIL count
- Important findings → CONCERN count
- Minor findings → noted but not counted in score

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Review DONE → severity output | `/blox:done` consumes it | Review output feeds directly into done decision |
| Checkpoint Level 2 → optional review | `_internal/checkpoint` can trigger it | Agent decides if NORMAL review is needed |
| S3/S4 → need new plan | `/blox:plan` | After FAILED status, new phase plan needed |
| S2 → accept with debt | TECH_DEBT.md | Manually log the accepted debt |
| Brand issues found | `/blox:brand` | For deeper brand analysis (if available) |
| A11y issues found | `/blox:design` | For deeper accessibility/design work (if available) |
| Security issues found | `/blox:secure` | For deeper security analysis (if available) |

---

## VERIFICATION

### Success Indicators
- Review report generated with structured format (issues list + severity + recommended action)
- Quality Score calculated using the EXACT formula: `max(0, 100 - (20 * FAIL) - (10 * CONCERN))`
- Severity determined: one of PASS, S1, S2, S3, S4
- All tests executed and results recorded (none silently skipped)
- GOLDEN_PRINCIPLES.md checked (or noted as missing if absent)
- In THOROUGH mode: Golden Answers validated (or noted as absent if none defined)
- In THOROUGH mode: domain checks run where applicable (or noted as N/A with reason)
- Score range label applied: Healthy, Needs Work, Critical, or Blocked

### Failure Indicators (STOP and fix!)
- Subjective "looks good" / "looks bad" without Quality Score
- Tests not executed (skipped or ignored)
- No severity assessment — just a vague pass/fail
- Review report missing affected files or fix estimates
- Score calculated with wrong formula
- Score allowed to go below 0 (floor is 0)
- NORMAL mode used when /blox:done requires THOROUGH
- Domain checks skipped in THOROUGH mode without N/A reason
- AI attribution found in review output or code

---

## EXAMPLES

### Example 1: THOROUGH Review — Healthy, All PASS

```
Agent runs /blox:check (THOROUGH mode, called by /blox:done)

Step 1: Collect Changes
  - 12 files changed: code 5, test 3, ui 3, docs 1
  - +340 lines, -45 lines
  - Baseline: commit a1b2c3d

Step 2: Pre-Submission Checklist
  - 8/8 PASS

Step 3: Architectural Invariant Check
  - 5 principles checked, 5/5 PASS

Step 4: Run Tests
  - Verification Commands: 6/6 PASS
  - npm test: 142/142 PASS

Step 5: Lint & Type Check
  - eslint: 0 errors, 0 warnings
  - tsc: PASS

Step 5a: Brand Voice Consistency
  - PASS — 8 UI strings checked, all match brand guidelines

Step 5b: Accessibility Review
  - PASS — 3 UI files scanned, 0 WCAG issues

Step 5c: Design Consistency Review
  - PASS — Components follow existing patterns, spacing tokens used

Step 5d: Performance Metrics Review
  - Bundle size: 245KB (no change from baseline)
  - No anti-patterns found

Step 5e: Security Scan
  - No security-sensitive patterns detected

Step 6: Golden Answers Validation
  - GA-01: PASS
  - GA-02: PASS
  - GA-03: PASS

Step 7: Quality Score
  - FAIL: 0, CONCERN: 0
  - Score: max(0, 100 - 0 - 0) = 100 (Healthy)
  - Trend: stable (was 100)

Step 8: Severity Assessment
  → PASS — no blocking issues

Step 9: Review Report
  Summary: Quality Score 100/100 (Healthy), PASS. Phase ready for close.
```

### Example 2: THOROUGH Review — S2 MODERATE (GP violation + design concerns)

```
Agent runs /blox:check (THOROUGH mode, called by /blox:done)

Step 1: Collect Changes
  - 45 files changed: code 25, test 10, ui 7, config 2, docs 1
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

Step 5: Lint & Type Check
  - eslint: 0 errors, 2 warnings → 1 CONCERN

Step 5a: Brand Voice Consistency
  - N/A — No brand guidelines found

Step 5b: Accessibility Review
  - CONCERN — 2 missing aria-labels on custom buttons

Step 5c: Design Consistency Review
  - CONCERN — 3 hardcoded px values bypassing spacing tokens

Step 5d: Performance Metrics Review
  - N/A — No measurable metrics

Step 5e: Security Scan
  - No security-sensitive patterns detected

Step 6: Golden Answers Validation
  - GA-01: PASS
  - GA-02: PASS

Step 7: Quality Score
  - FAIL: 3 (PSC #7 + GP-3 + GP-7)
  - CONCERN: 3 (lint warnings + a11y + design)
  - Score: max(0, 100 - (20 * 3) - (10 * 3)) = 10 (Blocked)
  - Trend: declined (was 85)

Step 8: Severity Assessment
  → SEVERITY 2: MODERATE
  → Reason: GP-3 and GP-7 violated — route handlers oversized, no service layer
  → Affected: backend/routes/admin/*.ts (8 files)
  → Estimated fix: 4-6 hours

Step 9: Review Report
  "The phase EXIT CRITERIA all PASS, but the quality review found
   two GOLDEN PRINCIPLE violations and domain quality concerns.
   Route handlers are oversized (8/10 > 100 lines) and there is no service layer.
   Accessibility and design consistency also need attention.

   Three options:
   1. Fix now — Remediation sub-phase: service layer extraction (~4-6h)
   2. Accept with debt — Log to TECH_DEBT.md, Quality Score drops to 10
   3. Reject phase — New approach needed (drastic, not recommended)"
```

### Example 3: NORMAL Review — At Checkpoint

```
Agent runs /blox:check (NORMAL mode, at checkpoint)

## Quick Review — 2026-03-17
- Changes: 5 files, +120/-30 lines
- Pre-Submission: 8/8 PASS
- Invariants: 3/3 PASS (only checked principles relevant to changed files)
- Tests: 4/4 PASS
- Quality Score: 100/100 (Healthy)
- Issues: None
```

### Example 4: THOROUGH Review — S4 CATASTROPHIC (Regression)

```
Agent runs /blox:check (THOROUGH mode)

Step 1-7: Current phase looks OK (score 85, Healthy)

Step 8: Severity Assessment — Cross-phase impact check
  → Current phase modified shared/schemas/user.ts (renamed field)
  → Running Build phase tests...
  → FAIL: 12 component tests broken (field name changed)
  → Running Foundation phase tests...
  → FAIL: 5 endpoint tests broken

  → SEVERITY 4: CATASTROPHIC — Regression detected!
  → Affected phases: Foundation, Build
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

### Example 5: THOROUGH Review — S1 with Accessibility Issues

```
Agent runs /blox:check (THOROUGH mode)

Steps 1-4: All PASS
Step 5: Lint — PASS

Step 5b: Accessibility Review
  - FAIL: 1 missing alt text on hero image (meaningful content)
  - CONCERN: 2 buttons with icon-only, no aria-label

Step 7: Quality Score
  - FAIL: 1 (missing alt text)
  - CONCERN: 2 (icon buttons)
  - Score: max(0, 100 - 20 - 20) = 60 (Needs Work)

Step 8: Severity Assessment
  → SEVERITY 1: MINOR
  → Auto-remediation items added to phase checklist:
    - [ ] FIX-1: Add alt text to hero image in components/Hero.tsx
    - [ ] FIX-2: Add aria-label to icon buttons in components/Toolbar.tsx
```

---

## REFERENCES (optional)

- `references/patterns/knowledge-patterns.md` — Engineering pattern compliance rules
- `GOLDEN_PRINCIPLES.md` (project root) — Project-specific architectural rules
- `QUALITY_SCORE.md` (project root) — Score tracking across phases
- `/blox:brand` — Deeper brand voice analysis (if available)
- `/blox:design` — Deeper design and accessibility work (if available)
- `/blox:secure` — Deeper security analysis (if available)
