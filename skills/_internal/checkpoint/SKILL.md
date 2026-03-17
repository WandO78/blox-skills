---
name: blox-internal-checkpoint
description: "Save progress at 3 levels during phase execution: AUTO (every 5 items), SMART (at checkpoints or context 50%), EMERGENCY (context 80%). This safety net MUST be invoked automatically during phase work."
user-invocable: false
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(Phase Memory entries, CONTEXT_CHAIN entries, Progress Log notes, commit messages)
MUST be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Active phase: !`grep -rl ">>> CURRENT <<<" plans/PHASE_*.md 2>/dev/null`
- Last checkpoint: !`grep "CP-\|CHECKPOINT" plans/PHASE_*.md 2>/dev/null | tail -5`
- Quality score: !`head -5 QUALITY_SCORE.md 2>/dev/null`

# _internal/checkpoint

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-internal-checkpoint
category: engine
complements: [_internal/chain, blox:done]

### Triggers — when the agent invokes automatically
trigger_keywords: [checkpoint, save, context, progress]
trigger_files: [CONTEXT_CHAIN.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke automatically during phase execution:
  - Level 1 (AUTO): every 5 checklist items or every commit
  - Level 2 (SMART): at --- CHECKPOINT --- markers or context 50%
  - Level 3 (EMERGENCY): at context window 80% — last line of defense
  The checkpoint system is the SAFETY NET of the entire skill library.
  Without it, all other skills' work can be lost on context reset.
auto_invoke: true
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| 5 checklist items done | Routine progress save | Yes — Level 1 AUTO |
| Every git commit | Post-commit save | Yes — Level 1 AUTO |
| `--- CHECKPOINT X ---` marker | Reached checkpoint line in phase file | Yes — Level 2 SMART |
| Context window ~50% | Agent notices growing context | Yes — Level 2 SMART |
| Important decision made | Architectural decision, large refactor | No — agent decides (Level 2) |
| Context window ~80% | Agent detects compression/truncation notice | Yes — Level 3 EMERGENCY |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Phase close | Close is more comprehensive (includes quality review + severity) | `/blox:done` |
| No active phase file | Nothing to save checkpoint against | — |
| Simple non-phase task | No checklist to track | — |

---

## SKILL LOGIC

> **3-level save system. Each level is a SUPERSET of the previous.**
> Level 1 ⊂ Level 2 ⊂ Level 3.
> The higher the level, the more is saved, the more it costs in time.

### Overview

```
LEVEL 1: AUTO          LEVEL 2: SMART           LEVEL 3: EMERGENCY
─────────────────      ─────────────────        ─────────────────
Trigger:               Trigger:                 Trigger:
 Every 5 items          Checkpoint marker        Context 80%
 Every commit           Context 50%
                        Important decision

Saves:                 Saves (Level 1 +):       Saves (Level 2 +):
 [x] checklist marks    Interim Phase Memory     Debug context
 >>> CURRENT <<< move   CONTEXT_CHAIN entry      Open questions
 Progress Log row       Git commit               Current task state
 Current Step update                             Git status snapshot

Cost: ~30 sec          Cost: ~1-2 min           Cost: ~2-3 min
Frequency: Often       Frequency: Planned       Frequency: Rare
```

---

### Step 1: Determine Checkpoint Level

The agent determines the level based on the trigger:

**Level 1 (AUTO) triggers:**
- Counter: 5 checklist items completed since last checkpoint
- Event: a git commit was just made
- This is the DEFAULT level — lightweight, frequent, no thinking required

**Level 2 (SMART) triggers:**
- The agent reaches a `--- CHECKPOINT X (description) ---` line in the phase file
- The agent notices context window is approximately 50% full
- An important architectural decision was just made
- A significant milestone was reached (e.g., all tests passing for a section)

**Level 3 (EMERGENCY) triggers:**
- The agent detects context window is approximately 80% full
- Signs: system compression notices, message truncation warnings, context getting very long
- This is the LAST LINE OF DEFENSE — if we don't save now, everything is lost

**When in doubt:** Level 2 is always safe. Over-checkpointing wastes a minute; under-checkpointing can lose hours.

**Edge case — no git repo:** If the project has no git repository, skip all git-related actions (commit, status snapshot). The file-based saves (checklist marks, Progress Log, Phase Memory, CONTEXT_CHAIN) still work and are the primary recovery mechanism.

---

### Step 2: Execute Level 1 (AUTO)

Level 1 is a fast, mechanical save. No AI summarization needed.

**2a. Update checklist marks**

Mark completed items with `[x]`:
```
- [x] **1.1** Implement user model    ← was [ ], now [x]
  - [x] 1.1.1 Zod schema             ← was [ ], now [x]
  - [x] 1.1.2 Database migration     ← was [ ], now [x]
```

**2b. Move `>>> CURRENT <<<` marker**

Move the marker to ABOVE the next pending `[ ]` item:

```
- [x] **1.2** Implement API routes

>>> CURRENT <<<

- [ ] **1.3** Write integration tests
```

**Movement rules:**
- The marker is ALWAYS above the FIRST unchecked `[ ]` item
- If all items in a section are `[x]`: move marker to the next section
- If all items are `[x]`: marker goes above `--- FINAL CHECKPOINT ---`
- There is exactly ONE `>>> CURRENT <<<` marker in the file at all times

**2c. Add Progress Log row**

Append a row to the Progress Log table in the phase file:

```
| N | YYYY-MM-DD | X.Y-X.Z | completed | [brief description of what was done] |
```

Format rules:
- `#`: sequential number
- `Date`: today's date
- `Step`: range of completed items (e.g., `1.1-1.3`)
- `Status`: one of `completed` | `in_progress` | `blocked` | `skipped`
- `Notes`: 1 short sentence

**2d. Update `Current Step` metadata**

Update the header at the top of the phase file:
```
## Current Step: 1.3
```

---

### Step 3: Execute Level 2 (SMART) — extends Level 1

Do everything from Level 1 PLUS:

**3a. Fill Interim Phase Memory**

In the Phase Memory section at the bottom of the phase file, add to the "Interim Memory" subsection:

```
### Interim Memory (collected from checkpoints)
- [CP-A] The SAP API uses integer IDs, not UUIDs — conversion needed at import
- [CP-A] The report generation service should be separate from the main API
- [CP-B] React Server Components can't use useEffect — moved data fetching to server
```

What to record:
- Decisions made ("we chose X because Y")
- Lessons learned ("the API behaves differently than documented")
- Surprises ("this library doesn't support ESM")
- Patterns discovered ("all CRUD entities follow the same schema pattern")

**3b. Update CONTEXT_CHAIN.md**

Add a new entry at the TOP of the chain (below the header), following this format:

```markdown
## [YYYY-MM-DD] Session: [Phase name] — CP-X: [brief description]

**Phase:** Phase XX — [name]
**Step:** [start] → [current]
**Status:** in_progress

### What happened
- [1-3 bullet points summarizing work since last entry]

### Next session task
- [What the next session should continue with]
```

Keep entries concise: max 15-20 lines. The Resumption Protocol reads the LAST entry.

**3c. Git commit**

Create a commit with a standardized message:

```
git add -A
git commit -m "Phase XX — CP-X: [brief description]"
```

Commit message format:
- `Phase XX` — the phase number
- `CP-X` — the checkpoint letter (CP-A, CP-B, etc.)
- `[description]` — 1 short sentence (what was accomplished)
- **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, or any AI tool attribution to commit messages or code

Example: `Phase 03 — CP-B: SAP import complete, report generation started`

**3d. Context Refresh (Compaction Defense)**

After saving, re-read fresh context to guard against compaction drift:

1. Re-read the phase file's `>>> CURRENT <<<` section — the next 3-5 checklist items
2. If working with a specific skill, re-read that SKILL.md's SKILL LOGIC section
3. State back to the conversation: "I am at step X.Y, working on [description], next is [next item]"

This ensures the agent has fresh instructions even if earlier chat context was compacted.
The re-read takes ~15 seconds but prevents hours of role drift.

> **Why here and not Level 1?** Level 1 is mechanical (mark items, move marker).
> Role drift only matters at the points where the agent needs to THINK about what to do next —
> which is exactly when Level 2 fires (section boundaries, context 50%, important decisions).

---

### Step 4: Execute Level 3 (EMERGENCY) — extends Level 2

Do everything from Level 2 PLUS:

**4a. Save debug context**

Add to the Progress Log with EMERGENCY status:

```
| N | YYYY-MM-DD | EMERGENCY | saved | Context full at step X.Y: [what was being worked on], [current state], [root cause if found] |
```

The Notes field MUST contain:
- What step/task was in progress
- What the current state of that task is (working? failing? debugging?)
- If debugging: what the suspected root cause is
- What was tried and what worked/didn't work

Example:
```
| 7 | 2026-03-01 | EMERGENCY | saved | Context full at step 2.3: AI summary endpoint test failing, root cause: missing API_KEY in test env, fix identified but not yet applied |
```

**4b. Save open questions**

Add to the Interim Phase Memory:

```
### Interim Memory (collected from checkpoints)
...existing entries...
- [EMERGENCY] Open questions: (1) Should the AI summary use streaming? (2) Is the 500ms timeout enough for production?
- [EMERGENCY] Current task: Fixing test env for AI summary endpoint — the API_KEY needs to be in .env.test
- [EMERGENCY] Uncommitted files: api/routes/ai-summary.ts, tests/ai-summary.test.ts
```

**4c. Git status snapshot**

Record the output of `git status` and `git diff --stat` in the Phase Memory:

```
- [EMERGENCY] Git status: 2 files modified (api/routes/ai-summary.ts, tests/ai-summary.test.ts), 0 untracked
```

**4d. Emergency git commit**

```
git add -A
git commit -m "Phase XX — EMERGENCY: context full at step X.Y — [1 sentence]"
```

**4e. Context Refresh (Critical — post-emergency)**

Same as Level 2 step 3d, but even MORE critical here:

1. Re-read the phase file's `>>> CURRENT <<<` section
2. Re-read the relevant SKILL.md's SKILL LOGIC section
3. Re-read GOLDEN_PRINCIPLES.md (if exists)
4. State back: "EMERGENCY checkpoint completed. I am at step X.Y, the task state is [state], next action is [action]"

At 80% context, compaction is imminent or already happening. This re-read is the LAST CHANCE
to anchor the agent's role before the context window resets.

**4f. CONTEXT_CHAIN emergency entry**

The CONTEXT_CHAIN entry for emergency checkpoints has an extra section:

```markdown
## [YYYY-MM-DD] Session: [Phase name] — EMERGENCY at step X.Y

**Phase:** Phase XX — [name]
**Step:** [start] → [current]
**Status:** emergency

### What happened
- [work summary]

### Next session task
- [EXACTLY what to do first when resuming]

### Emergency context
- **Debug state:** [what was being debugged and findings so far]
- **Uncommitted files:** [list of modified files]
- **Open questions:** [decisions still pending]
```

---

### Step 5: Post-Checkpoint Verification

After any checkpoint level, verify:

**Level 1 verification:**
- [ ] `>>> CURRENT <<<` marker is at the correct position (above first unchecked item)
- [ ] All completed items are marked `[x]`
- [ ] Progress Log has a new row
- [ ] `Current Step:` header matches the actual current item

**Level 2 verification (Level 1 +):**
- [ ] Interim Phase Memory has a new entry tagged with checkpoint letter
- [ ] CONTEXT_CHAIN.md has a new entry at the top
- [ ] Git commit exists with `Phase XX — CP-X:` format
- [ ] Context Refresh: agent re-read phase file current section and stated next step

**Level 3 verification (Level 2 +):**
- [ ] Progress Log has an EMERGENCY row with debug context
- [ ] Interim Phase Memory has `[EMERGENCY]` entries (task state, open questions, git status)
- [ ] CONTEXT_CHAIN has emergency entry with debug state + uncommitted files
- [ ] Emergency git commit exists
- [ ] Context Refresh: agent re-read phase file, SKILL.md, GOLDEN_PRINCIPLES and stated current state

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Level 2+ needs CONTEXT_CHAIN update | `_internal/chain` | At SMART and EMERGENCY checkpoints (Step 3b, 4f) |
| FINAL CHECKPOINT reached | `/blox:done` | The last checkpoint triggers phase close |
| Z7 phase: every commit | Regression check | In Z7, run existing tests after every commit (not just checkpoints) |

---

## VERIFICATION

### Success indicators
- `>>> CURRENT <<<` marker at the correct position in the phase file
- All completed items marked `[x]` — no stale unchecked items
- Progress Log has rows for each checkpoint (including EMERGENCY rows with debug context)
- Level 2+: Interim Phase Memory filled (not empty after SMART/EMERGENCY checkpoint)
- Level 2+: CONTEXT_CHAIN.md updated with concise entry (max 15-20 lines)
- Level 3: Debug context saved (what was being worked on, root cause, open questions)
- Level 3: Uncommitted files listed in Phase Memory
- Git commits follow `Phase XX — CP-X: [description]` format (Level 2+)
- No AI attribution in commits (no `Co-Authored-By`, no `Claude`, no `Opus`)
- A new session can resume within 2 minutes by following the Resumption Protocol

### Failure indicators (STOP and fix!)
- `>>> CURRENT <<<` marker missing or at wrong position (will confuse next session)
- Empty Progress Log after checkpoint (no record of what happened)
- Level 2 checkpoint with empty Interim Phase Memory (lessons lost between sessions!)
- Level 3 without debug context (the most critical information to save, and it's missing)
- Level 3 without git commit (uncommitted work at risk of loss)
- CONTEXT_CHAIN entry > 30 lines (too long — the Resumption Protocol needs fast reads)
- Multiple `>>> CURRENT <<<` markers in the same file (should be exactly one)

---

## EXAMPLES

### Example 1: Level 1 AUTO — Routine save after 5 items

Agent completes items 1.1 through 1.5 in Phase 03.

**Actions:**
1. Mark items 1.1-1.5 as `[x]`
2. Move `>>> CURRENT <<<` above item 1.6
3. Add Progress Log row: `| 1 | 2026-03-02 | 1.1-1.5 | completed | User model schema, migration, and basic CRUD routes |`
4. Update `Current Step: 1.6`

**Time cost:** ~30 seconds. No git commit, no Phase Memory, no CONTEXT_CHAIN update.

### Example 2: Level 2 SMART — Checkpoint marker reached

Agent reaches `--- CHECKPOINT A (Section 1 complete) ---` in the phase file.

**Actions (Level 1 +):**
1. All Level 1 actions (checklist, marker, progress log, current step)
2. Interim Phase Memory: `[CP-A] Zod schemas should be defined BEFORE API routes — it caught 3 type mismatches early`
3. CONTEXT_CHAIN entry: `Phase 03 — CP-A: User model complete, starting API routes`
4. Git commit: `Phase 03 — CP-A: User model schema, migration, and CRUD complete`

**Time cost:** ~1-2 minutes.

### Example 3: Level 3 EMERGENCY — Context 80% full

Agent detects context compression. Currently debugging a test failure at step 2.3.

**Actions (Level 2 +):**
1. All Level 1 + Level 2 actions
2. Progress Log EMERGENCY row: `| 5 | 2026-03-02 | EMERGENCY | saved | Context full at step 2.3: dashboard query test failing, suspected cause: missing JOIN on budget_year column, fix identified but not applied |`
3. Phase Memory `[EMERGENCY]` entries:
   - `[EMERGENCY] Current task: Fix dashboard query test — need to add budget_year JOIN`
   - `[EMERGENCY] Open questions: Should we index budget_year for performance?`
   - `[EMERGENCY] Uncommitted files: backend/routes/dashboard.ts, tests/dashboard.test.ts`
4. CONTEXT_CHAIN emergency entry with debug state + uncommitted files
5. Git commit: `Phase 03 — EMERGENCY: context full at step 2.3 — dashboard query test fix in progress`

**Time cost:** ~2-3 minutes. But it SAVES the next session from starting from scratch.

### Example 4: New session resumes using checkpoint data

A new session starts. The agent follows the Resumption Protocol:

1. Reads START_HERE.md → "Phase 03 — IN PROGRESS — Step 2.3"
2. Reads CONTEXT_CHAIN.md last entry → "EMERGENCY at step 2.3, dashboard query test, missing JOIN"
3. Reads Phase 03 file:
   - `>>> CURRENT <<<` at step 2.3
   - Progress Log last row: EMERGENCY details
   - Interim Phase Memory: learned about the JOIN issue, uncommitted files listed
4. Runs `git status` → sees 2 modified files
5. Runs `git diff` → understands the in-progress changes
6. **Resumes at step 2.3** — applies the JOIN fix, runs tests → PASS → continues

**Total resumption time: ~2 minutes.** Without the checkpoint, this would take 15-30 minutes of rediscovery.

---

## REFERENCES

- `references/templates/phase-template.md` — Checkpoint section format in phase files
- `references/patterns/knowledge-patterns.md` — Architecture invariant: Emergency checkpoint MUST NEVER be skipped
