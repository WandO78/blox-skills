---
name: blox-idea
description: "Start here. Describe what you want to build and blox guides you through everything — planning, design, coding, testing, and deployment."
user-invocable: true
argument-hint: "[describe what you want to build]"
---

## Language Protocol

Detect the user's language from their FIRST message (the idea description or first
answer). All generated content (questions, summaries, scaffolded file content, status
updates) MUST be written in the user's language. The skill logic instructions below
are in English for maintainability, but all OUTPUT facing the user follows THEIR language.

Additionally, this skill SETS the project language:
1. Detect language from the user's first response
2. Store in CLAUDE.md as `language: [code]` (e.g., `language: en`, `language: hu`)
3. All subsequent blox skills use this setting for user-facing output

---

## Scaffold template

When scaffolding a new project (Step 4), generate these files:
- `CLAUDE.md` — Project identity, tech stack, language setting, installed skills
- `START_HERE.md` — Phase tracker with Resumption Protocol
- `CONTEXT_CHAIN.md` — Session continuity chain (newest entry first)
- `ARCHITECTURE.md` — Layer diagram, tech stack details
- `GOLDEN_PRINCIPLES.md` — Architectural invariants, universal patterns
- `QUALITY_SCORE.md` — Quality matrix (initial: 100/100)
- `TECH_DEBT.md` — Open tech debt (initially empty)
- Directories: `docs/`, `plans/`, `completed/`, `failed/`

# /blox:idea

> **Purpose:** The single entry point for beginners. Takes a raw idea — "I want to
> build X" — and guides the user through vision discovery, tech stack selection,
> project scaffolding, master plan generation, and plugin setup. Everything flows
> from here. The user answers questions, blox handles everything else.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-idea
category: core
complements: [blox-plan, blox-setup, blox-scan]

### Triggers — when the agent invokes automatically
trigger_keywords: [idea, start, begin, create, build, new project]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when starting a brand new project from scratch, when the user has an
  idea but doesn't know where to start, or when the user wants the full autopilot
  experience. This is the FIRST skill new users encounter.
  Do NOT use for existing projects (use /blox:scan), mid-project work (use /blox:build),
  or when a plan already exists (use /blox:plan).
auto_invoke: false
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Starting a brand new project | "I want to build a restaurant booking site" | No — user invokes |
| User has an idea, doesn't know where to start | "I have this idea for an app..." | No — user invokes |
| Full autopilot experience desired | "Help me build this from scratch" | No — user invokes |
| First time using blox-skills | User discovery — this is the entry point | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Existing project needs assessment | Assessment, not creation | `/blox:scan` |
| Already have a plan, need execution | Plan exists, skip to build | `/blox:build` |
| Something is broken | Debugging, not ideation | `/blox:fix` |
| Adding a feature to existing project | Incremental, not greenfield | `/blox:plan` |
| Project already scaffolded | Don't overwrite existing structure | `/blox:plan` or `/blox:build` |

---

## USER CONTROL LEVELS

The skill adapts to the user's experience level — detected automatically from their
responses:

| Level | Detection | Behavior |
|-------|-----------|----------|
| **Autopilot** (default for beginners) | Simple answers, no tech preferences, "I don't know" | blox drives everything, user answers y/n |
| **Guided** | Some technical answers, partial preferences | blox suggests, user makes detailed choices |
| **Manual** | Detailed technical specs, strong preferences | User drives, blox assists where asked |

**Detection rules:**
- User gives a tech stack upfront ("Go with Chi router and sqlx") → Guided/Manual
- User says "I don't know" or picks multiple choice → Autopilot
- User provides detailed specs in the initial message → Manual — skip redundant questions

---

## SUPERPOWERS INTEGRATION

This skill orchestrates the full project lifecycle. It uses superpowers skills as engines:

