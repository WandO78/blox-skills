---
name: wando-dispatch
description: "Coordinate parallel agent work using Leader-Worker pattern: assign tasks from Parallel Work Plan, manage worktree isolation, enforce shared file protection, orchestrate merge order, run post-merge tests."
version: "1.0.0"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion]
---

# /wando:dispatch

> **Purpose:** Phase-aware Leader-Worker coordination for parallel agent work.
> Reads the Parallel Work Plan from the phase file, creates isolated worktrees,
> assigns tasks with output contracts, enforces shared file protection,
> orchestrates merge order, and runs post-merge verification.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-dispatch
category: advanced
complements: [wando-plan, wando-checkpoint, wando-review]

### Triggers — when the agent invokes automatically
trigger_keywords: [dispatch, parallel, worker, multi-agent, concurrent, parhuzamos]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when a phase file contains a Parallel Work Plan section (TEMPLATES.md Section 1.2).
  Coordinates multiple agents working on independent sections in isolated worktrees.
  Do NOT use for phases with < 20 items or strongly interdependent sections.
  The USER decides whether to dispatch — never auto-invoke.
auto_invoke: false
priority: optional

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Phase has Parallel Work Plan section | 2+ independent sections with `{Parallel Group: N}` | No — user decides |
| Large phase, independent sections | Section 2 and 3 can be parallelized | No — user decides |
| Phase > 20 checklist items with clear split | CRUD entities, multi-module build | No — user decides |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Phase < 20 items | Single agent is faster, dispatch overhead not worth it | Sequential execution |
| Strongly interdependent sections | Merge conflict risk too high | Sequential execution |
| Unknown domain | Explore first, THEN decide split | Sequential → dispatch later |
| User doesn't request it | Unnecessary complexity | Sequential execution |
| Context window fits everything (Opus 200k) | Single agent can hold it all | Sequential, cheaper |

---

## SKILL LOGIC

> **Leader-Worker pattern — phase-aware worktree isolation + merge ordering.**
> The Leader owns the phase file and shared files. Workers operate in isolated
> worktrees, each with a clear scope, file boundaries, and exit criteria.

### Step 1: Validate Dispatch Preconditions

Before dispatching, verify ALL of these:

```
PRECONDITIONS — ALL must be TRUE:
□ Phase file exists and has a Parallel Work Plan section
□ Prerequisite sections are DONE (e.g., Section 1 "Shared Schemas" complete)
□ Phase has >= 20 checklist items
□ At least 2 sections have the same {Parallel Group: N} annotation
□ Git repo is clean (no uncommitted changes)
□ Tests pass on current state (baseline)
```

If ANY precondition fails → STOP. Tell the user why dispatch is not possible.
Suggest sequential execution as alternative.

### Step 2: Parse Parallel Work Plan

Read the phase file's `## Parallel Work Plan` section. Extract:

```
FROM THE PLAN:
1. Parallel Strategy: [Section-parallel | Entity-parallel | Role-parallel]
2. Prerequisite: which sections must be DONE first
3. Worker table: worker name, branch name, scope, files, exit criteria
4. Shared files list (LEADER-ONLY)
5. Merge order (numbered sequence)
```

**Three parallel strategies:**

| Strategy | How it splits | Best for | Merge risk |
|----------|---------------|----------|------------|
| **Section-parallel** | Phase SECTIONS become worker tasks | Different file directories (API vs UI) | LOW — separate dirs |
| **Entity-parallel** | Phase ENTITIES split across workers | CRUD entities, repeated patterns | MEDIUM — shared barrel exports |
| **Role-parallel** | Pipeline: coder → tester → reviewer | Quality focus, not speed | LOW — sequential handoff |

**Default recommendation:** Section-parallel (lowest merge risk, clearest boundaries).

### Step 3: Create Worktrees

For each worker in the plan:

