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

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| New page or screen needs design | "Design the booking page" | No — user invokes |
| `/blox:idea` autopilot Phase 2 | Idea pipeline chains to design after brand | Yes — idea calls it |
| Component library creation | "Design the component system for the dashboard" | No — user invokes |
| Redesign existing page | "The settings page needs a UX overhaul" | No — user invokes |
| UX copy needed | "Write all the text for the onboarding flow" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Need brand identity first | Brand before design | `/blox:brand` |
| Ready to write code | Implementation, not design | `/blox:build` |
| Need image/logo assets | Asset generation | `/blox:image` |
| Quality review of existing UI | Review, not design | `/blox:check` (Steps 5b, 5c) |
| Project assessment | Assessment, not creation | `/blox:scan` |

---

## DESIGN MODES (auto-detected)

The skill auto-detects available tools and runs in the best available mode:

| Mode | Available tools | What it does |
|------|----------------|-------------|
| **Full** (Stitch + frontend-design) | Stitch MCP + frontend-design plugin | Stitch generates visual designs → user picks → frontend-design converts to production React/Vue code |
| **Stitch** (Stitch only) | Stitch MCP | Generates visual designs (HTML + Tailwind + screenshots), user iterates with variants/edits |
| **Code** (frontend-design only) | frontend-design plugin | Writes production-grade component code directly from specs |
| **Basic** (no plugins) | None | Text-based wireframe descriptions + component specs in markdown |

**Tool detection (runs at start of skill):**
```
CHECK Stitch MCP: look for mcp__stitch tools — any of these 14 tools:
  Project:  create_project, get_project, delete_project, list_projects
  Screens:  list_screens, get_screen, upload_screens_from_images
  Generate: generate_screen_from_text, edit_screens, generate_variants
  Design:   create_design_system, update_design_system, list_design_systems, apply_design_system

CHECK frontend-design: look for installed plugin
CHECK playground: look for installed plugin
CHECK image-generation: look for installed plugin

DECIDE mode:
  Stitch + frontend-design → FULL MODE
  Stitch only              → STITCH MODE
  frontend-design only     → CODE MODE
  Neither                  → BASIC MODE

ANNOUNCE to user:
  FULL:   "Stitch + frontend-design detected — I'll generate visual designs first, then convert to production code."
  STITCH: "Stitch detected — I'll generate visual designs (HTML + screenshots). For production code conversion, install the frontend-design plugin."
  CODE:   "Frontend-design detected — I'll write production-grade components directly. For visual exploration first, set up Google Stitch MCP."
  BASIC:  "Running in basic mode — I'll create detailed wireframe specs and component lists."
```

**Stitch MCP setup (if not configured):**
```
claude mcp add stitch \
  --transport http https://stitch.googleapis.com/mcp \
  --header "X-Goog-Api-Key: API_KEY" \
  -s user

API key: https://stitch.withgoogle.com/settings → API Keys → Create
```

---

### Stitch prompting formula

Structure Stitch prompts with these components for best results:

```
IDEA:    What it is (landing page, dashboard, login screen)
THEME:   Visual style (modern, minimal, dark, high-contrast)
CONTENT: Specific text, sections, components to include
IMAGE:   (optional) Description of desired imagery

GOOD:  "A mobile login screen with email/password fields, social login buttons,
        dark theme with rounded corners and Inter font"

GOOD:  "Product detail page for a Japandi-styled tea store. Neutral, minimal
        colors, black buttons. Soft, elegant font."

BAD:   "Make it look nice" (too vague — Stitch needs specifics)
```

**Edit prompts — one targeted change at a time:**
```
GOOD:  "Make the CTA button larger and change it to brand blue (#3B82F6)"
GOOD:  "Add a navigation bar with Home, Products, About, Contact links"
BAD:   "Completely redesign everything" (too broad — split into steps)
```

---

### Stitch critical agent behaviors

