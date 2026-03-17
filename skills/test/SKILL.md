---
name: blox-test
description: "Run and generate tests — unit, integration, E2E. Detect test framework, run existing tests, identify gaps, generate missing tests with TDD."
user-invocable: true
argument-hint: "[scope or test type]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(test reports, gap analysis, generated test descriptions, commit messages) MUST
be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Test framework: !`cat package.json 2>/dev/null | grep -E '"(vitest|jest|mocha|ava|tap)"' | head -3`
- Test status: !`npm test 2>/dev/null | tail -10`
- Coverage: !`npx vitest run --coverage 2>/dev/null | tail -5`
- Test files: !`find . -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' -o -name '*_test.go' -o -name '*_test.rs' 2>/dev/null | head -15`
- Source files: !`find . -path '*/src/*' -o -path '*/app/*' -o -path '*/lib/*' 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|go|rs)$' | head -15`

# /blox:test

> **Testing companion for any project.** Detects the test framework, runs existing
> tests, identifies untested code, generates missing tests with TDD methodology,
> and optionally creates E2E tests with Playwright. The goal: every critical path
> has a test, every edge case is considered, every error handler is exercised.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-test
category: domain
complements: [blox-build, blox-check]

### Triggers — when the agent invokes automatically
trigger_keywords: [test, tests, testing, unit test, integration test, e2e, coverage, teszt, tesztek]
trigger_files: [*.test.*, *.spec.*, test_*.py, *_test.go, *_test.rs, vitest.config.*, jest.config.*, pytest.ini, conftest.py]
trigger_deps: [vitest, jest, mocha, pytest, playwright]

### Phase integration
when_to_use: |
  Invoke when the user wants to run tests, check coverage, find untested code,
  or generate missing tests. Works standalone or chained from /blox:build or
  /blox:check. Useful after major implementation work to verify coverage,
  or proactively to identify gaps before they become bugs.
  Do NOT use when debugging a specific failing test (use /blox:fix),
  when reviewing quality beyond tests (use /blox:check), or when no code
  exists yet (use /blox:plan or /blox:build).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| After implementing a feature | "Run all tests to make sure nothing broke" | No — user invokes |
| Coverage check | "What's my test coverage?" | No — user invokes |
| Gap analysis | "What code is untested?" | No — user invokes |
| Generate tests | "Write tests for the auth module" | No — user invokes |
| E2E test creation | "Create E2E tests for the checkout flow" | No — user invokes |
| Phase completion chain | `/blox:build` completes → suggest testing | No — user decides |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Debugging a specific failing test | Need systematic debugging, not test generation | `/blox:fix` |
| Quality review beyond tests | Tests are ONE dimension of quality | `/blox:check` |
| No source code exists | Nothing to test | `/blox:plan` or `/blox:build` |
| Config/docs only changes | No testable logic | Skip testing |
| Setting up test framework only | Build handles framework setup | `/blox:build` (TDD WHEN NO TEST FRAMEWORK) |

---

## SKILL LOGIC

> **5-step testing pipeline.** Detect → Run → Analyze → Generate → E2E.
> Each step produces concrete output. Steps 4-5 are opt-in — the user decides
> whether to generate tests or only analyze gaps.

### Step 1: Detect Framework

**Purpose:** Identify the project's test framework, runner, and coverage tool.

**Actions:**
1. Scan project configuration files for test framework indicators:

```
DETECTION ORDER:
  1. package.json → devDependencies / scripts.test
  2. vitest.config.* / jest.config.* / .mocharc.* / ava.config.*
  3. pyproject.toml / pytest.ini / setup.cfg / conftest.py
  4. go.mod → built-in testing package
  5. Cargo.toml → built-in #[test] + cargo test
  6. build.gradle / pom.xml → JUnit
  7. *.csproj → xUnit / NUnit / MSTest
  8. Gemfile / .rspec → RSpec / Minitest
  9. composer.json / phpunit.xml → PHPUnit
```

2. Identify the test runner command:
   - Read `package.json` scripts → `test`, `test:unit`, `test:e2e`, `test:integration`
   - Read Makefile → `test`, `test-unit`, `test-integration` targets
   - Read CI config (`.github/workflows/*.yml`, `.gitlab-ci.yml`) → test step commands

