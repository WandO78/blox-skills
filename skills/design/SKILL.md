---
name: blox-design
description: "Use when the user needs any visual/creative work — UI design, logo, image, video. Routes to the right specialized skill (/blox:ui, /blox:image, /blox:video) after loading brand context and classifying the task."
user-invocable: true
argument-hint: "[describe what you want to design]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
MUST be written in the user's language. The skill logic instructions below are
in English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:design — Design Router

> **Purpose:** Classify design requests and route to the right specialized skill.
> Loads brand context ONCE and passes it to the target skill via conversation context.
> This is a lightweight dispatcher — the actual design work happens in sub-skills.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-design
category: domain
complements: [blox-ui, blox-image, blox-video, blox-brand]

### Triggers — when the agent invokes automatically
trigger_keywords: [design, wireframe, layout, logo, image, video, visual, UI, UX, page design, tervezes, vizualis, oldal, felulet, logó, kep, videó, animacio]
trigger_files: [docs/brand-guidelines.md, design-tokens.css]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke for ANY visual/creative design task. This skill classifies the request
  and routes to the specialized sub-skill. Do NOT invoke sub-skills directly —
  always go through /blox:design for brand context loading and proper routing.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example |
|---------|---------|
| UI/page design needed | "Design the settings page" |
| Logo or brand mark needed | "Create a logo for my project" |
| Image/illustration needed | "Generate a hero image" |
| Video/animation needed | "Create a product demo video" |
| Visual identity phase | Phase 2 from /blox:idea autopilot |
| Ambiguous creative request | "Design something for the landing page" |

## WHEN NOT TO USE

| Case | Use Instead |
|------|-------------|
| Need full brand identity system | `/blox:brand` (colors, typography, voice, tokens) |
| Ready to write code | `/blox:build` |
| Quality review | `/blox:check` |
| Project assessment | `/blox:scan` |

---

## SKILL LOGIC

> **3-step pipeline: context → classify → route.**
> Fast — the router should take under 30 seconds before handing off.

### Step 1: LOAD BRAND CONTEXT

Load brand identity so the target skill starts with full context.

```
1a. Read brand files (if they exist):
    - docs/brand-guidelines.md → personality, voice, colors, typography
    - design-tokens.css / design-tokens.json → color values, spacing, fonts
    - GOLDEN_PRINCIPLES.md → design-relevant rules

    IF found:
      → Summarize in 3-5 lines: "Brand context loaded:
        [Brand name] — [personality]. Colors: [primary], [secondary].
        Typography: [heading font] + [body font]."
    IF NOT found:
      → Note: "No brand context found. The target skill will use defaults
        or ask for preferences."

1b. Check project state:
    - What zone (Z0-Z7)? Check START_HERE.md or active phase
    - What phase is active? Check for phase files
    - What exists already? Check for docs/design/, assets/, src/components/
```

**Proceed immediately to Step 2 — no user interaction needed.**

---

### Step 2: CLASSIFY THE REQUEST

Determine what KIND of design work is needed. Use a 3-tier approach:

**TIER 1 — Keyword match (deterministic, fastest):**

```
UI/UX keywords (→ /blox:ui):
  EN: page, wireframe, layout, component, dashboard, form, screen,
      landing page, settings, sidebar, navigation, table, modal,
      onboarding flow, checkout, UI, UX, responsive
  HU: oldal, felulet, komponens, wireframe, elrendezes, urlap,
      navigacio, tabla, beallitasok, iranytopult, folyamat

IMAGE keywords (→ /blox:image):
  EN: logo, icon, illustration, hero image, graphic, asset,
      brand mark, monogram, social media image, OG image, pattern
  HU: logó, logo, ikon, illusztracio, kep, grafika, hoskep,
      mintazat, arculati elem

VIDEO keywords (→ /blox:video):
  EN: video, animation, motion, storyboard, demo video, explainer,
      screen recording, trailer, reel
  HU: videó, video, animacio, mozgokep, storybord, bemutato,
      kepernyofelvetel
```

**IMPORTANT — "asset FOR context" pattern:**
When an IMAGE keyword is the subject and a UI keyword is only the destination,
this is IMAGE, not COMPOUND:
- "hero image FOR the landing page" → IMAGE (the deliverable is an image)
- "icons FOR the navigation" → IMAGE (the deliverable is icons)
- "illustration FOR the blog" → IMAGE (the deliverable is an illustration)
vs. true COMPOUND:
- "design a landing page WITH a logo" → COMPOUND (two distinct deliverables)
- "create the page AND generate images" → COMPOUND (two tasks)

**TIER 2 — Context disambiguation (when keywords match multiple or none):**

```
IF ambiguous (e.g., "design something for the brand"):
  Check project state:
    - Brand files missing → probably /blox:brand (suggest, don't route)
    - Brand done, no UI yet → probably /blox:ui
    - Brand done, UI done, need assets → probably /blox:image
    - Active phase says "Visual Identity" → probably /blox:image (logo)
    - Active phase says "UI Design" → probably /blox:ui

IF compound request (two DISTINCT deliverables):
  Decompose into ordered sub-tasks:
    1. Logo/image first → /blox:image
    2. Then page/UI → /blox:ui
  Tell the user: "This has two parts. Let's start with the logo,
    then design the landing page."
```

**TIER 3 — Ask the user (last resort):**

```
IF still ambiguous after Tier 1 + 2:
  "What type of design work do you need?

   a) UI/page design — wireframes, components, UX copy
   b) Logo or image — AI-generated visual assets
   c) Video — storyboard, animation, screen recording
   d) Something else — describe it"

  Wait for answer → route accordingly.
```