1. **Generation takes 2-5 minutes** — `generate_screen_from_text` and `edit_screens` are slow. Do NOT retry on connection errors or timeouts. Instead, wait and use `get_screen` to check status.
2. **Present suggestions** — If `output_components` in the response contains suggestions, present them to the user before acting. If user accepts, call again with the suggestion as the new prompt.
3. **Download with `curl -L`** — Screen artifact URLs may redirect. Always use `curl -L` to follow redirects when downloading HTML or screenshots.
4. **One change at a time** — When editing screens with `edit_screens`, make one targeted change per call for best results. Multiple simultaneous changes degrade quality.
5. **Design system first** — Always create/apply a design system before generating screens for consistent output. Map brand tokens from /blox:brand directly.

---

### Stitch key parameters

**generate_screen_from_text:**
- `projectId` (required) — from `create_project`
- `prompt` (required) — structured with IDEA + THEME + CONTENT
- `deviceType` — `MOBILE | DESKTOP | TABLET | AGNOSTIC`
- `modelId` — `GEMINI_3_PRO` (higher quality) | `GEMINI_3_FLASH` (faster, iteration)

**generate_variants:**
- `variantCount` — 1 to 5 (default 3)
- `creativeRange` — `REFINE` (subtle) | `EXPLORE` (moderate) | `REIMAGINE` (dramatic)
- `aspects` — which parts to vary: `LAYOUT`, `COLOR_SCHEME`, `IMAGES`, `TEXT_FONT`, `TEXT_CONTENT`

**create_design_system:**
- `displayName` — brand name
- `theme.colorMode` — `LIGHT | DARK`
- `theme.accentColor` — hex color (e.g., `#3B82F6`)
- `theme.font` — `INTER | ROBOTO | POPPINS | DM_SANS | GEIST | PLAYFAIR_DISPLAY | MERRIWEATHER | MONTSERRAT | LATO | OPEN_SANS | SOURCE_CODE_PRO | SPACE_MONO | PLUS_JAKARTA_SANS`
- `theme.roundness` — `SHARP | SLIGHTLY_ROUNDED | ROUNDED | VERY_ROUNDED | PILL`
- `styleGuidelines` — freeform text (brand personality, do's/don'ts)

---

### Full Mode workflow (Stitch + frontend-design)

```
Step 2 (Wireframe/Layout):
  1. Create Stitch project (create_project)
  2. Map brand tokens → Stitch design system:
     - Brand primary color     → theme.accentColor
     - Brand personality       → styleGuidelines (freeform)
     - Brand heading font      → theme.font (closest match from 13 options)
     - Light/dark preference   → theme.colorMode
     - Corner radius style     → theme.roundness
     Call: create_design_system with mapped values
  3. Generate screen (generate_screen_from_text):
     - Use GEMINI_3_PRO for initial generation (higher quality)
     - Set deviceType based on target (DESKTOP for dashboard, MOBILE for app)
     - Use Stitch prompting formula: IDEA + THEME + CONTENT
  4. Generate 3 variants (generate_variants):
     - creativeRange: EXPLORE for first iteration
     - aspects: [LAYOUT, COLOR_SCHEME] to vary visual direction
  5. Present screenshots to user → "Which direction do you prefer? (1/2/3)"
     - If output_components has suggestions → present those too
  6. User picks → iterate with edit_screens if needed
     - Use GEMINI_3_FLASH for fast iteration edits
     - ONE change per edit_screens call
  7. Apply design system to final screens (apply_design_system) for consistency
  8. Download final HTML + screenshot (get_screen → curl -L URLs)

Step 4 (Component Specification):
  → Use frontend-design plugin to convert Stitch HTML to production React/Vue components
  → The Stitch screenshot serves as the visual reference
  → The Stitch HTML serves as the structural reference
  → frontend-design adds: bold typography, motion, accessibility, custom fonts
```

### Stitch Mode workflow (Stitch only)

```
Step 2: Same as Full Mode steps 1-8
Step 4: Design-to-code handoff:
  1. Download HTML: curl -L -o design.html "SCREEN_HTML_URL"
  2. Download screenshot: curl -L -o design.png "SCREEN_SCREENSHOT_URL"
  3. Include both in the design handoff document
  4. Component spec in markdown (like Basic mode) but WITH concrete HTML reference
  → User converts to React/Vue manually, with /blox:build, or with LLM conversion
```

