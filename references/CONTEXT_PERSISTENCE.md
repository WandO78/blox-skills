# Context Persistence Architecture

> **Problem:** After chat compaction, agents lose their roles, skip skill instructions,
> and revert to default behavior. This is the #1 threat to consistent skill execution.

---

## The Problem

Claude Code conversations have a finite context window. When it fills up, older messages
are compressed (compacted) into summaries. This compression loses:

- Skill instructions loaded at conversation start
- Role assignments ("you are in TDD RED phase")
- Project-specific rules discussed mid-conversation
- Decision context ("we chose X because Y")

What **survives** compaction:
- **CLAUDE.md** — always reloaded (system prompt level)
- **Files on disk** — phase files, SKILL.md, START_HERE.md
- **Last ~2-3 messages** — not yet compacted

## Three-Layer Defense

```
Layer 1: STATIC ANCHORS (CLAUDE.md)
  └── Always in context, zero effort
  └── Contains: re-read rules, critical invariants, active phase pointer

Layer 2: ACTIVE RE-READS (checkpoint skill)
  └── Fires at known safe points (Level 2+)
  └── Re-reads: phase file current section, relevant SKILL.md
  └── Ensures fresh context after every significant save

Layer 3: PASSIVE REMINDERS (hooks)
  └── Automatic, doesn't rely on agent memory
  └── Fires: on session start, periodically
  └── Outputs: current phase, current step, re-read instruction
```

**Why all 3 are needed:**
- CLAUDE.md alone: survives compaction but can't hold full skill logic (~size limit)
- Checkpoint alone: thorough but only fires at checkpoints (~gap between saves)
- Hooks alone: frequent but can only carry short messages (~no depth)

Together: **defense in depth** — if one layer fails, the next catches it.

---

## Layer 1: CLAUDE.md Role Anchors

The `/wando:init` skill generates CLAUDE.md with a **Context Persistence** section.
This section is SHORT (max ~30 lines) and contains:

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
1. [Auto-populated from GOLDEN_PRINCIPLES.md — top 3-5 rules]
2. [These are the rules most likely to be forgotten after compaction]
3. [Keep this list SHORT — max 5 items]
```

**Design constraints:**
- MAX 30 lines — CLAUDE.md is read on every turn, so brevity matters
- Focus on WHEN to re-read, not WHAT the skills say
- Include only the most critical invariants inline
- The active phase file path MUST be kept up-to-date (wando:close updates it)

---

## Layer 2: Checkpoint Context Refresh

The `/wando:checkpoint` skill includes a **Context Refresh** step at Level 2 and Level 3.

After saving checkpoint data (Phase Memory, CONTEXT_CHAIN, git commit), the agent:

1. **Re-reads the phase file's current section** — the `>>> CURRENT <<<` marker and
   the next 3-5 checklist items with their descriptions
2. **Re-reads the relevant SKILL.md** — if the current task maps to a specific skill
   (e.g., writing code → TDD skill, doing review → review skill)
3. **Confirms role** — states back what it's doing and what's next

This ensures that even if compaction happened during the checkpoint, the agent
has fresh context for the next block of work.

**When this fires:**
- Level 2 (SMART): at checkpoint markers, context 50%
- Level 3 (EMERGENCY): at context 80%

**NOT at Level 1** — too frequent, and Level 1 is mechanical (no role drift risk).

---

## Layer 3: Hook-Based Reminders

A shell hook that fires at specific events and outputs a short context reminder.

### Hook Script: `hooks/context-reminder.sh`

```bash
#!/bin/bash
# Context reminder hook for wando-skills
# Outputs current phase and step to keep agent oriented

START_HERE="START_HERE.md"
if [ ! -f "$START_HERE" ]; then
  exit 0  # Not a wando-managed project
fi

# Extract active phase file
ACTIVE_PHASE=$(grep "Aktiv phase" "$START_HERE" 2>/dev/null | sed 's/.*`\(.*\)`.*/\1/')
if [ -z "$ACTIVE_PHASE" ]; then
  exit 0
fi

# Extract current step from phase file
if [ -f "$ACTIVE_PHASE" ]; then
  CURRENT_STEP=$(grep "^## Current Step:" "$ACTIVE_PHASE" 2>/dev/null | head -1)
  PHASE_STATUS=$(grep "^## Status:" "$ACTIVE_PHASE" 2>/dev/null | head -1)
fi

echo "---"
echo "CONTEXT ANCHOR: Active phase: $ACTIVE_PHASE"
echo "$PHASE_STATUS | $CURRENT_STEP"
echo "If you've lost context: re-read the phase file's >>> CURRENT <<< section."
echo "---"
```

### Hook Configuration (`.claude/settings.json`)

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "command": "bash hooks/context-reminder.sh",
        "timeout": 2000
      }
    ]
  }
}
```

**Design constraints:**
- Output MAX 5 lines — this fires on every user message
- Only fires if START_HERE.md exists (wando-managed project)
- Timeout 2s — must not slow down interaction
- Does NOT re-read SKILL.md (too verbose for a hook) — just points to the right file

---

## How This Maps to Existing Skills

| Skill | Change | What it does |
|-------|--------|-------------|
| `/wando:init` | Stage 3a updated | Generates CLAUDE.md WITH Context Persistence section |
| `/wando:checkpoint` | Level 2+3 extended | Context Refresh step after save |
| `/wando:close` | Updates CLAUDE.md active phase | Keeps the pointer current |
| `/wando:plan` | No change | Phase files already have `>>> CURRENT <<<` |
| Hook system | New | Passive context reminder on user messages |

---

## Limitations

1. **Compaction timing is unpredictable** — we can't detect WHEN it happens, only
   prepare for AFTER it happens
2. **CLAUDE.md size matters** — every line adds to token cost on every turn
3. **Hooks can be disabled** — user can turn them off in settings
4. **Re-reads cost tokens** — each re-read of a SKILL.md is ~200-500 tokens
5. **No 100% guarantee** — an agent with severely compacted context may still miss
   a re-read rule in CLAUDE.md. This is a best-effort defense, not a proof.

The goal is not perfection — it's reducing "agent dropout" from ~frequent to ~rare.
