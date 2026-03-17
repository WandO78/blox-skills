---
name: blox-brand
description: "Create brand identity — discover personality, generate color palette, typography, and brand guidelines. Basic mode works standalone, premium with Brand Voice plugin."
user-invocable: true
argument-hint: "[brand name or description]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(brand discovery questions, guidelines, palette descriptions, typography reasoning)
MUST be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Project identity: !`head -20 CLAUDE.md 2>/dev/null`
- Existing brand files: !`ls brand-guidelines.md docs/brand-guidelines.md 2>/dev/null`
- Design tokens: !`ls design-tokens.css design-tokens.json 2>/dev/null`
- Golden Principles: !`head -20 GOLDEN_PRINCIPLES.md 2>/dev/null`
- Tech stack: !`head -10 CLAUDE.md 2>/dev/null`
- Active phase: !`ls plans/ 2>/dev/null`

# /blox:brand

> **Purpose:** Build a complete brand identity from scratch. Guides the user through
> brand personality discovery, then generates a color palette, typography system,
> brand guidelines document, and foundational design tokens. Works standalone in
> basic mode; enhanced with Brand Voice and image-generation plugins when available.
> This is typically the first creative phase in a new project.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-brand
category: domain
complements: [blox-design, blox-check, blox-idea]

### Triggers — when the agent invokes automatically
trigger_keywords: [brand, branding, identity, colors, palette, logo, arculat, szinek]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the project needs brand identity work: color palette, typography,
  brand voice, or design guidelines. Typically the first creative phase after
  /blox:idea scaffolding, or anytime the user wants to define/refine brand identity.
  Do NOT use for layout/component design (use /blox:design), for code implementation
  (use /blox:build), or for logo/asset generation alone (use /blox:image).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| New project needs brand identity | "Define the look and feel for my restaurant site" | No — user invokes |
| `/blox:idea` autopilot Phase 1 | Idea pipeline chains to brand as first creative phase | Yes — idea calls it |
| Rebranding an existing project | "I want to refresh the colors and typography" | No — user invokes |
| No brand guidelines exist yet | Project has code but no design system | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Already have brand guidelines | Don't overwrite existing identity | Review with `/blox:check` (Step 5a) |
| Need page layouts or components | Layout and component design, not brand | `/blox:design` |
| Need logo or image assets | Asset generation, not brand system | `/blox:image` |
| Need to write code | Implementation, not branding | `/blox:build` |
| Need to assess project quality | Assessment, not creation | `/blox:scan` |

---

## BASIC vs PREMIUM MODE

The skill auto-detects available plugins and adjusts its capabilities:

| Feature | Basic (no plugin) | Premium (Brand Voice plugin) |
|---------|-------------------|------------------------------|
| Discovery | Questions in chat | Full brand workshop flow |
| Color palette | AI-suggested based on personality | Research-backed with color theory |
| Guidelines | Markdown document | Interactive enforcement rules |
| Enforcement | Manual in `/blox:check` (Step 5a) | Auto-check in code/content |
| Logo/assets | Text description only | Full generation via image-generation plugin |

**Plugin detection (runs at start):**
```
IF image-generation plugin installed:
  → Enable logo concept generation in Step 6
  → Note: "Logo generation available — I can create logo concepts"

IF Brand Voice plugin installed:
  → Enable enhanced discovery flow
  → Enable enforcement rule generation
  → Note: "Brand Voice plugin detected — enhanced mode active"

IF neither:
  → Basic mode — all core features work, output is markdown-based
  → Note: "Running in basic mode — all brand essentials included"
```

---

## SKILL LOGIC

> **6-step pipeline from brand personality discovery to integrated design tokens.**
> Step 1 is interactive (user answers questions).
> Steps 2-6 are generated (user confirms each before moving on).

### Step 1: BRAND DISCOVERY

Ask questions to understand the brand personality. Adapt based on what the user
already provided in the argument or earlier conversation.

**Questions (in order):**

