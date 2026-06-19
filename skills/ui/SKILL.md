---
name: blox-ui
description: "Use when /blox:design routes a UI/UX task here. Wireframes, component specs, UX copy, accessibility, and design handoff for /blox:build. Do NOT invoke directly — use /blox:design which routes here automatically."
user-invocable: false
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(wireframe descriptions, UX copy, component specs, handoff documents) MUST be
written in the user's language. The skill logic instructions below are in English
for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:ui (internal — routed from /blox:design)

> **Purpose:** Turn brand identity and product requirements into concrete UI/UX
> specifications. Wireframing, UX copy, component specs with accessibility,
> and design handoff for `/blox:build`. This skill is invoked by `/blox:design`
> when the task is identified as UI/page/component work. Brand context is already
> loaded in the conversation by the router — proceed directly to Step 2.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-ui
category: domain
complements: [blox-design, blox-brand, blox-build, blox-check]

### Triggers — when the agent invokes automatically
trigger_keywords: [wireframe, layout, component, UX copy, page layout, komponens, felulet, wireframe]
trigger_files: [docs/brand-guidelines.md, design-tokens.css]
trigger_deps: []

### Phase integration
when_to_use: |
  Internal skill — invoked by /blox:design router when the task is UI/UX work.
  Do NOT invoke directly. Use /blox:design which classifies the task and routes here.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

> **Internal skill — not directly user-invocable.** It runs only when `/blox:design`
> classifies a task as UI/UX work and routes here. The user always types `/blox:design`
> (or runs `/blox:idea` autopilot); this skill is never invoked on its own.

| Routed here when /blox:design sees... | Example user request |
|---------------------------------------|----------------------|
| A new page or screen needs design | "Design the booking page" |
| `/blox:idea` autopilot reaches Phase 2 (design) | Idea pipeline chains to design after brand |
| A component library needs to be created | "Design the component system for the dashboard" |
| An existing page needs a UX overhaul | "The settings page needs a UX overhaul" |
| UX copy is needed for a screen/flow | "Write all the text for the onboarding flow" |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Need brand identity first | Brand before design | `/blox:brand` |
| Ready to write code | Implementation, not design | `/blox:build` |
| Need image/logo assets | Asset generation | `/blox:media` |
| Quality review of existing UI | Review, not design | `/blox:check` (Steps 5b, 5c) |
| Project assessment | Assessment, not creation | `/blox:scan` |

---

## DESIGN MODES

This skill produces wireframes, UX copy, and component specs. It runs in one of two
modes depending on whether the `frontend-design` plugin is available. Detection is
trivial — no ceremony: if `frontend-design` is available, use Code Mode; otherwise
use Basic Mode.

| Mode | When | What it does |
|------|------|-------------|
| **Code Mode** | `frontend-design` plugin available | Writes production-grade component code directly from the specs (Step 4 emits real `.tsx` skeletons instead of markdown). |
| **Basic Mode** | No plugins | Text wireframe descriptions + component specs in markdown (props, states, variants, a11y). |

**Visual assets / mockups / images** (icons, illustrations, hero images, logos,
visual mockups) are NOT generated in this skill — they are produced via **`/blox:media`**.
When a design needs generated imagery, hand off to `/blox:media` (see SKILL INTEGRATIONS).

**Missing tools → inform, don't block.** If `frontend-design` is not installed, say so
once and continue in Basic Mode. Never halt the design flow on a missing plugin.

---

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

## SKILL LOGIC

> **5-step pipeline from brand context to implementation handoff.**
> Each step builds on the previous one. User confirms layout (Step 2) before
> detailed specs are generated. Steps 3-5 are generated in sequence.

### Step 1: READ BRAND CONTEXT

Load existing brand identity and project context before designing anything.

**Actions:**

