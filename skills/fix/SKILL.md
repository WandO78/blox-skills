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

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

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

## SUPERPOWERS INTEGRATION

This skill debugs issues. It uses superpowers for systematic methodology:

- **Root cause analysis:** Follow `superpowers:systematic-debugging` 4-phase process: (1) Root Cause Investigation — read errors, reproduce, check changes; (2) Pattern Analysis — find working examples, compare; (3) Hypothesis Testing — form theory, test minimally; (4) Implementation — create failing test, fix, verify.
- **TDD for fixes:** Phase 4 uses `superpowers:test-driven-development` — write a failing test that reproduces the bug BEFORE implementing the fix.
- **What blox adds on top:** Checkpoint context (resume debugging across sessions via _internal/checkpoint), phase checklist integration (mark bug fix items as [x]).

**Rule:** Superpowers provides the debugging discipline (never guess, always find root cause). blox provides continuity (checkpoints, context chain, phase tracking).

---

## SKILL LOGIC

> **The debugging methodology lives in superpowers.** blox does NOT re-implement it —
> it defers to `superpowers:systematic-debugging`, then wraps the fix in blox continuity
> (checklist marks, checkpoints, root-cause commit, debt/principle logging).

### Methodology: DEFER to superpowers

**Follow `superpowers:systematic-debugging` for the root-cause investigation** (its 4-phase
process: Root Cause Investigation → Pattern Analysis → Hypothesis Testing → Implementation).
The Implementation phase uses `superpowers:test-driven-development` — write a failing test
that reproduces the bug BEFORE fixing.

Core discipline (enforced by superpowers): **never guess, work only from evidence, test every
hypothesis, fix the root cause not the symptom, never claim "fixed" without running all tests.**

### SLIM FALLBACK (graceful degradation)

If superpowers isn't installed, the short version:
1. **REPRODUCE** — find a reliable trigger; write down the steps. Can't reproduce → ask the user.
2. **EVIDENCE** — read errors/stack traces/logs; check `git log`/`git diff` for recent changes. No guessing.
3. **HYPOTHESIS → TEST** — form 1-3 specific, testable theories; test the likeliest first. CONFIRMED → step 4. ALL REJECTED → gather more evidence (max 3 cycles, then STOP and escalate to the user with what you tried).
4. **FAILING TEST → FIX → VERIFY** — write a test that reproduces the bug (MUST fail), write the minimal fix (test passes), run ALL tests (no regressions), remove debug code.

(Install superpowers for the full methodology.)

---

## BLOX OVERLAY — Verify, commit, and continuity

> This is the genuine blox value layered ON TOP of the superpowers methodology above.
> Apply it once a hypothesis is confirmed and the fix is implemented + verified.

### Verify and commit (root cause documented)

1. Run ALL tests one final time → all PASS; linter clean; build succeeds (if applicable)
2. Confirm all debug logs / temporary code added during investigation are removed
3. Stage specific files (NEVER `git add -A` or `git add .`)
4. Commit with the root cause in the message:
   ```
   fix: [what was fixed] — [root cause]
   ```
   - Example: `fix: dashboard blank page — API response format changed from array to {data: [...]}`
   - **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, `Anthropic`, or any AI tool attribution

### Phase continuity (if fixing during a phase)

- **Checklist marking:** mark the relevant item `[x]`. If the bug was NOT in the original
  checklist, add it as `[x]` with a `[BUG]` prefix.
- **Checkpoint trigger:** trigger `_internal/checkpoint` if checkpoint conditions are met (after commit).
- **TECH_DEBT logging:** if the fix reveals tech debt, log it to `TECH_DEBT.md` — don't fix
  everything now (Pattern 6: Momentum Protection).
- **GOLDEN_PRINCIPLES logging:** if the fix reveals a missing invariant, add the principle to
  `GOLDEN_PRINCIPLES.md` to prevent recurrence (Pattern 4: Fix Environment Not Agent).
- **Handoff:** if the fix scope exceeds a single commit (architectural change) → `/blox:plan`.
  Bug surfaced mid-build → return to `/blox:build`.

**Worked examples:** see `references/examples.md` (test-failure, blank-page, stuck/loop-back, escalate).

---

## TOOL SUGGESTIONS

During debugging, if a tool would help and is missing, inform the user in one line and continue:

| Context | Potential tool | Purpose |
|---------|---------------|---------|
| Web app debugging | Chrome DevTools MCP | Network, console, performance inspection |
| Database issues | Database MCP | Query inspection, data verification |
| API debugging | HTTP client / Postman MCP | Request/response inspection |
| Complex state issues | Debugger integration | Step-through debugging |

This is NON-BLOCKING — debugging always continues regardless of tool availability.

---

## INVARIANTS

1. **Never implement a fix without first writing a test that reproduces the bug**
2. **Never claim "fixed" without running ALL tests**
3. **Always document the root cause in the commit message**
4. **Never skip regression checking**
5. **If stuck after 3 hypothesis cycles: STOP, explain to user, ask for help**
6. **Never add debug code to production without cleanup** — remove all temporary logs/assertions before commit
7. **Stage specific files (if git active)** — never `git add -A` or `git add .`
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

Worked debugging walkthroughs (test-failure, blank-page, stuck/loop-back, escalate) have moved to
`references/examples.md` for progressive disclosure. They illustrate how the blox overlay wraps the
`superpowers:systematic-debugging` methodology.

---

## REFERENCES

- `references/examples.md` — Worked debugging examples (progressive disclosure)
- `references/patterns/knowledge-patterns.md` — Pattern 2 (Decision Waterfall), Pattern 4 (Fix Environment Not Agent)
- `skills/_internal/checkpoint/SKILL.md` — Checkpoint protocol (if fixing during a phase)
- @superpowers:systematic-debugging — debugging methodology (primary)
- @superpowers:test-driven-development — TDD methodology reference