```
Q1: "What does your brand stand for?"
    → Values, mission, what makes it unique.
    → If the user already described the brand (via argument), extract
      values from the description and ask for confirmation instead.

Q2: "Describe your brand in 3 words."
    → Brand personality essence.
    → Offer examples if the user hesitates:
      "Examples: Bold, Modern, Playful / Warm, Authentic, Trustworthy /
       Clean, Technical, Precise"

Q3: "Who is your target audience?"
    → Demographics (age, profession, location) and psychographics
      (what they care about, how they behave).
    → Multiple choice if user seems unsure:
      a) Young professionals (25-35)
      b) Families and parents
      c) Tech-savvy developers
      d) Business/enterprise users
      e) General public (broad appeal)
      f) Other: [describe]

Q4: "Any brands you admire or want to be similar to?"
    → Inspiration and reference points.
    → Optional — if user says "none" or "not sure", move on.
    → If user names brands, briefly note what makes those brands
      distinctive (colors, voice, feel) to inform later steps.

Q5: "What should your brand NEVER be?"
    → Anti-patterns and boundaries.
    → Examples: "Never corporate/stuffy", "Never childish",
      "Never aggressive", "Never generic".
    → This is critical for guardrails — it shapes the "Don'ts" list.
```

**Rules:**
- **ONE question per message** — never bundle questions
- If the user provided a detailed brand description upfront (argument or first
  message), skip redundant questions — extract answers from what they said
- **Maximum 5 questions** — don't over-interrogate
- If brand identity already exists (files detected in auto-state), ask:
  "I see existing brand guidelines. Want to refine them or start fresh?"

**After discovery — present the Brand Personality Summary:**

```
"Based on what you described, here's your brand personality:

 Brand essence: [3 words from Q2]
 Values: [from Q1]
 Audience: [from Q3]
 Inspiration: [from Q4, or 'None specified']
 Never: [from Q5]

 Does this capture your brand?"
```

**Wait for confirmation before proceeding.**
- "yes" / affirmative → proceed to Step 2
- User corrects something → update and re-confirm
- User wants to restart → go back to Q1

---

### Step 2: COLOR PALETTE GENERATION

Based on the confirmed brand personality, generate a complete color palette.

**Color psychology mapping (use as guidance, not rigid rules):**

```
Bold / Energetic     → Reds, oranges, bright accent colors
Calm / Trustworthy   → Blues, teals, cool tones
Natural / Organic    → Greens, earth tones, warm neutrals
Luxury / Premium     → Deep purples, golds, black + accent
Playful / Creative   → Bright multi-color, unexpected combinations
Clean / Minimal      → Monochrome base, single accent color
Warm / Friendly      → Warm yellows, oranges, soft reds
Tech / Modern        → Electric blues, slate grays, neon accents
```

**Generate the following palette:**

```
PRIMARY
  - Main brand color (the hero color)
  - Hover/active variant (darker)
  - Light variant (for backgrounds)

SECONDARY
  - Accent color (complements primary)
  - Hover/active variant
  - Light variant

NEUTRAL
  - Text primary (near-black, not pure #000)
  - Text secondary (muted)
  - Text on dark backgrounds
  - Background (main page background)
  - Surface (cards, panels)
  - Border (subtle dividers)

SEMANTIC
  - Success (green family)
  - Warning (amber/yellow family)
  - Error (red family)
  - Info (blue family)

DARK MODE (if applicable — generate when project has web/app UI)
  - Background dark
  - Surface dark
  - Text on dark
  - Border dark
  - Primary on dark (adjusted for contrast)
```

**WCAG contrast validation (MANDATORY):**
For each text-on-background combination, verify WCAG AA contrast:
- Normal text: minimum 4.5:1 contrast ratio
- Large text (18px+ or 14px bold): minimum 3:1 contrast ratio
- If a color fails contrast, adjust it until it passes
- Note in output: "All colors meet WCAG AA contrast requirements"

**Output format — dual format (CSS + Tailwind):**

