# /blox:build — Worked Examples

Worked TDD walkthroughs. The RED-GREEN-REFACTOR methodology lives in
`superpowers:test-driven-development`; these illustrate how the blox overlay
(checklist marks, `>>> CURRENT <<<` movement, checkpoints, quality gates) wraps it.

---

## Example 1: Web API endpoint (full TDD cycle)

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

UPDATE (blox overlay):
  [x] **1.3** Create GET /api/products endpoint
  Item counter: 3 (not yet 5, no checkpoint trigger)
```

---

## Example 2: Frontend component with design plugin

**Phase item:** `[ ] **2.1** Create ProductCard component`

```
UNDERSTAND:
  Item: Create ProductCard component
  Skills & Tools table shows: frontend-design companion installed → enhanced mode

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

UPDATE (blox overlay):
  [x] **2.1** Create ProductCard component
```

---

## Example 3: No test framework — setup first

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

NOW proceed with TDD for item 1.1
```

---

## Example 4: Checkpoint triggers during build (blox overlay)

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

---

## Example 5: TDD exception — config file

**Phase item:** `[ ] **3.2** Configure Docker Compose for dev environment`

```
UNDERSTAND:
  Item: Docker Compose configuration
  This is a config file (YAML) → TDD EXCEPTION (no testable logic)

WRITE docker-compose.yaml:
  Define services (app, db, redis); set environment variables, ports, volumes

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

---

## Example 6: Quality gate failure at section boundary (blox overlay)

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
