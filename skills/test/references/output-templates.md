# /blox:test — Output Formats & Test-Structure Templates

Verbatim output templates for each step and the test-file scaffolds. The detection
logic, gap-prioritization rules, and step triggers stay in SKILL.md — this file is the
formatting reference the agent fills in.

---

## Step 1 — Test Framework Detection (output format)

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

**No-framework prompt:**
```
"No test framework detected. Before generating tests, a framework is needed.

Recommended for this project: [framework based on language/stack]

Options:
A) Set up [framework] now (I'll install and configure it)
B) Skip test framework setup, just analyze code for testable areas
C) Use a different framework: [list alternatives]"
```

---

## Step 2 — Test Results (output format)

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

---

## Step 3 — Gap Analysis (output format)

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

### ⚠️ Orphaned Source Files (BLOCKING)
Files created in this session/phase that have NO test file yet.
These MUST be resolved before proceeding to next feature work.
| # | Source File | Type | Status |
|---|------------|------|--------|
| 1 | src/components/CostCenterSearch.tsx | component | ❌ No test file |
| 2 | src/hooks/useBudgetBalance.ts | hook | ❌ No test file |

### Summary
- Source files: [N] total, [M] without tests ([X]%)
- Orphaned files (no test at all): [N] — **BLOCKING if > 0** (INVARIANT 12)
- Functions: [N] public, [M] untested ([X]%)
- Edge cases: [N] identified, [M] missing tests
- Error handlers: [N] found, [M] untested
- Priority breakdown: P1: [N], P2: [N], P3: [N], P4: [N]
```

---

## Step 4 — Generate Missing Tests

**Generation prompt (ask before generating):**
```
"Found [N] testing gaps ([X] critical). Generate tests?
A) All gaps (P1-P4) — [estimated N test files, M test cases]
B) Critical only (P1) — [estimated N test files, M test cases]
C) Specific scope — tell me which files/functions
D) Skip — just use the gap report"
```

**Test structure per file:**
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

## Step 5 — E2E Tests

**Test specification format (BASIC mode):**
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

**Playwright test stub:**
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