```bash
# Create isolated worktree with dedicated branch
git worktree add .claude/worktrees/phaseXX-worker-NAME -b phaseXX-worker-NAME

# Example for 2 workers:
git worktree add .claude/worktrees/phase05-worker-a -b phase05-worker-a
git worktree add .claude/worktrees/phase05-worker-b -b phase05-worker-b
```

**Worktree rules:**
- Branch naming: `phaseXX-worker-NAME` (e.g., `phase05-worker-a`)
- Location: `.claude/worktrees/` directory (standard Claude Code location)
- Each worker gets its OWN worktree — never share
- Leader stays on the main branch

### Step 4: Define Worker Tasks

For each worker, create a **Task Definition** with ALL of these fields:

```
WORKER TASK DEFINITION:
┌──────────────────────────────────────────────────┐
│ Worker:       [worker-a]                          │
│ Branch:       [phase05-worker-a]                  │
│ Worktree:     [.claude/worktrees/phase05-worker-a]│
│                                                    │
│ Scope:        [Section 2: API routes]              │
│ Checklist:    [Items 2.1 — 2.8]                   │
│                                                    │
│ ALLOWED files (ONLY these):                        │
│   - backend/routes/*                               │
│   - backend/services/*                             │
│   - tests/routes/*                                 │
│                                                    │
│ FORBIDDEN files (NEVER touch):                     │
│   - Phase file (LEADER-ONLY)                       │
│   - Shared files (see LEADER-ONLY list)            │
│   - Other worker's files                           │
│                                                    │
│ READ-ONLY inputs:                                  │
│   - shared/schemas/* (from completed Section 1)    │
│                                                    │
│ Skills to use:                                     │
│   - /test-driven-development                       │
│   - [domain-specific skills]                       │
│                                                    │
│ Exit criteria:                                     │
│   - All tests PASS in worktree                     │
│   - [specific criteria from phase plan]            │
│                                                    │
│ Output Contract (MANDATORY):                       │
│   50-token summary in this EXACT format:           │
│   "Task [NAME] DONE. [N] commits. Tests: [PASS/   │
│    FAIL]. Files changed: [list]. Issues: [none/    │
│    description]. Score: [N/10]."                   │
└──────────────────────────────────────────────────┘
```

### Step 5: Launch Workers

Spawn worker agents using the Agent tool:

```
For EACH worker:
1. Use Agent tool with:
   - subagent_type: "general-purpose"
   - isolation: "worktree" (if supported) OR instruct worker to cd to worktree
   - prompt: Full Task Definition from Step 4
   - Include: FORBIDDEN files list explicitly
   - Include: Output Contract format explicitly

2. Workers run IN PARALLEL (same {Parallel Group})
   - Launch all workers in the same group simultaneously
   - Do NOT wait for one to finish before starting another
```

**Worker agent instructions template:**

```
You are Worker [NAME] for Phase [XX].
Your worktree: [path]
Your branch: [branch]

TASK: [scope description]
CHECKLIST ITEMS: [item range]

ALLOWED files (ONLY modify these):
[file patterns]

FORBIDDEN (NEVER modify — violation = IMMEDIATE STOP):
- Phase file: [path]
- Shared files: [list from LEADER-ONLY]
- Other worker files: [patterns]

READ-ONLY inputs:
[file patterns from completed sections]

EXIT CRITERIA:
[specific test/verification criteria]

WHEN DONE — respond with EXACTLY this format:
"Task [NAME] DONE. [N] commits. Tests: [PASS/FAIL]. Files changed: [list]. Issues: [none/description]. Score: [N/10]."
```

### Step 6: Monitor & Collect Results

The Leader waits for ALL workers in the current Parallel Group:

```
MONITORING:
- Each worker reports back via Output Contract
- Leader validates: does the summary match expectations?
- If a worker is SILENT for too long → check worktree for progress

RESULT COLLECTION:
For each worker, record:
- Status: DONE / FAIL / PARTIAL
- Output Contract summary
- Number of commits
- Test results
```

### Step 7: Handle Worker Failures

