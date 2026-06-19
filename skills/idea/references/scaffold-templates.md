# /blox:idea — Scaffold File Templates (Step 4)

Content specification for each file generated during project scaffolding. The source of
truth for overall structure is `references/templates/project-scaffold.md`; this file
details what goes INTO each scaffolded file. Step logic (when/whether to scaffold, git
handling) stays in SKILL.md.

## Files to create

```
1. CLAUDE.md
   Content:
   - Project name (from vision)
   - 1-2 sentence description (from Step 2 scope summary)
   - Tech stack (from Step 3)
   - Language setting: language: [detected code]
   - Installed Skills section (blox-skills listed)
   - Conventions section (empty — to be filled during development)

2. START_HERE.md
   Content:
   - Resumption Protocol (from template)
   - Empty Phase Tracker table (phases will be filled in Step 5)
   - Active Phase pointer (will be set in Step 5)

3. CONTEXT_CHAIN.md
   Content:
   - Header with "Newest entry first" instruction
   - First entry: "[today's date] — Project created from /blox:idea"
     Phase: Setup
     Status: completed
     What happened: Project scaffolded from idea: "[idea summary]"
     Next session task: Begin Phase 1

4. ARCHITECTURE.md
   Content:
   - Overview section (high-level description from vision)
   - Layer Diagram (based on tech stack — adapt layers to actual stack)
   - Tech Stack table (technology + rationale for each layer)
   - Key Decisions table (empty — AD-1 will be first entry)

5. GOLDEN_PRINCIPLES.md
   Content:
   - Universal principles (always included):
     1. "Evidence before assertions — never claim done without verification"
     2. "Fix the environment, not the agent — lint rules > documentation"
     3. "Corrections are cheap, waiting is expensive — ship at 80%, fix at next checkpoint"
   - Tech-specific principles (based on stack):
     Next.js: "Server components by default, client components only when needed"
     Supabase: "Row-level security on every table — no exceptions"
     FastAPI: "Pydantic models for all request/response schemas"
     TypeScript: "Strict mode always — no any types without documented reason"
     React Native: "Test on both platforms — iOS behavior != Android behavior"
     Python: "Type hints on all function signatures"
     Go: "Error handling at every call site — no silent failures"
     (add relevant principles based on the chosen tech stack)

6. QUALITY_SCORE.md
   Content:
   - Formula: 100 - (20 x FAILs) - (10 x CONCERNs)
   - Current Score: 100/100 (fresh start)
   - History table with first entry: today's date, 100, "Project created"

7. TECH_DEBT.md
   Content:
   - Open table (empty — no debt yet)
   - Resolved table (empty)
```

## Directories to create

```
docs/        — Project documentation
plans/       — Active phase files
completed/   — Completed phases (with Phase Memory)
failed/      — Failed phases (Phase Memory mandatory)
```
