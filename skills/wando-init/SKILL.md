---
name: wando-init
description: "Initialize a new project or retrofit an existing one with full project infrastructure. Use when starting a new project from scratch or bringing an existing project up to wando-skills standards."
user-invocable: true
disable-model-invocation: true
argument-hint: "[greenfield|retrofit] [project description]"
---

## Phase template (reference)

!`cat ${CLAUDE_SKILL_DIR}/../wando-references/PHASE_TEMPLATE.md 2>/dev/null || cat ~/.claude/skills/wando-references/PHASE_TEMPLATE.md 2>/dev/null`

# /wando:init

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.

### Identification
name: wando-init
category: init
complements: [wando-audit, wando-plan]

### Triggers — when the agent invokes automatically
trigger_keywords: [init, start, new project, setup, scaffold, bootstrap, initialize, begin]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when starting a new project from scratch (greenfield) or when
  retrofitting an existing project to the wando-skills standard.
  In retrofit mode, expects an audit report as input (from /wando:audit).
  Do NOT use for adding a new phase to an existing wando-managed project — use /wando:plan instead.
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| New project start | "Build a task management app" | No — user invokes |
| New project (empty folder) | User opens empty directory | No — user invokes |
| Retrofit existing project | "Bring this project up to wando workflow standards" | No — user invokes |
| After audit for retrofit | `/wando:audit` completed → init receives the report | No — user decides |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| START_HERE.md + CLAUDE.md already exist | Project is already wando-managed | `/wando:plan` (new phase) |
| Only need to plan a single phase | Full init not needed | `/wando:plan` |
| Just want to assess the project | Init MODIFIES — audit is READ-ONLY | `/wando:audit` |
| Simple one-off task | No project structure needed | Direct implementation |

---

## SKILL LOGIC

> **4-stage pipeline — from brainstorm to phase generation.**
> Two entry modes: greenfield (full pipeline) and retrofit (Stage 1 shortened, audit input).
> The template source of truth for generated files is TEMPLATES.md Sections 3-6.

### Entry Mode Decision

```
Is this an empty directory (no existing code)?
├── YES → GREENFIELD mode: Full pipeline (Stage 1 → 2 → 3 → 4)
│
└── NO → Is there an audit report from /wando:audit?
    ├── YES → RETROFIT mode: Stage 1 shortened → 2 (from audit) → 3 → 4
    │         Existing files are NEVER deleted or overwritten
    │
    └── NO → Run /wando:audit FIRST, then enter RETROFIT mode
             Or if user explicitly wants full init: GREENFIELD mode
```

---

### Stage 1: BRAINSTORM (Interactive)

> **Purpose:** Understand what the user wants to build. ALL output is saved to a file — NOTHING stays only in chat.

#### Interaction style (MANDATORY)

Follow these rules for ALL brainstorm questions:

- **Use `AskUserQuestion` for EVERY question** — present choices as interactive CLI options, NOT streaming text
  - Each question uses `AskUserQuestion` with 2-4 options (label + description)
  - Put the recommended option FIRST with "(Recommended)" suffix
  - The user always has "Other" automatically — they can type custom answers
  - This gives the same interactive experience as superpowers:brainstorming
- **One question at a time** — never ask 2+ questions at once
- **Agent recommendation** — lead with your recommended option and explain WHY in the description
- **Max 8-10 questions** — after 10 questions, wrap up and move to summary. If more exploration needed, do it in Stage 2.
- **Plannotator visual review** — after all questions are done, save the FULL brainstorm summary to `docs/brainstorm/BRAINSTORM_01.md`, then open `/plannotator-annotate docs/brainstorm/BRAINSTORM_01.md` for visual annotation. The user reviews the complete document in the browser, marks changes/additions/deletions. Process all annotations before proceeding to Stage 2.
- **YAGNI ruthlessly** — if a feature can wait, recommend "Later" and explain why

**Example AskUserQuestion usage for brainstorm:**
```
AskUserQuestion({
  questions: [{
    question: "What cloud platform should we target?",
    header: "Cloud",
    options: [
      { label: "Vercel (Recommended)", description: "Best for Next.js, free tier, instant deploys. Ideal for personal projects." },
      { label: "AWS", description: "Most flexible, but more setup. Good if you need Lambda/S3/RDS." },
      { label: "Self-hosted", description: "Full control, but you manage infra. Good if you have existing servers." }
    ],
    multiSelect: false
  }]
})
```