```css
/* brand-colors.css — Generated by /blox:brand */
:root {
  /* Primary */
  --color-primary: #XXXXXX;
  --color-primary-hover: #XXXXXX;
  --color-primary-light: #XXXXXX;

  /* Secondary */
  --color-secondary: #XXXXXX;
  --color-secondary-hover: #XXXXXX;
  --color-secondary-light: #XXXXXX;

  /* Neutral */
  --color-text: #XXXXXX;
  --color-text-secondary: #XXXXXX;
  --color-text-inverse: #XXXXXX;
  --color-background: #XXXXXX;
  --color-surface: #XXXXXX;
  --color-border: #XXXXXX;

  /* Semantic */
  --color-success: #XXXXXX;
  --color-warning: #XXXXXX;
  --color-error: #XXXXXX;
  --color-info: #XXXXXX;
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #XXXXXX;
    --color-surface: #XXXXXX;
    --color-text: #XXXXXX;
    --color-text-secondary: #XXXXXX;
    --color-border: #XXXXXX;
    --color-primary: #XXXXXX; /* adjusted for dark bg */
  }
}
```

```js
// tailwind.config brand colors — merge into existing config
colors: {
  primary: {
    DEFAULT: '#XXXXXX',
    hover: '#XXXXXX',
    light: '#XXXXXX',
  },
  secondary: {
    DEFAULT: '#XXXXXX',
    hover: '#XXXXXX',
    light: '#XXXXXX',
  },
  // ... (full palette)
}
```

**Present the palette visually in chat** (describe each color with name and hex)
and wait for user confirmation before proceeding.

---

### Step 3: TYPOGRAPHY SELECTION

Based on brand personality, suggest appropriate typefaces.

**Typography personality mapping:**

```
Professional / Corporate → Inter, Source Sans Pro, IBM Plex Sans
Elegant / Luxury         → Playfair Display, Cormorant, Libre Baskerville
Modern / Clean           → Inter, Geist, Satoshi, DM Sans
Playful / Creative       → Poppins, Quicksand, Nunito, Fredoka
Technical / Developer    → JetBrains Mono, Fira Code, Source Code Pro
Warm / Friendly          → Nunito, Lato, Open Sans, Rubik
Bold / Impact            → Montserrat, Oswald, Archivo Black
Editorial / Content      → Merriweather, Lora, Source Serif Pro
```

**Generate typography system:**

```
HEADING FONT
  - Primary suggestion (with reasoning tied to brand personality)
  - Alternative 1
  - Alternative 2

BODY FONT
  - Primary suggestion (with readability reasoning)
  - Alternative 1
  - Alternative 2

CODE FONT (if technical product — apps, dashboards, developer tools)
  - Primary suggestion
  - Alternative

FONT SCALE
  - h1: [size]  — Hero / page title
  - h2: [size]  — Section heading
  - h3: [size]  — Subsection heading
  - h4: [size]  — Card/widget heading
  - h5: [size]  — Label heading
  - h6: [size]  — Small heading
  - body: [size] — Default body text
  - small: [size] — Captions, footnotes
  - xs: [size]   — Legal text, timestamps

FONT WEIGHTS
  - Regular: 400
  - Medium: 500
  - Semibold: 600
  - Bold: 700

LINE HEIGHTS
  - Headings: 1.2 - 1.3
  - Body: 1.5 - 1.6
  - Tight (UI labels): 1.2
```

**Output format:**

```css
/* brand-typography.css — Generated by /blox:brand */
:root {
  --font-heading: '[Heading Font]', [fallback stack];
  --font-body: '[Body Font]', [fallback stack];
  --font-code: '[Code Font]', monospace;

  --text-h1: [size];
  --text-h2: [size];
  --text-h3: [size];
  --text-h4: [size];
  --text-h5: [size];
  --text-h6: [size];
  --text-body: [size];
  --text-small: [size];
  --text-xs: [size];

  --leading-heading: 1.25;
  --leading-body: 1.5;
  --leading-tight: 1.2;
}
```

Present the suggestions with reasoning and wait for user confirmation.
If user dislikes a suggestion, offer alternatives and re-confirm.

---

### Step 4: BRAND GUIDELINES DOCUMENT

Generate a comprehensive brand guidelines document based on confirmed
personality, colors, and typography.