- **Step 1 (Vision Discovery):** If `superpowers:brainstorming` is available, use its structured discovery flow (one question at a time, visual companion option). blox:idea adds: tech stack suggestion, scope decision, beginner-friendly language.
- **Step 5 (Master Plan):** Chain to `/blox:plan` (NOT directly to `superpowers:writing-plans`). blox:plan internally uses writing-plans but wraps it in blox phase file format.
- **Step 7 (Autopilot execution):** Chain to `/blox:build` for each phase. blox:build internally uses `superpowers:test-driven-development` and `superpowers:subagent-driven-development` or `superpowers:executing-plans`.

**Rule:** blox:idea is the ENTRY POINT. It calls blox skills which call superpowers skills. Never bypass blox skills to call superpowers directly in the autopilot flow.

---

## SKILL LOGIC

> **8-step pipeline from raw idea to running autopilot.**
> Steps 1-4 are interactive (user answers questions).
> Steps 5-8 are automated (blox handles everything, user confirms).

### Step 1: VISION DISCOVERY

Ask questions ONE AT A TIME to understand what the user wants to build.
Use multiple choice where possible — reduce cognitive load.

**Questions (in order):**

```
Q1: "What do you want to build?"
    → Open-ended. This is the core idea.
    → If the user already provided a detailed description via the argument,
      SKIP this question and use the argument.

Q2: "Who is it for?"
    → Multiple choice:
      a) Personal use (just me)
      b) Small team (2-10 people)
      c) Public users (anyone can sign up)
      d) Enterprise (company internal tool)
      e) Other: [describe]

Q3: "What's the main goal? What should users be able to DO?"
    → Open-ended — the core functionality.
    → If already clear from Q1, ask for ADDITIONAL functionality instead.

Q4: "Is there anything similar you've seen that you like?"
    → Optional — inspiration or reference.
    → If user mentions a competitor or reference, briefly analyze it
      (INTEGRATES: competitive-brief, synthesize-research knowledge).

Q5: "Any constraints?"
    → Budget, timeline, must-use technology, hosting preference, etc.
    → If user says "no" or "none", move on immediately.
```

**Rules:**
- **ONE question per message** — never bundle questions
- **Multiple choice preferred** — reduce decision fatigue
- If the user gives a detailed description upfront (argument or first message),
  skip redundant questions — extract answers from what they already said
- **Maximum 5 questions** — don't over-interrogate
- Detect the user's language from their FIRST response — set for entire project
- If user mentions competitors/inspiration (Q4), do lightweight research
  (INTEGRATES: synthesize-research, competitive-brief knowledge areas)
- If user describes a target audience (Q2), note the implications
  (INTEGRATES: user-research knowledge area)

**Language detection:**
After the user's first response, determine their language:
- Hungarian text → `language: hu`
- English text → `language: en`
- Spanish text → `language: es`
- etc.
Store this for Step 4 (CLAUDE.md generation).

---

### Step 2: SCOPE DECISION

Analyze the vision gathered in Step 1 and make a scope determination:

**Decision tree:**
```
Is this a single coherent project?
+-- YES → proceed to summary
|
Is it multiple independent subsystems?
+-- YES → suggest decomposing into sub-projects
|         "This looks like 2-3 separate projects. I suggest starting with
|          [most core piece] and adding the others later."
|
Is it too ambitious for one person?
+-- YES → suggest MVP scope
          "This is a big vision! Let's start with an MVP:
           [core feature 1], [core feature 2], [core feature 3].
           We can add [advanced feature] in a later phase."
```

**Present the scope summary back to the user for confirmation:**

```
"Based on what you described, here's what I see:

[2-3 sentence summary of the project]

This involves:
- [Component 1]
- [Component 2]
- [Component 3]

Does this capture what you want to build?"
```

This scope summary IS the lightweight spec (INTEGRATES: write-spec knowledge area).

**Wait for user confirmation before proceeding.**
- "yes" / affirmative → proceed to Step 3
- User corrects something → update the summary, re-confirm
- User wants to change scope → go back to relevant question

---

### Step 3: TECH STACK SUGGESTION

Based on the confirmed vision, suggest an appropriate tech stack.

