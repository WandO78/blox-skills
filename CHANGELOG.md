# Changelog

## v2.0.0 — 2026-03-08

Modernized all 11 skills with new skill system features.

### New features
- **`disable-model-invocation`** — 5 skills run without extra model call (init, close, dispatch, extract, analyze)
- **`context: fork`** — audit runs in isolated read-only agent
- **`argument-hint`** — autocomplete hints for all 11 skills
- **`!`command`` injection** — 8 skills auto-detect project state at invocation (active phase, quality score, checkpoints, etc.)
- **`${CLAUDE_SKILL_DIR}`** — portable template loading in plan and init
- **`$ARGUMENTS`** — user arguments passed into review skill

### Improvements
- All skill descriptions rewritten for native discovery ("Use when..." format)
- Audit skill fully self-contained for forked agent execution
- All injections use `2>/dev/null` for graceful degradation in any project
- Phase template loaded dynamically via `${CLAUDE_SKILL_DIR}` with fallback path

---

## v1.1.0 — 2026-03-05

Knowledge patterns embedded as auto-delivered templates.

### Changes
- **NEW** `references/KNOWLEDGE_PATTERNS.md` — 13 engineering patterns distilled into actionable templates with defaults
- **REWRITTEN** `wando:plan` Step 2 — transformed from questions to pattern-application (context layers, decision waterfall, architecture invariants, momentum protection — all auto-generated)
- **UPDATED** `wando:init` Stage 3e — GOLDEN_PRINCIPLES.md auto-seeded with universal patterns based on project type
- **UPDATED** `wando:review` Step 3 — pattern compliance checking (decision waterfall, layered architecture, mechanical enforcement)
- **UPDATED** `wando:close` Step 5 — Phase Memory now includes "Patterns Applied" section
- **UPDATED** `references/PHASE_TEMPLATE.md` — new Phase Memory format
- **NEW** `USAGE_GUIDE.md` — 10 use-case-based guide
- Generalized all examples to be project-agnostic

### Design philosophy change
Skills now DELIVER quality patterns automatically — the user gets quality results
without needing to understand the underlying engineering theory.

---

## v1.0.0 — 2026-03-04

Initial release of the wando-skills plugin.

### Skills included

**Core workflow (9 skills):**
- `wando:init` — 4-stage project bootstrap (Brainstorm → Decisions → Scaffolding → Phase Gen)
- `wando:plan` — Phase file generator with AUTO-DISCOVERY skill scan
- `wando:checkpoint` — 3-level save system (AUTO / SMART / EMERGENCY)
- `wando:review` — Quality review with severity assessment (S1-S4)
- `wando:close` — Severity-aware phase completion with Phase Memory
- `wando:audit` — Read-only project assessment and gap analysis
- `wando:dispatch` — Leader-Worker parallel coordination with worktree isolation
- `wando:gc` — Documentation maintenance and project health check
- `wando:chain` — CONTEXT_CHAIN.md session continuity updates

**Future skills (2 skeletons):**
- `wando:extract` — 3-layer source material extraction pipeline
- `wando:analyze` — Multi-source synthesis and comparison

### Shared references
- `ARCHITECTURE_INVARIANTS.md` — Project-level invariants
- `CONTEXT_PERSISTENCE.md` — Chat compaction defense architecture
- `PHASE_TEMPLATE.md` — Standard phase file template
- `SKILL_TEMPLATE.md` — Standard skill file template

### Development methodology
- TDD RED-GREEN-REFACTOR for every skill
- 42 gaps identified from 7 use case tests
- 13 principles from OpenAI Engineering articles
- 10 patterns from levnikolaevich/claude-code-skills ecosystem
