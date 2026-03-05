---
name: wando-plan
description: "Generate structured phase files for development tasks. Creates hierarchical checklists with checkpoints, exit criteria, verification commands, and auto-discovers relevant skills. Handles standard, Z7 EVOLVE, and parallel work templates."
version: "1.0.0"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion]
---

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

### Step 2: Context Discovery

Gather project context to inform template selection and content:

1. **Project type** (T1-T7) — read from CLAUDE.md or infer from tech stack
2. **Current zone** — read from START_HERE.md phase tracker or CLAUDE.md
3. **Tech stack** — read from CLAUDE.md, package.json/pyproject.toml, or infer
4. **Task scope** — what the user is asking to plan (feature, refactor, migration, etc.)
5. **Existing phases** — read START_HERE.md to understand what has been done

Apply the **9-section planning checklist** as a thinking framework:

| # | Section | Key question |
|---|---------|-------------|
| 0 | Repo Knowledge Check | What repo knowledge is relevant? (done in Step 1) |
| 1 | Context Layers | What existing knowledge, code, and tacit knowledge is relevant? |
| 2 | Decision Waterfall | What is the decision tree? Where are fallbacks? |
| 3 | Architecture Invariants | What layer rules and dependency directions apply? |
| 4 | Agent Readability & Isolation | Can the agent read all needed context? Needs worktree? |
| 5 | Review & Feedback Loop | Who reviews? Agent review? Human review? Both? |
| 6 | Provability & Eval | How do we prove it's correct? Golden Answers? |
| 7 | Memory, Learning & GC | What docs/principles/debt items will this produce? |
| 8 | Momentum Protection | How to minimize interruptions? Graceful degradation? |

Not every section needs a detailed answer — use judgment based on task complexity.

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

### Step 9: Request Approval

Present the generated phase file to the user:

1. Show the phase file summary (goal, checklist count, estimated sections)
2. Highlight any decisions made (Z7 detected, sub-phase split, parallel plan)
3. Show the Skills & Tools table (what was auto-discovered)
4. Ask: "Does this plan look good? Any changes needed?"

**If the user rejects:**
- Ask what to change
- Iterate on the specific sections
- Re-present for approval

**If the user approves:**
- Save the phase file to `plans/`
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