**Priority 1 — Check for tech stack defaults from extensions:**

```
IF extensions/tech-defaults.md exists (loaded by SessionStart hook):
  → Read the user's preferred stack priorities
  → Use these as the DEFAULT suggestion instead of the generic matrix
  → Example: user prefers Go for BE, Next.js for FE → suggest those first
  → Still allow override — present as default, not requirement
```

**Priority 2 — Generic decision matrix (when NO extensions loaded):**

```
Web app (frontend + backend + database):
  → Next.js + Supabase + Vercel
    Reasoning: batteries-included, fast to ship, scales well

Static website / landing page:
  → Next.js + Vercel (or plain HTML/CSS if very simple)
    Reasoning: free hosting, easy to update

Mobile app:
  → React Native + Expo + Supabase
    Reasoning: one codebase for iOS + Android, fast iteration

API / backend only:
  → Go + Gin (or Express/FastAPI depending on ecosystem)
    Reasoning: fast, simple, excellent concurrency

CLI tool:
  → Node.js (TypeScript) or Go
    Reasoning: broad ecosystem, easy distribution

Data processing / pipeline:
  → Python + pandas (or polars for performance)
    Reasoning: data ecosystem is Python-native

Desktop app:
  → Electron + React
    Reasoning: web skills transfer, cross-platform

IoT / Home Automation:
  → Home Assistant + YAML + Python
    Reasoning: established ecosystem

Google Workspace automation:
  → Google Apps Script (CLASP)
    Reasoning: native integration
```

**Present the suggestion:**

```
IF extensions loaded:
  "Your preferred stack for this type of project:

  [Stack from tech-defaults.md priorities]

  [1-sentence reasoning]

  This is your default — want to use it, or pick something different?"

IF no extensions:
  "For what you're building, I suggest:

  [Tech stack from generic matrix]

  [1-sentence reasoning]

  Does this work, or do you have a different preference?"
```

**User overrides:**
- If user specifies a different tech stack → use theirs, no pushback
- If user has no idea → use the suggestion (extensions or matrix)
- If user asks for advice → explain trade-offs briefly, then recommend

**Wait for confirmation before proceeding.**

---

### Step 4: PROJECT SCAFFOLDING

Generate the project structure using `references/templates/project-scaffold.md` as
the source of truth.

**Files to create:**

```
1. CLAUDE.md
   Content:
   - Project name (from vision)
   - 1-2 sentence description (from Step 2 scope summary)
   - Tech stack (from Step 3)
   - Language setting: language: [detected code]
   - Installed Skills section (blox-skills listed)
   - Conventions section (empty — to be filled during development)

2. START_HERE.md
   Content:
   - Resumption Protocol (from template)
   - Empty Phase Tracker table (phases will be filled in Step 5)
   - Active Phase pointer (will be set in Step 5)

3. CONTEXT_CHAIN.md
   Content:
   - Header with "Newest entry first" instruction
   - First entry: "[today's date] — Project created from /blox:idea"
     Phase: Setup
     Status: completed
     What happened: Project scaffolded from idea: "[idea summary]"
     Next session task: Begin Phase 1

4. ARCHITECTURE.md
   Content:
   - Overview section (high-level description from vision)
   - Layer Diagram (based on tech stack — adapt layers to actual stack)
   - Tech Stack table (technology + rationale for each layer)
   - Key Decisions table (empty — AD-1 will be first entry)

5. GOLDEN_PRINCIPLES.md
   Content:
   - Universal principles (always included):
     1. "Evidence before assertions — never claim done without verification"
     2. "Fix the environment, not the agent — lint rules > documentation"
     3. "Corrections are cheap, waiting is expensive — ship at 80%, fix at next checkpoint"
   - Tech-specific principles (based on stack):
     Next.js: "Server components by default, client components only when needed"
     Supabase: "Row-level security on every table — no exceptions"
     FastAPI: "Pydantic models for all request/response schemas"
     TypeScript: "Strict mode always — no any types without documented reason"
     React Native: "Test on both platforms — iOS behavior != Android behavior"
     Python: "Type hints on all function signatures"
     Go: "Error handling at every call site — no silent failures"
     (add relevant principles based on the chosen tech stack)

6. QUALITY_SCORE.md
   Content:
   - Formula: 100 - (20 x FAILs) - (10 x CONCERNs)
   - Current Score: 100/100 (fresh start)
   - History table with first entry: today's date, 100, "Project created"

7. TECH_DEBT.md
   Content:
   - Open table (empty — no debt yet)
   - Resolved table (empty)
```

