# /blox:test — Worked Examples

Reference walkthroughs of the 5-step testing pipeline. Decision logic lives in SKILL.md.

## Example 1: Full pipeline — TypeScript project with Vitest

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

## Example 2: Python project — gap analysis only

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

## Example 3: E2E test generation — Next.js with Playwright

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

## Example 4: No test framework — setup first

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

## Example 5: Targeted test generation — specific module

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
