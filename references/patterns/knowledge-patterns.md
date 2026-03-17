# Knowledge Patterns

> Auto-applied by blox skills during phase generation and execution.
> These patterns encode lessons from real-world projects.

## Pattern 1: Layered Context Model
The agent builds understanding in layers:
1. Static (files, configs)
2. Dynamic (git history, recent changes)
3. Inferred (patterns, conventions)
4. Tacit (lessons from Phase Memory, Golden Principles)
5. Session (current conversation context)
6. Cross-session (CONTEXT_CHAIN continuity)

**Applied by:** /blox:scan, /blox:plan

## Pattern 2: Decision Waterfall
Handle decisions in priority order:
1. Happy path (most common case)
2. Soft limit (warn but continue)
3. Fallback (alternative approach)
4. Graceful degradation (reduced functionality)

**Applied by:** /blox:build, /blox:fix

## Pattern 3: Progressive Disclosure
Don't overwhelm. Show what's needed when it's needed:
- CLAUDE.md is a table of contents, not a manual
- Phase files show the current section, not all sections
- Autopilot shows y/n, not technical details

**Applied by:** /blox:idea, /blox:plan

## Pattern 4: Fix Environment Not Agent
When something goes wrong, add guardrails — don't add retries:
- Lint rules > documentation
- Pre-commit hooks > review comments
- Type checking > runtime validation

**Applied by:** /blox:fix, /blox:build

## Pattern 5: Mechanical Enforcement
Automate quality. Don't rely on memory:
- Checklist items are checkboxes, not prose
- Exit criteria have verification commands
- Checkpoints are auto-triggered, not manual

**Applied by:** All skills

## Pattern 6: Momentum Protection
Don't break flow for trivial issues:
- Log tech debt, don't fix it now
- Skip non-blocking concerns
- Checkpoint saves context, not decisions

**Applied by:** _internal/checkpoint, /blox:build

## Pattern 7: Repo Knowledge Check
Always read before acting:
- ARCHITECTURE.md — what exists
- Phase Memories — what was learned
- GOLDEN_PRINCIPLES — what must not be violated
- TECH_DEBT — what is known but deferred

**Applied by:** /blox:plan, /blox:build, /blox:check

## Pattern 8: Verification Before Completion
Never claim done without evidence:
- Run tests, show output
- Check exit criteria, show results
- Fresh evidence, not cached assumptions

**Applied by:** /blox:done, /blox:check

## Pattern 9: Phase Memory as Knowledge
Every completed phase captures lessons:
- What worked (Golden Principles)
- What didn't (Antipatterns)
- What remains (Tech Debt)
- This knowledge feeds future phases

**Applied by:** /blox:done, /blox:plan

## Pattern 10: Context Preservation
Defend against context loss:
- CONTEXT_CHAIN.md — session continuity
- >>> CURRENT <<< marker — position tracking
- Emergency checkpoint — last line of defense
- Phase Memory — knowledge that survives sessions

**Applied by:** _internal/checkpoint, _internal/chain

## Pattern 11: Scope Discipline
Keep phases focused:
- Maximum 50 checklist items
- One clear directive per phase
- If it grows, split it
- Exit criteria define "done"

**Applied by:** /blox:plan

## Pattern 12: Quality as a Score
Make quality visible and trackable:
- Formula: 100 - (20 x FAILs) - (10 x CONCERNs)
- Floor: 0 (never negative)
- Trend over time (QUALITY_SCORE.md history)
- Score interpretation: 80+ Healthy, 50-79 Needs Work, <50 Critical

**Applied by:** /blox:check, _internal/cleanup

## Pattern 13: Graceful Degradation
Everything works at basic level, plugins enhance:
- No plugin → basic mode (always functional)
- Plugin installed → premium mode (better results)
- API key missing → warn, don't block
- Error → log, continue, suggest fix

**Applied by:** _internal/detect, all domain skills
