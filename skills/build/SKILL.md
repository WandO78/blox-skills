---
name: blox-build
description: "Build features with TDD — write tests first, implement, verify, commit. Auto-saves progress with checkpoints. Use when it's time to write code."
user-invocable: true
argument-hint: "[phase name or feature description]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(commit messages, checklist updates, checkpoint entries, status messages) MUST be
written in the user's language. The skill logic instructions below are in English
for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:build

> **Purpose:** The main coding skill. Takes checklist items from a phase file and
> implements them using TDD: write failing test, write minimal implementation, verify,
> refactor, commit. Auto-saves progress with checkpoints at regular intervals.
> This is where the actual code gets written.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-build
category: core
complements: [blox-plan, blox-check, blox-internal-checkpoint]

### Triggers — when the agent invokes automatically
trigger_keywords: [build, code, implement, develop, write, create, epites]
trigger_files: [plans/*.md with >>> CURRENT <<<]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when a phase file exists with checklist items to implement. This is the
  primary execution skill — it turns plans into working code. Called by the user
  directly, or chained from /blox:idea autopilot after plan generation.
  Do NOT use when no plan exists (use /blox:plan), when something is broken
  (use /blox:fix), or when quality review is needed (use /blox:check).
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Phase file has pending checklist items | "Build the user authentication phase" | No — user invokes |
| `/blox:idea` autopilot chains to it | Idea pipeline execution step | Yes — idea calls it |
| User wants to implement a specific feature | "Implement the GET /api/products endpoint" | No — user invokes |
| Resuming work on an active phase | "Continue where I left off" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| No plan exists | Need a plan first | `/blox:plan` |
| Something is broken | Debugging, not building | `/blox:fix` |
| Quality review needed | Review, not implementation | `/blox:check` |
| Phase is complete | Close the phase | `/blox:done` |
| Project not scaffolded | Need project structure first | `/blox:idea` |

---

## SUPERPOWERS INTEGRATION

This skill executes blox phase checklists. It uses superpowers for implementation discipline:

- **TDD cycle:** Follow `superpowers:test-driven-development` (RED-GREEN-REFACTOR) for every code item. This is an Iron Law — no production code without a failing test first.
- **Execution engine:** For phases with multiple independent tasks, use `superpowers:subagent-driven-development` (fresh subagent per task + two-stage review). For sequential work, use `superpowers:executing-plans`.
- **Git isolation:** Use `superpowers:using-git-worktrees` for feature work that needs isolation.
- **What blox adds on top:** Automatic checkpoint saves (every 5 items via _internal/checkpoint), plugin detection (_internal/detect), phase checklist tracking (`[x]` marks, `>>> CURRENT <<<` movement), and section dependency enforcement (brand before build).

**Rule:** The superpowers provide discipline (TDD, review, worktree). blox provides tracking (checkpoints, phase file, quality score). Both run together.

---

## SKILL LOGIC

> **6-step execution engine. Repeats the TDD cycle per checklist item,**
> **with automatic checkpointing to protect progress.**

### Step 1: Locate Active Work

Read project context and find the current work item.

```
1a. Read START_HERE.md → find the active phase
    - If no START_HERE.md → STOP: "No project structure found. Run /blox:idea first."
    - If no active phase → STOP: "No active phase. Run /blox:plan to create one."

1b. Read the active phase file → find `>>> CURRENT <<<` marker
    - The marker is ABOVE the first pending `[ ]` item
    - Read the next 3-5 checklist items to understand the immediate work
    - Note the current Section name and any dependencies
    - CHECK: Does the current section have a `(REQUIRES: Section N complete)` dependency?
      If yes → verify that Section N is actually complete (all items [x])
      If not complete → STOP: "Section N must be completed first. It uses /blox:[skill]."
    - CHECK: Is the current section a brand/design section?
      If yes → chain to the appropriate skill (/blox:brand or /blox:design) instead of coding
      /blox:build should NOT execute brand/design items — those need their specialized skills

1c. Read the phase's Skills & Tools table
    - Know which tools/plugins are available for this phase
    - If a plugin is listed but not installed → trigger `_internal/detect`

1d. Repo Knowledge Check (MANDATORY on first invocation this session)
    Read these 5 files BEFORE writing any code:

    - [ ] RK-1: ARCHITECTURE.md — which layers/domains are affected?
    - [ ] RK-2: Previous phase memories (completed/PHASE_*.md) — lessons learned?
    - [ ] RK-3: GOLDEN_PRINCIPLES.md — which invariants must be followed?
    - [ ] RK-4: TECH_DEBT.md — is there related open debt to address now?
    - [ ] RK-5: QUALITY_SCORE.md — what is the current quality baseline?

    If any file doesn't exist: note it and continue.
    If already done this session (e.g., resuming after checkpoint): skip.
```

---

### Step 2: TDD Cycle (per checklist item)

For EACH checklist item, follow this cycle:

**2a. UNDERSTAND the task**
- Read the checklist item description carefully
- Identify affected files (from phase file context or codebase scan)
- Check if this item has a Golden Answer → use as test target
- Check Architectural Invariants → know the rules before writing code

**2b. RED — Write the failing test**
- Write a test that describes the expected behavior
- Run it → MUST FAIL
  - If it passes: the test is wrong OR the feature already exists
  - If it passes and the feature exists: mark item as `[x]`, move to next
- If no test framework is configured: set one up first (see TDD WHEN NO TEST FRAMEWORK)

**2c. GREEN — Write minimal implementation**
- Write the SIMPLEST code that makes the test pass
- No extra features, no premature optimization, no gold-plating
- Run test → MUST PASS
  - If it fails: fix the implementation (not the test), re-run
  - Max 3 fix iterations → if still failing, investigate root cause

**2d. REFACTOR (if needed)**
- Clean up code while tests stay green
- Extract functions, improve naming, remove duplication
- Apply Golden Principles from the project's GOLDEN_PRINCIPLES.md
- Run tests again → still PASS
  - If tests fail after refactor: revert the refactor, it broke something

**2e. COMMIT (if git active)**
- **Skip this step if the project has no `.git` directory**
- **User override:** If user explicitly asks to commit → init git first (see checkpoint skill)
- Stage specific files (NEVER `git add -A` or `git add .`)
- Commit with descriptive message following project convention:
  - `feat: [what was added]` — new functionality
  - `fix: [what was fixed]` — bug fix
  - `refactor: [what was improved]` — code improvement, no behavior change
  - `test: [what was tested]` — test-only changes
  - `chore: [what was set up]` — tooling, config, dependencies
- **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, `Anthropic`, or any AI tool attribution

**2f. UPDATE CHECKLIST**
- Mark item as `[x]` in the phase file
- If the item had subtasks: mark each completed subtask as `[x]` too
- Increment the internal item counter (for checkpoint trigger)
- Move to next item

---

### Step 3: Checkpoint Integration

Checkpoints fire AUTOMATICALLY during the build cycle. The developer does NOT
think about checkpoints — they happen in the background.

**Checkpoint triggers (delegate to `_internal/checkpoint`):**

```
LEVEL 1 (AUTO) — lightweight, frequent:
  - After every 5 completed checklist items
  - After every git commit (if git active)
  Actions: mark [x], move >>> CURRENT <<<, Progress Log row, Current Step update

LEVEL 2 (SMART) — thorough, planned:
  - At --- CHECKPOINT X --- markers in the phase file
  - When context window feels ~50% full
  - After important architectural decisions
  Actions: Level 1 + Interim Phase Memory + CONTEXT_CHAIN entry + git commit (if git active)

LEVEL 3 (EMERGENCY) — last resort, critical:
  - When context window feels ~80% full
  - Signs: growing context, compression notices, truncation warnings
  Actions: Level 2 + debug context + open questions + git status snapshot (if git active)
```

**Chain:** Follow the checkpoint protocol in `skills/_internal/checkpoint/SKILL.md`

**Rules:**
- Over-checkpointing wastes ~1 minute; under-checkpointing can lose hours
- When in doubt: trigger Level 2 — it's always safe
- NEVER skip a checkpoint to "save time" — this is the safety net

---

### Step 4: Plugin Detection

First-time triggers during the build cycle invoke `_internal/detect` automatically:

```
First time writing code in a language → _detect checks for LSP plugin
First time writing tests              → _detect checks for test runner plugin
First time writing frontend components → _detect checks for frontend-design plugin
First time writing API endpoints       → _detect checks for security/API plugins
```

**Chain:** Follow the detection protocol in `skills/_internal/detect/SKILL.md`

**Rules:**
- Detection is NON-BLOCKING — work always continues regardless of plugin status
- If user declines a plugin: don't re-ask this session
- If plugin enhances the current work: note the enhancement in commit/checklist

---

### Step 5: Quality Gates (per section)

After completing all checklist items in a section, run quality gates BEFORE
moving to the next section:

```
GATE 1: Tests
  Run ALL project tests (not just the new ones)
  → ALL PASS? Continue
  → ANY FAIL? Fix before moving on (max 3 iterations, then investigate root cause)

GATE 2: Linter
  Run project linter (if configured)
  → 0 errors? Continue
  → Errors? Fix (auto-fix where possible: eslint --fix, ruff format)

GATE 3: Golden Answers
  Check Golden Answers table in the phase file (if defined)
  → All match expected output? Continue
  → Mismatch? Fix the implementation (not the Golden Answer)

GATE 4: Build
  Run project build (if applicable — not all projects have a build step)
  → SUCCESS? Continue
  → FAIL? Fix before moving on
```

**If ANY gate fails after 3 fix iterations:**
- STOP execution
- Record the failure in the Progress Log
- Add an `[BLOCKED reason]` marker on the failing item
- Inform the user: "Gate [N] failing at item [X.Y]. Here's what I tried: [summary]. Need help."

---

### Step 6: Section Complete — Next or Done

When a section's checklist items are all `[x]`:

```
MORE SECTIONS REMAIN?
  +-- YES → Move >>> CURRENT <<< to next section's first item
  |         Check section dependencies: (REQUIRES: Section N complete)
  |         Continue TDD cycle with next section
  |
  +-- NO (all sections done) →
      |
      Is this autopilot mode (chained from /blox:idea)?
      +-- YES → Chain to next skill per master plan
      |         (e.g., /blox:test, /blox:secure, /blox:deploy)
      |
      +-- NO → Suggest: "All items complete. Run /blox:check for quality review,
      |         then /blox:done to close the phase."
      |
      Run --- FINAL CHECKPOINT --- items:
      - [ ] CP-FINAL: All Exit Criteria PASS
      - [ ] CP-FINAL: Run /blox:done
```

---

## TDD WHEN NO TEST FRAMEWORK

If the project has no test framework yet, set one up BEFORE starting the TDD cycle:

```
1. DETECT language (from file extensions, package.json, requirements.txt, go.mod, etc.)

2. SUGGEST framework:
   TypeScript / JavaScript → Vitest (preferred) or Jest (if already configured)
   Python                  → pytest
   Go                      → built-in testing package
   Rust                    → built-in #[test] + cargo test
   Java                    → JUnit 5
   C# / .NET              → xUnit or NUnit
   Ruby                    → RSpec or Minitest
   PHP                     → PHPUnit
   Other                   → suggest the most common framework for that language

3. INSTALL and configure:
   - Install the framework (npm install -D vitest, pip install pytest, etc.)
   - Create config file if needed (vitest.config.ts, pytest.ini, etc.)
   - Add test script to package manager (package.json scripts, Makefile, etc.)
   - Create a sample test to verify the setup works

4. COMMIT: "chore: add [framework] test framework"

5. THEN start the TDD cycle for the actual checklist items
```

**Present this to the user before installing:**
"No test framework detected. I suggest [framework] for this project. Install? (y/n)"

---

## TDD EXCEPTIONS (when NOT to TDD)

Not everything needs a test-first approach. Use judgment:

| Item type | Approach | Why |
|-----------|----------|-----|
| Config files (YAML, JSON, TOML) | Write and validate | No testable logic |
| Documentation | Write directly | No testable behavior |
| Static assets (images, fonts, icons) | Add and verify | Nothing to test |
| One-line fixes | Test AFTER, not before | TDD overhead > value |
| Infrastructure setup (Docker, CI) | Test by running | Integration test, not unit test |
| Database migrations | Write and run | Migration tools have built-in validation |
| Environment/config setup | Verify by running | Runtime validation |

**IMPORTANT:** These are exceptions, NOT escape hatches. If the item contains
business logic, data transformation, API behavior, or user-facing functionality —
it GETS a test. When in doubt: write the test.

---

## INVARIANTS

1. **NEVER skip tests for business logic** — TDD is not optional for testable code
2. **Tests run BEFORE claiming an item is done** — evidence before assertions
3. **Commits are small and focused (if git active)** — one checklist item = one commit (or one logical change)
4. **Checkpoints fire automatically** — the developer doesn't think about them
5. **Golden Answers are verified when they exist** — they define correctness
6. **No code without understanding** — read the checklist item FULLY before writing
7. **Fix the test, not the assertion** — if a test fails, the implementation is wrong (unless the test itself has a bug)
8. **Refactor only with green tests** — never refactor on red
9. **Never force-push or amend during build (if git active)** — history is sacred, new commits only
10. **Stage specific files (if git active)** — never `git add -A` or `git add .`

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| 5 items done / commit made / checkpoint marker reached | `_internal/checkpoint` | Automatic during TDD cycle (Step 3) |
| First time writing code in a new language / first test / first frontend | `_internal/detect` | Automatic plugin detection (Step 4) |
| All sections complete | `/blox:check` | Suggest quality review (Step 6) |
| Quality review passed | `/blox:done` | Phase closure (Step 6) |
| Autopilot mode — phase complete | Next `/blox:*` per master plan | Chained by /blox:idea (Step 6) |
| Something breaks during build | `/blox:fix` | If TDD cycle hits a persistent failure |
| Z7 Evolution phase — every commit | Regression test suite | Run ALL existing tests after every commit |

---

## VERIFICATION

### Success indicators
- Checklist items marked `[x]` with corresponding git commits
- Tests written BEFORE implementation (RED → GREEN → REFACTOR cycle followed)
- All tests pass after each completed item
- Commits are small and focused: one item = one commit
- Commit messages follow convention (feat/fix/refactor/test/chore)
- Checkpoints fired at correct intervals (every 5 items, at markers, at context limits)
- `>>> CURRENT <<<` marker at the correct position throughout execution
- Quality gates passed at section boundaries (tests, lint, Golden Answers, build)
- Repo Knowledge Check completed on first invocation (RK-1 through RK-5)
- Golden Answers verified when defined in the phase file
- No AI attribution in commits or code (no Co-Authored-By, Claude, Opus, Anthropic)

### Failure indicators (STOP and fix!)
- Code written without tests for testable items (INVARIANT 1 violation)
- Tests never run — item marked `[x]` without test execution
- Bulk commits: multiple checklist items in one commit (INVARIANT 3 violation)
- Checkpoints skipped: > 5 items without Level 1, checkpoint marker ignored
- Golden Answers ignored: defined but never verified
- `>>> CURRENT <<<` marker missing or at wrong position
- `git add -A` or `git add .` used instead of specific file staging (INVARIANT 10 violation)
- Quality gate failure ignored: section moved on despite failing tests/lint
- Refactoring on red: code changed while tests are failing (INVARIANT 8 violation)
- AI attribution found in commits or generated code

---

## EXAMPLES

### Example 1: Web API endpoint (full TDD cycle)

**Phase item:** `[ ] **1.3** Create GET /api/products endpoint`

```
UNDERSTAND:
  Item: Create GET /api/products endpoint
  Affected files: src/routes/products.ts (new), tests/products.test.ts (new)
  Golden Answer: GA-02 says "GET /api/products returns JSON array with id, name, price"

RED — Write failing test:
  // tests/products.test.ts
  test("GET /api/products returns product list", async () => {
    const res = await request(app).get("/api/products");
    expect(res.status).toBe(200);
    expect(res.body).toBeInstanceOf(Array);
    expect(res.body[0]).toHaveProperty("id");
    expect(res.body[0]).toHaveProperty("name");
    expect(res.body[0]).toHaveProperty("price");
  });
  → Run: npm test → FAIL ✓ (route doesn't exist yet)

GREEN — Minimal implementation:
  // src/routes/products.ts
  router.get("/products", async (req, res) => {
    const products = await db.product.findMany();
    res.json(products);
  });
  → Run: npm test → PASS ✓

REFACTOR: (none needed — already minimal)

COMMIT (if git active):
  git add src/routes/products.ts tests/products.test.ts
  git commit -m "feat: GET /api/products endpoint with test"
  (Skip if no .git — go straight to UPDATE)

UPDATE:
  [x] **1.3** Create GET /api/products endpoint
  Item counter: 3 (not yet 5, no checkpoint trigger)
```

### Example 2: Frontend component with design plugin

**Phase item:** `[ ] **2.1** Create ProductCard component`

```
UNDERSTAND:
  Item: Create ProductCard component
  Skills & Tools table shows: frontend-design plugin installed
  _detect: frontend-design plugin available → enhanced mode

RED — Write test:
  test("ProductCard renders product name and price", () => {
    render(<ProductCard name="Widget" price={9.99} />);
    expect(screen.getByText("Widget")).toBeInTheDocument();
    expect(screen.getByText("$9.99")).toBeInTheDocument();
  });
  → Run: npm test → FAIL ✓

GREEN — Implement:
  Use frontend-design plugin knowledge for accessible, responsive design
  Implement ProductCard with semantic HTML, ARIA labels, responsive layout
  → Run: npm test → PASS ✓

REFACTOR:
  Ensure accessibility: alt tags, focus management, keyboard navigation
  → Run: npm test → still PASS ✓

COMMIT (if git active):
  git add src/components/ProductCard.tsx tests/ProductCard.test.tsx
  git commit -m "feat: ProductCard component with accessibility"
  (Skip if no .git)

UPDATE:
  [x] **2.1** Create ProductCard component
```

### Example 3: No test framework — setup first

**Phase item:** `[ ] **1.1** Set up project structure`

```
DETECT: package.json exists, no test framework configured
SUGGEST: "No test framework detected. I suggest Vitest for this project. Install? (y/n)"
User: "y"

INSTALL:
  npm install -D vitest @testing-library/react @testing-library/jest-dom
  Create vitest.config.ts with standard config
  Add "test": "vitest run" to package.json scripts
  Write sample test → run → PASS ✓

COMMIT (if git active):
  git add vitest.config.ts package.json package-lock.json
  git commit -m "chore: add Vitest test framework"
  (Skip if no .git)

NOW proceed with TDD for item 1.1
```

### Example 4: Checkpoint triggers during build

**Situation:** Agent completes items 1.1 through 1.5

```
Item 1.5 completed → counter = 5 → TRIGGER Level 1 AUTO checkpoint

Level 1 actions:
  - Mark items 1.1-1.5 as [x] in phase file
  - Move >>> CURRENT <<< above item 1.6
  - Add Progress Log row: | 1 | 2026-03-17 | 1.1-1.5 | completed | User model, migration, CRUD routes |
  - Update Current Step: 1.6
  - Reset counter to 0

Agent continues with item 1.6...

--- CHECKPOINT A (Section 1 complete) --- reached → TRIGGER Level 2 SMART checkpoint

Level 2 actions (Level 1 +):
  - Interim Phase Memory: "[CP-A] Zod schemas caught 3 type mismatches early"
  - CONTEXT_CHAIN entry: "Phase 03 — CP-A: User model complete"
  - Git commit: "Phase 03 — CP-A: Section 1 complete — user model and CRUD"
  - Context Refresh: re-read phase file and SKILL.md
```

### Example 5: TDD exception — config file

**Phase item:** `[ ] **3.2** Configure Docker Compose for dev environment`

```
UNDERSTAND:
  Item: Docker Compose configuration
  This is a config file (YAML) → TDD EXCEPTION

WRITE docker-compose.yaml:
  Define services (app, db, redis)
  Set environment variables, ports, volumes

VALIDATE by running:
  docker compose config → validates YAML syntax
  docker compose up -d → verify services start
  docker compose down → clean up

COMMIT:
  git add docker-compose.yaml
  git commit -m "chore: Docker Compose dev environment"

UPDATE:
  [x] **3.2** Configure Docker Compose for dev environment
```

### Example 6: Quality gate failure at section boundary

**Situation:** All items in Section 2 are done. Running quality gates.

```
GATE 1: npm test → 47 passed, 1 failed
  FAIL: test/auth.test.ts — "should reject expired token"
  → Fix: update token validation logic
  → Re-run: npm test → 48 passed ✓

GATE 2: npm run lint → 0 errors ✓

GATE 3: Golden Answers
  GA-01: "Login with valid credentials returns 200 + JWT" → PASS ✓
  GA-02: "Login with invalid password returns 401" → PASS ✓
  GA-03: "Expired token returns 403" → PASS ✓ (fixed above)

GATE 4: npm run build → SUCCESS ✓

All gates passed. Continue to Section 3.
```

---

## REFERENCES

- `references/templates/phase-template.md` — Phase file format (checklist structure, checkpoint format)
- `references/patterns/knowledge-patterns.md` — Engineering patterns (TDD, quality gates, architecture invariants)
- `skills/_internal/checkpoint/SKILL.md` — Checkpoint protocol (Level 1/2/3)
- `skills/_internal/detect/SKILL.md` — Plugin detection protocol