3. Identify coverage tool:
   - Vitest → built-in `--coverage` (c8/v8/istanbul)
   - Jest → built-in `--coverage`
   - pytest → `pytest-cov`
   - Go → `go test -cover`
   - Rust → `cargo tarpaulin` or `cargo llvm-cov`
   - If no coverage tool: note as gap

4. Identify E2E framework (if applicable):
   - Playwright → `@playwright/test` in deps or `playwright.config.*`
   - Cypress → `cypress` in deps or `cypress.config.*`
   - Puppeteer → `puppeteer` in deps

**If NO test framework found:**
```
STOP and inform:
"No test framework detected. Before generating tests, a framework is needed.

Recommended for this project: [framework based on language/stack]

Options:
A) Set up [framework] now (I'll install and configure it)
B) Skip test framework setup, just analyze code for testable areas
C) Use a different framework: [list alternatives]"

If user chooses A → follow /blox:build TDD WHEN NO TEST FRAMEWORK protocol
If user chooses B → skip to Step 3 (gap analysis only, no execution)
If user chooses C → install the chosen framework
```

**Output format:**
```
## Test Framework Detection
- Language: [TypeScript | Python | Go | Rust | ...]
- Framework: [Vitest | Jest | pytest | go test | cargo test | ...]
- Runner command: [npm test | pytest | go test ./... | ...]
- Coverage tool: [c8 | istanbul | pytest-cov | go cover | none]
- E2E framework: [Playwright | Cypress | none]
- Test file pattern: [*.test.ts | test_*.py | *_test.go | ...]
- Config file: [vitest.config.ts | pytest.ini | ...]
```

---

### Step 2: Run Existing Tests

**Purpose:** Execute the full test suite and produce a structured report.

**Actions:**
1. Run the detected test command from Step 1
2. Parse test output and extract:
   - **Total tests:** count of all test cases
   - **Passed:** count + percentage
   - **Failed:** count + list with error summaries (file:line + assertion message)
   - **Skipped:** count + list with skip reasons
   - **Duration:** total execution time
3. Run coverage report (if coverage tool available):
   - Statement coverage %
   - Branch coverage %
   - Function coverage %
   - Line coverage %
   - Per-file breakdown (top 10 lowest coverage files)
4. Parse and present results

**Error handling:**
- If tests hang (>5 min) → kill and report timeout
- If test runner crashes → report the error, suggest fix
- If dependency missing → report which dependency, suggest install command

**Output format:**
```
## Test Results
- Total: [N] tests
- Passed: [N] ([X]%)
- Failed: [N] ([X]%)
- Skipped: [N]
- Duration: [X]s

### Failing Tests
| # | Test | File:Line | Error |
|---|------|-----------|-------|
| 1 | should validate email | auth.test.ts:42 | Expected "valid" got "invalid" |
| 2 | ... | ... | ... |

### Coverage Summary (if available)
- Statements: [X]% ([N]/[M])
- Branches: [X]% ([N]/[M])
- Functions: [X]% ([N]/[M])
- Lines: [X]% ([N]/[M])

### Lowest Coverage Files
| # | File | Statements | Branches | Functions |
|---|------|-----------|----------|-----------|
| 1 | src/utils/validation.ts | 23% | 10% | 20% |
| 2 | ... | ... | ... | ... |
```

**If no tests exist (0 test files found):**
```
"No existing tests found. Proceeding to gap analysis (Step 3) to identify
what should be tested."
```

---

### Step 3: Identify Gaps

**Purpose:** Analyze source code vs test coverage to find untested areas.

**Actions:**
1. **Map source files to test files:**
   - For each source file, find its corresponding test file
   - Convention mapping:
     - `src/utils/auth.ts` → `test/utils/auth.test.ts` or `src/utils/__tests__/auth.test.ts`
     - `app/services/user.py` → `tests/services/test_user.py`
     - `pkg/auth/handler.go` → `pkg/auth/handler_test.go`
   - List source files WITHOUT a corresponding test file

2. **Analyze untested functions/modules:**
   - Read exported/public functions in source files
   - Cross-reference with test files to identify untested functions
   - Focus on: exported functions, API handlers, service methods, utility functions

