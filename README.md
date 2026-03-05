# wando-skills

Agent-first development skill library for Claude Code.

Phase-based planning, automatic checkpoints, severity-aware quality review,
and structured project memory — so the agent NEVER loses work, and project
quality is guaranteed from day one.

## Installation

```
/plugin add wando/wando-skills
```

## Skills

| Skill | Description | Priority |
|-------|-------------|----------|
| `/wando:init` | Project setup — 4-stage pipeline (Brainstorm → Decisions → Scaffolding → Phase Gen) | Required for new projects |
| `/wando:plan` | Phase file generator — checklist, checkpoints, exit criteria, AUTO-DISCOVERY skill scan | Required for phase planning |
| `/wando:checkpoint` | 3-level save — AUTO (every 5 items), SMART (at markers), EMERGENCY (context 80%) | Automatic |
| `/wando:review` | Quality review — invariants, tests, Golden Answers, Quality Score (S1-S4 severity) | Required at phase close |
| `/wando:close` | Phase completion — Pre-Submission Checklist, severity decision, Phase Memory (ALWAYS!) | Required at phase end |
| `/wando:audit` | Project assessment — tech stack, zone, gap analysis, quality baseline (READ-ONLY) | Required for retrofit |
| `/wando:gc` | Maintenance — doc freshness, cross-link validation, TECH_DEBT review, cleanup suggestions | Recommended |
| `/wando:chain` | CONTEXT_CHAIN.md update — session context chain (max 20-30 lines per entry) | Automatic |
| `/wando:dispatch` | Parallel work — Leader-Worker pattern, worktree isolation, merge ordering | Optional |
| `/wando:extract` | Source material processing — 3-layer pipeline (FUTURE) | Optional |
| `/wando:analyze` | Source material synthesis — functional grouping, 3-way comparison (FUTURE) | Optional |

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
4. **AUTO-DISCOVERY** — skills automatically find each other
5. **Resumption Protocol** — new session resumes within 2 minutes

## Contributing

To write a new skill, follow the `writing-skills` (superpowers) TDD methodology:

1. **RED** — Simulate the task WITHOUT the skill, document where it breaks down
2. **GREEN** — Write the minimal SKILL.md (YAML frontmatter + AUTO-DISCOVERY + logic)
3. **REFACTOR** — Pressure tests, close loopholes

Every SKILL.md MUST contain:
- YAML frontmatter (name, description, version, user-invocable, allowed-tools)
- AUTO-DISCOVERY block (trigger_keywords, category, priority)
- WHEN TO USE / WHEN NOT TO USE tables
- SKILL LOGIC (step-by-step)
- VERIFICATION (success/failure indicators)

## License

MIT
