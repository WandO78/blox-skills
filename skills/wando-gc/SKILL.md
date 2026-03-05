---
name: wando-gc
description: "Run garbage collection on project documentation: check doc freshness, validate cross-links, review TECH_DEBT items, update QUALITY_SCORE, suggest cleanups, verify skill registry consistency. Keeps project metadata healthy over time."
version: "1.0.0"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# /wando:gc

> **Purpose:** Periodic project health maintenance. Checks documentation freshness,
> validates cross-links, reviews tech debt, updates quality score, suggests cleanups,
> and verifies skill registry consistency. NEVER auto-deletes — only suggests.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.
> See: SKILL_COMPOSITION.md "AUTO-DISCOVERY system"

### Identification
name: wando-gc
category: quality
complements: [wando-audit, wando-close]

### Triggers — when the agent invokes automatically
trigger_keywords: [gc, cleanup, freshness, stale, maintenance, health, karbantartas]
trigger_files: [TECH_DEBT.md, QUALITY_SCORE.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke periodically (after phase completions) or on explicit request.
  Checks documentation freshness, validates cross-links, reviews tech debt,
  and suggests cleanups. Does NOT auto-delete — only suggests.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| After phase close | "Clean up after this phase" | No — user/close invokes |
| Periodic maintenance | "Check project health" | No — user invokes |
| Doc freshness concern | "Are the docs still up to date?" | No — user invokes |
| Before major release | "Validate everything is consistent" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| First project assessment | GC assumes existing structure | `/wando:audit` |
| Code quality review | GC is doc-focused, not code | `/wando:review` |
| Project has no docs/ | Nothing to check | `/wando:init` first |

---

## SKILL LOGIC

> **6-step maintenance pipeline. Each step produces a section in the GC Report.**
> The GC report is presented to the user — the user decides what to act on.

### Step 1: Doc Freshness Check

Compare documentation files against their related source files:

```
FOR EACH doc in docs/:
  1. Find related source files (code, config, schema)
     - Use naming convention: docs/api.md <-> src/api/*, docs/db-schema.md <-> prisma/schema.prisma
     - Use cross-references inside the doc (links to source files)
  2. Compare last modified dates:
     - doc.modified_date vs source.modified_date
  3. Classify:
     - FRESH: doc modified AFTER or SAME as source
     - STALE: source modified AFTER doc (doc may be outdated)
     - ORPHANED: doc references files that no longer exist
     - UNTRACKED: source files with no corresponding doc
```

**Output:** Freshness table

```
| Doc | Related Source | Doc Modified | Source Modified | Status |
|-----|---------------|-------------|-----------------|--------|
| docs/api.md | src/api/* | 2026-03-01 | 2026-03-04 | STALE |
| docs/setup.md | docker-compose.yml | 2026-03-04 | 2026-03-02 | FRESH |
```

**Inspiration:** VEMO Data clean `scripts/check-docs-freshness.py` pattern (PROJECT_ANALYSIS M9).

### Step 2: Cross-link Validation

Check all internal cross-references:

```
SCAN all markdown files for:
  1. File references: [text](path/to/file.md) — does the file exist?
  2. Section references: [text](file.md#section) — does the section exist?
  3. Pointer comments: "See: FILE.md" or "-> FILE.md" — does the target exist?

FOR EACH broken link:
  - Record: source file, line number, target, reason (missing file / missing section)
```

**Output:** Broken links list

```
| Source | Line | Target | Issue |
|--------|------|--------|-------|
| CLAUDE.md:45 | 45 | docs/old-spec.md | File not found |
| START_HERE.md:12 | 12 | plans/PHASE_03.md#step-2 | Section not found |
```

### Step 3: TECH_DEBT Review

If `TECH_DEBT.md` exists, review its items:

```
FOR EACH item in TECH_DEBT.md:
  1. Check age: when was it added?
     - > 30 days old -> flag as AGED
     - > 90 days old -> flag as EXPIRED
  2. Check complexity: is it marked as "simple" or "low effort"?
     - Simple + aged = QUICK WIN (suggest resolving now)
  3. Check relevance: does the related code/feature still exist?
     - If removed -> suggest removing the debt item too
```

**Output:** Tech debt summary

```
| Item | Age | Complexity | Status | Recommendation |
|------|-----|-----------|--------|----------------|
| TD-001: Refactor auth middleware | 45 days | Medium | AGED | Schedule for next phase |
| TD-002: Remove unused helper | 12 days | Simple | QUICK WIN | Resolve now |
| TD-003: Migrate old API | 95 days | High | EXPIRED | Re-evaluate: still needed? |
```

### Step 4: QUALITY_SCORE Update

If `QUALITY_SCORE.md` exists, recalculate:

```
QUALITY SCORE FORMULA:
  score = 100 - (20 x FAIL_count) - (10 x CONCERN_count)

WHERE:
  FAIL: Exit criteria not met, tests broken, critical issues
  CONCERN: Stale docs, aged tech debt, broken links

RECALCULATE based on current GC findings:
  - Each STALE doc = 1 CONCERN
  - Each broken link = 1 CONCERN
  - Each EXPIRED tech debt = 1 CONCERN
  - Test failures = FAIL (if test suite exists)
```

### Step 5: Cleanup Suggestions

Generate cleanup suggestions (NEVER auto-execute):

```
SUGGEST (not auto-delete):
  1. ORPHANED docs — docs referencing removed files
  2. EMPTY files — 0 bytes or only whitespace
  3. DUPLICATE content — near-identical files
  4. OBSOLETE phase files — completed phases still in plans/ (not moved to completed/)
  5. Unused config — referenced by nothing
```

**Format:**
```
## Cleanup Suggestions

> These are SUGGESTIONS only. Review each before acting.

- [ ] Delete `docs/old-api.md` — references removed API (orphaned)
- [ ] Move `plans/PHASE_03.md` -> `completed/` (phase completed but not moved)
- [ ] Review `scripts/legacy.sh` — last used 2025-11 (stale?)
```

### Step 6: Skill Registry Consistency

If the project uses wando-skills, verify:

```
COMPARE:
  1. Installed skills (skills/*/SKILL.md files)
  2. CLAUDE.md skill registry (if exists)
  3. Phase file "Skills & Tools" sections

CHECK:
  - Every installed skill is in the registry
  - Every registry entry has a matching SKILL.md
  - Phase files reference only installed skills
  - AUTO-DISCOVERY blocks are consistent with actual triggers
```

---

## GC REPORT FORMAT

The final output is a structured report:

```markdown
# GC Report — [Project Name] — [Date]

## Summary
- Docs checked: [N]
- Fresh: [N] | Stale: [N] | Orphaned: [N]
- Cross-links: [N] valid | [N] broken
- Tech debt: [N] items | [N] quick wins | [N] expired
- Quality Score: [N]/100 (delta: [+/-N] from last)
- Cleanup suggestions: [N]

## 1. Doc Freshness
[Step 1 output table]

## 2. Broken Links
[Step 2 output table]

## 3. Tech Debt Review
[Step 3 output table]

## 4. Quality Score
[Step 4 calculation]

## 5. Cleanup Suggestions
[Step 5 suggestion list]

## 6. Skill Registry
[Step 6 consistency check]
```

---

## INVARIANT

**GC NEVER DELETES OR MODIFIES FILES AUTOMATICALLY.**
Every cleanup action is a SUGGESTION. The user reviews and decides.
The only file GC MAY update: `QUALITY_SCORE.md` (score recalculation).

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| GC finds deep structural issues | `/wando:audit` | If more than surface-level cleanup needed |
| Phase close triggers maintenance | `/wando:close` calls GC | Optional post-close maintenance |
| Quality score needs detailed review | `/wando:review` | If score drops significantly |

---

## VERIFICATION

### Success indicators
- GC Report generated with all 6 sections
- Freshness table shows accurate modified dates
- All cross-links validated (true positives, no false alarms)
- TECH_DEBT items correctly aged and classified
- Quality Score matches formula calculation
- Cleanup suggestions are actionable and specific

### Failure indicators (STOP and fix!)
- GC deleted or modified files without user approval (INVARIANT violation)
- Freshness check uses wrong dates (git vs filesystem)
- False positive broken links (dynamic references, generated files)
- Quality Score miscalculated

---

## EXAMPLES

### Example 1: Healthy Project

**Situation:** Phase 05 just completed. User runs `/wando:gc`.

**GC Report Summary:**
```
Docs checked: 8 | Fresh: 7 | Stale: 1 | Orphaned: 0
Cross-links: 23 valid | 0 broken
Tech debt: 3 items | 1 quick win | 0 expired
Quality Score: 90/100 (delta: 0)
Cleanup suggestions: 1
```

**Action:** User fixes the 1 stale doc, resolves the quick win. Done.

### Example 2: Neglected Project

**Situation:** No GC run for 3 phases. User runs `/wando:gc`.

**GC Report Summary:**
```
Docs checked: 12 | Fresh: 4 | Stale: 6 | Orphaned: 2
Cross-links: 18 valid | 7 broken
Tech debt: 8 items | 3 quick wins | 2 expired
Quality Score: 50/100 (delta: -30)
Cleanup suggestions: 5
```

**Action:** User sees score dropped 30 points. Decides to allocate a maintenance phase.
GC suggests: "Consider running `/wando:audit` for a deeper assessment."