3. **Identify missing edge case tests:**
   - For each tested function, check if common edge cases are covered:
     - Empty/null/undefined input
     - Boundary values (0, -1, MAX_INT, empty string, empty array)
     - Error conditions (invalid input, network failure, timeout)
     - Concurrent access (if applicable)
     - Permission/auth edge cases (if applicable)

4. **Identify missing error handling tests:**
   - Scan for try/catch blocks, error handlers, error middleware
   - Check if error paths have corresponding tests
   - List error conditions without test coverage

5. **Identify uncovered branches:**
   - If coverage data available: use branch coverage report
   - If no coverage: scan for conditionals (if/else, switch, ternary) in critical paths
   - List branches that are likely untested

6. **Prioritize gaps:**
   - **P1 — Critical path:** Business logic, authentication, payment, data integrity
   - **P2 — Error handling:** Error paths, fallbacks, edge cases
   - **P3 — Utility/Helper:** Pure functions, formatters, validators
   - **P4 — UI/Presentation:** Component rendering, styling logic (lowest priority)

**Output format:**
```
## Gap Analysis

### Untested Source Files (no corresponding test file)
| # | Source File | Priority | Reason |
|---|------------|----------|--------|
| 1 | src/services/payment.ts | P1 | Critical business logic, handles transactions |
| 2 | src/utils/format.ts | P3 | Pure utility functions |

### Untested Functions (in partially tested files)
| # | Function | File | Priority | Why it matters |
|---|----------|------|----------|----------------|
| 1 | processRefund() | services/payment.ts | P1 | Financial operation |
| 2 | formatCurrency() | utils/format.ts | P3 | Display helper |

### Missing Edge Cases
| # | Test File | Function | Missing Case | Priority |
|---|-----------|----------|-------------|----------|
| 1 | auth.test.ts | validateToken() | expired token | P1 |
| 2 | auth.test.ts | validateToken() | malformed JWT | P2 |

### Missing Error Handling Tests
| # | Source File | Error Condition | Priority |
|---|------------|----------------|----------|
| 1 | services/api.ts | Network timeout | P1 |
| 2 | services/api.ts | 500 response | P2 |

### Summary
- Source files: [N] total, [M] without tests ([X]%)
- Functions: [N] public, [M] untested ([X]%)
- Edge cases: [N] identified, [M] missing tests
- Error handlers: [N] found, [M] untested
- Priority breakdown: P1: [N], P2: [N], P3: [N], P4: [N]
```

---

### Step 4: Generate Missing Tests

**Purpose:** Write tests for identified gaps using TDD methodology.

**Trigger:** User explicitly requests test generation, OR user confirms after gap analysis.
Do NOT auto-generate — always present gaps first (Step 3) and ask:

```
"Found [N] testing gaps ([X] critical). Generate tests?
A) All gaps (P1-P4) — [estimated N test files, M test cases]
B) Critical only (P1) — [estimated N test files, M test cases]
C) Specific scope — tell me which files/functions
D) Skip — just use the gap report"
```

**Actions (when user confirms):**

1. **For each gap, write a test using TDD principles:**

   a. **Read the source code** — understand WHAT the function does before writing tests
   b. **Write the test FIRST** — describe expected behavior:
      - Happy path: normal input → expected output
      - Edge cases: boundary values, empty inputs, nulls
      - Error cases: invalid input, failures, timeouts
   c. **Run the test:**
      - If it FAILS (function has a bug or missing behavior) → report it
      - If it PASSES → the function works correctly, test is a guard
   d. **Group tests logically:**
      - One `describe` block per function/method
      - Related edge cases grouped together
      - Clear test names: `"should [expected behavior] when [condition]"`

2. **Test structure per file:**

```
// [test framework imports]
// [source imports — the module being tested]

describe("[ModuleName]", () => {
  // Setup / mocks (if needed)

  describe("[functionName]", () => {
    // Happy path
    it("should [expected behavior] with valid input", () => { ... });

    // Edge cases
    it("should handle empty input", () => { ... });
    it("should handle null/undefined", () => { ... });

    // Error cases
    it("should throw when [error condition]", () => { ... });
  });
});
```

