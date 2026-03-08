# wando-skills

Agent-first development skill library for Claude Code.

Phase-based planning, automatic checkpoints, severity-aware quality review,
and structured project memory — so the agent NEVER loses work, and project
quality is guaranteed from day one.

## Installation

```
/plugin add wando/wando-skills
```

## Skills (v2.0)

| Skill | Description |
|-------|-------------|
| `/wando:init` | Initialize a new project or retrofit an existing one with full project infrastructure |
| `/wando:plan` | Generate structured phase files with hierarchical checklists, checkpoints, exit criteria, and auto-discovered skills |
| `/wando:checkpoint` | Save progress at 3 levels: AUTO (every 5 items), SMART (at checkpoints or context 50%), EMERGENCY (context 80%) |
| `/wando:review` | Run quality review: architectural invariants, tests, Golden Answers, Quality Score (S1-S4 severity) |
| `/wando:close` | Complete a phase with severity-aware verification, Phase Memory, and meta-file updates |
| `/wando:audit` | Assess any project's current state without modifying it: tech stack, zone (Z0-Z7), gap analysis, quality baseline |
| `/wando:dispatch` | Coordinate parallel agent work using Leader-Worker pattern with worktree isolation |
| `/wando:gc` | Run garbage collection on project docs: freshness check, cross-link validation, TECH_DEBT review |
| `/wando:chain` | Update CONTEXT_CHAIN.md with a concise session entry. Called automatically by checkpoints and close |
| `/wando:extract` | Process source materials through a 3-layer pipeline: deterministic, AI classification, deep extraction |
| `/wando:analyze` | Synthesize extracted materials: functional grouping, three-way comparison, pattern identification |

## v2.0 Features

| Feature | What it does | Skills |
|---------|-------------|--------|
| `disable-model-invocation` | Skill runs without an extra model call — pure template execution | init, close, dispatch, extract, analyze |
| `context: fork` | Skill runs in an isolated agent that cannot modify files | audit |
| `argument-hint` | Autocomplete hints when invoking skills | All 11 skills |
| `!`command`` injection | Dynamic project state loaded at invocation time (active phase, quality score, etc.) | checkpoint, plan, close, chain, review, gc, audit, init |
| `${CLAUDE_SKILL_DIR}` | Portable reference file loading (phase template) | plan, init |
| `$ARGUMENTS` | User arguments passed into skill body | review |

## How It Works

```
/wando:init          Project setup (or /wando:audit → /wando:init for retrofit)
       ↓
/wando:plan          Phase planning (checklist, checkpoints, skills)
       ↓
  [work happens]     Agent follows the phase checklist
       ↓
/wando:checkpoint    Automatic saves (3 levels)
       ↓
/wando:review        Quality review (NORMAL or THOROUGH mode)
       ↓
/wando:close         Phase completion (severity → COMPLETED or FAILED)
       ↓
/wando:gc            Maintenance (periodic)
```

## Project Structure (created by init)

```
[project]/
├── CLAUDE.md              ← Project identity + Relevant Skills
├── START_HERE.md          ← Phase tracker + Resumption Protocol
├── CONTEXT_CHAIN.md       ← Session context chain
├── ARCHITECTURE.md        ← Layer diagram + tech stack
├── GOLDEN_PRINCIPLES.md   ← Invariants
├── QUALITY_SCORE.md       ← Quality matrix
├── TECH_DEBT.md           ← Open tech debt
├── plans/                 ← Active phase files
├── completed/             ← Completed phases
└── failed/                ← Failed phases (with Phase Memory!)
```

## Key Principles

1. **Phase Memory is ALWAYS written** — especially on FAIL (failure lessons are the most valuable knowledge)
2. **Max 50 items per phase** — if more: split into sub-phases
3. **`>>> CURRENT <<<` marker** — the agent always knows where it left off
4. **AUTO-DISCOVERY** — skills automatically find each other at runtime
5. **Resumption Protocol** — new session resumes within 2 minutes
6. **Dynamic state injection** — skills auto-detect project state via `!`command`` blocks
7. **Graceful degradation** — all injections use `2>/dev/null`, skills work in any project

## Skill Architecture

```
~/.claude/skills/
├── wando-init/SKILL.md          ← Project bootstrap
├── wando-plan/SKILL.md          ← Phase planning
├── wando-checkpoint/SKILL.md    ← Progress saves
├── wando-review/SKILL.md        ← Quality review
├── wando-close/SKILL.md         ← Phase completion
├── wando-audit/SKILL.md         ← Read-only assessment (forked agent)
├── wando-dispatch/SKILL.md      ← Parallel coordination
├── wando-gc/SKILL.md            ← Doc maintenance
├── wando-chain/SKILL.md         ← Session continuity
├── wando-extract/SKILL.md       ← Source extraction
├── wando-analyze/SKILL.md       ← Source synthesis
└── wando-references/            ← Shared templates
    ├── PHASE_TEMPLATE.md
    ├── SKILL_TEMPLATE.md
    ├── ARCHITECTURE_INVARIANTS.md
    ├── CONTEXT_PERSISTENCE.md
    └── KNOWLEDGE_PATTERNS.md
```

## Contributing

To write a new skill, follow the `writing-skills` (superpowers) TDD methodology:

1. **RED** — Simulate the task WITHOUT the skill, document where it breaks down
2. **GREEN** — Write the minimal SKILL.md (YAML frontmatter + AUTO-DISCOVERY + logic)
3. **REFACTOR** — Pressure tests, close loopholes

Every SKILL.md MUST contain:
- YAML frontmatter (name, description, version, user-invocable, argument-hint)
- AUTO-DISCOVERY block (trigger_keywords, category, priority)
- WHEN TO USE / WHEN NOT TO USE tables
- SKILL LOGIC (step-by-step)
- VERIFICATION (success/failure indicators)

## License

MIT