```
1a. Read brand guidelines (if they exist):
    - docs/brand-guidelines.md → brand personality, voice, do's/don'ts
    - design-tokens.css / design-tokens.json → colors, typography, spacing
    - GOLDEN_PRINCIPLES.md → design-relevant rules

    IF brand guidelines exist:
      → Extract: color palette, typography, spacing scale, component tokens
      → Extract: brand personality (warm/cool, formal/casual, etc.)
      → Note: "Brand context loaded — designing within your brand system"

    IF brand guidelines do NOT exist:
      → Note: "No brand guidelines found. I'll use sensible defaults.
        Run /blox:brand first for a cohesive design system."
      → Use neutral defaults: Inter font, blue primary, 4px spacing base
      → Continue — do NOT block

1b. Read project context:
    - CLAUDE.md → tech stack, project type, target audience
    - ARCHITECTURE.md → existing component structure, layout patterns
    - Scan existing components (src/components/ or equivalent):
      → Know the naming convention, file structure, existing patterns

    IF existing components found:
      → Follow their naming convention and structure
      → Note: "Found existing components — matching your patterns"

    IF no existing components:
      → Propose a component structure in Step 5 (handoff)

1c. Understand the design request:
    - Parse the user's argument or message for the design target
    - Identify: is this a full page, a section, a component, or a flow?
    - Identify: what data does this page/component display or collect?

    CLASSIFICATION:
    - PAGE → full page with layout, navigation, sections, multiple components
    - SECTION → part of a page (hero, footer, sidebar, feature grid)
    - COMPONENT → single reusable UI element (card, modal, form, table)
    - FLOW → multi-step user journey (onboarding, checkout, signup)
```

**Output:** Brief summary of brand context loaded and design target identified.
Proceed to Step 2 immediately — no user confirmation needed at this step.

---

### Step 2: WIREFRAME / LAYOUT

Describe the page layout, component hierarchy, and navigation flow.
Present layout options for user to choose.

**For PAGE or FLOW targets:**

```
LAYOUT OPTIONS — present 2-3 choices:

"Which layout fits your [page name]?

  a) [Layout A name] — [1-sentence description]
     [ASCII wireframe sketch, 5-8 lines]

  b) [Layout B name] — [1-sentence description]
     [ASCII wireframe sketch, 5-8 lines]

  c) [Layout C name] — [1-sentence description]
     [ASCII wireframe sketch, 5-8 lines]

Pick one, or describe what you'd prefer."
```

**Common layout patterns to draw from:**

```
DASHBOARD         → Sidebar nav + top bar + content grid (cards, tables, charts)
LANDING PAGE      → Hero + features + social proof + CTA + footer
FORM PAGE         → Header + centered form + helper text + submit
LIST/TABLE PAGE   → Filters/search bar + data table + pagination
DETAIL PAGE       → Breadcrumb + content area + sidebar (related items)
SETTINGS PAGE     → Vertical tabs/sections + form fields per section
CHECKOUT FLOW     → Progress bar + step content + order summary sidebar
AUTH PAGES        → Centered card with form, brand header, social login options
BLOG/CONTENT      → Article content + TOC sidebar + author info + related posts
```

**ASCII wireframe format:**

```
Use box-drawing characters for clear structure:

┌──────────────────────────────────────────┐
│  HEADER / NAV                            │
├──────────┬───────────────────────────────┤
│          │                               │
│ SIDEBAR  │  MAIN CONTENT                 │
│  nav     │  ┌──────┐ ┌──────┐ ┌──────┐  │
│  items   │  │ Card │ │ Card │ │ Card │  │
│          │  └──────┘ └──────┘ └──────┘  │
│          │                               │
├──────────┴───────────────────────────────┤
│  FOOTER                                  │
└──────────────────────────────────────────┘
```

**For COMPONENT targets:**
- Skip layout selection — go directly to component wireframe
- Show the component's visual structure, states, and variants

**For FLOW targets:**
- Show each step as a mini-wireframe with arrows between steps
- Include branching paths (success, error, alternative flows)

**Responsive behavior (MANDATORY):**
After layout selection, describe how it adapts:
```
MOBILE (< 768px):
  - Sidebar collapses to hamburger menu
  - Cards stack vertically (1 column)
  - Table becomes card list

TABLET (768px - 1024px):
  - Sidebar becomes top nav
  - Cards: 2 columns
  - Table: horizontal scroll if needed

DESKTOP (> 1024px):
  - Full layout as designed
  - Cards: 3-4 columns
  - Table: full width with all columns
```

**Wait for user to pick a layout before proceeding.**
- User picks → confirm and proceed to Step 3
- User describes custom layout → adapt and confirm
- User unsure → recommend one based on brand personality and use case

---

