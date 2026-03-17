---
name: blox-fix
description: "Something broken? Systematic debugging — reproduce, gather evidence, form hypothesis, test, fix with TDD, verify no regressions. Never guess."
user-invocable: true
argument-hint: "[describe the problem]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(debug reports, hypothesis descriptions, commit messages, status updates) MUST
be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Active phase: !`ls plans/ 2>/dev/null`
- Recent errors: !`git log --oneline -3 2>/dev/null`
- Test status: (detected at runtime)

# /blox:fix

> **Systematic debugging with TDD verification.** Reproduce the bug, gather
> evidence, form testable hypotheses, prove the fix with a failing test, verify
> no regressions. Never guess — always test.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-fix
category: core
complements: [blox-build, blox-check]

### Triggers — when the agent invokes automatically
trigger_keywords: [fix, bug, error, broken, debug, crash, fail, hiba, javitas]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when something is broken: test failure, runtime error, crash, regression,
  or unexpected behavior. This is the debugging skill — it replaces ad-hoc
  "let me try changing this" with a systematic hypothesis-driven process.
  Do NOT use for new features (use /blox:build), quality review (use /blox:check),
  or performance optimization without a bug (use /blox:check metrics).
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Test is failing | "The login test fails after my change" | No — user invokes |
| Runtime error or crash | "The dashboard shows a blank page" | No — user invokes |
| Feature not working as expected | "Users can't upload files anymore" | No — user invokes |
| Regression detected | "/blox:check found broken tests in other phases" | No — user invokes |
| User says something is broken | "Something is broken" / "This doesn't work" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| New feature needed | Building, not debugging | `/blox:build` |
| Quality review | Evaluating, not fixing | `/blox:check` |
| Performance optimization (not a bug) | Optimization, not debugging | `/blox:check metrics` |
| No code exists yet | Nothing to debug | `/blox:plan` |
| Known tech debt (not broken) | Planned improvement, not bug | `/blox:build` with debt item |

---

## SKILL LOGIC

> **7-step debugging engine.** Each step has a clear purpose and exit condition.
> The process is linear — no skipping steps. If stuck, the skill has a built-in
> escalation protocol (Step 4 rejection → back to Step 2, or STOP after 3 cycles).

### Step 1: REPRODUCE

**Purpose:** Confirm the bug exists and find a reliable way to trigger it.

**Actions:**
1. Read the bug report: user description, error message, stack trace
2. Find a reliable reproduction path:
   - Run the failing test (if a test is failing)
   - Execute the failing operation (if runtime error)
   - Follow the user's steps (if user-reported behavior)
3. If CANNOT reproduce:
   - Gather more context: check logs, environment, configuration
   - Ask the user for more details (exact steps, environment, when it last worked)
   - Check if the issue is intermittent (race condition, timing, state-dependent)
4. Write down the reproduction steps (these become the basis for the test in Step 5)

**Exit condition:** Bug reliably reproduced OR escalated to user for more info.

**Output format:**
```
## Reproduction
- Problem: [one-sentence description]
- Steps to reproduce: [numbered list]
- Error output: [actual error message/stack trace]
- Reproducible: [yes/no/intermittent]
```

---

### Step 2: GATHER EVIDENCE

**Purpose:** Collect facts. DO NOT GUESS — only work with evidence.

**Actions:**
1. Read error messages, stack traces, and logs carefully
2. Check git history: what changed recently?
   - `git log --oneline -10` — recent commits
   - `git diff HEAD~3` — recent code changes
   - `git log --oneline --all -- [affected files]` — file-specific history
3. Check test output: which tests fail? Were they passing before?
   - `git stash && npm test && git stash pop` — test without local changes (if applicable)
4. Check environment: versions, configs, env vars
   - Node/Python/Go version, dependency versions
   - Environment-specific configuration
5. Check the codebase: read the affected files, understand the data flow
6. Note EVERY piece of evidence — even seemingly unrelated facts

**Exit condition:** Enough evidence to form at least one hypothesis.

