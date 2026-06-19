---
name: blox-plan
description: "Generate structured phase files with hierarchical checklists, checkpoints, exit criteria, and auto-discovered skills. Use when planning a new feature, refactor, or multi-step development task."
user-invocable: true
argument-hint: "[feature description or phase name]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(phase files, checklist items, exit criteria, skill mappings, approval summaries)
MUST be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

## Phase template

Every generated phase file MUST follow this structure:
- Header: DIRECTIVE, ZONE (human label), CHECKLIST SYMBOLS
- Status/Current Step/Started/Last Updated metadata
- Progress Log table
- Exit Criteria with Verification Commands (bash)
- Goal + Prerequisites
- Skills & Tools table (auto-discovered)
- Checklist sections with `>>> CURRENT <<<` marker
- Checkpoint markers (`--- CHECKPOINT X ---`) every 15-20 items with 4 mandatory items
- `--- FINAL CHECKPOINT ---` at end → triggers `/blox:done`
- Architectural Invariants (3-7 rules)
- Golden Answers table (3-7 input/output pairs)
- Phase Memory section (mandatory, filled on completion)
- Max 50 checklist items — split into sub-phases if exceeded

# /blox:plan

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-plan
category: plan
complements: [blox-internal-checkpoint, blox-idea]

### Triggers — when the agent invokes automatically
trigger_keywords: [plan, phase, design, feature, sprint, milestone, roadmap, planning]
trigger_files: [START_HERE.md, CONTEXT_CHAIN.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when a new development phase needs planning: new feature, refactor,
  migration, or any multi-step task. Also called by /blox:idea in Stage 4.
  Auto-discovers installed skills and maps them to the phase's Skills & Tools table.
  Do NOT use for simple, single-step tasks that don't need a phase file.
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| New feature planning | "Plan the dashboard feature" | No — user invokes |
| `/blox:idea` Stage 4 | Idea pipeline phase generation step | Yes — idea calls it |
| New phase needed | "We need a new phase for the refactor" | No — user invokes |
| Large task breakdown | "This task is too big, break it into phases" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Simple 1-2 step task | Too much overhead | Direct implementation |
| Active phase file exists | Don't need new phase, continue the existing one | Resumption Protocol |
| Project setup | Full init needed, not just a phase | `/blox:idea` |
| Just want to assess | Assessment only, no planning | `/blox:scan` |

---

## SUPERPOWERS INTEGRATION

This skill generates blox-compatible phase files. It leverages superpowers for task detail:

- **Task breakdown:** Use `superpowers:writing-plans` methodology for bite-sized tasks (2-5 min each, exact file paths, complete code, TDD steps). But wrap the output in blox phase file format (checklist symbols, `>>> CURRENT <<<` marker, checkpoint markers, Phase Memory section).
- **Plan review:** Use superpowers plan-document-reviewer for quality check of generated plans.
- **Execution handoff:** The plan header should say "Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan" — but ALSO: "Maintain blox checkpoint saves (follow _internal/checkpoint protocol) and update phase checklist marks during execution."

**Rule:** The OUTPUT of this skill is always a blox phase file (with checklist, checkpoints, exit criteria, Golden Answers), NOT a superpowers plan file (with Task 1, Task 2 format). The superpowers methodology informs the CONTENT, the blox format provides the STRUCTURE.

**User decisions — ALWAYS use AskUserQuestion tool, NEVER inline text:**
When a decision is needed from the user (architecture choice, approach selection, scope question),
use the `AskUserQuestion` tool which shows a pop-up with options. NEVER write options as inline
text in the terminal — the user cannot easily select from inline text. AskUserQuestion provides:
- Clickable options with descriptions
- Preview panes for comparing approaches (ASCII mockups, code snippets)
- Recommended option marked first with "(Recommended)"
- User can add notes to their selection

Example — WRONG:
```
"Két megközelítést látok:
 a) Közvetlen SQL
 b) Exchange táblák
 c) Hibrid
 Melyiket választod?"
```

Example — RIGHT:
```
AskUserQuestion({
  questions: [{
    question: "Az ATHOS kapcsolat technikailag hogyan működjön?",
    header: "ATHOS",
    options: [
      { label: "Hibrid (Recommended)", description: "Közvetlen SQL most, exchange tábla később" },
      { label: "Közvetlen SQL", description: "Go service közvetlenül az ATHOS SQL Server-en" },
      { label: "Exchange táblák", description: "ATHOS fejlesztők staging DB-be írnak" }
    ]
  }]
})
```

---

## SKILL LOGIC

> **Phase file generation pipeline — 9 steps.**
> The template source of truth is ALWAYS `references/templates/phase-template.md`.
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
If called from `/blox:idea` Stage 4: some files were JUST created — read them.

### Step 2: Context Discovery + Pattern Application

Gather project context to inform template selection and content:

1. **Tech stack** (dynamically detected) — read from CLAUDE.md, package.json/pyproject.toml, or scan project files. List specific technologies (e.g., "Next.js + React + TypeScript + Prisma + PostgreSQL"), NOT predefined categories.
2. **Current zone** — read from START_HERE.md phase tracker or CLAUDE.md. Use human-readable labels: Ideation/Planning/Foundation/Building/Hardening/Launch/Maintenance/Evolution (with Z0-Z7 in parentheses for reference).
3. **Existing phases** — read START_HERE.md to understand what has been done
4. **Task scope** — what the user is asking to plan (feature, refactor, migration, etc.)
5. **Relevant blox skills** — which `/blox:*` skills map to this phase's work (e.g., `/blox:brand` for branding, `/blox:design` for architecture, `/blox:build` for implementation)

**Apply the 9-section pattern framework.** Each section contains a PATTERN that the
agent APPLIES to the phase — not a question to answer, but a template to fill in.
The patterns are documented in `references/patterns/knowledge-patterns.md`.

> **KEY PRINCIPLE:** The user does NOT need to know these patterns exist.
> The skill DELIVERS quality results automatically by applying them.

The full 9-section pattern catalog (Section 0 Repo Knowledge → Section 9 Security
Awareness, each with its fill-in table) is in `references/pattern-framework.md`. Apply
the relevant sections to the phase; use judgment based on complexity (a simple feature
may collapse Sections 1-2 to one line each, a complex Evolution phase fills all nine).

### Step 3: Phase Template Selection

Based on context discovery, select the appropriate template variant:

**Decision tree:**

```
Is this a live/production system + new feature?
+-- YES -> Evolution template (standard + 4 extra sections)
|         Detection: CLAUDE.md contains "PRODUCTION" / "LIVE" / "DEPLOYED"
|                    AND the task adds new functionality
|
+-- NO -> Standard template
         |
         Will the checklist likely exceed 50 items?
         +-- YES -> Sub-phase split: Phase XXa + Phase XXb
         |         Each sub-phase <= 50 items with own Exit Criteria
         |
         +-- NO -> Single standard phase file
                  |
                  Are there 2+ independent sections (>= 20 items total)?
                  +-- YES -> Add Parallel Work Plan section (optional)
                  +-- NO -> Standard only
```

**Evolution template** adds these 4 EXTRA sections to the standard template:

1. **Impact Analysis** (IA-1 through IA-8) — MUST be completed BEFORE any coding
   - IA-1: Affected DB tables and columns
   - IA-2: Affected backend files (route, service, middleware)
   - IA-3: Affected frontend files (component, hook, page)
   - IA-4: Affected tests count (existing: N -> expectation: ALL remain GREEN)
   - IA-5: Backward compatibility assessment
   - IA-6: Migration needed? (description or "NO")
   - IA-7: Performance impact
   - IA-8: Rollback strategy (-> see Rollback Plan)

2. **Rollback Plan** (MANDATORY in Evolution — not optional)
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
   - If ANY existing test FAILS: STOP — not acceptable in Evolution
   - In Evolution: run regression after EVERY COMMIT, not just at checkpoints

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
   - Plugin skills: ~/.claude/plugins/*/skills/*/SKILL.md
   - blox-skills: [blox-skills install dir]/skills/*/SKILL.md
   - blox-skills internal: [blox-skills install dir]/skills/_internal/*/SKILL.md
   - Superpowers: check available superpowers skills

2. PARSE: Extract AUTO-DISCOVERY block from each SKILL.md
   Fields to read:
   - name, category, complements
   - trigger_keywords, trigger_files, trigger_deps
   - when_to_use, auto_invoke, priority

3. MATCH: Compare against phase plan content
   - Phase plan text contains skill's trigger_keywords? -> MATCH
   - Project files match skill's trigger_files? -> MATCH
   - Project dependencies match skill's trigger_deps? -> MATCH

4. GENERATE: Build Skills & Tools table from matches
   Format:
   | Skill | When | Priority |
   |-------|------|----------|
   | /test-driven-development | Every new function and bugfix | mandatory |
   | [matched skill] | [from when_to_use] | [from priority] |
```

**Always include** (regardless of scan results):
- `/test-driven-development` (superpowers) — mandatory for all phases (Iron Law)
- `_internal/checkpoint` — mandatory (safety net)
- `/blox:check` — mandatory at phase end

**Skill-to-phase mapping:** For each generated phase, specify WHICH `/blox:*` skill
is the primary driver for that phase. This helps the agent know what to invoke:

```
Phase 1: Brand Identity     -> /blox:brand
Phase 2: System Design      -> /blox:design
Phase 3: Foundation Setup   -> /blox:build
Phase 4: Feature Build      -> /blox:build
Phase 5: Test & Harden      -> /blox:test + /blox:secure
Phase 6: Deploy             -> /blox:deploy
Phase 7: Documentation      -> /blox:docs
```

Not every phase maps 1:1 to a skill — some phases use multiple skills or none specifically.
The mapping is a HINT for the agent, not a rigid requirement.

**Creative phases route through /blox:design:** Video, marketing, deck, image, audio
and animation work map to `/blox:design`, which dispatches to `/blox:media` and
`/blox:slides`. Do NOT create separate phase rows for media/slides — they have no
first-class phase template and are reachable only via the design router. A creative
phase's primary driver is always `/blox:design`.

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

**Skill execution order within a phase:**
When a phase involves multiple blox skills, sections MUST follow this priority order:
1. `/blox:brand` — always FIRST (design decisions inform everything else)
2. `/blox:design` — after brand (UI design needs brand identity)
3. `/blox:build` — after design (code implements the design)
4. `/blox:test` — after build (test what was built)
5. `/blox:secure` — after build (audit what was built)
6. `/blox:deploy` — last (deploy what passed tests)

Example: If Phase 1 has both brand and build tasks:
```
### Section 1: Brand Identity → /blox:brand
- [ ] 1.1 Brand discovery (colors, typography, personality)
- [ ] 1.2 Design tokens (CSS variables)
- [ ] 1.3 Brand guidelines document

--- CHECKPOINT A (Brand complete) ---

### Section 2: Project Setup → /blox:build (REQUIRES: Section 1 complete)
- [ ] 2.1 Initialize project
- [ ] 2.2 Apply brand tokens to project
```

NEVER start build tasks before brand/design tasks in the same phase.
The `(REQUIRES: Section N complete)` dependency enforces this.

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
- [ ] CP-FINAL: Run `/blox:done`
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

### Step 9: Request Approval (Plannotator)

**MANDATORY:** After saving the phase file, open it in Plannotator for user review.
Do NOT ask "jónak tartod?" in text — the user needs to see and annotate the full document visually.

```
1. Save the phase file to plans/PHASE_XX_name.md
2. Show a brief summary in CLI: goal, checklist count, sections, key decisions
3. Open in Plannotator for visual review:
   → Skill("plannotator:plannotator-annotate", args: "/full/path/to/plans/PHASE_XX_name.md")
   → The user sees the FULL plan in the browser
   → The user can annotate specific sections with feedback
   → Feedback returns to the conversation structured by section

4. Process feedback:
   → If no annotations / user approved: finalize, update START_HERE.md, proceed
   → If annotations with feedback: address EACH annotation, edit the file, then
     re-open in Plannotator: Skill("plannotator:plannotator-annotate", ...) again
   → Repeat until no more feedback

5. Fallback (if plannotator not available):
   Use AskUserQuestion with options: "Approve as-is", "I have changes", "Reject"
```

**IMPORTANT:** Always use the FULL ABSOLUTE path when calling plannotator-annotate.
Relative paths will fail. Example: `/Users/name/project/plans/PHASE_01.md` not `plans/PHASE_01.md`.

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Creative planning needed first | `/brainstorming` (superpowers) | If scope is unclear before planning |
| Phase ready for execution (subagents available) | `/subagent-driven-development` (superpowers) | PRIMARY — mandatory when subagents are available |
| Phase ready for execution (no subagents) | `/executing-plans` (superpowers) | FALLBACK — only when subagent support is unavailable |
| Phase has Parallel Work Plan | Advanced parallel coordination | For Leader-Worker coordination |
| Called from init pipeline | `/blox:idea` | Stage 4 calls plan for phase generation |

---

## VERIFICATION

### Success indicators
- Phase file saved in `plans/` directory, following `references/templates/phase-template.md` format exactly
- Checklist <= 50 items (if more: sub-phase split proposed and approved)
- Skills & Tools table populated from AUTO-DISCOVERY scan (minimum 3 mandatory skills)
- Skill-to-phase mapping included: each phase specifies which `/blox:*` skill drives it
- Exit Criteria present with executable Verification Commands
- Checkpoints placed every ~15-20 items with all 4 mandatory checkpoint items
- `>>> CURRENT <<<` marker at the first checklist item
- Repo Knowledge Check section with 5 items (RK-1 through RK-5)
- START_HERE.md phase tracker updated with new phase
- Progress Log table present (empty, ready for entries)
- Phase Memory section present (empty, to be filled at close)
- If Evolution (Z7) detected: all 4 extra sections present (Impact Analysis, Rollback Plan, Feature Flag, Regression Checkpoint)
- Tech stack dynamically detected (specific technologies listed, no predefined categories)
- Zone labels use human-readable names with Z-code in parentheses

### Failure indicators (STOP and fix!)
- Checklist > 50 items without sub-phase split
- Empty Skills & Tools table (should have at least 3 mandatory skills)
- No Exit Criteria or Verification Commands
- No checkpoints in the checklist
- Missing `>>> CURRENT <<<` marker
- Missing Repo Knowledge Check section
- Phase file does not follow `references/templates/phase-template.md` format
- Evolution scenario but missing Impact Analysis or Rollback Plan
- START_HERE.md not updated
- User approval not requested (phase saved without asking)
- AI attribution found in generated phase file (Co-Authored-By, Claude, Opus, Anthropic, Generated by AI — see Invariant 15)
- Using predefined type categories (T1-T7) instead of dynamic tech stack detection
- Using bare zone codes (Z0-Z7) without human-readable labels

---

## EXAMPLES

Four worked walkthroughs (standard feature phase, Evolution/production phase, sub-phase
split, greenfield skill-to-phase mapping) live in `references/examples.md`.

---

## REFERENCES

- `references/examples.md` — 4 worked walkthroughs of the generation pipeline
- `references/pattern-framework.md` — 9-section pattern catalog (Step 2 applies these automatically)
- `references/templates/phase-template.md` — Phase file template (source of truth for format)
- `references/patterns/knowledge-patterns.md` — Engineering patterns rationale