| Situation | Action |
|-----------|--------|
| Worker DONE, tests PASS | Proceed to merge (Step 8) |
| Worker DONE, tests FAIL | Leader reviews failures. Option A: fix in worktree. Option B: new worker to fix. |
| Worker FAIL (crash/error) | Other workers' work is SAFE. Restart failed worker OR leader completes manually. |
| Worker modifies FORBIDDEN file | VIOLATION. Discard worker branch. Re-dispatch with stricter instructions. |
| Worker too slow (others done) | Proceed with partial merge. Slow worker continues independently. |

**Critical:** A single worker failure does NOT invalidate other workers' work.
Each worktree is isolated — failures are contained.

### Step 8: Merge Sequence

Execute the merge in the EXACT order specified in the Parallel Work Plan:

```
MERGE PROTOCOL (sequential, NOT parallel):

For each worker in merge order:
  1. Switch to main branch
  2. git merge phaseXX-worker-NAME --no-ff
     (--no-ff: preserve merge commit for traceability)
  3. If CONFLICT:
     a. Leader resolves manually (typically barrel exports, configs)
     b. Commit conflict resolution
     c. Document: which files conflicted, how resolved
  4. Run WORKER'S test suite (just this worker's tests)
     - If FAIL → fix before proceeding to next merge
  5. Proceed to next worker

After ALL merges:
  6. Run FULL test suite (entire project)
     - This catches integration issues between workers
  7. If FULL tests FAIL:
     a. git bisect to identify which merge broke it
     b. Fix the integration issue
     c. Re-run full tests until PASS
```

**Merge order matters.** The plan specifies which worker merges first because:
- Earlier merges are cleaner (no prior merge residue)
- Later merges may need conflict resolution with earlier changes
- The most "foundational" worker should merge first

### Step 9: Post-merge Verification & Cleanup

After all merges pass:

```
POST-MERGE CHECKLIST:
□ Full test suite PASS (MANDATORY — no exceptions)
□ No orphaned files from worktrees
□ Phase file updated: mark parallel sections as [x] DONE
□ Progress Log entry: "Parallel dispatch: [N] workers, [strategy], merged successfully"
□ Checkpoint: invoke /wando:checkpoint Level 2
□ Worktree cleanup:
  git worktree remove .claude/worktrees/phaseXX-worker-a
  git worktree remove .claude/worktrees/phaseXX-worker-b
  git branch -d phaseXX-worker-a
  git branch -d phaseXX-worker-b
```

---

## PARALLEL INVARIANTS

> **These are NON-NEGOTIABLE. Violating ANY of them leads to catastrophe.**

### INV-1: Phase file is LEADER-ONLY
The Leader is the EXCLUSIVE owner of the phase file. No worker may read or write it.
**Why:** Two agents writing the same file simultaneously = corrupt checklist, lost progress.

### INV-2: Workers are ISOLATED
Worker-A cannot read, write, or reference Worker-B's files (and vice versa).
**Why:** Unknown file modification = hidden dependency = merge hell.

### INV-3: Shared files are LEADER-ONLY
Barrel exports (`index.ts`), routing configs, `package.json`, database migrations
— ONLY the Leader modifies these, AFTER merge.
**Why:** These are the #1 source of merge conflicts.

### INV-4: Every worker tests its own work
Worker DONE = "all MY tests PASS" (not just "I wrote code").
**Why:** Merging untested code = the other worker's code breaks too.

### INV-5: Post-merge FULL test suite is MANDATORY
After ALL workers merge, the Leader runs the FULL test suite. Not optional.
**Why:** Two individual PASS results don't guarantee combined PASS. Integration matters.

### INV-6: Worker Output Contract is MANDATORY
Every worker returns a 50-token summary in the defined format.
**Why:** Without structured output, the Leader can't assess completion objectively.

---

## SKILL INTEGRATIONS

### Built-in orchestration (from dispatching-parallel-agents)