**Directories to create:**

```
docs/        — Project documentation
plans/       — Active phase files
completed/   — Completed phases (with Phase Memory)
failed/      — Failed phases (Phase Memory mandatory)
```

**Version control (git):**

Git is NOT mandatory. Use the brainstorm results (Steps 1-3) to decide:

```
IF .git already exists (user chose git before blox):
  git add all scaffolded files
  git commit -m "Add blox project structure from /blox:idea"

IF no .git directory exists:
  Check the confirmed scope and tech stack from Steps 1-3:
    ALWAYS initialize local version control (silent, no user action needed):
      git init
      Create .gitignore (appropriate for tech stack):
        - node_modules/ (Node.js)
        - __pycache__/ (Python)
        - .env (always)
        - .env.local (always)
        - dist/ or build/ (build output)
        - .next/ (Next.js)
        - .blox/ (blox internal state — not committed)
      git add all scaffolded files
      git commit -m "Initial project setup"

    Note: git init is LOCAL only — not GitHub/GitLab. It gives rollback
    from minute one at zero cost. Remote backup is suggested later when
    the project grows (see checkpoint skill).
```

---

### Step 5: MASTER PLAN GENERATION

Chain to `/blox:plan` to generate the full project plan.

**Instructional chain:**
"Now follow the `/blox:plan` skill to generate phases for this project."

**Context passed to /blox:plan:**
- Project vision (from Step 1)
- Confirmed scope (from Step 2)
- Tech stack (from Step 3)
- Scaffolded structure (from Step 4)

**Phase structure guidance — /blox:plan will determine the right phases, but
the typical flow based on project type is:**

```
Web app (frontend + backend):
  Phase 1: Brand Identity       → /blox:brand
  Phase 2: UI/UX Design         → /blox:design
  Phase 3: Foundation (DB, auth, project setup) → /blox:build
  Phase 4: Core Features        → /blox:build
  Phase 5: Testing & Security   → /blox:test + /blox:secure
  Phase 6: Deployment           → /blox:deploy
  Phase 7: Documentation        → /blox:docs

API / backend only:
  Phase 1: Foundation (DB schema, auth) → /blox:build
  Phase 2: Core API endpoints   → /blox:build
  Phase 3: Testing & Security   → /blox:test + /blox:secure
  Phase 4: Deployment           → /blox:deploy
  Phase 5: Documentation        → /blox:docs

CLI tool:
  Phase 1: Core functionality   → /blox:build
  Phase 2: Testing              → /blox:test
  Phase 3: Packaging & Distribution → /blox:deploy
  Phase 4: Documentation        → /blox:docs

Static website:
  Phase 1: Brand Identity       → /blox:brand
  Phase 2: Design & Build       → /blox:design + /blox:build
  Phase 3: Content              → /blox:docs
  Phase 4: Deployment           → /blox:deploy
```

Not all phases are always needed — /blox:plan determines the right set based on
the actual project. Skip brand/design for CLI tools, skip deployment for local-only
tools, etc.

**CRITICAL ORDERING RULE:**
Brand and design MUST be separate phases or separate sections BEFORE any build phase.
NEVER combine brand/design work with technical build work in the same section.
The reason: design decisions (colors, typography, layout) must be finalized BEFORE
code implements them. If the agent starts coding before the design is done, it will
have to redo the work.

