# DESIGN.md Schema (brand-identity generation template)
# Source format: VoltAgent/awesome-design-md (Google Stitch DESIGN.md). License MIT.
# Use this 9-section structure to GENERATE a brand's DESIGN.md; use exemplars/ as few-shot.

## YAML front-matter (token dictionary — referenced by the prose sections)
The file opens with a `---` fenced YAML block. Real exemplars carry a large,
exhaustive token map (apple.md has ~270 lines of front-matter). Keys:

```
version: alpha            # format version tag
name: <Brand>-design-analysis
description: <2-4 sentence essence of the visual system>
colors:                   # every named color token (primary, ink, body, canvas, surface-*, hairline, on-*, gradients...)
typography:               # type-scale tokens (hero-display, h1..h6, body, caption, mono...) each with size/weight/line-height/tracking/family
rounded:                  # border-radius tokens (none, sm, md, lg, xl, pill, full...)
spacing:                  # spacing-scale tokens (xs..3xl or numeric step scale)
components:               # per-component token overrides (button, card, input, nav, footer...)
```

The nine prose sections below reference these tokens as `{colors.primary}`,
`{typography.body}`, `{rounded.pill}`, `{spacing.lg}`, etc.

## Overview
1-2 paragraphs: the brand's design philosophy and what makes the system distinctive.

## Colors
### Brand & Accent      — primary, accent, interactive/focus colors
### Surface             — canvas, surface tiers, elevated backgrounds
### Text                — ink, body, muted, on-dark/on-primary variants
### Hairlines & Borders — divider/hairline/border tokens
### Brand Gradient      — signature gradient(s), if any

## Typography
### Font Family             — primary, display, mono families
### Hierarchy               — the type scale (display → caption) with size/weight/leading/tracking
### Principles              — how type is applied (tracking, casing, rhythm)
### Note on Font Substitutes — web-safe / fallback stacks

## Layout
### Spacing System        — the spacing scale and how it's applied
### Grid & Container       — column grid, max-widths, gutters
### Whitespace Philosophy  — density and breathing room

## Elevation & Depth
Shadow tiers, layering, and decorative-depth rules (often "Decorative Depth").

## Shapes
### Border Radius Scale    — the `{rounded.*}` tokens in use
### Photography Geometry    — image crop/aspect/mask conventions

## Components
Token-referenced specs per component:
### Top Navigation
### Buttons
### Cards & Containers
### Inputs & Forms
### Footer

## Do's and Don'ts
### Do    — practices that uphold the system
### Don't — anti-patterns that break it

## Responsive Behavior
### Breakpoints         — viewport thresholds
### Touch Targets       — minimum hit sizes
### Collapsing Strategy — how layout reflows
### Image Behavior      — responsive image rules

---

# Optional trailing sections (present in most exemplars — include when generating)
## Iteration Guide   — guidance for refining/extending the system
## Known Gaps        — acknowledged unknowns / unverified assumptions

# Adjustment note
# This SCHEMA was reconciled against the real exemplars (apple/stripe/vercel/notion/
# linear/airbnb/spotify/tesla). Differences from the original 9-section brief:
#  - Front-matter includes a `version: alpha` key, and the token map is far more
#    granular than name/description/colors{}/typography{}/rounded{}/spacing{}/components{}.
#  - Two optional trailing sections (Iteration Guide, Known Gaps) appear in most files.
#  - "Elevation & Depth" subsection is typically labeled "Decorative Depth".
# The nine core sections and their subsection breakdown match the real format exactly.