### Step 3: UX COPY

Generate all user-facing text for the selected layout. Every piece of text
the user will see on the page/component.

**UX copy categories (generate ALL that apply):**

```
NAVIGATION
  - Menu item labels
  - Breadcrumb labels
  - Tab labels

HEADINGS & TITLES
  - Page title / h1
  - Section headings / h2-h4
  - Card titles
  - Modal titles

BODY TEXT
  - Hero description / subtitle
  - Feature descriptions
  - Empty state descriptions
  - Help text / instructions

ACTIONS
  - Primary CTA button text (e.g., "Book Now", "Get Started")
  - Secondary action text (e.g., "Learn More", "Cancel")
  - Link text (never "Click here" — always descriptive)
  - Submit button text

FORM ELEMENTS
  - Input labels
  - Placeholder text (hint, not label)
  - Helper text (below input, explains format or requirements)
  - Validation error messages (specific, not "Invalid input")
  - Success messages

STATUS & FEEDBACK
  - Loading state text (e.g., "Finding available tables...")
  - Empty state text (e.g., "No reservations yet. Book your first table!")
  - Error state text (e.g., "We couldn't load the menu. Please try again.")
  - Success state text (e.g., "Table booked! Check your email for confirmation.")
  - Toast/notification messages

ACCESSIBILITY TEXT (invisible but critical)
  - Image alt text descriptions
  - ARIA labels for icon buttons (e.g., aria-label="Close dialog")
  - Screen reader announcements for dynamic content
  - Skip navigation link text
```

**UX copy rules:**
- Match the brand voice from brand-guidelines.md (if loaded in Step 1)
- Be specific — "Book a Table" not "Submit", "3 seats left" not "Low availability"
- Error messages: say what happened + what the user can do next
- Empty states: explain what could be here + how to create it
- Loading states: say what's happening, not just a spinner
- Never use jargon the target audience wouldn't understand
- Button text uses verbs: "Save Changes", "Send Message", "Create Account"
- Avoid negative framing: "Keep editing" not "Don't leave"

**Output format — structured table:**

```markdown
### UX Copy — [Page/Component Name]

| Location | Element | Text | Notes |
|----------|---------|------|-------|
| Hero | h1 | "Find Your Perfect Table" | Primary headline |
| Hero | subtitle | "Book a table at Bella Vita in seconds" | Supports h1 |
| Hero | CTA button | "Book Now" | Primary action |
| Form | label | "Party size" | Dropdown label |
| Form | placeholder | "Select number of guests" | Dropdown hint |
| Form | error | "Please select how many guests" | Validation |
| Empty state | heading | "No reservations yet" | First-time user |
| Empty state | body | "Book your first table and we'll save it here" | Encourages action |
| Loading | text | "Finding available tables..." | During API call |
| Error | text | "We couldn't check availability right now. Please try again." | API failure |
| Image | alt | "Interior of Bella Vita restaurant with candlelit tables" | Hero image |
| Icon button | aria-label | "Close booking dialog" | X button on modal |
```

**Do NOT ask for confirmation at this step** — generate based on already-confirmed
layout and brand context. Present the full table and proceed to Step 4.
If the user wants to adjust copy later, they can.

---

### Step 4: COMPONENT SPECIFICATION

List every component needed with props, states, variants, and accessibility
requirements. This is the technical spec that `/blox:build` will implement.

**For each component, specify:**

```markdown
### [ComponentName]

**Purpose:** [1-sentence what it does]
**Location:** [where in the page hierarchy]

#### Props
| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| title | string | yes | — | Card heading text |
| variant | 'primary' \| 'secondary' | no | 'primary' | Visual variant |

#### States
| State | Description | Visual Change |
|-------|-------------|---------------|
| default | Normal display | — |
| hover | Mouse over interactive area | Background lightens, cursor pointer |
| loading | Data being fetched | Skeleton placeholder, pulse animation |
| empty | No data to display | Empty state message with CTA |
| error | Failed to load | Error message with retry button |
| disabled | Not interactive | Reduced opacity (0.5), no pointer events |

#### Variants (if applicable)
| Variant | When | Visual Difference |
|---------|------|-------------------|
| primary | Main CTA | Brand primary color background |
| secondary | Alternative action | Outlined, transparent background |
| destructive | Delete/remove actions | Error color background |

#### Accessibility Requirements
- [ ] Role: [button | link | dialog | alert | navigation | etc.]
- [ ] ARIA label: "[specific label text]"
- [ ] Keyboard: [Tab to focus, Enter/Space to activate, Escape to close]
- [ ] Focus indicator: [2px solid primary color ring]
- [ ] Screen reader: [announces state changes, e.g., "Loading products"]
- [ ] Color contrast: [text on background meets 4.5:1 minimum]
- [ ] Touch target: [minimum 44x44px for mobile]
```

