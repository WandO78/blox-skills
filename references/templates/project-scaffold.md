# Project Scaffold Template

> Used by `/blox:idea` to generate initial project structure.

## Generated Files

| File | Purpose | When Created |
|------|---------|-------------|
| `CLAUDE.md` | Project identity, tech stack, installed skills registry | Always |
| `START_HERE.md` | Phase tracker with Resumption Protocol | Always |
| `CONTEXT_CHAIN.md` | Session continuity chain (newest entry first) | Always |
| `ARCHITECTURE.md` | Layer diagram, tech stack details | Always |
| `GOLDEN_PRINCIPLES.md` | Architectural invariants, universal patterns | Always |
| `QUALITY_SCORE.md` | Quality matrix + trend history | Always |
| `TECH_DEBT.md` | Open tech debt + future work | Always |
| `.blox/plugin-state.yaml` | Plugin installation tracking | On first _detect run |

## Generated Directories

| Directory | Purpose |
|-----------|---------|
| `docs/` | Project documentation |
| `plans/` | Active phase files |
| `completed/` | Completed phases (with Phase Memory) |
| `failed/` | Failed phases (Phase Memory mandatory) |

## CLAUDE.md Template

```markdown
# [Project Name]

> [1-2 sentence project description]

## Tech Stack
- [Detected or chosen tech stack]

## Installed Skills
- blox-skills: /blox:idea, /blox:plan, /blox:build, /blox:check, ...

## Language
language: [detected language code, e.g., en, hu, es]

## Conventions
- [Project-specific conventions discovered during setup]
```

## START_HERE.md Template

```markdown
# START HERE

> Read this FIRST in every new session.

## Resumption Protocol
1. Read CONTEXT_CHAIN.md (last entry) — understand where we left off
2. Read the active phase file (find >>> CURRENT <<< marker)
3. Run `git status` — check for uncommitted work
4. Continue from the current step

## Phase Tracker

| Phase | Name | Status | Zone |
|-------|------|--------|------|
| 01 | [name] | PENDING | [zone] |

## Active Phase
→ plans/Phase_01_[name].md
```

## CONTEXT_CHAIN.md Template

```markdown
# Context Chain

> Newest entry first. Read the top entry to resume.

---

## [YYYY-MM-DD HH:MM] — Session N

**Phase:** [active phase]
**Step:** [current step]
**Status:** [what was accomplished]
**Next:** [what to do next]
**Blockers:** [none / description]
```

## ARCHITECTURE.md Template

```markdown
# Architecture

> System architecture and technical decisions.

## Overview
[High-level description of the system]

## Layer Diagram
```
[Visual representation of system layers]
```

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| [layer] | [tech] | [why chosen] |

## Key Decisions

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| AD-1 | [decision] | [why] | [date] |
```

## QUALITY_SCORE.md Template

```markdown
# Quality Score

> Formula: 100 - (20 x FAILs) - (10 x CONCERNs) — Floor: 0

## Current Score: [—]

## History

| Date | Score | Phase | Notes |
|------|-------|-------|-------|
| [date] | [score] | [phase] | [notes] |

## Score Interpretation
- 80-100: Healthy
- 50-79: Needs Work
- 0-49: Critical
```

## TECH_DEBT.md Template

```markdown
# Tech Debt

> Known issues deferred for later resolution.

## Open

| # | Description | Source Phase | Severity | Target Phase |
|---|-------------|------------|----------|-------------|
| TD-1 | [description] | [phase] | [low/medium/high] | [phase or TBD] |

## Resolved

| # | Description | Resolved In | Date |
|---|-------------|------------|------|
```

## GOLDEN_PRINCIPLES.md Template

```markdown
# Golden Principles

> Architectural invariants learned from project experience.
> These MUST NOT be violated without explicit discussion.

## Universal

1. [Principle from Phase Memory or project setup]

## Project-Specific

1. [Principle discovered during development]
```