**Output format:**
```
## Evidence
- Error: [exact error message]
- Stack trace: [key frames]
- Recent changes: [relevant commits/diffs]
- Test results: [which tests fail and how]
- Environment: [relevant versions/configs]
- Observations: [anything else notable]
```

---

### Step 3: FORM HYPOTHESIS

**Purpose:** Based on evidence, propose specific, testable explanations.

**Actions:**
1. Analyze the evidence from Step 2
2. Form 1-3 specific hypotheses, ranked by likelihood
3. Each hypothesis MUST be:
   - **Specific** — not "something is wrong with auth" but "the JWT verification rejects tokens with the new issuer field"
   - **Testable** — there must be a way to confirm or reject it
   - **Evidence-based** — linked to at least one piece of evidence from Step 2
4. Format each hypothesis clearly

**Exit condition:** At least one testable hypothesis formed.

**Output format:**
```
## Hypotheses (ranked by likelihood)
1. [MOST LIKELY] "The bug is caused by [specific cause] because [evidence]"
   - Test: [how to confirm or reject]
2. [POSSIBLE] "The bug is caused by [specific cause] because [evidence]"
   - Test: [how to confirm or reject]
3. [UNLIKELY] "The bug is caused by [specific cause] because [evidence]"
   - Test: [how to confirm or reject]
```

---

### Step 4: TEST HYPOTHESIS

**Purpose:** Confirm or reject each hypothesis with evidence, not assumptions.

**Actions:**
1. Start with the MOST LIKELY hypothesis
2. Design a test that would CONFIRM or REJECT it:
   - Add a debug log or assertion
   - Run a specific test case
   - Check a specific value at a specific point
   - Inspect a specific state or output
3. Execute the test
4. Interpret the result:

```
CONFIRMED → proceed to Step 5 (write failing test)
REJECTED  → move to next hypothesis
ALL REJECTED → gather more evidence (back to Step 2)
```

**Cycle limit:** Maximum 3 full cycles (Step 2 → Step 3 → Step 4).
If all 3 cycles exhaust without confirmation → STOP and escalate (see STUCK PROTOCOL).

**Exit condition:** One hypothesis confirmed OR stuck protocol triggered.

---

### Step 5: WRITE FAILING TEST (TDD)

**Purpose:** Write a test that REPRODUCES the bug. This test is the PROOF that the fix works.

**Actions:**
1. Write a test that exercises the exact bug scenario
   - Use the reproduction steps from Step 1
   - Use the confirmed hypothesis from Step 4
2. Run the test → it MUST FAIL
   - If it passes: the test doesn't capture the bug — rewrite it
   - If it fails with the expected error: proceed to Step 6
3. This test becomes the permanent regression guard

**Reference:** @superpowers:test-driven-development for TDD methodology.

**If no test framework exists:**
- Set one up (same as `/blox:build` TDD WHEN NO TEST FRAMEWORK)
- Then write the failing test

**Exit condition:** A test exists that FAILS, reproducing the bug.

---

### Step 6: IMPLEMENT FIX

**Purpose:** Write the minimal fix that makes the failing test pass.

**Actions:**
1. Write the MINIMAL code change that fixes the root cause
   - Fix the CAUSE, not the SYMPTOM
   - Change as few files as possible
   - Don't refactor, don't add features, don't "improve while I'm here"
2. Run the bug-reproducing test → MUST PASS
3. Run ALL project tests → check for regressions
   - `npm test` / `pytest` / `cargo test` / project-specific test command
   - ALL tests must pass, not just the new one