**Component hierarchy — show the tree structure:**

```
Page
├── Header
│   ├── Logo
│   ├── Navigation
│   │   ├── NavItem (x5)
│   │   └── MobileMenuButton
│   └── UserMenu
├── Main
│   ├── HeroSection
│   │   ├── Heading
│   │   ├── Subtitle
│   │   └── CTAButton
│   ├── ContentGrid
│   │   └── ContentCard (x6)
│   │       ├── CardImage
│   │       ├── CardTitle
│   │       ├── CardDescription
│   │       └── CardAction
│   └── EmptyState (conditional)
└── Footer
    ├── FooterLinks
    └── Copyright
```

**Accessibility checklist (MANDATORY for every design):**

```
GLOBAL ACCESSIBILITY — verify these for the full design:

[ ] Heading hierarchy: h1 → h2 → h3 (no skipped levels)
[ ] Skip navigation: "Skip to main content" link as first focusable element
[ ] Landmark regions: <header>, <nav>, <main>, <footer> used correctly
[ ] Focus order: logical tab order matches visual reading order
[ ] Color independence: information not conveyed by color alone
[ ] Motion: animations respect prefers-reduced-motion
[ ] Text resize: content readable at 200% zoom without horizontal scroll
[ ] Touch targets: all interactive elements minimum 44x44px on mobile
```

**Premium mode enhancement (frontend-design plugin):**
If the frontend-design plugin is available, generate actual component skeletons
instead of markdown specs:
```
→ Generate TypeScript component file with:
  - Props interface
  - Accessible markup (ARIA attributes built-in)
  - CSS module or Tailwind classes from design tokens
  - All states handled (loading, empty, error)
  - Responsive breakpoints
→ Note: "Component skeleton generated — /blox:build will add business logic"
```

**Present the full component spec and wait for user confirmation.**
- User confirms → proceed to Step 5
- User wants changes → adjust and re-present
- User wants to skip components → still generate the handoff (Step 5) with the layout

---

### Step 5: DESIGN HANDOFF

Create the implementation spec that `/blox:build` will use. This is the bridge
between design and code — everything a developer needs to build it.

**Handoff document structure (saved as `docs/design/[page-name].md`):**

