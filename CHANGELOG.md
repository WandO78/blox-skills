# Changelog

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