4. If regressions found:
   - The fix is wrong or incomplete
   - Analyze which tests broke and why
   - Refine the fix (don't revert the test — the test is correct)
   - Max 3 refinement iterations → if still failing, the root cause analysis may be wrong (back to Step 3)

**Exit condition:** Bug-reproducing test passes AND all existing tests pass.

---

### Step 7: VERIFY AND COMMIT

**Purpose:** Final verification and clean commit.

**Actions:**
1. Run ALL tests one final time → all PASS
2. Run linter (if configured) → clean
3. Run build (if applicable) → success
4. Stage specific files (NEVER `git add -A` or `git add .`)
5. Commit with descriptive message:
   ```
   fix: [what was fixed] — [root cause]
   ```
   - The commit message MUST include the root cause
   - Example: `fix: dashboard blank page — API response format changed from array to {data: [...]}`
   - **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, `Anthropic`, or any AI tool attribution
6. If fixing during a phase:
   - Update the phase checklist: mark the relevant item `[x]`
   - If a new item was needed (bug not in original checklist): add it as `[x]` with `[BUG]` prefix
   - Trigger `_internal/checkpoint` if appropriate
7. Clean up any debug logs or temporary code added during investigation

**Exit condition:** Clean commit with root cause documented, all tests green.

---

## STUCK PROTOCOL

When all hypotheses are rejected after 3 cycles, STOP and communicate clearly:

```
"I've tested [N] hypotheses and none explain the bug:

1. [hypothesis] — REJECTED because [evidence]
2. [hypothesis] — REJECTED because [evidence]
3. [hypothesis] — REJECTED because [evidence]

I need more information to continue. Could you:
a) [specific question about the environment or context]
b) [specific log or output to check]
c) [specific scenario to test manually]"
```

**Rules for the stuck protocol:**
- NEVER silently give up — always explain what was tried
- NEVER make a random change hoping it works — that's guessing
- Present what was learned (rejected hypotheses ARE useful information)
- Ask SPECIFIC questions, not vague "can you help?"

---

## KEY PRINCIPLES

```
1. NEVER GUESS — always test your hypothesis before implementing a fix
2. EVIDENCE FIRST — read logs, errors, stack traces before touching code
3. ONE FIX AT A TIME — don't fix multiple things simultaneously
4. REPRODUCE FIRST — if you can't reproduce it, you can't verify the fix
5. TEST THE FIX — the failing test that reproduces the bug IS the proof
6. CHECK REGRESSIONS — the fix must not break anything else
7. ROOT CAUSE — fix the cause, not the symptom
```

---

## ANTI-PATTERNS (things this skill prevents)

| Anti-pattern | Why it's wrong | What to do instead |
|-------------|----------------|-------------------|
| "Let me try changing this and see" | Guessing, not debugging | Form a hypothesis first (Step 3) |
| "The error says X so let me fix X" | X might be a symptom, not the cause | Gather evidence, find root cause (Step 2-3) |
| "It works now" without tests | No proof, regression risk | Write a test that proves the fix (Step 5) |
| Fixing 5 things at once | Can't tell which fix worked | Isolate and fix one at a time (Step 6) |
| Ignoring other failing tests | Regressions shipped | Run ALL tests after every fix (Step 6) |
| "I don't know why it works now" | Root cause unknown, will recur | Find and document the root cause (Step 3-4) |

---

## PLUGIN DETECTION

During debugging, `_internal/detect` may suggest tools:

| Context | Potential tool | Purpose |
|---------|---------------|---------|
| Web app debugging | Chrome DevTools MCP | Network, console, performance inspection |
| Database issues | Database MCP | Query inspection, data verification |
| API debugging | HTTP client / Postman MCP | Request/response inspection |
| Complex state issues | Debugger integration | Step-through debugging |

Detection is NON-BLOCKING — debugging always continues regardless of plugin availability.

---

## INVARIANTS

1. **Never implement a fix without first writing a test that reproduces the bug**
2. **Never claim "fixed" without running ALL tests**
3. **Always document the root cause in the commit message**
4. **Never skip regression checking**
5. **If stuck after 3 hypothesis cycles: STOP, explain to user, ask for help**
6. **Never add debug code to production without cleanup** — remove all temporary logs/assertions before commit
7. **Stage specific files** — never `git add -A` or `git add .`
8. **No AI attribution in commits or code** — no Co-Authored-By, Claude, Opus, Anthropic

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Bug found during `/blox:build` TDD cycle | `/blox:fix` | When a persistent failure isn't a simple test fix |
| `/blox:check` finds regressions (S4) | `/blox:fix` | After severity assessment identifies broken tests |
| Fix complete during a phase | `_internal/checkpoint` | After commit, if checkpoint conditions are met |
| Bug requires architectural change | `/blox:plan` | If fix scope exceeds a single commit |
| Fix reveals tech debt | TECH_DEBT.md | Log it, don't fix everything now (Pattern 6: Momentum Protection) |
| Fix reveals missing Golden Principle | GOLDEN_PRINCIPLES.md | Add the principle to prevent recurrence (Pattern 4: Fix Environment Not Agent) |

---

## VERIFICATION

### Success Indicators
- Bug reproduced with a test (Step 5 completed before Step 6)
- Hypothesis formed and tested with evidence (Steps 3-4 documented)
- Fix implemented with TDD: failing test → minimal fix → all green
- ALL tests pass after the fix (new + existing — no regressions)
- Root cause documented in the commit message
- No debug code or temporary logs left in the codebase
- Commit is small and focused (only the fix, nothing else)
- No AI attribution in commits or generated code

### Failure Indicators (STOP and fix!)
- Fix attempted without reproduction (Step 1 skipped)
- No test written for the bug (Step 5 skipped)
- Guessing instead of testing hypotheses ("let me try this")
- Regressions introduced (other tests now failing)
- Root cause unknown ("it just works now")
- Multiple unrelated changes in one commit
- Debug logs left in committed code
- `git add -A` or `git add .` used instead of specific file staging
- AI attribution found in commits or code

---

## EXAMPLES

### Example 1: Test failing after code change

```
User: "/blox:fix — the login test is failing"

Step 1: REPRODUCE
  Run: npm test -- --grep "login"
  → FAIL: "Expected 200, got 401"
  Reproducible: yes

Step 2: GATHER EVIDENCE
  Error: test/auth.test.ts:42 — Expected status 200, received 401
  git log -5 → commit abc123 "feat: update auth middleware to validate token format"
  git diff abc123~1 → middleware now checks for "Bearer v2:" prefix
  Test fixture uses "Bearer eyJhb..." (old format)

Step 3: FORM HYPOTHESIS
  1. [MOST LIKELY] "The new middleware rejects tokens without the v2 prefix,
     but the test fixture uses the old format"
     - Test: check the test fixture's token format against middleware validation

Step 4: TEST HYPOTHESIS
  Read test fixture → token starts with "Bearer eyJhb..." (old format)
  Read middleware → rejects tokens without "Bearer v2:" prefix
  → CONFIRMED: format mismatch

Step 5: WRITE FAILING TEST
  test("auth accepts both old and new token formats", () => {
    // Old format (backward compatibility)
    expect(validateToken("Bearer eyJhb...")).toBe(true);
    // New format
    expect(validateToken("Bearer v2:eyJhb...")).toBe(true);
  });
  → Run: FAIL ✓ (old format rejected)

Step 6: IMPLEMENT FIX
  Update middleware: accept both "Bearer " and "Bearer v2:" prefixes
  → Bug test: PASS ✓
  → All tests: 48/48 PASS ✓

Step 7: VERIFY AND COMMIT
  npm test → 48/48 PASS
  npm run lint → clean
  git add src/middleware/auth.ts test/auth.test.ts
  git commit -m "fix: auth middleware accepts both token formats — v2 prefix
  validation was too strict, rejecting valid old-format tokens during migration"
```

### Example 2: Runtime error — blank page

```
User: "/blox:fix — the dashboard shows a blank page"

Step 1: REPRODUCE
  Open dashboard URL → blank page
  Browser console → TypeError: Cannot read property 'map' of undefined
  Reproducible: yes (every page load)

Step 2: GATHER EVIDENCE
  Error: src/components/Dashboard.tsx:28 — data.map is not a function
  Stack trace: Dashboard → useEffect → fetchData → render
  git log -5 → commit def456 "feat: wrap API responses in {data: [...]} format"
  git diff def456~1 → API now returns {data: [...]} instead of [...]
  Dashboard code: const items = await fetch("/api/items"); items.map(...)

Step 3: FORM HYPOTHESIS
  1. [MOST LIKELY] "API returns {data: [...]} object instead of [...] array,
     but Dashboard.tsx expects a plain array"
     - Test: inspect actual API response format

Step 4: TEST HYPOTHESIS
  curl /api/items → {"data": [{"id": 1, ...}]}
  Dashboard code expects: [...] (plain array)
  → CONFIRMED: response format mismatch

Step 5: WRITE FAILING TEST
  test("Dashboard handles wrapped API response", () => {
    const mockResponse = { data: [{ id: 1, name: "Item 1" }] };
    render(<Dashboard data={mockResponse} />);
    expect(screen.getByText("Item 1")).toBeInTheDocument();
  });
  → Run: FAIL ✓ (TypeError: data.map is not a function)

Step 6: IMPLEMENT FIX
  Update Dashboard.tsx: unwrap .data from API response
  const response = await fetch("/api/items");
  const { data: items } = await response.json();
  → Bug test: PASS ✓
  → All tests: 92/92 PASS ✓

Step 7: VERIFY AND COMMIT
  npm test → 92/92 PASS
  npm run lint → clean
  npm run build → success
  git add src/components/Dashboard.tsx test/Dashboard.test.tsx
  git commit -m "fix: Dashboard unwraps {data} from API response —
  API format changed from array to {data: array} in def456"
```

### Example 3: Stuck — all hypotheses rejected

```
User: "/blox:fix — file uploads fail silently"

Step 1: REPRODUCE
  Upload a file → no error message, but file doesn't appear
  Reproducible: yes

Step 2: GATHER EVIDENCE (Cycle 1)
  No error in browser console
  No error in server logs
  git log -10 → no recent upload-related changes
  Network tab → POST /api/upload returns 200
  But file not in storage bucket

Step 3: FORM HYPOTHESIS (Cycle 1)
  1. "Storage bucket permissions changed"
  2. "Upload path misconfigured"
  3. "File saved but listing endpoint broken"

Step 4: TEST HYPOTHESIS (Cycle 1)
  1. Bucket permissions → checked, write access OK → REJECTED
  2. Upload path → checked config, path correct → REJECTED
  3. Listing endpoint → manual bucket check, file not there → REJECTED

Step 2: GATHER EVIDENCE (Cycle 2)
  Deeper inspection: API returns 200 but...
  Read upload handler code → try/catch swallows error, returns 200 always
  Add temporary log in catch block → re-test
  Error: "ENOSPC: no space left on device"

Step 3: FORM HYPOTHESIS (Cycle 2)
  1. "Server disk is full, upload fails silently because error is caught"

Step 4: TEST HYPOTHESIS (Cycle 2)
  df -h → /tmp is 100% full
  → CONFIRMED: disk full + silent error swallowing

Step 5-7: Write test, fix error handling (throw instead of swallow),
  clean up /tmp, commit with root cause documented.
```

### Example 4: Stuck after 3 cycles — escalate

```
Step 1-4: Three full cycles completed, all hypotheses rejected

STOP — Escalate to user:

"I've tested 8 hypotheses across 3 investigation cycles and none
explain why the WebSocket connection drops after exactly 30 seconds:

Cycle 1:
1. Server timeout configuration → REJECTED (set to 120s)
2. Client heartbeat interval → REJECTED (sending every 15s)
3. Proxy timeout → REJECTED (nginx proxy_read_timeout is 300s)

Cycle 2:
4. Load balancer idle timeout → REJECTED (checked AWS ALB: 60s)
5. Connection pool exhaustion → REJECTED (pool at 20% capacity)

Cycle 3:
6. SSL/TLS renegotiation → REJECTED (no renegotiation in logs)
7. Memory leak causing GC pause → REJECTED (heap stable)
8. Firewall rule → REJECTED (no drops in firewall logs)

I need more information to continue. Could you:
a) Check if this happens on all network paths (VPN vs direct)
b) Run a packet capture during the disconnect: tcpdump -i eth0 port 443
c) Tell me if the 30-second timing is exact or approximate"
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Pattern 2 (Decision Waterfall), Pattern 4 (Fix Environment Not Agent)
- `skills/_internal/checkpoint/SKILL.md` — Checkpoint protocol (if fixing during a phase)
- `skills/_internal/detect/SKILL.md` — Plugin detection for debugging tools
- @superpowers:test-driven-development — TDD methodology reference
