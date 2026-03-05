# Phase File Template — Reference

> **Source:** TEMPLATES.md Section 1.1
> **Used by:** `/wando:plan`, `/wando:init`
> This file is a COPY of the phase file template for reference purposes.
> The SOURCE OF TRUTH is TEMPLATES.md Section 1.1.

---

```markdown
# Phase XX: [Name]

> **DIRECTIVE**: [1-2 sentences for the agent — clear, imperative]
> **PROTOCOL**: → docs/PROTOCOL.md (details, if any)
> **ZONE**: [Z2-FOUNDATION | Z3-BUILD | Z7-EVOLVE | ...]
> **PROJECT TYPE**: [T1 | T2 | ... | T7]
> **CHECKLIST SYMBOLS**: [ ] pending | [~] in progress | [x] done | [BLOCKED reason] | [SKIPPED reason]

## Status: [PENDING | IN PROGRESS | IN PROGRESS — REMEDIATION | COMPLETED | FAILED — REQUIRES REDESIGN]
## Current Step: [number]
## Started: [date]
## Last Updated: [date]

---

## Progress Log

| # | Date | Step | Status | Notes |
|---|------|------|--------|-------|
| 1 | YYYY-MM-DD | 1.1-1.3 | completed | [description] |

## Exit Criteria

- [ ] [Verifiable criterion 1 — metric + threshold]
- [ ] [Verifiable criterion 2]
- [ ] Verification Commands ALL PASS:
```bash
[command]
```

---

## Goal
[2-3 sentences — WHAT this phase achieves, WHY it matters]

## Input / Output / Prerequisites

| Type | File | Size | Description |
|------|------|------|-------------|
| INPUT | ... | ... lines | ... |
| OUTPUT | ... | — | ... |
| PREREQ | Phase XX complete | — | ... |

## Repo Knowledge Check

> **Mandatory:** The agent MUST read these BEFORE doing anything.

- [ ] RK-1: ARCHITECTURE.md
- [ ] RK-2: Previous phase memories
- [ ] RK-3: GOLDEN_PRINCIPLES.md
- [ ] RK-4: TECH_DEBT.md
- [ ] RK-5: QUALITY_SCORE.md

## Skills & Tools

| Skill | When | Priority |
|-------|------|----------|
| [auto-discovered skill] | [trigger] | [mandatory/recommended/optional] |

---

## Checklist

### Section 1: [Section name] {Parallel Group: 1}

>>> CURRENT <<<

- [ ] **1.1** [Main task]
  - [ ] 1.1.1 [Subtask]
- [ ] **1.2** [Main task]

--- CHECKPOINT A (Section 1 complete) ---
- [ ] CP-A: Progress Log updated
- [ ] CP-A: `>>> CURRENT <<<` marker moved
- [ ] CP-A: Interim Phase Memory filled (MANDATORY)
- [ ] CP-A: CONTEXT_CHAIN.md updated

### Section 2: [Section name] (REQUIRES: Section 1 complete)

- [ ] **2.1** [Main task]

--- FINAL CHECKPOINT ---
- [ ] CP-FINAL: All Exit Criteria PASS
- [ ] CP-FINAL: → Run `/wando:close`

> **CHECKLIST LIMIT: Maximum 50 items**

---

## Architectural Invariants

1. [Rule]

## Golden Answers (if relevant)

| # | Input | Expected Output | Test Method |
|---|-------|-----------------|-------------|

## Feeds Into

- **Phase XX+1** — [what it receives]

---

## Phase Memory (Retrospective)

> **MANDATORY — ON PASS AND FAIL ALIKE**

### Status: [COMPLETED | FAILED — REQUIRES REDESIGN]
### Quality Score: [N/10]

### Golden Principles (what worked)
### Antipatterns (what did NOT work)
### Patterns Applied (from KNOWLEDGE_PATTERNS.md)
### Tech Debt (what remains open)
### Interim Memory (collected from checkpoints)
```