Correct:  Phase 1: Brand → Phase 2: Design → Phase 3: Build
Also OK:  Phase 1: Section 1 Brand (FIRST) → Section 2 Build (REQUIRES: Section 1)
Wrong:    Phase 1: Build + Brand mixed together

---

### Step 6: SETUP CHECK

After plan generation, chain to `/blox:setup` to check and install needed plugins.

**Instructional chain:**
"Now follow the `/blox:setup` skill to check and install needed plugins."

Only suggest plugins needed for the generated plan's phases — don't overwhelm with
everything in the registry. The setup skill handles the interactive install flow.

---

### Step 7: AUTOPILOT START

Present the complete plan to the user with a clear summary:

```
"Everything is ready!

[N] phases planned
[installed count] plugins installed
[scaffolded files count] files created

Phase 1: [name] — driven by /blox:[skill]
Phase 2: [name] — driven by /blox:[skill]
Phase 3: [name] — driven by /blox:[skill]
...

Start with Phase 1 ([name])? (y/n)"
```

**On "y":**
Load the first phase file and begin executing it by chaining to the corresponding
blox skill. For example, if Phase 1 is "Brand Identity", chain to `/blox:brand`.

**On "n":**
"No problem. You can start any phase later by running the corresponding /blox:[skill]
command. Your project structure and plan are saved."

**At EVERY phase transition:**
"Phase [N] ([name]) complete. Continue to Phase [N+1] ([name])? (y/n)"

This ensures the user always has control over when to proceed, while maintaining
the autopilot flow.

---

### Step 8: INTEGRATES

These knowledge areas are BUILT INTO the skill logic — they are not separate skills
to invoke, but capabilities that enhance the 7 steps above:

| Knowledge Area | Where Applied | How |
|----------------|---------------|-----|
| **write-spec** | Step 2 | The scope summary IS a lightweight spec |
| **synthesize-research** | Step 1, Q4 | If user mentions competitors/inspiration, research them |
| **competitive-brief** | Step 1, Q4 | If user provides references, briefly analyze strengths/weaknesses |
| **user-research** | Step 1, Q2 | Target audience analysis informs tech stack and feature priorities |

These are NOT invoked as separate skills. They enhance the natural flow of vision
discovery and scope definition.

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| Scaffolding fails (no write permission) | Continue in advisory mode — tell user what to create manually | "I can't create files here. Here's what you need to set up: [list]" |
| Git init fails | Continue without git, note in TECH_DEBT | "Git setup skipped — I noted this in TECH_DEBT.md for later" |
| /blox:plan fails | Fall back to manual planning with user | "Let me help you create a plan step by step instead" |
| /blox:setup can't install plugins | Continue in basic mode | "Plugin setup skipped — blox works without plugins, they just enhance it" |
| User abandons mid-flow | Save whatever was completed, update CONTEXT_CHAIN | "Progress saved. Run /blox:idea again to continue where you left off" |
| Disk full | Warn, switch to advisory output | "Disk is full — here's the plan as text, save it when space is available" |

---

## INVARIANTS

1. **ONE question per message** — never overwhelm the user with multiple questions
2. **Always confirm vision before tech stack** — Step 2 confirmation is mandatory
3. **Never force a tech stack** — always offer user choice, always accept overrides
4. **Scaffold files are English** — user communication in detected language, but file content (code, configs, markdown structure) uses English
5. **Master plan always maps phases to blox skills** — each phase specifies its driver skill
6. **Setup check always runs after plan generation** — never skip plugin detection
7. **Autopilot always asks before phase transitions** — user controls the pace
8. **Maximum 5 questions** — if user gave enough info, skip remaining questions
9. **Language detected and stored** — from first user response, persisted in CLAUDE.md
10. **Graceful degradation always** — every error has a fallback, nothing blocks

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Vision confirmed, scope decided, tech stack chosen | `/blox:plan` | Step 5 — master plan generation |
| Master plan generated | `/blox:setup` | Step 6 — plugin check and install |
| Autopilot starts Phase 1 | Corresponding `/blox:*` skill | Step 7 — phase execution |
| Autopilot phase transition | Next phase's `/blox:*` skill | Step 7 — after user confirms |
| Project scaffolded | `_internal/detect` | Via `/blox:setup` — plugin detection |