### Code Mode workflow (frontend-design only — current behavior)

```
Step 2: Text-based wireframe descriptions (ASCII layout options)
Step 4: frontend-design generates production components directly
```

### Basic Mode workflow (no plugins — fallback)

```
Step 2: Text-based wireframe descriptions
Step 4: Markdown component specs with props, states, variants, a11y requirements
```

**Additional plugin capabilities (any mode):**
- **playground**: Interactive prototype from any wireframe/design
- **image-generation**: AI-generated UI assets (icons, illustrations, hero images)

**Stitch + image upload workflow (any Stitch mode):**
If user has a reference image (screenshot, Figma export, sketch):
```
1. upload_screens_from_images — upload as base64 to create a reference screen
2. edit_screens — use the uploaded screen as starting point for AI edits
3. Iterate with edit_screens + generate_variants as usual
```

---

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
| Assets needed (icons, illustrations) | `/blox:image` | During Step 2/4 if image-generation plugin available |
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

### Example 1: Restaurant booking page (full pipeline — chained from /blox:idea)

```
/blox:idea autopilot chains to /blox:design for Phase 2 (UI Design)

STEP 1 — Read Brand Context:
  Brand loaded: Bella Vita — Warm, Authentic, Family-friendly
  Colors: Terracotta primary (#C75B39), Olive Green secondary (#6B7C3F)
  Typography: Playfair Display headings, Lato body
  Spacing: 4px base grid from design-tokens.css
  Tech stack: Next.js + Tailwind CSS

  "Brand context loaded — designing within your Bella Vita brand system."

STEP 2 — Wireframe/Layout:
  "Which layout for your booking page?

   a) Centered form — clean, focused
      ┌──────────────────────────────────┐
      │  HEADER (logo + nav)             │
      ├──────────────────────────────────┤
      │       ┌──────────────┐           │
      │       │  Hero image  │           │
      │       ├──────────────┤           │
      │       │ Booking Form │           │
      │       │  date, time  │           │
      │       │  guests, CTA │           │
      │       └──────────────┘           │
      ├──────────────────────────────────┤
      │  FOOTER                          │
      └──────────────────────────────────┘

   b) Split screen — image left, form right
      ┌──────────────────────────────────┐
      │  HEADER (logo + nav)             │
      ├────────────────┬─────────────────┤
      │                │                 │
      │  Hero image    │  Booking Form   │
      │  (restaurant   │  date, time     │
      │   interior)    │  guests, name   │
      │                │  [Book Now]     │
      │                │                 │
      ├────────────────┴─────────────────┤
      │  FOOTER                          │
      └──────────────────────────────────┘

   c) Full-width hero + form below
      ┌──────────────────────────────────┐
      │  HEADER (logo + nav)             │
      ├──────────────────────────────────┤
      │  HERO (full-width image + text)  │
      ├──────────────────────────────────┤
      │  ┌────────────────────────────┐  │
      │  │  Booking Form (wide)       │  │
      │  │  date | time | guests |CTA │  │
      │  └────────────────────────────┘  │
      ├──────────────────────────────────┤
      │  TESTIMONIALS / INFO SECTION     │
      ├──────────────────────────────────┤
      │  FOOTER                          │
      └──────────────────────────────────┘

   Pick one, or describe what you'd prefer."

User: "b) the split screen"

  "Split screen layout — image showcasing the restaurant on the left,
   booking form on the right.

   Responsive behavior:
   - Mobile (< 768px): stacks vertically — image on top, form below
   - Tablet (768-1024px): 40/60 split (narrower image, wider form)
   - Desktop (> 1024px): 50/50 split as designed"

STEP 3 — UX Copy:
  "Here's all the text for your booking page:

   | Location | Element | Text | Notes |
   |----------|---------|------|-------|
   | Header | nav | Home, Menu, Book a Table, About, Contact | 5 nav items |
   | Hero | h1 | 'Your Table Awaits' | Main headline over image |
   | Form | h2 | 'Reserve Your Evening' | Form section heading |
   | Form | label | 'Date' | Date picker label |
   | Form | label | 'Time' | Time picker label |
   | Form | label | 'Guests' | Guest count dropdown label |
   | Form | placeholder | 'Select a date' | Date picker hint |
   | Form | placeholder | 'Choose a time' | Time picker hint |
   | Form | placeholder | 'Number of guests' | Dropdown hint |
   | Form | label | 'Your Name' | Name input label |
   | Form | placeholder | 'Full name' | Name input hint |
   | Form | label | 'Email' | Email input label |
   | Form | placeholder | 'your@email.com' | Email input hint |
   | Form | CTA | 'Book My Table' | Primary submit button |
   | Form | helper | 'We will send confirmation to this email' | Under email |
   | Form | error | 'Please choose a date for your visit' | Missing date |
   | Form | error | 'Please select a time slot' | Missing time |
   | Form | error | 'Please tell us how many guests' | Missing guests |
   | Form | error | 'Please enter your name' | Missing name |
   | Form | error | 'Please enter a valid email address' | Invalid email |
   | Loading | text | 'Checking available tables...' | During API call |
   | Success | h2 | 'Table Booked!' | Confirmation heading |
   | Success | body | 'We have sent a confirmation to [email]. See you [date]!' | Confirmation |
   | Error | text | 'We could not complete your booking. Please try again.' | API failure |
   | Error | action | 'Try Again' | Retry button |
   | Image | alt | 'Candlelit dining room at Bella Vita with rustic wooden tables' | Hero img |
   | Icon | aria-label | 'Close confirmation' | X on success modal |
   | Skip nav | text | 'Skip to booking form' | Screen reader |"

STEP 4 — Component Specification:
  "Component hierarchy:

   BookingPage
   ├── Header
   │   ├── Logo
   │   └── Navigation (5 items)
   ├── SplitLayout
   │   ├── HeroImage
   │   └── BookingForm
   │       ├── DatePicker
   │       ├── TimePicker
   │       ├── GuestSelector
   │       ├── NameInput
   │       ├── EmailInput
   │       └── SubmitButton
   ├── BookingConfirmation (modal)
   └── Footer

   [Full props/states/a11y spec for each component...]"

STEP 5 — Design Handoff:
  "Design handoff saved:
   - docs/design/booking-page.md (full implementation spec)

   Files to create: 8 components, 1 API route, 1 style module
   API endpoints: GET /api/availability, POST /api/bookings
   Design tokens: Terracotta primary, Playfair headings, 4px grid

   Design complete. Ready for next phase."

→ /blox:idea autopilot asks: "Continue to Phase 3 (Build)?"
```