3. **Run ALL tests after generating each file:**
   - New tests + existing tests → ALL must pass
   - If a new test reveals a bug: report it clearly, don't fix silently
   - If a new test conflicts with existing tests: investigate and resolve

4. **Commit generated tests:**
   - Stage specific test files (NEVER `git add -A` or `git add .`)
   - Commit: `test: add [scope] tests — [N] test cases for [module/feature]`
   - **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, `Anthropic`, or any AI attribution

**Reference:** @superpowers:test-driven-development for TDD methodology.

**Output format:**
```
## Generated Tests
| # | Test File | Tests Added | Coverage Before | Coverage After |
|---|-----------|------------|----------------|---------------|
| 1 | test/services/payment.test.ts | 12 | 0% | 85% |
| 2 | test/utils/format.test.ts | 8 | 30% | 92% |

### Bugs Found During Test Generation
| # | Test | File | Bug Description |
|---|------|------|----------------|
| 1 | "should handle negative amounts" | payment.test.ts | processRefund() allows negative amounts |

### Test Run After Generation
- Total: [N] tests (was [M])
- Passed: [N]
- Failed: [N] (bugs found — see above)
- Coverage: [X]% (was [Y]%)
```

---

### Step 5: E2E Tests (Web Applications)

**Purpose:** Generate end-to-end test specifications for key user flows.

**Trigger:** Only runs if:
- The project is a web application (has frontend: React, Vue, Svelte, Next.js, etc.)
- The user asks for E2E tests OR the scope includes E2E
- Skip if the project is a library, CLI tool, backend-only API, or non-web

**Mode detection:**

```
BASIC MODE (default — no Playwright plugin):
  Generate test SPECIFICATIONS only:
  - Describe test scenarios in structured format
  - User implements or uses Playwright codegen to create actual tests
  - No execution, just planning

PREMIUM MODE (Playwright MCP plugin available):
  Generate AND run E2E tests:
  - Write Playwright test files
  - Execute tests via the plugin
  - Capture screenshots on failure
  - Report results with visual evidence
```

**Actions (BASIC mode):**

1. **Identify key user flows:**
   - Read route definitions, page components, navigation structure
   - Map critical user journeys:
     - Authentication flow (login, register, logout, password reset)
     - Core feature flows (CRUD operations, main user tasks)
     - Payment/checkout flow (if applicable)
     - Onboarding flow (if applicable)
     - Error recovery (404, session expired, offline)

2. **Write test specifications:**

```markdown
### E2E Test Specifications

#### Flow 1: User Authentication
**Priority:** P1 — Critical
**Steps:**
1. Navigate to /login
2. Enter valid email and password
3. Click "Sign in" button
4. Assert: redirected to /dashboard
5. Assert: user name displayed in header
6. Assert: auth token stored in cookies

**Variants:**
- Invalid credentials → error message displayed
- Empty form → validation errors shown
- Remember me → token persists after browser close

#### Flow 2: [Next flow...]
```

3. **If Playwright is the E2E framework:**
   - Generate Playwright test file stubs with proper structure:
     ```typescript
     import { test, expect } from '@playwright/test';

     test.describe('Authentication', () => {
       test('should login with valid credentials', async ({ page }) => {
         await page.goto('/login');
         await page.fill('[data-testid="email"]', 'user@example.com');
         await page.fill('[data-testid="password"]', 'validpassword');
         await page.click('[data-testid="submit"]');
         await expect(page).toHaveURL('/dashboard');
         await expect(page.locator('[data-testid="user-name"]')).toBeVisible();
       });
     });
     ```

**Actions (PREMIUM mode — Playwright plugin available):**

1. All BASIC mode actions, PLUS:
2. Generate full Playwright test files (not just stubs)
3. Run tests via the Playwright MCP plugin
4. Capture screenshots on failure
5. Report with visual evidence

**Output format:**
```
## E2E Test Report
- Mode: [BASIC | PREMIUM]
- Flows identified: [N]
- Test specs generated: [N]
- Test files created: [list] (BASIC: stubs only, PREMIUM: full tests)

### User Flows
| # | Flow | Priority | Tests | Status |
|---|------|----------|-------|--------|
| 1 | Authentication | P1 | 4 specs | [Generated | Executed: PASS/FAIL] |
| 2 | Product CRUD | P1 | 6 specs | [Generated | Executed: PASS/FAIL] |
```

