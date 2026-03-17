---
name: blox-internal-chain
description: "Update CONTEXT_CHAIN.md with a concise session entry (max 30 lines): what happened, state, next steps. Called automatically by checkpoints (Level 2+) and done."
user-invocable: false
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(CONTEXT_CHAIN entries, session summaries, next-session tasks) MUST be written in
the user's language. The skill logic instructions below are in English for
maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# _internal/chain

> **Purpose:** Keep the CONTEXT_CHAIN.md current. Adds a concise entry (max 20-30 lines)
> summarizing what happened, where we are, and what comes next. This is the lifeline
> for session continuity — the Resumption Protocol reads the LAST entry.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-internal-chain
category: engine
complements: [_internal/checkpoint, blox:done]

### Triggers — when the agent invokes automatically
trigger_keywords: [chain, context, session, context chain, kontextus, lanc]
trigger_files: [CONTEXT_CHAIN.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke at Level 2+ checkpoints and at phase close to add an entry
  to CONTEXT_CHAIN.md. Each entry is max 20-30 lines summarizing:
  what happened, current state, and next session's task.
  The Resumption Protocol reads the LAST entry to orient a new session.
auto_invoke: true
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Level 2 SMART checkpoint | Checkpoint marker reached in phase | Yes — checkpoint calls it |
| Level 3 EMERGENCY checkpoint | Context window 80%+ | Yes — checkpoint calls it |
| Phase close | `/blox:done` completing a phase | Yes — done calls it |
| End of work session | Agent wrapping up for the day | No — agent decides |
| Significant milestone | Major feature complete, important decision made | No — agent decides |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Level 1 AUTO checkpoint | Too frequent, would bloat the chain | Just update phase checklist |
| No CONTEXT_CHAIN.md exists | File must exist first | Run `/blox:idea` to create it |
| Minor progress | Not enough happened to record | Wait for next checkpoint |

---

## SKILL LOGIC

> **3-step entry creation. Each entry follows the standard context chain format exactly.**

### Step 1: Collect Current State

Gather the information needed for the entry:

```
READ from the active phase file:
  1. Phase number and name
  2. Current step (from >>> CURRENT <<< marker or last [x] item)
  3. Status (in_progress / completed / emergency)

READ from recent work:
  4. What happened — summarize in 1-3 bullet points:
     - Key decisions made
     - Files created/modified
     - Tests run and results
     - Problems encountered
  5. Next session task — what should the next session start with

IF EMERGENCY:
  6. Debug context — what was the error/problem
  7. Uncommitted files — list files with unsaved changes
```

### Step 2: Write Entry

Insert a NEW entry at the TOP of CONTEXT_CHAIN.md (after the header), using this exact format:

```markdown
## [YYYY-MM-DD] Session: [short description]

**Phase:** Phase XX — [name]
**Step:** [start step] -> [end step] ([status])
**Status:** [completed | in_progress | emergency]

### What happened
- [1-3 concise bullet points]

### Next session task
- [What to do next — specific enough to START immediately]
```

**If emergency, add:**
```markdown
### Emergency context
- **Debug:** [what was the error]
- **Uncommitted:** [file list]
- **Recovery:** [suggested next step]
```

### Step 3: Format Validation

After writing the entry, validate:

```
CHECKS:
[] Entry is at the TOP of the file (newest first)
[] Date format: [YYYY-MM-DD]
[] Phase reference matches active phase
[] Status is one of: completed | in_progress | emergency
[] "What happened" section present and non-empty
[] "Next session task" section present and non-empty
[] Entry length: <= 30 lines (excluding emergency context)
[] Separator (---) between entries
```

**If entry exceeds 30 lines:** Cut details. Keep only the most important bullets.
The chain is a SUMMARY, not a log. Deep details go in the phase file's Progress Log.

---

## ENTRY LENGTH RULES

| Content | Max lines | Notes |
|---------|-----------|-------|
| Header (date, phase, status) | 4 | Fixed format |
| What happened | 3-8 | 1-3 bullets, concise |
| Next session task | 2-4 | Specific, actionable |
| Emergency context (if needed) | 5-8 | Debug + uncommitted + recovery |
| **TOTAL (normal)** | **~15-20** | Target: 20 lines |
| **TOTAL (emergency)** | **~20-28** | Max: 30 lines |

---

## INVARIANTS

1. **Newest entry FIRST** — entries are in reverse chronological order
2. **Max 30 lines per entry** — the chain is a summary, not a log
3. **"Next session task" is MANDATORY** — without it, the next session is lost
4. **Standard format** — no custom formats, follow the entry template exactly
5. **One entry per invocation** — don't batch multiple sessions into one entry

---

## SKILL INTEGRATIONS

| When this happens... | Called by | Context |
|---------------------|----------|---------|
| Level 2+ checkpoint | `_internal/checkpoint` | status: in_progress |
| Phase completion | `/blox:done` | status: completed |
| Emergency save | `_internal/checkpoint` Level 3 | status: emergency |

---

## VERIFICATION

### Success indicators
- New entry appears at TOP of CONTEXT_CHAIN.md
- Entry contains: Phase, Step, Status, What happened, Next session task
- Entry follows standard context chain format exactly
- Entry is <= 30 lines
- Date is correct (today's date)

### Failure indicators (STOP and fix!)
- Entry appended at BOTTOM (wrong order — should be top)
- Entry exceeds 30 lines (too verbose — cut it down)
- Missing "Next session task" (critical for session continuity)
- Wrong phase reference (doesn't match active phase)
- CONTEXT_CHAIN.md doesn't exist (run `/blox:idea` first)
- AI attribution found in chain entry (Co-Authored-By, Claude, Opus, Anthropic, Generated by AI)

---

## EXAMPLES

### Example 1: Normal Checkpoint (in_progress)

```markdown
## [2026-03-04] Session: Phase 05 Section 2 complete

**Phase:** Phase 05 — Master Data & Admin
**Step:** 2.1 -> 2.8 (Section 2 complete)
**Status:** in_progress

### What happened
- Section 2 (API routes) complete: 8 CRUD endpoints with Zod validation
- All route tests PASS (32/32)
- Discovered: need shared middleware for auth — added to TECH_DEBT

### Next session task
- Section 3 (Admin screens) — start with 3.1 entity list component
```

### Example 2: Phase Close (completed)

```markdown
## [2026-03-04] Session: Phase 05 COMPLETED — Master Data & Admin

**Phase:** Phase 05 — Master Data & Admin
**Step:** 1.1 -> 3.6 (complete)
**Status:** completed

### What happened
- All 3 sections complete: Schemas (10), API routes (15), Admin screens (15)
- Quality Score: 85/100 (1 CONCERN: auth middleware tech debt)
- Phase Memory recorded in phase file

### Next session task
- Phase 06 (Auth & Permissions) — now unblocked
```

### Example 3: Emergency (context dying)

```markdown
## [2026-03-04] Session: EMERGENCY — Phase 05 mid-Section 2

**Phase:** Phase 05 — Master Data & Admin
**Step:** 2.4 (in progress)
**Status:** emergency

### What happened
- Section 2 items 2.1-2.3 complete (API routes for entities 1-3)
- Working on 2.4 (entity 4 route) when context hit 80%

### Next session task
- Resume at item 2.4 — entity 4 API route
- Run tests first to verify 2.1-2.3 still pass

### Emergency context
- **Debug:** Context window 80% — triggered emergency checkpoint
- **Uncommitted:** backend/routes/entity4.ts (partial), tests/routes/entity4.test.ts (partial)
- **Recovery:** git stash the partial work, resume from clean state
```

---

## REFERENCES

- `references/templates/phase-template.md` — Context chain entry format reference
- `references/patterns/knowledge-patterns.md` — Architecture invariant: session continuity through context chain