### Example 2: Dashboard design (standalone invocation)

```
User: /blox:design "admin dashboard with user management and analytics"

STEP 1 — Read Brand Context:
  No brand guidelines found.
  Tech stack: Next.js + Tailwind
  "No brand found. Using clean defaults — Inter font, blue primary."

STEP 2 — Wireframe/Layout:
  "Which dashboard layout?

   a) Sidebar navigation — classic dashboard
      ┌────────┬─────────────────────────────┐
      │        │  TOP BAR (search + profile)  │
      │ SIDE   ├─────────────────────────────┤
      │ NAV    │  ┌───────┐ ┌───────┐        │
      │        │  │ Stat  │ │ Stat  │ ...    │
      │ Users  │  └───────┘ └───────┘        │
      │ Stats  │  ┌──────────────────────┐   │
      │ Config │  │  Data Table / Chart  │   │
      │        │  └──────────────────────┘   │
      └────────┴─────────────────────────────┘

   b) Top navigation — more content space
      ┌──────────────────────────────────────┐
      │  TOP NAV (logo + items + profile)    │
      ├──────────────────────────────────────┤
      │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐│
      │  │ Stat │ │ Stat │ │ Stat │ │ Stat ││
      │  └──────┘ └──────┘ └──────┘ └──────┘│
      │  ┌───────────────┐ ┌────────────────┐│
      │  │  Users Table  │ │  Chart Area    ││
      │  └───────────────┘ └────────────────┘│
      └──────────────────────────────────────┘

   c) Collapsible sidebar — best of both
      ┌──┬───────────────────────────────────┐
      │  │  TOP BAR (breadcrumb + actions)   │
      │◀▶├───────────────────────────────────┤
      │  │  KPI cards row                    │
      │  │  ┌─────────────┐ ┌──────────────┐│
      │  │  │ Users table │ │ Activity log ││
      │  │  └─────────────┘ └──────────────┘│
      └──┴───────────────────────────────────┘

   For an admin dashboard with data tables and analytics, I recommend (a)."

User: "a) sidebar"

  [Responsive behavior described]

STEP 3 — UX Copy:
  [Full UX copy table for dashboard: nav labels, stat card labels, table
   headers, empty states for each section, filter labels, action buttons,
   bulk action labels, confirmation dialogs, search placeholder, etc.]

STEP 4 — Component Specification:
  [Full component tree: DashboardLayout, Sidebar, TopBar, StatCard,
   UsersTable, UserRow, UserActions, AnalyticsChart, Pagination,
   SearchInput, FilterDropdown, BulkActionBar, ConfirmDialog...
   Each with props, states, variants, a11y requirements]

STEP 5 — Design Handoff:
  "Design handoff saved: docs/design/admin-dashboard.md

   14 components, 3 API endpoints, full a11y spec.
   Run /blox:build to implement this design."
```