**Document structure (saved as `docs/brand-guidelines.md`):**

```markdown
# [Brand Name] — Brand Guidelines

## Brand Story
[1 paragraph — who the brand is, what it stands for, why it exists.
 Written in the brand's own voice.]

## Brand Values
1. [Value 1] — [1-sentence explanation]
2. [Value 2] — [1-sentence explanation]
3. [Value 3] — [1-sentence explanation]
(3-5 values, derived from Step 1 Q1)

## Voice & Tone
**We are:** [3 personality words from Step 1 Q2]
**We sound like:** [description of how the brand communicates]
**Examples:**
- Instead of "[generic/wrong tone example]" → say "[brand-voice example]"
- Instead of "[generic/wrong tone example]" → say "[brand-voice example]"
- Instead of "[generic/wrong tone example]" → say "[brand-voice example]"

## Do's and Don'ts

### Do's
- [Behavior aligned with brand values]
- [Tone directive]
- [Visual directive]
- [Communication directive]

### Don'ts
- [Anti-pattern from Step 1 Q5]
- [Tone to avoid]
- [Visual to avoid]
- [Communication to avoid]

## Color Palette
[Full palette from Step 2 with hex codes, organized by category]

### Usage Rules
- Primary color: Use for CTAs, key actions, links
- Secondary color: Use for accents, highlights, secondary buttons
- Neutral colors: Use for text, backgrounds, borders
- Semantic colors: Use ONLY for their designated purpose (success/warning/error/info)
- NEVER use primary color for error states
- NEVER use more than 3 colors in a single component

## Typography
[Full typography system from Step 3]

### Usage Rules
- Headings: Always use heading font, semibold or bold weight
- Body: Always use body font, regular weight
- Never use more than 2 font families on a single page
- Minimum body text size: 16px (accessibility)
- Maximum line length: 75 characters (readability)

## Logo Usage (if logo exists)
- Minimum size: [specify]
- Clear space: [specify]
- Acceptable backgrounds: [specify]
- Never stretch, rotate, or recolor the logo

## Spacing & Layout Principles
- Base unit: 4px
- Use consistent spacing scale: 4, 8, 12, 16, 24, 32, 48, 64
- Components have consistent internal padding
- Sections have consistent vertical rhythm
```

**Do NOT ask for confirmation at this step** — generate the document based on
already-confirmed choices from Steps 1-3. Present a summary of what was generated.

---

### Step 5: DESIGN SYSTEM BASICS (Design Tokens)

Generate foundational design tokens beyond colors and typography.

**Token categories:**

```
SPACING SCALE (4px base)
  --space-1:  4px    (0.25rem)
  --space-2:  8px    (0.5rem)
  --space-3:  12px   (0.75rem)
  --space-4:  16px   (1rem)
  --space-6:  24px   (1.5rem)
  --space-8:  32px   (2rem)
  --space-12: 48px   (3rem)
  --space-16: 64px   (4rem)

BORDER RADIUS
  --radius-none: 0
  --radius-sm:   4px   (0.25rem)
  --radius-md:   8px   (0.5rem)
  --radius-lg:   16px  (1rem)
  --radius-full: 9999px

SHADOWS
  --shadow-sm:  0 1px 2px rgba(0,0,0,0.05)
  --shadow-md:  0 4px 6px rgba(0,0,0,0.07)
  --shadow-lg:  0 10px 15px rgba(0,0,0,0.10)
  --shadow-xl:  0 20px 25px rgba(0,0,0,0.15)

BREAKPOINTS
  --bp-mobile:  0px      (default — mobile first)
  --bp-tablet:  768px    (md)
  --bp-desktop: 1024px   (lg)
  --bp-wide:    1280px   (xl)

TRANSITIONS
  --transition-fast:   150ms ease
  --transition-normal: 250ms ease
  --transition-slow:   400ms ease

Z-INDEX SCALE
  --z-base:     0
  --z-dropdown: 10
  --z-sticky:   20
  --z-modal:    30
  --z-tooltip:  40
  --z-toast:    50
```

