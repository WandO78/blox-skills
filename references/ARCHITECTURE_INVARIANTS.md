# Architectural Invariants — wando-skills

> **Purpose:** These rules MUST NEVER be violated by the agent — under any circumstances.
> Every wando skill SKILL.md may reference this file.

---

## Plugin-level invariants

1. **Skill = SKILL.md** — Every skill is a single markdown file (YAML frontmatter + body). No code, no scripts, no binaries.

2. **AUTO-DISCOVERY is mandatory** — Every SKILL.md MUST contain an AUTO-DISCOVERY block (trigger_keywords, trigger_files, trigger_deps).

3. **YAML frontmatter is mandatory** — Every SKILL.md MUST start with YAML frontmatter (name, description, version, user-invocable, allowed-tools).

4. **TDD workflow** — Every skill is built using the `writing-skills` TDD methodology: RED (simulate without skill) → GREEN (minimal SKILL.md) → REFACTOR (close loopholes).

5. **Max 50 items** — A single phase file MUST NOT contain more than 50 checklist items. If more: split into sub-phases.

6. **Superpowers embedding** — Orchestration logic (brainstorming, writing-plans, executing-plans) is EMBEDDED in skills, NOT referenced.

7. **Universal skill referencing** — TDD, debug, verification skills are REFERENCED, not embedded.

8. **TEMPLATES.md is the source of truth** — The ONLY source for the phase file template is TEMPLATES.md Section 1.1.

---

## Project-level invariants (for projects managed by wando-skills)

9. **Phase Memory is ALWAYS written** — On PASS and FAIL alike. Failure lessons are the most valuable knowledge.

10. **Pre-Submission Checklist is the FIRST step** — At close, the 8-point checklist runs FIRST, not the review.

11. **Audit NEVER modifies** — `/wando:audit` is read-only. Only `/wando:init` may modify.

12. **Emergency checkpoint MUST NEVER be skipped** — At context 80%, Level 3 checkpoint is a LIFESAVER.

13. **COMPLETED status ONLY when Exit Criteria + Quality Review PASS** — No shortcuts.

14. **Severity assessment is the ONLY decision field** — The review does NOT decide PASS/FAIL directly.