### Example 3: Single component design

```
User: /blox:design "pricing card component"

STEP 1 — Read Brand Context:
  Brand loaded: SaaS product, Electric Blue primary
  "Brand context loaded."

STEP 2 — Wireframe (component-level):
  "Pricing card structure:

   ┌─────────────────────┐
   │  Plan Name          │
   │  $XX /month         │
   │  ─────────────────  │
   │  ✓ Feature 1        │
   │  ✓ Feature 2        │
   │  ✓ Feature 3        │
   │  ✗ Feature 4 (gray) │
   │                     │
   │  [ Choose Plan ]    │
   │                     │
   │  'Most Popular' tag │
   │  (optional)         │
   └─────────────────────┘

   3 variants: Basic, Pro (highlighted), Enterprise
   Responsive: full-width on mobile, side-by-side on desktop"

STEP 3-5 — [UX copy, component spec with props/states/a11y, handoff]

  "Design saved: docs/design/pricing-card.md
   1 component with 3 variants, 5 states, full a11y.
   Run /blox:build to implement."
```

### Example 4: Multi-step flow design

```
User: /blox:design "onboarding flow for new users"

STEP 1 — Read Brand Context:
  [loads brand]

STEP 2 — Flow wireframe:
  "Onboarding flow — 4 steps:

   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
   │ Step 1   │ ──→ │ Step 2   │ ──→ │ Step 3   │ ──→ │ Step 4   │
   │ Welcome  │     │ Profile  │     │ Prefs    │     │ Done!    │
   │ + name   │     │ + avatar │     │ + theme  │     │ → app    │
   └──────────┘     └──────────┘     └──────────┘     └──────────┘
        ↑                                                   │
        └──── 'Start Over' ────────────────────────────────┘

   Progress bar at top shows completion (25%, 50%, 75%, 100%)
   Back button on Steps 2-4
   Skip button on Steps 2-3 (optional fields)

   Responsive: same flow on all devices, form fields stack vertically on mobile"

STEP 3-5 — [UX copy for each step, component specs, handoff with flow logic]
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Engineering patterns (WCAG, design tokens, component architecture)
- `skills/brand/SKILL.md` — Brand identity (consumed by design, runs before it)
- `skills/build/SKILL.md` — Implementation (consumes design handoff, runs after it)
- `skills/check/SKILL.md` — Quality review Steps 5b, 5c (accessibility, design consistency)
- `skills/image/SKILL.md` — Image/asset generation (optional enhancement)
- `registry/curated-plugins.yaml` — Plugin detection for premium mode
