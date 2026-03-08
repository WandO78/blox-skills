---
name: wando-extract
description: "Process source materials through a 3-layer pipeline: deterministic extraction, AI classification, deep knowledge extraction. Use when documents need to become actionable project knowledge."
version: "2.0.0"
user-invocable: true
disable-model-invocation: true
argument-hint: "<source file or URL>"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
---

# /wando:extract

> **FUTURE SKILL** — Functional skeleton with pipeline overview.
> Detailed logic to be implemented in a later iteration when source
> material processing becomes a recurring need.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-extract
category: learn
complements: [wando-analyze]

### Triggers — when the agent invokes automatically
trigger_keywords: [extract, source, material, documentation, spec, process, forras, anyag, feldolgozas]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when new source materials arrive (specs, API docs, legacy system docs,
  external references) and need structured extraction. Based on the Methodology
  project's 3-layer pipeline: deterministic -> AI classification -> deep extraction.
  FUTURE SKILL — detailed logic to be implemented in a later iteration.
auto_invoke: false
priority: optional

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| New source material | "Process this API specification" | No — user invokes |
| External documentation | "Extract key info from these docs" | No — user invokes |
| Legacy system analysis | "Understand this codebase from its docs" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Already extracted material | No need to re-extract | `/wando:analyze` |
| Simple file reading | No pipeline needed | Direct Read tool |
| Codebase exploration | Extract is for documents, not code | `/wando:audit` |

---

## SKILL LOGIC

> **3-layer extraction pipeline (Methodology project pattern).**
> Each layer builds on the previous one, producing progressively deeper understanding.

### Step 1: Deterministic Extraction

Machine-processable content extraction:

```
EXTRACT FROM SOURCE:
  - Headers and document structure (outline)
  - Tables (data, mappings, configurations)
  - Code blocks and examples
  - Numbers, dates, versions
  - URLs and references
  - Definitions and glossary terms

OUTPUT: Raw structured data (headers, tables, code, numbers)
```

### Step 2: AI Classification

Context-aware categorization of extracted content:

```
CLASSIFY EACH EXTRACTED ITEM:
  - GOAL: What the system/spec is trying to achieve
  - RULE: Constraint, requirement, invariant
  - EXAMPLE: Code sample, usage pattern
  - DECISION: Architectural choice with rationale
  - RISK: Known limitation, edge case, warning
  - REFERENCE: External link, dependency, related system

OUTPUT: Categorized content with confidence scores
```

### Step 3: Deep Knowledge Extraction

Implicit knowledge that requires understanding context:

```
EXTRACT IMPLICIT KNOWLEDGE:
  - Unstated assumptions (what's taken for granted?)
  - Edge cases (what happens at boundaries?)
  - Architectural decisions (why THIS approach?)
  - Integration points (how does this connect to other systems?)
  - Failure modes (what can go wrong?)

OUTPUT: Deep insights not directly stated in the source
```

### Output Format: EXTRACT.md

```markdown
# [Source Name] — Extract

> **Source:** [URL or file path]
> **Processed:** [date]
> **Size:** [pages/sections/words]

## Key Facts (Deterministic)
[Step 1 output — tables, numbers, structure]

## Classified Content
### Goals
[Step 2 — GOAL items]

### Rules & Constraints
[Step 2 — RULE items]

### Examples
[Step 2 — EXAMPLE items]

### Decisions
[Step 2 — DECISION items]

## Deep Insights
[Step 3 output — implicit knowledge]

## Open Questions
[Things that need clarification from the source owner]
```

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Extract complete | `/wando:analyze` | To synthesize across multiple extracts |
| Extract reveals project needs | `/wando:init` | If extracted content suggests project structure |

---

## VERIFICATION

### Success indicators
- EXTRACT.md file created in references/ or designated directory
- All 3 pipeline layers executed
- Source metadata recorded (URL, date, size)
- Content classified with clear categories

### Failure indicators (STOP and fix!)
- Extract stayed in chat (not saved to file)
- Unstructured free text (no categorization)
- Missing source metadata (can't trace back to origin)
