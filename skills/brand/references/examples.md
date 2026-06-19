# /blox:brand — Worked Examples

Three end-to-end walkthroughs of the brand pipeline. These illustrate the
conversational flow (ONE question per message, max 5 questions, confirmation
gates) and the kind of output each step produces.

---

## Example 1: Restaurant brand (Autopilot from /blox:idea)

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

---

## Example 2: Tech startup (Standalone invocation)

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

---

## Example 3: User can't decide — archetype fallback

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