The parallel dispatching logic from the `dispatching-parallel-agents` skill is
BUILT INTO this skill (not referenced). This includes:
- Agent spawning with worktree isolation
- Parallel group assignment from `{Parallel Group: N}` annotations
- Worker output collection and validation

### External skill references

| When this happens... | Call | When |
|---------------------|------|------|
| Worktree creation | `git worktree add` commands | Step 3 — creating worker environments |
| Post-merge checkpoint | `/wando:checkpoint` Level 2 | Step 9 — after all merges pass |
| Quality review of merged code | `/wando:review` THOROUGH | Step 9 — optional, if user requests |
| Worker needs TDD workflow | `/test-driven-development` | In worker task definition |

### Phase system integration

| Phase element | How dispatch uses it |
|---------------|---------------------|
| Parallel Work Plan section | Step 2 parses this for worker definitions |
| `{Parallel Group: N}` annotations | Determines which sections run in parallel |
| Checklist items | Mapped to specific workers (scope) |
| Progress Log | Leader writes dispatch events |
| Phase Memory | Records parallel work outcomes |
| Exit Criteria | Post-merge verification includes these |

---

## VERIFICATION

### Pre-dispatch checks
```bash
# Phase file has Parallel Work Plan
grep -q "## Parallel Work Plan" PHASE_FILE && echo "PASS" || echo "FAIL: No Parallel Work Plan"

# Git is clean
git status --porcelain | wc -l | grep "^0$" && echo "PASS" || echo "FAIL: Uncommitted changes"

# Baseline tests pass
[PROJECT_TEST_COMMAND] && echo "PASS" || echo "FAIL: Baseline tests broken"
```

### Post-merge checks
```bash
# Full test suite
[PROJECT_TEST_COMMAND] && echo "PASS" || echo "FAIL: Post-merge tests broken"

# No orphaned worktrees
git worktree list | grep -c "phaseXX-worker" | grep "^0$" && echo "PASS" || echo "FAIL: Orphaned worktrees"

# All parallel sections marked done
grep -c "\[ \]" PHASE_FILE_PARALLEL_SECTIONS | grep "^0$" && echo "PASS" || echo "FAIL: Unchecked items"
```

### Success indicators
- Every worker operated in its own worktree
- No worker modified LEADER-ONLY files
- Merge order followed as specified
- Post-merge FULL test suite PASS
- All Worker Output Contracts received and valid
- Worktrees cleaned up

### Failure indicators (STOP and fix!)
- Worker modified shared file → VIOLATION: discard branch, re-dispatch
- Post-merge tests FAIL → `git bisect` to find breaking merge
- No worktree isolation → ABORT: workers on same branch
- Missing Worker Output Contract → worker may not be done
- Merge conflicts in non-shared files → worker scope overlap (plan error)

---

## EXAMPLES

### Example 1: Section-parallel — CRUD Phase (Happy Path)

**Situation:** Phase 05 has 40 items. Section 1 (Schemas, 10 items) is DONE.
Section 2 (API routes, 15 items) and Section 3 (Admin screens, 15 items) are independent.

**Phase file Parallel Work Plan:**
```markdown
## Parallel Work Plan

### Parallel Strategy: Section-parallel
### Prerequisite: Section 1 (Schemas) DONE

| Worker | Branch | Scope | Files | Exit Criteria |
|--------|--------|-------|-------|---------------|
| worker-a | phase05-worker-a | Section 2: API routes | backend/routes/*, tests/routes/* | All route tests PASS |
| worker-b | phase05-worker-b | Section 3: Admin screens | frontend/pages/admin/*, tests/admin/* | All screen tests PASS |

### Shared files (LEADER-ONLY)
- shared/schemas/index.ts (barrel export)
- frontend/app/routes.tsx (routing config)
- backend/app.ts (route registration)

### Merge order
1. worker-a → main (conflict-free, backend only)
2. worker-b → main (needs barrel + routing update)
3. Full test suite
4. Checkpoint C
```

**Dispatch execution:**

Step 1: Preconditions — all PASS (Section 1 DONE, git clean, tests pass).