**Basic component patterns (token-based, not full components):**

```css
/* Button pattern tokens */
--btn-padding-x: var(--space-4);
--btn-padding-y: var(--space-2);
--btn-radius: var(--radius-md);
--btn-font-weight: 600;

/* Card pattern tokens */
--card-padding: var(--space-6);
--card-radius: var(--radius-lg);
--card-shadow: var(--shadow-md);
--card-border: 1px solid var(--color-border);

/* Input pattern tokens */
--input-padding-x: var(--space-3);
--input-padding-y: var(--space-2);
--input-radius: var(--radius-md);
--input-border: 1px solid var(--color-border);
--input-focus-ring: 2px solid var(--color-primary);
```

**Output format:** Generate a single `design-tokens.css` file that combines
ALL tokens (colors from Step 2, typography from Step 3, and design tokens
from this step).

Also generate a JSON version for programmatic access:

```json
{
  "colors": { ... },
  "typography": { ... },
  "spacing": { ... },
  "radius": { ... },
  "shadows": { ... },
  "breakpoints": { ... }
}
```

---

### Step 6: SAVE AND INTEGRATE

Save all generated artifacts and update project files.

**Files to create/update:**

```
CREATE:
  docs/brand-guidelines.md    — Brand guidelines from Step 4
  design-tokens.css           — Combined design tokens (colors + typography + tokens)
  design-tokens.json          — JSON version for programmatic access

CREATE (if Tailwind project detected):
  brand.tailwind.config.js    — Tailwind-compatible brand config (merge into tailwind.config)

UPDATE (if exists):
  GOLDEN_PRINCIPLES.md        — Add brand-relevant principles:
    - "All colors from design-tokens.css — no hardcoded hex values in components"
    - "Brand voice follows docs/brand-guidelines.md — review user-facing copy"
    - "WCAG AA contrast minimum for all text-on-background combinations"
    - "Maximum 2 font families per page — heading + body (+ code if technical)"

UPDATE (if exists):
  CONTEXT_CHAIN.md            — Add entry:
    "[date] — Brand identity created by /blox:brand"
    Phase: Brand Identity
    Status: completed
    What happened: Brand personality defined, color palette generated,
      typography selected, guidelines documented, design tokens created.
    Next session task: [depends on plan — typically /blox:design]
```

**Integration with autopilot flow:**
```
IF called from /blox:idea autopilot:
  → Report completion: "Brand identity complete. Ready for next phase."
  → The autopilot flow in /blox:idea handles the phase transition prompt.

IF called standalone:
  → Report completion with summary of all generated files.
  → Suggest: "Run /blox:design to turn these brand tokens into UI components."
```

**Git commit (if git repo exists):**
```
git add docs/brand-guidelines.md design-tokens.css design-tokens.json
git add brand.tailwind.config.js  # if created
git commit -m "feat: brand identity — [brand name] palette, typography, guidelines"
```

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| No write permission (docs/) | Output everything in chat as code blocks | "I can't create files here. Here's your brand system — copy it to your project." |
| No GOLDEN_PRINCIPLES.md | Skip the update, note for later | "Brand principles generated — add them to GOLDEN_PRINCIPLES.md when it exists." |
| User can't decide on colors | Offer 3 pre-built palette options based on personality | "Here are 3 palettes that match your brand. Pick one, or I'll adjust." |
| User can't describe brand | Offer a brand archetype quiz (5 quick A/B choices) | "Let's try a quick exercise — pick which feels more like you:" |
| Plugin detection fails | Continue in basic mode | "Running in basic mode — all brand essentials included." |
| Existing brand files detected | Ask before overwriting | "I see existing brand guidelines. Refine them or start fresh?" |
| WCAG contrast check fails | Auto-adjust colors until compliant | "Adjusted [color] to meet accessibility contrast requirements." |

---

## INVARIANTS