```markdown
# Design Handoff: [Page/Component Name]

> **Designed by:** /blox:design
> **Date:** YYYY-MM-DD
> **Status:** Ready for implementation
> **Implements:** [phase file reference if applicable]

## Layout

[ASCII wireframe from Step 2, finalized version]

### Responsive Behavior
- **Mobile (< 768px):** [description]
- **Tablet (768-1024px):** [description]
- **Desktop (> 1024px):** [description]

## Component Hierarchy

[Tree from Step 4]

## File Structure

Exact files to create/modify:

| File | Type | Action | Description |
|------|------|--------|-------------|
| src/components/BookingPage.tsx | page | CREATE | Main booking page layout |
| src/components/BookingForm.tsx | component | CREATE | Reservation form with validation |
| src/components/TimeSlotPicker.tsx | component | CREATE | Available time slot grid |
| src/components/BookingConfirmation.tsx | component | CREATE | Success confirmation modal |
| src/styles/booking.module.css | styles | CREATE | Page-specific styles |
| src/lib/api/bookings.ts | API | CREATE | Booking API client functions |

## Data Flow

[Describe how data moves through the components:]
- Where does data come from? (API, props, state, context)
- What API endpoints are needed? (GET, POST, PUT, DELETE)
- What client-side state is managed? (form state, UI state, server state)
- What validation rules apply? (Zod schemas, form validation)

## API Endpoints Needed

| Method | Endpoint | Purpose | Request | Response |
|--------|----------|---------|---------|----------|
| GET | /api/availability | Check available slots | ?date=YYYY-MM-DD&guests=N | TimeSlot[] |
| POST | /api/bookings | Create reservation | { date, time, guests, name, email } | Booking |

## UX Copy Reference

[Link to Step 3 UX copy table — or inline if component-scoped]

## Design Tokens Used

[List specific tokens from design-tokens.css that apply:]
- Primary color: var(--color-primary) for CTAs and active states
- Background: var(--color-background) for page, var(--color-surface) for cards
- Spacing: var(--space-4) for component padding, var(--space-6) for section gaps
- Typography: var(--font-heading) for h1-h3, var(--font-body) for text
- Radius: var(--radius-md) for cards, var(--radius-lg) for modals

## Accessibility Spec

[Consolidated from Step 4 — the complete a11y requirements:]
- Keyboard navigation flow diagram
- ARIA landmark map
- Screen reader announcement list
- Focus management for modals/dialogs
- Color contrast verification table

## Design QA Gate
> Ran against power-design qa-checklist.md (21 rules). Result: [PASS / fixed: list rule #s].
> Key thresholds confirmed: contrast ≥4.5:1, 8pt spacing grid, ≤4 type sizes, whitespace ≥40%.

## Implementation Notes

[Practical notes for /blox:build:]
- Start with [component name] — it has no dependencies
- [Component X] depends on [API endpoint Y] — build the API first
- Use [pattern/library] for [specific behavior]
- Watch out for [known complexity or edge case]
```

**Files to create/update:**

```
CREATE:
  docs/design/[page-name].md    — Full design handoff document

UPDATE (if exists):
  GOLDEN_PRINCIPLES.md          — Add design-relevant principles:
    - "All spacing from design tokens — no arbitrary px/rem values"
    - "Every interactive element has keyboard accessibility"
    - "Every image has meaningful alt text"
    - "Color contrast meets WCAG AA (4.5:1 normal text, 3:1 large text)"

UPDATE (if exists):
  CONTEXT_CHAIN.md              — Add entry:
    "[date] — UI/UX designed by /blox:design"
    Phase: UI/UX Design
    Status: completed
    What happened: [page/component] designed with layout, UX copy,
      component specs, accessibility requirements, and handoff spec.
    Next session task: /blox:build to implement the design
```

**User review via Plannotator (MANDATORY):**
```
After saving the handoff document:
  → Skill("plannotator:plannotator-annotate", args: "/full/path/docs/design/[page-name].md")
  → User reviews the design spec in the browser, annotates sections
  → Process feedback, edit file, re-open if needed
  → When approved: commit and proceed
```

**Integration with autopilot flow:**
```
IF called from /blox:idea autopilot:
  → Report completion: "Design complete. Ready for next phase."
  → The autopilot flow in /blox:idea handles the phase transition prompt.

IF called standalone:
  → Report completion with summary of all generated files.
  → Suggest: "Run /blox:build to implement this design."
```

**Git commit (if git active):**
```
git add docs/design/[page-name].md
git commit -m "feat: UI/UX design — [page/component name] layout, components, handoff"
```

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| No brand guidelines | Use sensible defaults (Inter, blue, 4px grid) | "No brand found. Using defaults — run /blox:brand for a custom design system." |
| No design tokens | Generate inline token references with placeholder values | "No design tokens found. I'll reference where tokens should go." |
| No write permission (docs/) | Output everything in chat as code blocks | "Can't create files here. Here's your design spec — copy it to your project." |
| User can't choose layout | Recommend one based on content type and audience | "Based on your content, I recommend [layout]. Here's why:" |
| No tech stack detected | Generate framework-agnostic component specs | "No framework detected. Specs are framework-agnostic — adapt to your stack." |
| Plugin detection fails | Continue in basic mode | "Running in basic mode — full design specs included." |
| Too many components for one design | Split into sections, design incrementally | "This is a large design. Let's start with [section], then continue." |
| Existing design docs found | Ask before overwriting | "I see an existing design for [page]. Update it or start fresh?" |

---

## INVARIANTS

