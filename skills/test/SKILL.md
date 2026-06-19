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

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

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

**If NO test framework found:** STOP and present the no-framework prompt (see
`references/output-templates.md`), then route:
- User chooses **A** → follow `/blox:build` TDD WHEN NO TEST FRAMEWORK protocol
- User chooses **B** → skip to Step 3 (gap analysis only, no execution)
- User chooses **C** → install the chosen framework

**Output:** Use the "Test Framework Detection" template in `references/output-templates.md`.

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

**Output:** Use the "Test Results" template in `references/output-templates.md` (totals,
failing-tests table, coverage summary, lowest-coverage files).

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

**Output:** Use the "Gap Analysis" template in `references/output-templates.md` (untested
files, untested functions, missing edge cases, missing error-handling tests, the
⚠️ Orphaned Source Files BLOCKING table, and the summary with the P1-P4 breakdown).

**CRITICAL:** If orphaned source files > 0, the gap analysis output MUST include a prominent warning. The agent MUST NOT proceed to generate tests for other files while orphaned files exist — orphaned files get P0 priority (above P1).

---

### Step 4: Generate Missing Tests

**Purpose:** Write tests for identified gaps using TDD methodology.

**Trigger:** User explicitly requests test generation, OR user confirms after gap analysis.
Do NOT auto-generate — always present gaps first (Step 3) and ask using the generation
prompt in `references/output-templates.md` (options A=all / B=critical only / C=specific
scope / D=skip).

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

2. **Test structure per file:** one `describe` block per module, nested `describe` per
   function, grouping happy-path / edge-case / error-case `it()` blocks. Scaffold in
   `references/output-templates.md`.

3. **Run ALL tests after generating each file:**
   - New tests + existing tests → ALL must pass
   - If a new test reveals a bug: report it clearly, don't fix silently
   - If a new test conflicts with existing tests: investigate and resolve

4. **Commit generated tests (if git active):**
   - Stage specific test files (NEVER `git add -A` or `git add .`)
   - Commit: `test: add [scope] tests — [N] test cases for [module/feature]`
   - **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, `Anthropic`, or any AI attribution

**Reference:** @superpowers:test-driven-development for TDD methodology.

**Output:** Use the "Generated Tests" template in `references/output-templates.md`
(tests-added table with before/after coverage, bugs-found table, post-generation test run).

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

2. **Write test specifications** using the spec format in `references/output-templates.md`
   (priority, numbered steps, assertions, variants per flow).

3. **If Playwright is the E2E framework:** generate Playwright test file stubs using the
   stub scaffold in `references/output-templates.md`.

**Actions (PREMIUM mode — Playwright plugin available):**

1. All BASIC mode actions, PLUS:
2. Generate full Playwright test files (not just stubs)
3. Run tests via the Playwright MCP plugin
4. Capture screenshots on failure
5. Report with visual evidence

**Output:** Use the "E2E Test Report" template in `references/output-templates.md`.

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
11. **NEVER simplify or exclude tests** — do not remove test cases, skip assertions, or make fields optional to avoid test failures. If tests are failing, fix the tests or the code — never weaken the test suite. This is enterprise software, not a prototype.
12. **Every new source file MUST have a dedicated test file** — components, hooks, services, utilities, middleware — all need their own test file. No orphaned source files without tests. Gap analysis (Step 3) enforces this.

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| No test framework detected | `/blox:build` TDD framework setup | Step 1 — if user chooses to set up |
| Bug found during test generation | `/blox:fix` | Step 4 — if new test reveals a bug |
| Test generation complete, quality check needed | `/blox:check` | After Step 4 — suggest quality review |
| E2E tests need a missing tool (e.g. Playwright) | Inform in one line, continue | Step 5 — non-blocking |
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
- Tests simplified, excluded, or removed to make the suite pass (INVARIANT 11 violation)
- Source types/interfaces made optional to avoid updating test fixtures (INVARIANT 11 violation)
- New source files without corresponding test files (INVARIANT 12 violation)

---

## EXAMPLES

Five worked pipeline walkthroughs (full Vitest pipeline, Python gap-analysis-only,
Next.js E2E generation, no-framework setup, targeted single-module generation) live in
`references/examples.md`.

---

## REFERENCES

- `references/examples.md` — 5 worked pipeline walkthroughs
- `references/output-templates.md` — per-step output formats + test-file/E2E scaffolds
- `references/patterns/knowledge-patterns.md` — TDD methodology, quality gates
- `skills/build/SKILL.md` — TDD WHEN NO TEST FRAMEWORK section (framework setup)
- @superpowers:test-driven-development — TDD reference for test generation approach