Step 2: Parse plan — Strategy: Section-parallel, 2 workers, 3 shared files.

Step 3: Create worktrees:
```bash
git worktree add .claude/worktrees/phase05-worker-a -b phase05-worker-a
git worktree add .claude/worktrees/phase05-worker-b -b phase05-worker-b
```

Step 4: Task definitions created with ALLOWED/FORBIDDEN file lists.

Step 5: Both workers launched in parallel (same Parallel Group 2).

Step 6: Results collected:
- Worker-A: "Task worker-a DONE. 12 commits. Tests: PASS. Files: backend/routes/*, tests/routes/*. Issues: none. Score: 9/10."
- Worker-B: "Task worker-b DONE. 10 commits. Tests: PASS. Files: frontend/pages/admin/*, tests/admin/*. Issues: none. Score: 8/10."

Step 7: No failures.

Step 8: Merge:
1. `git merge phase05-worker-a --no-ff` → clean
2. `git merge phase05-worker-b --no-ff` → conflict in `shared/schemas/index.ts`
   → Leader resolves: adds new exports to barrel file
3. Full test suite → PASS

Step 9: Cleanup, checkpoint, phase file updated.

**Result:** 40 items completed in ~60% of sequential time. Zero integration issues.

---

### Example 2: Worker Failure — Recovery

**Situation:** Same setup as Example 1, but Worker-A crashes mid-work.

**What happens:**

Step 6: Worker-B reports DONE. Worker-A is silent.

Step 7: Leader checks Worker-A's worktree:
```bash
cd .claude/worktrees/phase05-worker-a
git log --oneline -5  # See what was committed
[TEST_COMMAND]         # Check what passes
```

**Decision matrix:**

| Worker-A state | Leader action |
|---------------|--------------|
| 80%+ done, tests pass for completed items | Leader completes remaining items manually |
| < 50% done | Re-dispatch Worker-A with same task |
| Code is broken | Discard branch, re-dispatch fresh |

Worker-B's work is COMPLETELY UNAFFECTED. This is the power of worktree isolation.

**Leader completes Worker-A manually:**
```bash
cd .claude/worktrees/phase05-worker-a
# Complete remaining items 2.6, 2.7, 2.8
# Run tests
# Commit
```

Then proceed to merge (Step 8) as normal.

---

### Example 3: Merge Conflict — Shared File

**Situation:** Despite LEADER-ONLY rules, the merge reveals a conflict.

**Diagnosis:**
```bash
git merge phase05-worker-b --no-ff
# CONFLICT in frontend/app/routes.tsx
```

**This means EITHER:**
1. The shared file list was incomplete (routes.tsx should have been LEADER-ONLY) → add to list for next time
2. A worker violated the FORBIDDEN rule → check worker's commits

**Resolution:**
```bash
# Leader resolves conflict manually
git diff --name-only --diff-filter=U  # List conflicted files
# Edit each conflicted file
# Choose correct version / combine changes
git add .
git commit -m "Resolve merge conflict: combine worker-a and worker-b route changes"
```

**NEVER** add `Co-Authored-By`, `Claude`, `Opus`, or any AI tool attribution to commit messages or code.

**Post-resolution:** Full test suite to verify the resolution didn't break anything.

**Phase Memory note:** "Merge conflict in routes.tsx — add to LEADER-ONLY list for future phases."

---

### Example 4: When NOT to Dispatch

**Situation:** Phase 09 has 15 items, all tightly coupled (migration script depends on schema which depends on seed data).

**Step 1: Preconditions check:**
```
□ Phase has Parallel Work Plan? → NO (plan says sequential)
□ Phase >= 20 items? → NO (15 items)
□ At least 2 independent Parallel Groups? → NO (all coupled)
```

**Result:** Preconditions FAIL. Dispatch NOT invoked.

**Leader tells user:**
"This phase has 15 tightly coupled items — sequential execution is faster and safer.
Dispatch adds overhead that isn't justified for phases under 20 items."
