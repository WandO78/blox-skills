# Blox Knowledge Cornerstones — Implementation Plan (Plan 2 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Wire the vendored design-knowledge (Plan 1) into the two knowledge cornerstones — `blox:ui` (design rules + searchable DB + mandatory QA gate) and `blox:brand` (DESIGN.md schema/exemplars + brand library + extract-from-URL) — keeping both SKILL.md lean via progressive disclosure.

**Architecture:** Both skills are existing markdown skills in `skills/{ui,brand}/SKILL.md`. We ADD small, lean sections that point the agent at the shared knowledge under `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/` (loaded on demand — NOT inlined), and update each REFERENCES list. We preserve every skill's YAML frontmatter, `## AUTO-DISCOVERY` block, Language Protocol, and existing Step structure. No knowledge text is duplicated into the SKILL.md.

**Tech Stack:** Markdown skills (blox convention). Runtime file access via `${CLAUDE_PLUGIN_ROOT}` (the established plugin convention — used by blox hooks). Validation via `scripts/validate.sh`. Branch: `feat/design-media-consolidation` (already checked out).

**Spec:** `docs/superpowers/specs/2026-06-15-blox-design-media-consolidation-design.md`
**Depends on:** Plan 1 (vendored knowledge present under `references/design-knowledge/`).

---

## Runtime path convention (applies to all inserted content)

Skills reference shared knowledge at runtime via `${CLAUDE_PLUGIN_ROOT}`:
- Search DB: `python3 "${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/ui-ux-pro-max/search.py" "<query>" [-d <domain>]`
- Read a knowledge file: `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/<file>` etc.

Domains for `search.py -d`: `color | typography | ux | chart | style | product` (omit `-d` for auto-detect).

---

## File Structure
- Modify: `skills/ui/SKILL.md` (add DESIGN KNOWLEDGE & QA GATE section; add QA-gate gate to Step 5; update REFERENCES)
- Modify: `skills/brand/SKILL.md` (add EXTRACT-FROM-URL option + knowledge grounding; update REFERENCES)

> No new files. This plan only edits two existing skills to consume Plan 1's knowledge.

---

## Task 1: blox:ui — design knowledge grounding + mandatory QA gate

**Files:** Modify `skills/ui/SKILL.md`

- [ ] **Step 1: Read the current skill to find the anchors**

Run: `sed -n '1,55p;430,445p;780,795p;1283,1291p' skills/ui/SKILL.md` (and read more around any anchor as needed). Confirm these anchors exist: `## SKILL LOGIC` (~line 437), `### Step 5: DESIGN HANDOFF` (~line 784), `## REFERENCES` (~line 1283). Do NOT alter the frontmatter or `## AUTO-DISCOVERY` block.

- [ ] **Step 2: Insert the DESIGN KNOWLEDGE & QA GATE section immediately BEFORE `## SKILL LOGIC`**

Insert this block (verbatim) as a new section right before the `## SKILL LOGIC` heading:

```markdown
## DESIGN KNOWLEDGE & QA GATE

Ground every design decision in the bundled knowledge base. Load it ON DEMAND — never inline it.

**1. Query the design DB before deciding** (palettes, font pairings, UX rules, chart types, styles):
```
python3 "${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/ui-ux-pro-max/search.py" "<intent>" [-d color|typography|ux|chart|style]
```
Use the returned real palettes / font-pairings / UX rules to justify choices instead of inventing them. Example: before picking colors for a fintech dashboard, run `search.py "fintech dashboard" -d color`.

**2. Apply the design principles** — read the relevant rules on demand from
`${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/design-principles.md`
(visual hierarchy, Gestalt, modular type scale, 8pt grid, contrast, layout).

**3. QA GATE (MANDATORY before Step 5 handoff):** run every UI output through
`${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/qa-checklist.md`
(21 numbered rules with thresholds — e.g. whitespace ≥40%, WCAG contrast ≥4.5:1 body / ≥3:1 large, 8pt grid spacing, ≤4 type sizes per slide/screen). Fix any failing rule before handoff. The gate result is recorded in the handoff doc (Step 5).
```

- [ ] **Step 3: Add the QA-gate record to the Step 5 handoff document template**

In `### Step 5: DESIGN HANDOFF`, inside the handoff document structure (the fenced `markdown` block starting `# Design Handoff:`), add a new section line. After the `## Accessibility Spec` section reference (or near the end of the template, before `## Implementation Notes`), insert:

```markdown
## Design QA Gate
> Ran against power-design qa-checklist.md (21 rules). Result: [PASS / fixed: list rule #s].
> Key thresholds confirmed: contrast ≥4.5:1, 8pt spacing grid, ≤4 type sizes, whitespace ≥40%.
```

If the exact `## Accessibility Spec` / `## Implementation Notes` anchors differ, place the `## Design QA Gate` block as the last section inside the handoff template fenced block. Keep it inside the ```markdown fenced block.

- [ ] **Step 4: Update the REFERENCES section**

In `## REFERENCES`, add these three bullets (keep the existing bullets):

```markdown
- `references/design-knowledge/ui-ux-pro-max/` — searchable design DB (palettes, font pairings, UX rules, charts) via `search.py`
- `references/design-knowledge/power-design/design-principles.md` — design principles (hierarchy, grid, type, color)
- `references/design-knowledge/power-design/qa-checklist.md` — 21-point QA gate (run before handoff)
```

- [ ] **Step 5: Verify the knowledge paths resolve and the validator passes**

```bash
cd /Users/wando/Documents/dev/skill/wando-skills
# the referenced files exist in the repo (CLAUDE_PLUGIN_ROOT resolves here at install time):
test -f references/design-knowledge/ui-ux-pro-max/search.py && echo "search ok"
test -f references/design-knowledge/power-design/qa-checklist.md && echo "qa ok"
# new sections are present:
grep -q "## DESIGN KNOWLEDGE & QA GATE" skills/ui/SKILL.md && echo "section ok"
grep -q "## Design QA Gate" skills/ui/SKILL.md && echo "gate ok"
# skill still valid:
./scripts/validate.sh | tail -3
```
Expected: all four echoes print, and `VALIDATION PASSED`. If validate FAILS on blox-ui, you broke frontmatter/AUTO-DISCOVERY — revert that edit and reinsert without touching them.

- [ ] **Step 6: Commit**

```bash
cd /Users/wando/Documents/dev/skill/wando-skills
git add skills/ui/SKILL.md
git commit -m "feat(ui): ground design in vendored knowledge DB + mandatory QA gate"
```

---

## Task 2: blox:brand — extract-from-URL + knowledge-grounded palette/typography

**Files:** Modify `skills/brand/SKILL.md`

- [ ] **Step 1: Read the current skill to find the anchors**

Run: `sed -n '1,56p;108,200p;310,400p;887,893p' skills/brand/SKILL.md`. Confirm anchors: `## SKILL LOGIC` (~line 108), `### Step 1: BRAND DISCOVERY` (~line 114), `### Step 2: COLOR PALETTE GENERATION` (~line 186), `### Step 3: TYPOGRAPHY SELECTION` (~line 310), `## REFERENCES` (~line 887). Do NOT alter frontmatter or `## AUTO-DISCOVERY`.

- [ ] **Step 2: Add the EXTRACT-FROM-URL option immediately AFTER the `## SKILL LOGIC` heading (before `### Step 1: BRAND DISCOVERY`)**

Insert this block verbatim:

```markdown
### Step 0: EXTRACT FROM AN EXISTING BRAND (optional fast path)

If the user references an existing brand/site to match or evolve (e.g. "make it feel like
stripe.com", "we already have a site at <url>"), extract its identity instead of asking
discovery questions from scratch:

1. Follow the recipe at `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/extract-brand.md`
   (uses Firecrawl's branding extraction to pull palette, typography, and voice from a URL).
2. Map the result into the brand guidelines (Step 4) and design tokens (Step 5).
3. Confirm the extracted identity with the user, then refine.

If no existing brand is referenced, skip this and go to Step 1 (discovery from scratch).
Use `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/design-md/exemplars/` (real DESIGN.md
files for apple, stripe, linear, vercel, notion, spotify, airbnb, tesla) as few-shot reference,
and `.../power-design/brands/` (73 brand-style files) as a broader library.
```

- [ ] **Step 3: Ground Step 2 (palette) in the searchable DB**

At the start of `### Step 2: COLOR PALETTE GENERATION`, insert this paragraph (after the heading, before the existing content):

```markdown
**Ground the palette in real data first.** Query the design DB for proven palettes that fit
the brand's product type and personality, then adapt — don't invent from zero:
```
python3 "${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/ui-ux-pro-max/search.py" "<product type + personality>" -d color
```
Use the returned palettes (with their WCAG-checked foreground/background pairings) as the
starting point, then tailor to the brand. Carry contrast compliance (≥4.5:1 body text) into the tokens.
```

- [ ] **Step 4: Ground Step 3 (typography) in the searchable DB**

At the start of `### Step 3: TYPOGRAPHY SELECTION`, insert this paragraph (after the heading):

```markdown
**Ground type choices in proven pairings first.** Query the design DB for font pairings that
fit the brand personality, then adapt:
```
python3 "${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/ui-ux-pro-max/search.py" "<personality / use case>" -d typography
```
Each result includes the Google Fonts URL + CSS import + Tailwind config. Prefer a returned
pairing over an ad-hoc choice; record the rationale.
```

- [ ] **Step 5: Update the REFERENCES section**

In `## REFERENCES`, add (keep existing bullets):

```markdown
- `references/design-knowledge/design-md/SCHEMA.md` — 9-section DESIGN.md brand template
- `references/design-knowledge/design-md/exemplars/` — real brand DESIGN.md exemplars (few-shot)
- `references/design-knowledge/power-design/brands/` — 73-brand style library
- `references/design-knowledge/power-design/extract-brand.md` — extract identity from a URL (Firecrawl)
- `references/design-knowledge/ui-ux-pro-max/` — searchable palettes / font pairings via `search.py`
```

- [ ] **Step 6: Verify and commit**

```bash
cd /Users/wando/Documents/dev/skill/wando-skills
test -f references/design-knowledge/power-design/extract-brand.md && echo "extract ok"
test -d references/design-knowledge/design-md/exemplars && echo "exemplars ok"
grep -q "### Step 0: EXTRACT FROM AN EXISTING BRAND" skills/brand/SKILL.md && echo "step0 ok"
grep -c 'search.py' skills/brand/SKILL.md   # expect >= 2 (palette + typography)
./scripts/validate.sh | tail -3
git add skills/brand/SKILL.md
git commit -m "feat(brand): add extract-from-URL + ground palette/type in vendored DB"
```
Expected: echoes print, `search.py` count ≥ 2, `VALIDATION PASSED`.

---

## Task 3: Cross-skill validation

- [ ] **Step 1: Full validator + reference integrity**

```bash
cd /Users/wando/Documents/dev/skill/wando-skills
./scripts/validate.sh | tail -3
# every ${CLAUDE_PLUGIN_ROOT} knowledge path referenced in ui/brand resolves to a real repo file:
grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/references/design-knowledge/[A-Za-z0-9_./-]+' skills/ui/SKILL.md skills/brand/SKILL.md \
  | sed 's#${CLAUDE_PLUGIN_ROOT}/##' | sort -u \
  | while read p; do [ -e "$p" ] && echo "OK  $p" || echo "MISSING  $p"; done
```
Expected: `VALIDATION PASSED`; every path prints `OK` (no `MISSING`). A `MISSING` means a typo in a path — fix the SKILL.md reference to match the real vendored path.

- [ ] **Step 2: Confirm both commits exist**

```bash
cd /Users/wando/Documents/dev/skill/wando-skills && git log --oneline -2
```
Expected: the two commits from Tasks 1 and 2.

---

## Self-Review (completed by plan author)

- **Spec coverage:** spec §4/§5 "blox:ui ← power-design principles + 21-point QA gate + ui-ux-pro-max DB" → Task 1; "blox:brand ← awesome-design-md schema/exemplars + power-design brand lib + extract-brand recipe + grounded palette/typography" → Task 2. Lean SKILL.md + progressive disclosure (§1) → all inserted blocks point to `${CLAUDE_PLUGIN_ROOT}` references, none inline the knowledge.
- **Placeholder scan:** the only bracketed tokens are inside fenced template examples the agent fills at runtime (`[PASS / fixed: list rule #s]`, `<intent>`, `<url>`) — these are runtime placeholders in skill instructions, not plan gaps. All inserted section content is complete.
- **Type/path consistency:** every runtime path uses the identical prefix `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/` and matches the actual Plan-1 vendored layout (`ui-ux-pro-max/search.py`, `power-design/{design-principles.md,qa-checklist.md,extract-brand.md,brands/}`, `design-md/{SCHEMA.md,exemplars/}`); Task 3 Step 1 mechanically verifies each path resolves.