1. **Always ask before generating** — confirm brand personality (Step 1) before any output
2. **Colors meet WCAG AA contrast** — accessibility by default, never optional
3. **Brand guidelines saved to docs/** — persistent artifacts, not just chat output
4. **Design tokens in standard formats** — CSS custom properties AND JSON (+ Tailwind if applicable)
5. **ONE question per message** — never overwhelm the user with multiple questions
6. **Maximum 5 questions** — extract answers from context, skip redundant questions
7. **Never force aesthetic choices** — always present options, always accept user overrides
8. **No hardcoded color values downstream** — all colors reference design tokens
9. **Graceful degradation** — every error has a fallback, nothing blocks the flow

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Brand identity complete (autopilot) | Next phase skill (typically `/blox:design`) | After Step 6 — via /blox:idea autopilot |
| Brand identity complete (standalone) | Suggest `/blox:design` | After Step 6 — user decides |
| Logo concept needed | `/blox:image` | During Step 4 if image-generation plugin available |
| Brand enforcement needed later | `/blox:check` Step 5a | At quality review — checks brand voice consistency |
| Brand guidelines exist at review time | `/blox:check` consumes them | Step 5a reads brand-guidelines.md |
| Design tokens ready for components | `/blox:design` | Next phase — turns tokens into UI components |

---

## VERIFICATION

### Success Indicators
- Brand personality confirmed through max 5 questions, ONE per message
- Color palette includes primary, secondary, neutral, and semantic colors
- All text-on-background color combinations meet WCAG AA contrast (4.5:1 normal, 3:1 large)
- Typography system includes heading, body, and optionally code font with reasoning
- Font scale defined (h1-h6, body, small, xs)
- Brand guidelines document saved to `docs/brand-guidelines.md`
- Design tokens saved to `design-tokens.css` AND `design-tokens.json`
- If Tailwind project: `brand.tailwind.config.js` created
- If GOLDEN_PRINCIPLES.md exists: brand principles added
- If CONTEXT_CHAIN.md exists: completion entry added
- Dark mode variants included (for web/app projects)
- No AI attribution in any generated file

### Failure Indicators (STOP and fix!)
- Colors generated without user confirming brand personality (INVARIANT 1 violation)
- Color combination fails WCAG AA contrast (INVARIANT 2 violation)
- Output only in chat — no files saved (INVARIANT 3 violation)
- Multiple questions in one message (INVARIANT 5 violation)
- Aesthetic choices forced without user consent (INVARIANT 7 violation)
- Hardcoded hex values in guidelines instead of token references
- AI attribution found in generated files

---

## EXAMPLES

### Example 1: Restaurant brand (Autopilot from /blox:idea)

```
/blox:idea autopilot chains to /blox:brand for Phase 1

blox: "Let's define the brand identity for your restaurant site.
       What does Bella Vita stand for? What makes it special?"

User: "It's an authentic Italian family restaurant. We care about
       fresh ingredients, homemade pasta, and making people feel at home."

blox: "Perfect. Describe Bella Vita in 3 words."

User: "Warm, authentic, family-friendly"

blox: "Who are your typical guests?
       a) Young professionals (25-35)
       b) Families and parents
       c) Tourists and food enthusiasts
       d) Business diners
       e) Other"

User: "b) and c)"

blox: "Any restaurants or brands you admire? (optional)"

User: "Olive Garden's family feel, but more authentic and less corporate"

blox: "What should Bella Vita NEVER feel like?"

User: "Never corporate, never fast-food, never pretentious fine dining"

blox: "Here's your brand personality:

       Brand essence: Warm, Authentic, Family-friendly
       Values: Fresh ingredients, homemade tradition, hospitality
       Audience: Families with kids + tourists/food enthusiasts
       Inspiration: Olive Garden's warmth, but more authentic
       Never: Corporate, fast-food, pretentious

       Does this capture Bella Vita?"

User: "yes"

blox: [generates color palette]
      "Your color palette:
       Primary: Terracotta (#C75B39) — warm, earthy, Italian clay
       Secondary: Olive Green (#6B7C3F) — fresh herbs, garden feel
       Neutrals: Cream (#FAF5EF) bg, Espresso (#2D1B0E) text
       Semantic: standard green/amber/red/blue
       All colors meet WCAG AA contrast.

       Does this palette feel right?"

User: "yes"

blox: [generates typography]
      "Typography:
       Headings: Playfair Display — elegant serif, Italian heritage feel
       Body: Lato — warm, readable, pairs well with Playfair
       Font scale: h1 2.5rem down to xs 0.75rem

       Alternatives: Cormorant (headings), Source Sans Pro (body)

       Does this work?"

User: "yes"

blox: [generates brand-guidelines.md, design-tokens.css, design-tokens.json]
      "Brand identity complete!

       Files created:
       - docs/brand-guidelines.md (full guidelines)
       - design-tokens.css (CSS custom properties)
       - design-tokens.json (programmatic access)

       3 brand principles added to GOLDEN_PRINCIPLES.md.

       Brand identity complete. Ready for next phase."

→ /blox:idea autopilot asks: "Continue to Phase 2 (UI Design)?"
```

### Example 2: Tech startup (Standalone invocation)

```
User: /blox:brand "SaaS dashboard for developer teams"

blox: "What does this product stand for?
       What's the core value you're delivering to developer teams?"

User: "We help dev teams ship faster by visualizing their deployment pipeline.
       Think clarity, speed, no BS."

blox: "Describe the brand in 3 words."

User: "Clean, fast, developer-friendly"

blox: "Who's the primary user?
       a) Individual developers
       b) Small dev teams (2-10)
       c) Engineering orgs (10-50+)
       d) DevOps/SRE specifically
       e) Mixed"

User: "b) and c)"

blox: [skips Q4 — user seems decisive, and skips Q5 — implied from personality]

      "Brand personality:

       Brand essence: Clean, Fast, Developer-friendly
       Values: Clarity over cleverness, speed matters, respect for developers
       Audience: Dev teams and engineering orgs (2-50+)
       Never: [implied] Cluttered, slow, patronizing

       Correct?"

User: "yes, and never 'enterprise-y' with fake stock photos"

blox: [updates Never list, generates palette]
      "Color palette:
       Primary: Electric Blue (#3B82F6) — trust, clarity, tech
       Secondary: Slate (#475569) — professional, developer-friendly
       Neutrals: White (#FFFFFF) bg, Near-black (#0F172A) text
       Code: Amber (#F59E0B) for highlights, syntax accents
       Dark mode: full dark theme (developers prefer it)
       All WCAG AA compliant.

       How's this?"

User: "yes"

blox: [generates typography]
      "Typography:
       Headings + Body: Inter — clean, neutral, excellent for dashboards
       Code: JetBrains Mono — industry standard, ligature support
       Scale optimized for data-dense UI (slightly smaller base)

       Sound good?"

User: "yes"

blox: [saves all files]
      "Brand identity complete!

       Files created:
       - docs/brand-guidelines.md
       - design-tokens.css (with dark mode)
       - design-tokens.json

       Tip: Run /blox:design to turn these tokens into dashboard components."
```

### Example 3: User can't decide — archetype fallback

```
User: /blox:brand

blox: "What does your brand stand for?"

User: "I'm not sure yet, I just know I need a website"

blox: "No problem! Let's try a quick exercise.
       Pick which feels more like your brand:

       a) Warm & personal  OR  b) Cool & professional?"

User: "a"

blox: "a) Playful & casual  OR  b) Serious & trustworthy?"

User: "b"

blox: "a) Bold & attention-grabbing  OR  b) Calm & understated?"

User: "b"

blox: "Based on your choices, your brand leans toward:
       Warm, Trustworthy, Understated

       Think: a reliable local business that people trust.
       Colors in the warm neutral space — earth tones, soft blues.

       Does this feel right, or should we adjust?"

User: "that's actually perfect"

blox: [continues with this personality to Step 2]
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Engineering patterns (WCAG enforcement, design tokens)
- `skills/design/SKILL.md` — UI/component design (chained after brand)
- `skills/check/SKILL.md` — Quality review Step 5a (brand voice consistency)
- `skills/image/SKILL.md` — Image/logo generation (optional enhancement)
- `registry/curated-plugins.yaml` — Plugin detection for premium mode