---

## VERIFICATION

### Success indicators
- Vision captured through max 5 questions, ONE per message
- User confirmed the scope summary before tech stack discussion
- Tech stack decided — either suggested by blox or chosen by user
- Project scaffolded: CLAUDE.md, START_HERE.md, CONTEXT_CHAIN.md, ARCHITECTURE.md, GOLDEN_PRINCIPLES.md, QUALITY_SCORE.md, TECH_DEBT.md + directories (docs/, plans/, completed/, failed/)
- Language detected and stored in CLAUDE.md
- Master plan generated with phases mapped to blox skills (via /blox:plan)
- Plugins checked and installed (via /blox:setup)
- Autopilot ready to start — user asked before first phase begins
- Git repo initialized (or failure noted in TECH_DEBT)
- CONTEXT_CHAIN.md has first entry
- No AI attribution in any scaffolded file (no Co-Authored-By, Claude, Opus, Anthropic, Generated by AI)

### Failure indicators (STOP and fix!)
- Multiple questions in one message (INVARIANT 1 violation)
- Tech stack chosen before vision confirmed (INVARIANT 2 violation)
- Tech stack forced without user consent (INVARIANT 3 violation)
- Scaffolding skipped entirely without advisory fallback
- No plan generated (Step 5 skipped)
- User never confirmed vision summary (Step 2 confirmation skipped)
- Language not detected or not stored in CLAUDE.md
- Phase plan does not map phases to blox skills
- AI attribution found in scaffolded files

---

## EXAMPLES

### Example 1: Complete beginner (Autopilot mode)

```
User: /blox:idea "I want to build a restaurant website where people can book tables"

blox: "Great idea! Let me ask a few questions to understand what you need.

       Who is this website for?
       a) A specific restaurant you own/work at
       b) A template for any restaurant
       c) A platform where multiple restaurants can list"

User: "a"

blox: "What should visitors be able to do on the site?
       a) Just see the menu and contact info
       b) Book a table online
       c) Book a table + order food for delivery
       d) All of the above"

User: "b"

blox: "Any similar sites you've seen that you like? (optional — skip if none)"

User: "no"

blox: "Any constraints? Budget, timeline, must-use technology?
       (skip if none)"

User: "no"

blox: "Got it! Here's what I see:

       A website for a specific restaurant where visitors can view the menu,
       see restaurant info, and book tables online.

       This involves:
       - Public-facing site with menu and restaurant info
       - Table booking system with date/time selection
       - Admin view for the restaurant to manage bookings

       Does this capture what you want to build?"

User: "yes"

blox: "For this, I suggest:

       Next.js + Supabase + Vercel

       This gives you a fast website with a database for bookings,
       user-friendly admin panel, and free hosting on Vercel.

       Sound good?"

User: "yes"

blox: [scaffolds project — CLAUDE.md, START_HERE.md, etc.]
      [chains to /blox:plan — generates 5-phase master plan]
      [chains to /blox:setup — checks plugins]

      "Everything is ready!

       5 phases planned
       4 plugins installed
       7 files + 4 directories created

       Phase 1: Brand Identity — colors, fonts, style (/blox:brand)
       Phase 2: UI Design — pages and components (/blox:design)
       Phase 3: Core Build — booking system, menu page (/blox:build)
       Phase 4: Testing & Security (/blox:test + /blox:secure)
       Phase 5: Deploy to Vercel (/blox:deploy)

       Start with Phase 1? (y/n)"

User: "y"

blox: [loads Phase 1, chains to /blox:brand]
```

### Example 2: Experienced developer (Guided/Manual mode)