---

## INVARIANTS

1. **Run existing tests BEFORE generating new ones** — understand the baseline first
2. **Read source code BEFORE writing tests** — tests must match actual implementation
3. **Generated tests must be runnable** — no placeholder assertions, no pseudo-code
4. **Never modify source code** — this skill ONLY creates/modifies test files
5. **Report bugs found, don't fix them** — if a test reveals a bug, report it clearly
6. **Group tests by priority** — critical paths (P1) always come first
7. **Stage specific files** — never `git add -A` or `git add .`
8. **No AI attribution** — no Co-Authored-By, Claude, Opus, Anthropic in commits or code
9. **Ask before generating** — always show gap analysis first, let user decide scope
10. **All tests must pass together** — new tests must not break existing ones

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| No test framework detected | `/blox:build` TDD framework setup | Step 1 — if user chooses to set up |
| Bug found during test generation | `/blox:fix` | Step 4 — if new test reveals a bug |
| Test generation complete, quality check needed | `/blox:check` | After Step 4 — suggest quality review |
| E2E tests need Playwright plugin | `_internal/detect` | Step 5 — plugin detection |
| Tests generated during a phase | `_internal/checkpoint` | After commit, if checkpoint conditions met |
| Test gaps reveal missing features | `/blox:plan` | If gaps indicate unplanned work |

---

## VERIFICATION

### Success Indicators
- Test framework correctly detected (matches actual project config)
- Existing tests executed and results parsed (pass/fail/skip counts accurate)
- Coverage report generated (if coverage tool available)
- Gap analysis produced with prioritized findings (P1-P4)
- Generated tests are syntactically correct and runnable
- ALL tests pass after generation (existing + new)
- Generated tests follow project conventions (naming, structure, imports)
- Test files committed with descriptive messages
- No AI attribution in commits or generated test code
- Bugs found during generation reported clearly (not silently fixed)

### Failure Indicators (STOP and fix!)
- Tests generated without reading source code first (INVARIANT 2 violation)
- Generated tests have placeholder assertions (`expect(true).toBe(true)`)
- Source code modified by this skill (INVARIANT 4 violation)
- Test generation started without showing gaps to user (INVARIANT 9 violation)
- New tests break existing tests (INVARIANT 10 violation)
- `git add -A` or `git add .` used instead of specific file staging
- AI attribution found in commits or generated code
- Coverage numbers fabricated (not from actual tool output)
- Gap analysis missing priority classification

---

## EXAMPLES

### Example 1: Full pipeline — TypeScript project with Vitest

```
User: "/blox:test"

Step 1: Detect Framework
  Language: TypeScript
  Framework: Vitest
  Runner: npm test (vitest run)
  Coverage: c8 (built-in)
  E2E: Playwright (installed)
  Config: vitest.config.ts

Step 2: Run Existing Tests
  Total: 87 tests
  Passed: 84 (97%)
  Failed: 2 (2%)
  Skipped: 1
  Duration: 4.2s

  Failing Tests:
  | 1 | should reject expired token | auth.test.ts:89 | Token still accepted after expiry |
  | 2 | should paginate results | api.test.ts:156 | Returns all results, no pagination |

  Coverage: 62% statements, 48% branches, 55% functions

Step 3: Identify Gaps
  Untested files: 8/24 source files (33%)
  P1 Critical: payment.ts (0%), auth-middleware.ts (20%)
  P2 Error handling: 12 try/catch blocks without test coverage
  P3 Utilities: format.ts (30%), validate.ts (45%)

  → "Found 42 testing gaps (8 critical). Generate tests?
     A) All gaps (P1-P4) — ~8 test files, ~95 test cases
     B) Critical only (P1) — ~2 test files, ~24 test cases
     C) Specific scope
     D) Skip"

User: "B"

Step 4: Generate Missing Tests
  Generated: payment.test.ts (14 tests), auth-middleware.test.ts (10 tests)
  Bugs found: 1 (payment allows negative refund amounts)
  All tests: 111 total, 110 passed, 1 failed (the bug)
  Coverage: 62% → 78% statements

  git add test/services/payment.test.ts test/middleware/auth-middleware.test.ts
  git commit -m "test: add payment and auth-middleware tests — 24 critical path tests"
```

