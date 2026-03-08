---
name: wando-analyze
description: "Synthesize extracted materials: functional grouping, three-way comparison, corrections table, pattern identification. Use when you have multiple EXTRACT.md files to compare."
version: "2.0.0"
user-invocable: true
disable-model-invocation: true
argument-hint: "<extract files or topic>"
allowed-tools: [Read, Write, Edit, Glob, Grep, Agent]
---

# /wando:analyze

> **FUTURE SKILL** — Functional skeleton with analysis overview.
> Detailed logic to be implemented in a later iteration when
> multi-source synthesis becomes a recurring need.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-analyze
category: learn
complements: [wando-extract]

### Triggers — when the agent invokes automatically
trigger_keywords: [analyze, analysis, synthesis, szintezis, elemzes, compare, osszehasonlitas]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke after extraction (wando:extract) to synthesize across multiple
  source materials. Uses functional grouping, three-way comparison,
  corrections tracking, and pattern identification.
  FUTURE SKILL — detailed logic to be implemented in a later iteration.
auto_invoke: false
priority: optional

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Multiple extracts ready | "Synthesize these 3 API docs" | No — user invokes |
| Cross-source comparison | "Compare old vs new spec" | No — user invokes |
| Pattern identification | "What patterns emerge from these sources?" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Single source material | No synthesis needed | `/wando:extract` is enough |
| Code analysis | Analyze is for documents | `/wando:audit` or `/wando:review` |
| Project health check | Different purpose | `/wando:gc` |

---

## SKILL LOGIC

> **4-step analysis pipeline (Methodology project pattern).**
> Takes EXTRACT.md files as input, produces SYNTHESIS.md as output.

### Step 1: Functional Grouping

Organize content by FUNCTION, not by source:

```
INSTEAD OF:
  Source A says X about auth
  Source B says Y about auth

GROUP AS:
  AUTH:
    - Source A perspective: X
    - Source B perspective: Y
    - Consensus / conflict: [analysis]
```

This prevents source-organized thinking and enables cross-cutting insights.

### Step 2: Three-way Comparison

Compare what EXISTS vs what's DESCRIBED vs what's MISSING:

```
| Feature | Implemented? | Documented? | Status |
|---------|-------------|-------------|--------|
| Auth    | Yes         | Yes         | ALIGNED |
| Caching | Yes         | No          | UNDOCUMENTED |
| Search  | No          | Yes         | MISSING |
| Legacy API | Yes      | Removed     | EXTRA (tech debt?) |
```

Categories:
- **ALIGNED:** Implemented and documented — healthy
- **UNDOCUMENTED:** Exists in code but not in docs — doc debt
- **MISSING:** In spec/docs but not implemented — feature gap
- **EXTRA:** In code but removed from spec — potential tech debt

### Step 3: Corrections Table

Track where sources CONTRADICT each other or reality:

```
| # | Source A says | Source B says | Reality | Resolution |
|---|-------------|-------------|---------|------------|
| 1 | Max 100 items | Max 50 items | Code: 100 | Source B outdated |
| 2 | REST only | GraphQL support | Both exist | Source A outdated |
```

This prevents propagating outdated information.

### Step 4: Pattern Identification

Identify recurring patterns across sources:

```
PATTERNS TO LOOK FOR:
  - HAPPY PATH: The standard flow everyone agrees on
  - DELTA: Where sources diverge (and why)
  - IMPLICIT RULES: Unstated conventions everyone follows
  - ANTI-PATTERNS: Things every source warns against
  - EVOLUTION: How the system changed over time
```

### Output Format: SYNTHESIS.md

```markdown
# [Topic] — Synthesis

> **Sources:** [list of EXTRACT.md files]
> **Analyzed:** [date]

## Functional Groups
[Step 1 output — organized by function]

## Comparison Matrix
[Step 2 output — implemented/documented/missing/extra]

## Corrections
[Step 3 output — contradictions resolved]

## Patterns
[Step 4 output — recurring patterns]

## Recommendations
[Actionable next steps based on analysis]
```

---

## SKILL INTEGRATIONS

| When this happens... | Called after | Context |
|---------------------|-------------|---------|
| Extracts are ready | `/wando:extract` | Analyze the extracted content |
| Analysis reveals project needs | → `/wando:plan` | If analysis suggests new phases/features |
| Analysis reveals gaps | → `/wando:audit` | If gaps need deeper assessment |

---

## VERIFICATION

### Success indicators
- SYNTHESIS.md created with all 4 analysis sections
- Functional grouping (not source-organized)
- Three-way comparison table present
- Corrections tracked with resolution
- Actionable recommendations

### Failure indicators (STOP and fix!)
- Analysis organized by source (not by function)
- Missing corrections table (contradictions untracked)
- No recommendations (analysis without actionable output)