**Classification output — ONE of:**
- `UI` → route to `/blox:ui`
- `IMAGE` → route to `/blox:image`
- `VIDEO` → route to `/blox:video`
- `BRAND` → suggest `/blox:brand` (don't route, inform user)
- `COMPOUND` → decompose and sequence

---

### Step 3: ROUTE TO TARGET SKILL

Chain to the classified skill using instructional invocation.

```
ANNOUNCE the routing decision:
  "This is [UI/image/video] work. Routing to /blox:[skill]."
  (If brand context was loaded, it's already in the conversation.)

INVOKE the target skill:
  → Use the Skill tool to invoke /blox:ui, /blox:image, or /blox:video
  → The target skill picks up from its own Step 1 (or Step 2 if context
    is already loaded in conversation)

IF COMPOUND:
  → Invoke first skill, wait for completion
  → Then invoke second skill
  → Tell user: "First part done. Now continuing with [next part]."
```

---

## ERROR HANDLING

| Error | Fallback |
|-------|----------|
| Target skill not found | Fall back to basic mode — give text-based guidance |
| User request completely unclear | Ask ONE clarifying question (Tier 3) |
| Brand context files unreadable | Continue without brand — target skill handles defaults |
| Compound request too complex | Break into phases, suggest `/blox:plan` |

---

## INVARIANTS

1. **Always load brand context first** — even if the target skill loads it too (conversation context makes it faster)
2. **Never do design work in the router** — classify and dispatch, nothing else
3. **ONE routing decision per invocation** — don't try to handle multiple unrelated tasks
4. **Compound requests get decomposed** — sequence them, don't parallelize
5. **Respect the user's language** — classification works in any language, output matches user
6. **Fast dispatch** — the router should resolve in under 30 seconds

---

## VERIFICATION

### Success Indicators
- Brand context loaded (or absence noted)
- Request classified correctly into UI/IMAGE/VIDEO/BRAND/COMPOUND
- Target skill invoked with brand context available in conversation
- Compound requests decomposed and sequenced
- User informed of routing decision

### Failure Indicators (STOP and fix!)
- Router doing actual design work (wireframes, prompts, specs) — delegate!
- Wrong classification (logo request routed to UI, page request routed to image)
- Skipping brand context loading
- Asking user to classify when keywords clearly match one category
- Taking more than 1 minute before routing (too slow)

---

## EXAMPLES

### Example 1: Clear UI request (EN)

```
User: /blox:design "admin dashboard with user management"

STEP 1 — Brand Context:
  Brand loaded: DevFlow — Electric Blue, Inter + JetBrains Mono
  "Brand context loaded: DevFlow — modern, technical.
   Colors: Electric Blue (#3B82F6). Typography: Inter + JetBrains Mono."

STEP 2 — Classification:
  Keywords: "dashboard", "user management" → UI (Tier 1 match)

STEP 3 — Route:
  "This is UI/page design work. Routing to /blox:ui."
  → Invoke Skill("blox:ui")
  → /blox:ui picks up with brand context in conversation
```

### Example 2: Logo request (HU)

```
User: /blox:design "keszits egy logot a projekthez"

STEP 1 — Brand Context:
  Brand loaded: MindCraft — Warm Wisdom palette, Outfit + Nunito
  "Brand kontextus betoltve: MindCraft — meleg, bolcs.
   Szinek: Deep Teal (#2A6B6B), Amber (#D4A843)."

STEP 2 — Klasszifikacio:
  Kulcsszavak: "logot" → IMAGE (Tier 1 match)

STEP 3 — Iranyitas:
  "Ez logo/kep feladat. Iranyitom a /blox:image skill-hez."
  → Invoke Skill("blox:image")
```

### Example 3: Compound request (EN)

```
User: /blox:design "create a logo and design the landing page"

STEP 1 — Brand Context:
  Brand loaded.

STEP 2 — Classification:
  Keywords: "logo" → IMAGE + "landing page" → UI
  → COMPOUND: [IMAGE first, then UI]

STEP 3 — Route:
  "This has two parts:
   1. Logo creation (first) — routing to /blox:image
   2. Landing page design (after) — routing to /blox:ui

   Let's start with the logo."
  → Invoke Skill("blox:image")
  → After completion: Invoke Skill("blox:ui")
```

### Example 4: Ambiguous request (HU)

```
User: /blox:design "valami szepet az oldalhoz"

STEP 1 — Brand Context:
  Brand loaded.

STEP 2 — Classification:
  Keywords: "oldalhoz" → lehetne UI, de "valami szepet" nem specifikus
  Context check: brand done, UI files missing → valoszinuleg UI
  → UI (Tier 2 context resolution)

STEP 3 — Route:
  "Ez UI/oldal design feladat. Iranyitom a /blox:ui skill-hez."
  → Invoke Skill("blox:ui")
```

### Example 5: Video request (EN)

```
User: /blox:design "product demo video for the landing page"

STEP 1 — Brand Context:
  Brand loaded.

STEP 2 — Classification:
  Keywords: "demo video" → VIDEO (Tier 1 match)

STEP 3 — Route:
  "This is video work. Routing to /blox:video."
  → Invoke Skill("blox:video")
```

### Example 6: Needs brand first

```
User: /blox:design "design the full visual identity"

STEP 1 — Brand Context:
  No brand files found.

STEP 2 — Classification:
  Keywords: "visual identity" → could be IMAGE (logo) or BRAND (full system)
  Context check: no brand files → needs /blox:brand first

STEP 3 — Suggest:
  "A 'visual identity' requires a brand system first (colors, typography, voice).
   Run /blox:brand to create the brand identity, then come back for
   logo and visual assets."
  → Do NOT route — suggest /blox:brand
```
