---
name: blox-slides
description: "Create presentation decks — MARP markdown slides (charts, dashboards, dark/light themes) or HTML decks, designed on real principles and brand. Use when the user wants slides, a deck, a presentation, or a pitch."
user-invocable: true
argument-hint: "[describe the deck you need]"
---

## Language Protocol
Detect the user's language from the conversation. All deck CONTENT follows THEIR language;
these instructions stay in English.

## Context Discovery
Reads project + brand state at runtime via Read/Glob/Grep/Bash. Pulls brand context
(`docs/brand-guidelines.md`, design tokens) when present so decks are on-brand.

# /blox:slides

> **Purpose:** Build presentation decks that look designed, not defaulted. Applies real
> slide-design principles + a QA gate, pulls brand context, and pulls images/charts from
> /blox:media. Output as MARP markdown (default) or HTML; animated/scroll-embeddable decks
> via HyperFrames.

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-slides
category: domain
complements: [blox-design, blox-brand, blox-media]

### Triggers — when the agent invokes automatically
trigger_keywords: [slides, slide, deck, presentation, pitch, keynote, powerpoint, marp, prezentacio, dia, bemutato]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the user wants a presentation / deck / pitch. Routed from /blox:design for
  presentation tasks, or invoked directly. Uses /blox:brand for identity and /blox:media for
  any generated imagery. For non-slide UI use /blox:ui.
auto_invoke: false
priority: recommended

---

## DESIGN RULES & QA GATE (apply to every deck)
Slides ARE design — ground them in the bundled knowledge, never wing it:
- **Principles & QA gate:** the 21-point checklist at
  `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/qa-checklist.md` is written
  for slide design (one idea/slide, ≤3s glanceable, ≥40% whitespace, ≤4 type sizes, 8pt grid,
  WCAG contrast). Run every deck through it before delivering. Deeper rationale:
  `.../power-design/design-principles.md`.
- **Palettes / font pairings:** query `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/ui-ux-pro-max/search.py`.

## BUILD A DECK
1. **Read 2-3 matching example decks first** from `references/examples/` (22 curated decks: dashboards,
   editorial, how-to, travel, hero…) — they are the quality bar for composition and density.
2. Follow `references/marp-guide.md` for themes (dark/light), components (metric cards, status dots,
   charts), interactive elements, image rules, and export. Default 16:9, generic dark template unless
   brand says otherwise.
3. Pull **brand** context (palette/type/voice) when present so the deck is on-brand. Generate any
   needed images/charts via **/blox:media** (cost shown before paid generation).
4. **Export (MARP):** `npx @marp-team/marp-cli slides.md --pdf --allow-local-files` (also `--pptx`, `--html`).
   Relative image paths only.
5. **Animated / scroll-embeddable deck?** Use HyperFrames (HTML→MP4 / player web component) —
   see `${CLAUDE_PLUGIN_ROOT}/skills/media/references/animation-render.md`.

> Corporate/branded themes (e.g. a company template) are NOT bundled here; if the project has one
> in the private extensions tree, load it from there. Otherwise use the generic templates.

## INVARIANTS
- Read example decks before generating. Run the QA gate before delivering.
- One idea per slide; never overflow (it clips silently).
- Relative image paths only. Pull brand context when it exists.

## REFERENCES
- `references/marp-guide.md` — MARP themes, components, charts, export (vendored from marp-slides v2)
- `references/examples/` — 22 curated reference decks (read before generating)
- `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/qa-checklist.md` — 21-point QA gate
- `skills/media/references/animation-render.md` — HyperFrames for animated/scroll decks
