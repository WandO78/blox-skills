---
name: wando-plan
description: "Generate structured phase files with hierarchical checklists, checkpoints, exit criteria, and auto-discovered skills. Use when planning a new feature, refactor, or multi-step development task."
version: "2.0.0"
user-invocable: true
argument-hint: "[feature description or phase name]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, "Bash(plannotator:*)"]
---

## Current Project State (auto-detected)

- Project identity: !`head -20 CLAUDE.md 2>/dev/null`
- Zone/status: !`grep -i "zone\|status\|phase" START_HERE.md 2>/dev/null | head -10`
- Existing phases: !`ls plans/PHASE_*.md 2>/dev/null`
- Completed: !`ls completed/PHASE_*.md 2>/dev/null`

## Phase template (reference)

!`cat ${CLAUDE_SKILL_DIR}/../wando-references/PHASE_TEMPLATE.md 2>/dev/null || cat ~/.claude/skills/wando-references/PHASE_TEMPLATE.md 2>/dev/null`

# /wando:plan

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-plan
category: plan
complements: [wando-checkpoint, wando-init]

### Triggers — when the agent invokes automatically
trigger_keywords: [plan, phase, design, feature, sprint, milestone, roadmap, planning]
trigger_files: [START_HERE.md, CONTEXT_CHAIN.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when a new development phase needs planning: new feature, refactor,
  migration, or any multi-step task. Also called by /wando:init in Stage 4.
  Auto-discovers installed skills and maps them to the phase's Skills & Tools table.
  Do NOT use for simple, single-step tasks that don't need a phase file.
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| New feature planning | "Plan the dashboard feature" | No — user invokes |
| `/wando:init` Stage 4 | Init pipeline phase generation step | Yes — init calls it |
| New phase needed | "We need a new phase for the refactor" | No — user invokes |
| Large task breakdown | "This task is too big, break it into phases" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Simple 1-2 step task | Too much overhead | Direct implementation |
| Active phase file exists | Don't need new phase, continue the existing one | Resumption Protocol |
| Project setup | Full init needed, not just a phase | `/wando:init` |
| Just want to assess | Assessment only, no planning | `/wando:audit` |

---

## SKILL LOGIC

> **Phase file generation pipeline — 9 steps.**
> The template source of truth is ALWAYS `references/PHASE_TEMPLATE.md` (copy of TEMPLATES.md Section 1.1).
> The skill NEVER contains a hardcoded template copy — it REFERENCES the template.

### Step 1: Repo Knowledge Check (MANDATORY — do NOT skip)

Read these 5 files BEFORE doing anything else. Mark each as checked.

```
- [ ] RK-1: ARCHITECTURE.md — which layers/domains are affected?
- [ ] RK-2: Previous phase memories (completed/PHASE_*.md) — what are the lessons learned?
- [ ] RK-3: GOLDEN_PRINCIPLES.md — which invariants are relevant?
- [ ] RK-4: TECH_DEBT.md — is there related open debt worth addressing now?
- [ ] RK-5: QUALITY_SCORE.md — what is the current quality baseline?
```

If any of these files don't exist yet (e.g., new project): note it and continue.
If called from `/wando:init` Stage 4: some files were JUST created — read them.

### Step 2: Context Discovery + Pattern Application

Gather project context to inform template selection and content:

1. **Project type** (T1-T7) — read from CLAUDE.md or infer from tech stack
2. **Current zone** — read from START_HERE.md phase tracker or CLAUDE.md
3. **Tech stack** — read from CLAUDE.md, package.json/pyproject.toml, or infer
4. **Task scope** — what the user is asking to plan (feature, refactor, migration, etc.)
5. **Existing phases** — read START_HERE.md to understand what has been done

**Apply the 9-section pattern framework.** Each section contains a PATTERN that the
agent APPLIES to the phase — not a question to answer, but a template to fill in.
The patterns are documented in `references/KNOWLEDGE_PATTERNS.md`.

> **KEY PRINCIPLE:** The user does NOT need to know these patterns exist.
> The skill DELIVERS quality results automatically by applying them.

---

#### Section 0: Repo Knowledge Check
*(Done in Step 1 — RK-1 through RK-5)*

#### Section 1: Context Layers
**Pattern:** Build the 6-layer context table for this phase.

For EACH layer, identify what exists and what's missing:

| Layer | What exists | What's missing | Action |
|-------|------------|----------------|--------|
| 1. Code & Schema | [list relevant files/modules] | [gaps] | Read before coding |
| 2. Documentation | [ARCHITECTURE, specs, design docs] | [gaps] | Create if missing |
| 3. Project Memory | [completed phases, GOLDEN_PRINCIPLES] | [gaps] | Read for lessons |
| 4. Tacit Knowledge | [anything NOT yet in the repo] | [gaps] | **WRITE IT DOWN NOW** |
| 5. Runtime Context | [logs, metrics, current state] | [gaps] | Include data-gather tasks |
| 6. External Refs | [API docs, framework docs] | [gaps] | Add to references/ |

**Layer 4 is the most dangerous gap.** If knowledge exists only in someone's head,
a Slack thread, or a Google Doc — create a checklist item to write it into the repo
BEFORE coding begins. "What can't be seen doesn't exist."

#### Section 2: Decision Layers
**Pattern:** For every significant decision point in this feature, generate a 4-layer waterfall table.

| Decision Point | Primary (happy path) | Degraded (constrained) | Fallback (minimum viable) | Error state (never crash) |
|----------------|---------------------|----------------------|--------------------------|--------------------------|
| [e.g., API call] | Normal response | Cached/stale data | User-friendly error msg | Loading skeleton |
| [e.g., auth] | Full access | Read-only mode | Login redirect | Offline notice |
| [e.g., save] | Instant save | Queued background save | Local draft retained | "Unsaved" indicator |

**Rules the agent follows automatically:**
- Every user-facing feature gets at least ONE decision waterfall row
- The "Error state" column is MANDATORY — the system must NEVER crash or show a blank screen
- Internal/backend features: at minimum Primary + Fallback
- The fallback should be the SIMPLEST working version, not a complex alternative
- When the developer doesn't specify: API fail → cached data or friendly error; auth unclear → login redirect; save fail → save locally + retry

#### Section 3: Architecture Invariants
**Pattern:** Apply the layered architecture. Define dependency directions.

Identify the layers in this project and enforce one-way dependencies:

```
Layer N: [name] — depends on: [layers below] — NEVER depends on: [layers above]

Default layers (adapt to project):
  Types/Schemas  → depends on: nothing
  Config         → depends on: Types
  Data/Repo      → depends on: Types, Config
  Service        → depends on: Types, Config, Data
  API/Routes     → depends on: Types, Service
  UI/Frontend    → depends on: Types, API (via Service interface)
```

For EACH layer touched by this phase:
- What is the dependency direction?
- What cross-cutting concerns apply? (auth, logging, error handling → via Providers)
- Can this be checked mechanically? → If YES: add lint rule or structural test
  - Lint error messages MUST contain remediation instructions for the agent
  - Example: "Route handler > 50 lines. Extract logic to services/[domain].ts"

#### Section 4: Agent Readability & Progressive Disclosure
**Pattern:** Apply progressive disclosure to documentation and context.

```
CLAUDE.md (~100 lines) = map, NOT encyclopedia
  └── Points to: ARCHITECTURE.md, docs/, references/
```

Checklist (the agent fills this in automatically):
- [ ] Every piece of knowledge the agent needs IS in the repo
- [ ] If NOT → add a checklist item to create the missing doc/reference
- [ ] CLAUDE.md doesn't exceed ~100 lines (if growing → extract to docs/)
- [ ] External library docs → add LLM-friendly version to references/
- [ ] Complex code → self-documenting naming (no magic numbers, no unclear abbreviations)
- [ ] Worktree needed? (if parallel work, apply Pattern 11)

#### Section 5: Review & Quality Loop
**Pattern:** Apply the automated review pipeline.

Default review flow (agent applies automatically):
```
Code written → Run tests → Run linter → Check Golden Principles
  → ALL PASS? → Mark task complete
  → ANY FAIL? → Fix specific issue → Re-run (max 3 iterations)
  → Still failing? → STOP, explain the blocker, ask for help
```

For this phase, determine:
- Test framework: [project's existing framework, or vitest/pytest default]
- Lint tool: [project's existing linter, or eslint/ruff default]
- Human review needed at: [S2+ severity only, or at specific milestones]
- Agent self-review: ALWAYS (default — never skip)

**Iron Law (built in):** NEVER claim "done" without running verification commands
and confirming the output shows success. Evidence before assertions.

#### Section 6: Provability — Golden Answers
**Pattern:** Define expected input-output pairs BEFORE coding.

Generate a Golden Answers table for this phase:

| # | Input/Scenario | Expected Output | Test Method |
|---|---------------|-----------------|-------------|
| GA-01 | [specific input or scenario] | [exact expected result] | [command/test/check] |
| GA-02 | [edge case] | [expected handling] | [command/test/check] |
| GA-03 | [error case] | [expected error response] | [command/test/check] |

**Minimum counts (agent enforces automatically):**
- Simple phase (< 20 items): 3 Golden Answers
- Standard phase (20-40 items): 5 Golden Answers
- Complex phase (40-50 items): 7 Golden Answers

**Key rule:** Test BEHAVIOR, not implementation. "The output is X" not "the code calls function Y." Functionally equivalent outputs are acceptable.

#### Section 7: Knowledge Lifecycle
**Pattern:** Plan what knowledge this phase will produce.

The agent generates a knowledge plan:
```
This phase will produce:
├── Phase Memory → MANDATORY (even on fail — especially on fail)
├── Golden Principles → [list patterns worth capturing, if any]
│   └── Promotable to lint/CI? → [yes/no for each]
├── Architecture updates → [if layer structure changes]
├── Tech Debt entries → [known compromises]
└── Docs to update/create → [list specific files]
```

**Key rule:** If a Golden Principle is violated AND caught only by manual review
(not by automation), add a checklist item: "Promote GP-X to lint rule / CI check."

#### Section 8: Momentum Protection
**Pattern:** Apply reasonable defaults, never block for perfection.

Defaults the agent applies automatically:
```
| Situation | Default Action | Document Where |
|-----------|---------------|----------------|
| Unclear requirement | Most common pattern, note assumption | Phase file "Assumptions" |
| Missing API spec | Build interface, mock impl | TECH_DEBT.md |
| Two valid approaches | Pick simpler one, note alternative | Phase Memory |
| Edge case unclear | Handle gracefully (no crash), log | TECH_DEBT.md |
| User not responding | Continue with defaults | CONTEXT_CHAIN.md |
```

**Key rules:**
- Checkpoints protect against loss → the agent can move FAST
- "Corrections are cheap, waiting is expensive" — ship at 80%, fix at next checkpoint
- NEVER block for perfection — good enough NOW beats perfect LATER

**Exceptions (DO block for these):**
- Security vulnerabilities → STOP immediately
- Data loss risk → STOP, ensure backup
- Breaking change to production (Z7) → STOP, user decision required

---

Not every section needs a detailed table — use judgment based on task complexity.
For a simple feature, Sections 1-2 might be a single line each.
For a complex Z7 phase, all sections get full tables.

### Step 3: Phase Template Selection

Based on context discovery, select the appropriate template variant:

**Decision tree:**

```
Is this a live/production system + new feature?
├── YES → Z7 EVOLVE template (standard + 4 extra sections)
│         Detection: CLAUDE.md contains "PRODUCTION" / "LIVE" / "DEPLOYED"
│                    AND the task adds new functionality
│
└── NO → Standard template
         │
         Will the checklist likely exceed 50 items?
         ├── YES → Sub-phase split: Phase XXa + Phase XXb
         │         Each sub-phase ≤ 50 items with own Exit Criteria
         │
         └── NO → Single standard phase file
                  │
                  Are there 2+ independent sections (≥ 20 items total)?
                  ├── YES → Add Parallel Work Plan section (optional)
                  └── NO → Standard only
```

**Z7 EVOLVE template** adds these 4 EXTRA sections to the standard template:

1. **Impact Analysis** (IA-1 through IA-8) — MUST be completed BEFORE any coding
   - IA-1: Affected DB tables and columns
   - IA-2: Affected backend files (route, service, middleware)
   - IA-3: Affected frontend files (component, hook, page)
   - IA-4: Affected tests count (existing: N → expectation: ALL remain GREEN)
   - IA-5: Backward compatibility assessment
   - IA-6: Migration needed? (description or "NO")
   - IA-7: Performance impact
   - IA-8: Rollback strategy (→ see Rollback Plan)

2. **Rollback Plan** (MANDATORY in Z7 — not optional)
   - Trigger: what event would require rollback
   - Step 1: Feature flag = OFF (< 5 min)
   - Step 2-3: Specific steps (DB migration revert, cache invalidation, etc.)
   - Estimated rollback time
   - Responsible party

3. **Feature Flag Configuration**
   - Flag name, type (boolean/percentage/user-group), default OFF
   - Activation condition (which tests/checks must pass)
   - Removal plan (when to remove — flags are TEMPORARY, not permanent!)

4. **Regression Checkpoint**
   - Existing test count BEFORE the feature: [N]
   - Expected existing test count AFTER: [N] (SAME number!)
   - If ANY existing test FAILS: STOP — not acceptable in Z7
   - In Z7: run regression after EVERY COMMIT, not just at checkpoints

**Parallel Work Plan section** (optional, for any zone) adds:

- Parallel Strategy: Section-parallel | Entity-parallel | Role-parallel
- Prerequisite: which section must finish first
- Worker table: worker name, branch, scope, files, exit criteria
- Shared files list (LEADER-ONLY — workers MUST NOT modify these)
- Merge order + post-merge full test requirement
- When NOT to parallelize (< 20 items, interdependent, unknown domain)

### Step 4: AUTO-DISCOVERY Scan

Scan all installed skills to populate the Skills & Tools table.

**Scan process:**

```
1. SCAN: Read all installed skills' SKILL.md files
   Locations to check:
   - Project-local: .claude/skills/*/SKILL.md
   - Plugin skills: ~/.claude/plugins/*/skills/*/SKILL.md
   - Superpowers: check available superpowers skills

2. PARSE: Extract AUTO-DISCOVERY block from each SKILL.md
   Fields to read:
   - name, category, complements
   - trigger_keywords, trigger_files, trigger_deps
   - when_to_use, auto_invoke, priority

3. MATCH: Compare against phase plan content
   - Phase plan text contains skill's trigger_keywords? → MATCH
   - Project files match skill's trigger_files? → MATCH
   - Project dependencies match skill's trigger_deps? → MATCH

4. GENERATE: Build Skills & Tools table from matches
   Format:
   | Skill | When | Priority |
   |-------|------|----------|
   | /test-driven-development | Every new function and bugfix | mandatory |
   | [matched skill] | [from when_to_use] | [from priority] |
```

**Always include** (regardless of scan results):
- `/test-driven-development` — mandatory for all phases (Iron Law)
- `/wando:checkpoint` — mandatory (safety net)
- `/wando:review` — mandatory at phase end

**If no skills match:** The table still has the 3 mandatory skills above. An empty scan result is NOT a failure — it just means no additional skills are relevant.

### Step 5: Checklist Generation

Generate the hierarchical checklist following these rules:

**Structure rules:**
- Main tasks: `**N.M**` bold numbered (e.g., `**1.1**`, `**2.3**`)
- Subtasks: `N.M.K` under parent (e.g., `1.1.1`, `1.1.2`)
- All items start with `[ ]` (pending)
- First item gets `>>> CURRENT <<<` marker above it

**Section rules:**
- Group related tasks into named Sections
- Add `{Parallel Group: N}` annotation if parallelizable
- Add `(REQUIRES: Section N complete)` for dependencies
- Each Section should have 5-20 items

**Checkpoint placement:**
- Add `--- CHECKPOINT [letter] (Section N complete) ---` every ~15-20 items
- Every checkpoint MUST include these 4 items:
  ```
  - [ ] CP-X: Progress Log updated
  - [ ] CP-X: `>>> CURRENT <<<` marker moved to next section
  - [ ] CP-X: Interim Phase Memory filled (MANDATORY)
  - [ ] CP-X: CONTEXT_CHAIN.md updated
  ```
- The last checkpoint before review should also include:
  ```
  - [ ] CP-X: `/requesting-code-review`
  ```

**Size limit enforcement:**
- Count ALL items (sections + main tasks + subtasks + checkpoint items)
- If count > 50: STOP and propose sub-phase split
  - Split into Phase XXa + Phase XXb (or more)
  - Each sub-phase gets its own Exit Criteria
  - Present the split to the user for approval

**Final checkpoint:**
```
--- FINAL CHECKPOINT ---
- [ ] CP-FINAL: All Exit Criteria PASS
- [ ] CP-FINAL: → Run `/wando:close`
```

### Step 6: Exit Criteria + Verification Commands

Generate measurable, verifiable exit criteria:

**Rules:**
- Every criterion MUST be verifiable (metric + threshold)
- Include executable Verification Commands in a bash block
- Common patterns:
  ```
  - [ ] All tests PASS
  - [ ] Lint PASS (0 errors)
  - [ ] Coverage >= [N]%
  - [ ] Build SUCCESS
  ```
- Add task-specific criteria (e.g., "Dashboard page renders with sample data")

**Verification Commands block:**
```bash
# Tests
npm test  # or pytest, etc.
# Lint
npm run lint
# Build
npm run build
# Custom verification
[task-specific commands]
```

### Step 7: Architectural Invariants + Golden Answers

**Architectural Invariants:**
- Extract from GOLDEN_PRINCIPLES.md (project-level invariants)
- Add phase-specific invariants (rules that must not be violated during this phase)
- Keep to 3-7 invariants — focused, not exhaustive

**Golden Answers (if applicable):**
- Define expected input-output pairs for key behaviors
- Format: Input | Expected Output | Test Method
- Use for features where correctness can be objectively verified

### Step 8: START_HERE.md Update

Update the phase tracker table in START_HERE.md:

1. Add new row for the generated phase
2. Set status to PENDING
3. Link to the phase file in `plans/`
4. If sub-phases were created: add a row for each

### Step 9: Request Approval (Plannotator-assisted)

Present the generated phase file to the user for visual review:

1. **Save the phase file FIRST** to `plans/PHASE_XX_name.md` (draft state)
2. Show a brief summary in CLI: goal, checklist count, sections, key decisions
3. **Open Plannotator for visual annotation:**
   ```
   /plannotator-annotate plans/PHASE_XX_name.md
   ```
   The user reviews the FULL plan in the browser, can:
   - Highlight sections to change
   - Add inline comments
   - Mark items for removal or addition
4. **Process all annotations** — apply changes from Plannotator feedback
5. If no Plannotator available (headless/CI): fall back to CLI — use `AskUserQuestion` with options:
   - "Approve as-is"
   - "I have changes" (then ask what to change)
   - "Reject — start over"

**If the user rejects:**
- Ask what to change (or read Plannotator annotations)
- Iterate on the specific sections
- Re-present for approval (re-open Plannotator if changes were significant)

**If the user approves:**
- Finalize the phase file in `plans/`
- Update START_HERE.md (Step 8)
- Report: "Phase file saved. Ready to begin execution."

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Creative planning needed first | `/brainstorming` (superpowers) | If scope is unclear before planning |
| Phase ready for execution | `/executing-plans` (superpowers) | To execute the approved plan |
| Phase ready for subagent execution | `/subagent-driven-development` (superpowers) | Alternative execution method |
| Phase has Parallel Work Plan | `/wando:dispatch` | For Leader-Worker coordination |
| Called from init pipeline | `/wando:init` | Stage 4 calls plan for phase generation |

---

## VERIFICATION

### Success indicators
- Phase file saved in `plans/` directory, following `references/PHASE_TEMPLATE.md` format exactly
- Checklist ≤ 50 items (if more: sub-phase split proposed and approved)
- Skills & Tools table populated from AUTO-DISCOVERY scan (minimum 3 mandatory skills)
- Exit Criteria present with executable Verification Commands
- Checkpoints placed every ~15-20 items with all 4 mandatory checkpoint items
- `>>> CURRENT <<<` marker at the first checklist item
- Repo Knowledge Check section with 5 items (RK-1 through RK-5)
- START_HERE.md phase tracker updated with new phase
- Progress Log table present (empty, ready for entries)
- Phase Memory section present (empty, to be filled at close)
- If Z7 detected: all 4 extra sections present (Impact Analysis, Rollback Plan, Feature Flag, Regression Checkpoint)

### Failure indicators (STOP and fix!)
- Checklist > 50 items without sub-phase split
- Empty Skills & Tools table (should have at least 3 mandatory skills)
- No Exit Criteria or Verification Commands
- No checkpoints in the checklist
- Missing `>>> CURRENT <<<` marker
- Missing Repo Knowledge Check section
- Phase file does not follow `references/PHASE_TEMPLATE.md` format
- Z7 scenario but missing Impact Analysis or Rollback Plan
- START_HERE.md not updated
- User approval not requested (phase saved without asking)

---

## EXAMPLES

### Example 1: Standard Phase (new feature)

**User says:** "Plan the user dashboard feature."

**Agent runs `/wando:plan`:**

1. Repo Knowledge Check → reads ARCHITECTURE.md (frontend layer, API routes), GOLDEN_PRINCIPLES.md (Zod schema first), etc.
2. Context → T1 Web App, Z3-BUILD, Next.js + FastAPI
3. Template → Standard (not production, not > 50 items)
4. AUTO-DISCOVERY → matches: `/test-driven-development` (mandatory), `/react-best-practices` (trigger: "dashboard", "component"), `/frontend-design` (trigger: "UI", "page"), `/wando:checkpoint` (mandatory), `/wando:review` (mandatory)
5. Checklist → ~30 items in 3 sections (Schema + API, Frontend Components, Integration)
6. Exit Criteria → Dashboard renders, API returns data, tests PASS, lint PASS
7. Invariants → "Zod schema FIRST", "Route handler max 50 lines"
8. START_HERE.md → new row added
9. Present to user → approved

### Example 2: Z7 EVOLVE Phase (production system)

**User says:** "Add budget year 2027 filter to all procurement lists."

**Agent detects Z7:** CLAUDE.md says "Status: PRODUCTION", 15 active users → Z7 EVOLVE

**Agent runs `/wando:plan --zone=Z7`:**

1. Standard phase generated PLUS 4 Z7 extra sections
2. Impact Analysis (IA-1..IA-8) added as FIRST section
3. Rollback Plan: feature flag OFF < 5 min
4. Feature Flag: FEATURE_BUDGET_YEAR_FILTER, default OFF
5. Regression Checkpoint: existing test count recorded, EVERY COMMIT regression check
6. Checklist includes: Z7-PRE (Impact Analysis) → Z7-BUILD (implementation) → Z7-VALIDATE → Z7-RELEASE

### Example 3: Sub-phase Split (large scope)

**Agent generates checklist → counts 75 items**

**Agent proposes:** "This phase has 75 items, exceeding the 50-item limit. I recommend splitting into:
- Phase 05a: Database Schema + Backend API (35 items)
- Phase 05b: Frontend Components + Integration (40 items)

Phase 05b depends on Phase 05a. Approve this split?"

---

## REFERENCES

- `references/PHASE_TEMPLATE.md` — Phase file template (source of truth for format)
- `references/ARCHITECTURE_INVARIANTS.md` — Project-level invariants
- `references/SKILL_TEMPLATE.md` — SKILL.md template (for understanding AUTO-DISCOVERY format)
- `references/KNOWLEDGE_PATTERNS.md` — Engineering patterns (Step 2 applies these automatically)