```
User: /blox:idea "REST API in Go with PostgreSQL for inventory management"

blox: "Who will use this API?
       a) Just you / personal project
       b) Small team (2-10 people)
       c) Public API (anyone can access)
       d) Enterprise / internal company tool"

User: "Internal warehouse team, about 20 users"

blox: "What specific functionality do you need?
       (The core idea is clear — what are the key endpoints?)"

User: "JWT auth, CRUD for products, stock levels, barcode scanning endpoint"

blox: "Here's what I see:

       Go REST API with PostgreSQL for warehouse inventory management.
       JWT authentication, product CRUD operations, stock level tracking,
       and a barcode scanning endpoint. Internal use for ~20 warehouse users.

       This involves:
       - Auth middleware (JWT)
       - Product management (CRUD + stock levels)
       - Barcode scanning integration
       - Admin/reporting endpoints

       Correct?"

User: "yes, and I'll use Chi router and sqlx"

blox: "Perfect. Using your stack: Go + Chi + sqlx + PostgreSQL.

       [scaffolds project with Go-specific structure]
       [chains to /blox:plan — generates plan, skips brand/design phases]
       [chains to /blox:setup — checks Go-relevant plugins]

       Everything is ready!

       5 phases planned
       2 plugins installed
       7 files + 4 directories created

       Phase 1: Foundation — DB schema, auth middleware (/blox:build)
       Phase 2: Core API — product CRUD, stock endpoints (/blox:build)
       Phase 3: Barcode — scanning endpoint integration (/blox:build)
       Phase 4: Testing & Security (/blox:test + /blox:secure)
       Phase 5: Deploy (/blox:deploy)

       Start? (y/n)"
```

### Example 3: User provides everything upfront

```
User: /blox:idea "Personal finance tracker. React Native + Expo + Supabase.
       I want to track expenses, set budgets, and see charts. Just for me."

blox: [detects: vision clear, tech stack specified, audience known]
      [skips Q1 (already answered), Q2 (personal use), Q3 (clear), Q5 (no constraints mentioned)]

      "Any similar apps you've seen that you like? (optional)"

User: "YNAB is great but too expensive"

blox: [notes: YNAB as inspiration — envelope budgeting style]

      "Here's what I see:

       Personal finance tracker for mobile (React Native + Expo + Supabase).
       Track expenses, set budgets (YNAB-inspired envelope style),
       and visualize spending with charts. Personal use only.

       This involves:
       - Expense tracking (add, categorize, search)
       - Budget management (envelope-style, monthly reset)
       - Charts and reports (spending by category, trends)
       - Data sync via Supabase (accessible from any device)

       Does this capture what you want?"

User: "yes"

blox: "Using your chosen stack: React Native + Expo + Supabase.

       [scaffolds, plans, setup]

       6 phases planned...
       Start with Phase 1? (y/n)"
```

### Example 4: Scope too ambitious — MVP suggestion

```
User: /blox:idea "I want to build the next Airbnb but for office spaces,
       with AI matching, blockchain payments, and VR tours"

blox: [Q1 answered, proceeds with Q2-Q5]
      ...

blox: "This is a big vision! It has several independent systems:
       - Office listing marketplace
       - AI matching engine
       - Blockchain payment system
       - VR tour integration

       I suggest starting with an MVP:
       Office listing marketplace with search and booking.
       We can add AI matching, blockchain, and VR as separate phases later.

       This MVP involves:
       - Office listings with photos and details
       - Search and filter by location, size, price
       - Booking and payment (standard, not blockchain yet)
       - User accounts for hosts and renters

       Start with this scope?"

User: "yes, that makes sense"

blox: [proceeds with MVP scope]
```

---

## REFERENCES

- `references/templates/project-scaffold.md` — Project scaffold template (source of truth for Step 4)
- `references/patterns/knowledge-patterns.md` — Knowledge patterns applied automatically
- `skills/plan/SKILL.md` — Master plan generation (chained in Step 5)
- `skills/setup/SKILL.md` — Plugin setup (chained in Step 6)