#### Brainstorm topics

Ask the user these questions interactively. Adapt based on context (skip what's obvious, dig deeper where unclear):

**1. Project goal**
- "What do you want to build?" → Goal, target audience, problem being solved
- "In one sentence?" → Elevator pitch

**2. Input materials**
- "Do you have any existing specs, designs, API docs, or references?"
- If yes: note file paths, sizes, content types → will go to `docs/references/`

**3. Environment**
- "What context will this run in?" → Corporate/personal/client
- "Cloud preference?" → GCP/AWS/Vercel/none
- "Is there an existing system this connects to?"

**4. Constraints and rules**
- "Are there any constraints I should know about?" → GDPR, security, accessibility, deadlines
- "Any company standards?" → Design system, code conventions, CI/CD requirements

**5. Visual concept**
- "How do you envision the UI?" → Platform (desktop/mobile/both), style, references
- "Existing brand?" → Brand guide, colors, design system

**6. Scope**
- "What's the MVP?" → Features for first version
- "What's for later?" → v2+ features (goes to TECH_DEBT.md "Future" section)

**Save brainstorm output** to `docs/brainstorm/BRAINSTORM_01.md` in structured format:

```markdown
# BRAINSTORM DOCUMENT: [project name]
## Date: [date]

### 1. Project goal
**One sentence:** [...]
**Details:** [2-3 sentences]
**Target audience:** [...]
**Problem solved:** [...]

### 2. Input materials
| File/Source | Size | Type | Content |
|------------|------|------|---------|
| [spec.pdf] | [42 pages] | Specification | [brief description] |
| (none) | — | — | — |

### 3. Environment
- **Context:** [corporate / personal / client]
- **Cloud:** [GCP / AWS / Vercel / other]
- **Existing system:** [yes/no, details if yes]
- **Team:** [solo + AI / team]

### 4. Constraints and rules
| Constraint | Type | Impact |
|-----------|------|--------|
| [GDPR compliance] | Legal | → encrypted PII, consent flow |
| [2 week deadline] | Time | → MVP scope only |

### 5. Visual concept
- **Platform:** [desktop / mobile / both]
- **Style:** [modern minimal / corporate / playful]
- **References:** [URLs, screenshots]
- **Brand:** [existing guide / new / none]

### 6. Scope
#### MVP (first version)
- [feature 1]
- [feature 2]
#### Later (v2+)
- [feature 3]
```

**In RETROFIT mode:** Stage 1 is shortened — skip questions that the audit already answered (tech stack, environment). Focus on: "What do you want to do next with this project?"

---

### Stage 2: DECISIONS (Automatic + User Approval)

> **Purpose:** Turn brainstorm output into concrete technical decisions. The user MUST approve before scaffolding begins.

<HARD-GATE>
Stage 2 approval is MANDATORY. Do NOT proceed to Stage 3 without the user seeing and approving the PROJECT DECISIONS block.
</HARD-GATE>

**Fast-track:** If Stage 1 brainstorm already covered tech stack, architecture, and deployment decisions in depth (through A/B/C questions), Stage 2 becomes a **formal summary approval** — compile the decisions from Stage 1 into the PROJECT DECISIONS block and present for confirmation. Do NOT re-ask questions that were already answered in Stage 1.

**2a. Project Type Detection (T1-T7)**

Use these heuristics:

| Type | Detection signals |
|------|------------------|
| T1: Corporate Full-Stack | Corporate context + FastAPI/Django + React + Docker + GCP |
| T2: Personal Full-Stack | Personal context + Next.js + Vercel/AWS |
| T3: Research/Planning | No code output needed, only docs/plans |
| T4: Google Apps Script | Google Sheets/Drive/Gmail automation, CLASP |
| T5: Home Assistant IoT | Smart home, YAML config, sensors/automations |
| T6: One-off Task | Single script, no project structure needed → suggest NOT using init |
| T7: Data Pipeline | ETL, data cleaning, pandas/SQL heavy |

**2b. Zone Configuration**

Determine which zones the project needs:

| Zone | Needed if... | Default |
|------|-------------|---------|
| Z0: UNDERSTAND | New domain, complex requirements, source material processing | Skip if clear task |
| Z1: DESIGN | New project, major refactor, multiple solutions possible | Recommended for T1/T2 |
| Z2: FOUNDATION | Any coding project | Always (T1/T2/T4/T5/T7) |
| Z3: BUILD | Feature implementation | Always |
| Z4: HARDEN | Pre-production testing/security | Mandatory for corporate (T1), recommended for T2 |
| Z5: SHIP | Deploy to users | When deployment is planned |
| Z6: MANAGE | Live system maintenance | After Z5, automatic |
| Z7: EVOLVE | New features on live system | After Z5, when new features added |

**In RETROFIT mode:** Zone is detected from the audit report:
- Has deployed version? → Z5+ (already shipped)
- Has working code? → Z3+ (in build or after)
- Has DB schema? → Z2+ (foundation done)
- Has architecture docs? → Z1+ (design done)

**2c. Tech Stack Scan**

Scan the project directory for tech stack signals:

```
package.json / package-lock.json → Node.js / npm ecosystem
  → dependencies: react, next → React/Next.js
  → dependencies: fastify, express → Node backend
pyproject.toml / requirements.txt → Python ecosystem
  → fastapi, django → Python backend
  → pandas, numpy → Data pipeline
Dockerfile / docker-compose.yml → Container deployment
.github/workflows/ → GitHub Actions CI
.gitlab-ci.yml → GitLab CI
prisma/schema.prisma → Prisma ORM
tsconfig.json → TypeScript
tailwind.config.* → Tailwind CSS
```

**In greenfield:** Tech stack comes from brainstorm decisions (Stage 1 → 2).
**In retrofit:** Tech stack comes from the file scan + audit report.

**2d. Architecture Decisions**

Based on project type and tech stack, propose:
- Layer structure (e.g., Types → Config → Repo → Service → Runtime → UI)
- Module/domain structure
- API design approach
- Database choice

**2e. Present to User for Approval (Plan Mode → Plannotator)**

1. **Save decisions to file FIRST:** Write the PROJECT DECISIONS block to `docs/brainstorm/DECISIONS_01.md`
2. **Enter Plan Mode and submit for approval:**
   - Call `EnterPlanMode`
   - Write the DECISIONS content to the plan file (location specified by system in plan mode)
   - Call `ExitPlanMode` — this triggers Plannotator with **Approve** and **Request Changes** buttons
   - The user reviews tech stack, architecture, zones in the browser with approve/deny capability
3. **If approved:** Proceed to Stage 3 scaffolding
4. **If denied with feedback:** Process feedback, revise `docs/brainstorm/DECISIONS_01.md`, rewrite plan file, call `ExitPlanMode` again. Repeat until approved.
5. **Fallback (headless/CI, no Plannotator):** Skip plan mode, use `AskUserQuestion` with options: "Approve", "I have changes", "Start over"

**This approval is MANDATORY.** Do NOT proceed to Stage 3 without user confirmation.

> **Context preservation:** Plan mode is a tool call within the same conversation — your full context is preserved throughout the approval loop.

---

### Stage 3: SCAFFOLDING (Automatic)

> **Purpose:** Create all project infrastructure files. Uses the approved decisions from Stage 2.

<HARD-GATE>
Stage 3 is MANDATORY. Do NOT skip scaffolding. Do NOT jump to plan generation or implementation.
You MUST create CLAUDE.md, START_HERE.md, ARCHITECTURE.md, GOLDEN_PRINCIPLES.md, QUALITY_SCORE.md, TECH_DEBT.md, and CONTEXT_CHAIN.md BEFORE generating any phase files.
These files are the project's operating system — without them, the agent loses context, skips rules, and produces lower quality work.
</HARD-GATE>

**Pre-requisite: Git Repository**

Before generating any files, check if a git repository exists:

```
Is there a .git/ directory?
├── YES → Continue to file generation
│
└── NO → Initialize git repository FIRST
    1. Run: git init
    2. Create .gitignore (from tech stack — Node: node_modules, Python: __pycache__, etc.)
    3. Stage existing files: git add -A
    4. Initial commit: git commit -m "Initial commit — pre-wando state"
    5. This preserves the project's pre-wando state as a clean baseline
    6. IMPORTANT: Do NOT skip this — version control is foundational
```

In retrofit mode, this initial commit captures the project's state BEFORE any wando changes, enabling easy rollback if needed.

**Generate these files in order:**

**3a. CLAUDE.md**

Content sourced from:
- Project identity → Stage 1 brainstorm (goal, audience)
- Tech stack → Stage 2 decisions
- Layer rules → Stage 2 architecture
- Constraints → Stage 1 brainstorm (GDPR, standards, etc.)
- Relevant Skills → AUTO-DISCOVERY scan (see 3a-skills below)

**Relevant Skills section** — populated via AUTO-DISCOVERY scan:

```
1. SCAN: Read all installed skills' SKILL.md AUTO-DISCOVERY blocks
2. MATCH trigger_keywords against project context (tech stack, brainstorm content)
3. MATCH trigger_deps against project dependencies (package.json, pyproject.toml)
4. GENERATE 4 categories:
   - Mandatory (always): test-driven-development, systematic-debugging, verification-before-completion
   - Tech Stack Specific: matched by trigger_deps (e.g., react → react-best-practices)
   - Project Workflow: wando:plan, wando:checkpoint, wando:close, wando:review
   - Not Needed: explicitly non-matching skills (helps the agent NOT invoke them)
```

**Context Persistence section** — compaction-proof role anchors:

This section ensures the agent stays on track AFTER chat compaction. It is SHORT
(max ~30 lines) and tells the agent WHEN to re-read files, not WHAT the skills say.

```markdown
## Context Persistence (Compaction-Safe Rules)

> THESE RULES ALWAYS APPLY. After chat compaction, re-read this section.

### Where Am I?
- **Active phase**: `plans/PHASE_XX_name.md`
- **Current step**: Look for `>>> CURRENT <<<` marker in the phase file
- **Last context**: Read last entry in `CONTEXT_CHAIN.md`

### Mandatory Re-reads
| Event | Action |
|-------|--------|
| Lost context / after compaction | Read START_HERE.md → active phase file → `>>> CURRENT <<<` |
| Before making code changes | Re-read GOLDEN_PRINCIPLES.md |
| After checkpoint (Level 2+) | Re-read current section of phase file + relevant SKILL.md |
| Starting new task or step | Read phase file next checklist item + relevant SKILL.md |
| Unsure what to do | START_HERE.md → CONTEXT_CHAIN.md last entry → active phase |

### Critical Rules (NEVER violate)
[Auto-populated: top 3-5 rules from GOLDEN_PRINCIPLES.md]
```

**The active phase path MUST be updated** by `/wando:close` when phases change.
See: `references/CONTEXT_PERSISTENCE.md` for full architecture documentation.

**3b. START_HERE.md**

Following TEMPLATES.md Section 4:
- Phase Tracker table (populated with phases from Stage 4)
- Standard Resumption Protocol (6-step, always the same)
- Project context (tech stack, key files)

**3c. CONTEXT_CHAIN.md**

First entry:
```markdown
## [YYYY-MM-DD] Session: Project initialized

**Phase:** Project setup
**Step:** init complete
**Status:** completed

### What happened
- Project initialized with /wando:init
- [Type] project, [Zone config], [Tech stack summary]
- [N] phase files generated

### Next session task
- Begin Phase 01: [first phase name]
```

**3d. ARCHITECTURE.md**

Content sourced from:
- Layer diagram → Stage 2 architecture decisions
- Tech stack details with rationale → Stage 2
- Module/domain structure → Stage 2
- In retrofit: generated from existing code structure analysis

**3e. GOLDEN_PRINCIPLES.md**

Content sourced from TWO places:

**A. Universal patterns** (auto-seeded from `references/KNOWLEDGE_PATTERNS.md`):
These are ALWAYS included — the user doesn't need to ask for them.
Select the most relevant patterns based on project type:

| Pattern | Include for | Golden Principle to generate |
|---------|------------|------------------------------|
| Decision Waterfall (P2) | T1, T2, T4, T7 | "Every user-facing feature has fallback behavior defined" |
| Layered Architecture (P3) | T1, T2 | "Code depends only on layers below it — never upward" |
| Progressive Disclosure (P3) | ALL types | "CLAUDE.md is a map (~100 lines), not an encyclopedia" |
| Mechanical Enforcement (P5) | T1, T2 | "Rules checkable by machine are lint rules, not documentation" |
| Evidence Before Assertions (P7) | ALL types | "Never claim done without running verification commands" |
| Momentum Protection (P10) | ALL types | "When uncertain, apply reasonable default and document assumption" |
| Clean Attribution | ALL types | "No AI tool attribution in code or git (no Co-Authored-By, Claude, Opus references)" |

**B. Project-specific rules** from user input:
- Constraints → Stage 1 brainstorm ("GDPR" → "All PII encrypted at rest")
- Tech stack rules → Stage 2 ("Route handler max 50 lines, business logic in service layer")
- Company standards → Stage 1 (e.g., "Use company design system" or brand guide)

**3f. QUALITY_SCORE.md + TECH_DEBT.md**

- QUALITY_SCORE.md: initial score + breakdown table + Score History + Coverage Detail section, updated by `/wando:review`
- TECH_DEBT.md: empty in greenfield; in retrofit: populated from audit gap analysis
  - v2+ features from Stage 1 scope → listed in "Future" section

**3g. Directory structure**

```
mkdir -p docs/brainstorm docs/references plans completed failed
```

In retrofit: only create directories that don't already exist.

**3h. Input materials (if any from Stage 1)**

Copy/link referenced files to `docs/references/` with a manifest noting sizes and content types.

---

### Stage 4: PHASE GENERATION (Automatic)

> **Purpose:** Generate the first phase files by calling `/wando:plan`.

<HARD-GATE>
Stage 4 MUST call `/wando:plan` for each phase. Do NOT use `writing-plans`, `executing-plans`, or any other superpowers skill for plan generation. The `/wando:plan` skill produces phase files with checklists, checkpoints, exit criteria, verification commands, and AUTO-DISCOVERY — features that monolithic plan files lack. Each phase = one file in `plans/PHASE_XX_name.md`.
</HARD-GATE>

**4a. Determine phases based on zone configuration:**

From Stage 2 zones, generate appropriate phases:

| Zone | Typical phases |
|------|---------------|
| Z1: DESIGN | Architecture Design, UI/UX Design |
| Z2: FOUNDATION | Repo Setup, Database Schema, Auth, UI Shell |
| Z3: BUILD | Core Feature phases (from brainstorm MVP scope) |
| Z4: HARDEN | Testing Suite, Security Audit, Performance |
| Z5: SHIP | Deployment, Monitoring |

In retrofit: phases come from the audit gap analysis.
**Order: R-4 FIRST (if dirty git), then R-0 → R-3:**
- R-4: Git Hygiene (commit uncommitted files, clean working tree) — **ALWAYS FIRST if dirty**
- R-0: Agent Context (CLAUDE.md, START_HERE — already done by Stage 3)
- R-1: Knowledge Capture (ARCHITECTURE from code, retroactive CONTEXT_CHAIN)
- R-2: Code Quality (fix existing errors, add linter + formatter, optimize build output)
- R-3: Safety Net (pre-commit hooks, CI pipeline, test coverage tracking)

**4b. Call `/wando:plan` for each phase**

The plan skill handles: template selection, AUTO-DISCOVERY scan, checklist generation, exit criteria, checkpoints.

**4c. Update START_HERE.md**

Fill in the Phase Tracker table with all generated phases.

**4d. Final confirmation**

Present to the user:
```
PROJECT READY
─────────────
Files created: CLAUDE.md, START_HERE.md, ARCHITECTURE.md, GOLDEN_PRINCIPLES.md, ...
Phases generated: [N] phases in plans/
First phase: [name]

Ready to begin? Start Phase 01?
```

---

### Brainstorm → File Mapping Guarantee

> **NOTHING from the brainstorm stays only in chat.** Every piece of information maps to a file:

| Brainstorm output | Destination file | Section |
|-------------------|-----------------|---------|
| Project goal, audience | CLAUDE.md | Project identity |
| Project goal, audience | START_HERE.md | Project context |
| Input materials | docs/references/ | Copied files |
| Input materials | Phase files | "Input/Output" table |
| Environment, tech stack | CLAUDE.md | Tech stack |
| Environment, tech stack | ARCHITECTURE.md | Tech stack decisions |
| Constraints, rules | GOLDEN_PRINCIPLES.md | Invariants |
| Constraints, rules | CLAUDE.md | Constraints section |
| Visual concept | ARCHITECTURE.md | Frontend section |
| Visual concept | docs/design-docs/ | Design references |
| MVP scope | Phase files | Checklists |
| Later scope (v2+) | TECH_DEBT.md | "Future" section |
| Full brainstorm | docs/brainstorm/BRAINSTORM_01.md | Complete record |

---

### Retrofit Mode Details

In retrofit mode, these critical rules apply:

1. **NEVER delete existing files** — only create new ones or add sections to existing ones
2. **NEVER overwrite existing content** — if CLAUDE.md exists, ADD the Relevant Skills section, don't replace
3. **Existing code stays untouched** — init only creates management/documentation files
4. **Audit report is the input** — Stage 2 decisions come from audit findings, not from scratch
5. **Gap analysis drives phases** — retrofit phases address specific gaps found by audit

**Retroactive Phase Memory for pre-wando phases:**

If the project has completed phases that were done BEFORE wando-skills was adopted:
1. Identify completed phases (from START_HERE.md tracker, CONTEXT_CHAIN.md, or audit findings)
2. For each completed phase, write a **retroactive Phase Memory** based on available evidence:
   - Read the phase file's Progress Log, Exit Criteria, and any docs it produced
   - Read CONTEXT_CHAIN.md entries for that phase
   - Write Phase Memory with what CAN be reconstructed:
     ```markdown
     ## Phase Memory (Retroactive — written during retrofit)
     ### Status: COMPLETED (pre-wando)
     ### Quality Score: N/A (not measured at completion)
     ### What happened (reconstructed)
     - [Key outputs and decisions based on available evidence]
     ### Lessons (if discernible)
     - [Any patterns visible from the work done]
     ```
3. Move completed phase files to `completed/` directory (with date suffix)
4. This ensures the project's history is captured even though wando:close didn't run originally

**What init creates in retrofit (alongside existing files):**

| File | Action |
|------|--------|
| CLAUDE.md | CREATE if missing, ADD Relevant Skills if exists |
| START_HERE.md | CREATE (always new — this is the entry point) |
| CONTEXT_CHAIN.md | CREATE with retroactive first entry |
| ARCHITECTURE.md | CREATE from code analysis (not from brainstorm) |
| GOLDEN_PRINCIPLES.md | CREATE from existing code patterns |
| QUALITY_SCORE.md | CREATE from audit quality baseline |
| TECH_DEBT.md | CREATE from audit gap analysis |
| plans/ | CREATE with retrofit phases (R-0 through R-4) |
| completed/ | MOVE pre-wando completed phases here (with retroactive Phase Memory) |

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Retrofit mode (existing project) | `/wando:audit` | BEFORE init — audit report is init's input |
| Phase generation (Stage 4) | `/wando:plan` | Init calls plan to create phase files |
| Brainstorm phase (Stage 1) | Built-in (brainstorming style embedded) | A/B/C questions, one per message, section approval |
| Project ready, start execution | Begin Phase 01 using wando skills | `/wando:checkpoint` for progress, `/wando:review` for quality, `/wando:close` for completion |

---

## VERIFICATION

### Success indicators
- CLAUDE.md created with Relevant Skills section (AUTO-DISCOVERY populated, 4 categories)
- START_HERE.md created with Phase Tracker table and standard Resumption Protocol
- CONTEXT_CHAIN.md created with first entry
- ARCHITECTURE.md created with layer diagram and tech stack
- GOLDEN_PRINCIPLES.md created with project-specific invariants
- QUALITY_SCORE.md created (empty matrix or audit baseline)
- TECH_DEBT.md created (empty or audit gaps)
- docs/brainstorm/BRAINSTORM_01.md saved (Stage 1 output not lost in chat)
- At least 1 phase file generated in plans/
- START_HERE.md Phase Tracker populated with all generated phases
- User approved decisions in Stage 2 (not auto-decided)
- In retrofit: existing files untouched (no deletions, no overwrites)

### Failure indicators (STOP and fix!)
- Missing files (CLAUDE.md, START_HERE, ARCHITECTURE, etc.)
- Empty Relevant Skills section in CLAUDE.md (AUTO-DISCOVERY scan didn't run)
- No phase file generated (Stage 4 didn't call /wando:plan)
- Brainstorm output stayed in chat only (not saved to docs/brainstorm/)
- Decisions made without user approval (Stage 2 approval skipped)
- In retrofit: existing files deleted or overwritten
- Stage 1 insights not reflected in project files (mapping guarantee violated)

---

## EXAMPLES

### Example 1: Greenfield — New Next.js project

**User:** "I want to build a task management app."

**Stage 1 (BRAINSTORM):**
- Goal: Task management for small teams, Kanban-style
- Environment: Personal project, Vercel deploy
- Constraints: None specific
- MVP: Board view, task CRUD, drag-and-drop
- Later: Team collaboration, notifications

→ Saved to `docs/brainstorm/BRAINSTORM_01.md`

**Stage 2 (DECISIONS):**
- Type: T2 Personal Full-Stack
- Zones: Z1 → Z2 → Z3 → Z5 (skip Z4 for personal)
- Tech: Next.js 15 + Prisma + PostgreSQL + Vercel
- Architecture: App Router, Server Components, Prisma ORM
- User approves ✓

**Stage 3 (SCAFFOLDING):**
- CLAUDE.md with Relevant Skills: react-best-practices, frontend-design, TDD, wando:*
- START_HERE.md with Resumption Protocol
- ARCHITECTURE.md with layer diagram
- GOLDEN_PRINCIPLES.md: "Zod schema first", "Server Components by default"
- All directories created

**Stage 4 (PHASE GENERATION):**
- Phase 01: Repo Setup + Database Schema
- Phase 02: Task CRUD + Board View
- Phase 03: Drag-and-Drop + Polish
- Phase 04: Deploy to Vercel

→ "Ready to begin Phase 01?"

### Example 2: Retrofit — Existing FastAPI project

**User:** "Bring this project up to wando standards."

**Agent:** Runs `/wando:audit` first → structured report.

**Stage 1 (shortened):** "What do you want to work on next?" → "Add a new reporting module"

**Stage 2 (from audit):**
- Type: T1 Corporate Full-Stack (detected: FastAPI + React + Docker + GCP)
- Zone: Currently at Z3 (has working code), needs Z7 for new feature
- Gaps: No CLAUDE.md, no START_HERE, no ARCHITECTURE, tests at 45% coverage
- User approves ✓

**Stage 3 (SCAFFOLDING):**
- Creates CLAUDE.md, START_HERE.md, ARCHITECTURE.md (from code analysis), etc.
- Existing code UNTOUCHED
- TECH_DEBT.md populated from audit gaps

**Stage 4 (PHASE GENERATION):**
- Phase R-4: Git Hygiene (commit 66 uncommitted files, clean tree)
- Phase R-1: Knowledge Capture (ARCHITECTURE from code)
- Phase R-2: Code Quality (fix existing errors, add linter + formatter)
- Phase R-3: Safety Net (pre-commit hooks, CI pipeline, coverage tracking)
- Phase Z7-01: Reporting Module (Impact Analysis → Build → Validate → Release)

→ "Ready to begin Phase R-1?"

---

## REFERENCES

- `references/PHASE_TEMPLATE.md` — Phase file template
- `references/SKILL_TEMPLATE.md` — SKILL.md template
- `references/ARCHITECTURE_INVARIANTS.md` — Project-level invariants
- `references/KNOWLEDGE_PATTERNS.md` — Engineering patterns (auto-applied by init and plan)