1. **Read brand guidelines before designing** — if they exist, use them (never design in a vacuum)
2. **Every interactive element has keyboard accessibility** — tab, enter, escape, arrow keys as appropriate
3. **Every image has alt text specification** — meaningful for content images, empty for decorative
4. **Color contrast meets WCAG AA** — 4.5:1 for normal text, 3:1 for large text
5. **Mobile-first responsive design** — unless user explicitly specifies desktop-only
6. **UX copy matches brand voice** — if brand guidelines exist, copy follows them
7. **Component specs are implementable** — every prop has a type, every state has a visual description
8. **Design handoff includes file paths** — `/blox:build` knows exactly what files to create
9. **Graceful degradation** — every error has a fallback, nothing blocks the flow
10. **No AI attribution in any generated file** — no Co-Authored-By, Claude, Opus, Anthropic

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Design complete (autopilot) | Next phase skill (typically `/blox:build`) | After Step 5 — via /blox:idea autopilot |
| Design complete (standalone) | Suggest `/blox:build` | After Step 5 — user decides |
| No brand identity exists | Suggest `/blox:brand` | Step 1 — if no brand files found |
| Assets needed (icons, illustrations) | `/blox:media` | During Step 2/4 via /blox:media |
| Interactive prototype requested | Playground plugin | During Step 2 if playground plugin available |
| Production component code needed | Frontend-design plugin | During Step 4 for enhanced component generation |
| Design quality review needed later | `/blox:check` Steps 5b, 5c | At quality review — checks a11y and design consistency |
| Design tokens ready for components | `/blox:build` consumes handoff | Next phase — implements the design spec |

---

## VERIFICATION

### Success Indicators
- Brand context loaded before designing (or defaults noted if absent)
- Layout options presented with ASCII wireframes for user to choose
- Responsive behavior described for mobile, tablet, and desktop
- UX copy generated for ALL user-facing text: headings, buttons, errors, empty states, loading states
- UX copy includes accessibility text: alt texts, ARIA labels, screen reader announcements
- Component spec includes props (typed), states, variants, and accessibility requirements
- Every interactive component has keyboard navigation specified
- Every image has alt text specification in the UX copy table
- Component hierarchy tree shows parent-child relationships
- Design handoff saved to `docs/design/[page-name].md`
- Handoff includes: file paths, data flow, API endpoints, design tokens, a11y spec
- If GOLDEN_PRINCIPLES.md exists: design principles added
- If CONTEXT_CHAIN.md exists: completion entry added
- No AI attribution in any generated file

### Failure Indicators (STOP and fix!)
- Designing without loading brand context first (INVARIANT 1 violation)
- Interactive element without keyboard accessibility spec (INVARIANT 2 violation)
- Image without alt text specification (INVARIANT 3 violation)
- Text-on-background color combination without WCAG AA contrast (INVARIANT 4 violation)
- Desktop-only design without responsive behavior (INVARIANT 5 violation)
- UX copy that contradicts brand voice guidelines (INVARIANT 6 violation)
- Component spec without typed props or state descriptions (INVARIANT 7 violation)
- Handoff document without file paths (INVARIANT 8 violation)
- Vague component descriptions like "add appropriate styling" — be specific
- AI attribution found in generated files

---

## EXAMPLES

Worked examples (full 5-step pipeline runs): see `references/examples.md`
— a restaurant booking page (chained from /blox:idea), an admin dashboard
(standalone), a single component, and a multi-step flow.

---

## REFERENCES

- `references/examples.md` — worked examples of the full 5-step design pipeline
- `references/patterns/knowledge-patterns.md` — Engineering patterns (WCAG, design tokens, component architecture)
- `references/design-knowledge/ui-ux-pro-max/` — searchable design DB (palettes, font pairings, UX rules, charts) via `search.py`
- `references/design-knowledge/power-design/design-principles.md` — design principles (hierarchy, grid, type, color)
- `references/design-knowledge/power-design/qa-checklist.md` — 21-point QA gate (run before handoff)
- `skills/brand/SKILL.md` — Brand identity (consumed by design, runs before it)
- `skills/build/SKILL.md` — Implementation (consumes design handoff, runs after it)
- `skills/check/SKILL.md` — Quality review Steps 5b, 5c (accessibility, design consistency)
- `skills/media/SKILL.md` — Media generation (images, video, audio)
- `registry/requirements.yaml` — blox companions + media/build prerequisites (premium-mode tools)