### Example 2: Python project — gap analysis only

```
User: "/blox:test — just show me what's untested"

Step 1: Detect Framework
  Language: Python
  Framework: pytest
  Runner: pytest
  Coverage: pytest-cov

Step 2: Run Existing Tests
  Total: 156 tests
  Passed: 156 (100%)
  Coverage: 71% statements

Step 3: Identify Gaps
  Untested: 5/18 modules (28%)
  P1: services/billing.py (0 tests), services/notifications.py (12% coverage)
  P2: 8 exception handlers without tests
  P3: utils/date_helpers.py (40% coverage)

  Summary presented to user. User chose D (skip generation).

  → No tests generated. Gap report delivered.
```

### Example 3: E2E test generation — Next.js with Playwright

```
User: "/blox:test e2e"

Step 1: Detect Framework
  E2E: Playwright (@playwright/test in devDependencies)
  Config: playwright.config.ts

Step 5: E2E Tests (BASIC mode — no Playwright plugin)
  Flows identified:
  1. Authentication (login, register, logout) — P1
  2. Product CRUD (create, read, update, delete) — P1
  3. Checkout (add to cart, payment, confirmation) — P1
  4. User settings (profile edit, password change) — P2
  5. Search and filter — P2

  Generated: e2e/auth.spec.ts, e2e/products.spec.ts (stubs with test descriptions)
  "These are test specifications with Playwright structure.
   Run `npx playwright test` to execute, or `npx playwright codegen` to record actual interactions."

  git add e2e/auth.spec.ts e2e/products.spec.ts
  git commit -m "test: add E2E test specs for auth and product flows"
```

### Example 4: No test framework — setup first

```
User: "/blox:test"

Step 1: Detect Framework
  Language: TypeScript (from tsconfig.json)
  Framework: NONE detected
  → "No test framework detected. Recommended: Vitest (modern, fast, TypeScript-native).

     Options:
     A) Set up Vitest now
     B) Skip setup, just analyze code for testable areas
     C) Use a different framework (Jest, Mocha, etc.)"

User: "A"

  → Follow /blox:build TDD WHEN NO TEST FRAMEWORK protocol
  → Install vitest, create config, verify with sample test
  → Then continue with Step 2
```

### Example 5: Targeted test generation — specific module

```
User: "/blox:test src/services/payment.ts"

Step 1: Detect Framework → Vitest (already detected)

Step 2: Run Existing Tests → 87/87 PASS, 62% coverage

Step 3: Identify Gaps (scoped to payment.ts)
  Functions in payment.ts: processPayment, processRefund, validateCard, getTransactionHistory
  Tested: processPayment (partial — happy path only)
  Untested: processRefund, validateCard, getTransactionHistory
  Missing edge cases: processPayment with invalid amount, expired card, duplicate transaction

  → "Found 18 gaps in payment.ts (all P1 critical). Generate tests?"

User: "Yes"

Step 4: Generate tests for payment.ts
  Generated: test/services/payment.test.ts (18 tests)
  - processRefund: 5 tests (happy path, negative amount, zero, exceed balance, not found)
  - validateCard: 4 tests (valid, expired, invalid number, missing CVV)
  - getTransactionHistory: 3 tests (with results, empty, date range filter)
  - processPayment edge cases: 6 tests (invalid amount, expired card, duplicate, timeout, partial, currency)

  All tests: 105 total, 104 passed, 1 failed
  Bug found: processRefund allows negative amounts (no validation)

  git add test/services/payment.test.ts
  git commit -m "test: add payment service tests — 18 tests covering refund, validation, history"
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — TDD methodology, quality gates
- `skills/build/SKILL.md` — TDD WHEN NO TEST FRAMEWORK section (framework setup)
- `skills/_internal/detect/SKILL.md` — Plugin detection for Playwright and other test tools
- @superpowers:test-driven-development — TDD reference for test generation approach
