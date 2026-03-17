---
name: blox-image
description: "Generate images with AI — logos, UI assets, illustrations. Multi-engine support with auto-selection."
user-invocable: true
argument-hint: "[describe the image you need]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(prompt descriptions, refinement options, asset documentation) MUST be written
in the user's language. The skill logic instructions below are in English for
maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Current Project State (auto-detected)

- Project identity: !`head -20 CLAUDE.md 2>/dev/null`
- Brand guidelines: !`ls docs/brand-guidelines.md brand-guidelines.md BRAND_VOICE.md 2>/dev/null`
- Design tokens: !`cat design-tokens.json 2>/dev/null | head -30`
- Brand colors: !`grep -i "color-primary\|color-secondary" design-tokens.css 2>/dev/null | head -6`
- Existing assets: !`ls -d assets/ public/images/ public/assets/ src/assets/ 2>/dev/null`
- Asset inventory: !`find assets/ public/images/ public/assets/ src/assets/ -type f \( -name "*.png" -o -name "*.svg" -o -name "*.jpg" -o -name "*.webp" \) 2>/dev/null | head -15`
- Active phase: !`grep -l ">>> CURRENT <<<" plans/PHASE_*.md 2>/dev/null`
- Image plugins: !`ls ~/.claude/plugins/image-generation 2>/dev/null`

# /blox:image

> **Purpose:** Generate images for the project — logos, hero images, icons,
> illustrations, UI assets, social media graphics, and more. Reads brand
> guidelines to maintain visual consistency, crafts optimized prompts for AI
> image generation, and supports iterative refinement. Works in basic mode
> (detailed text prompt output) or premium mode (direct AI generation via
> image-generation plugin).

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-image
category: domain
complements: [blox-brand, blox-design]

### Triggers — when the agent invokes automatically
trigger_keywords: [image, logo, icon, illustration, hero image, asset, graphic, kep, logó, ikon]
trigger_files: [docs/brand-guidelines.md, design-tokens.css]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the project needs visual assets: logos, hero images, icons,
  illustrations, social media graphics, or any AI-generated image. Typically
  called during brand identity (/blox:brand Step 6 for logo concepts), UI
  design (/blox:design for page assets), or standalone for any image need.
  Do NOT use for brand identity system (use /blox:brand), for UI layout or
  component design (use /blox:design), or for video content (use /blox:video).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Project needs a logo | "Create a logo for my restaurant" | No — user invokes |
| Hero image for landing page | "Generate a hero image for the homepage" | No — user invokes |
| Icons for UI components | "I need icons for the dashboard navigation" | No — user invokes |
| Social media graphics | "Create an Open Graph image for sharing" | No — user invokes |
| `/blox:brand` needs logo concepts | Brand pipeline Step 6 chains here | Yes — brand calls it |
| `/blox:design` needs page assets | Design pipeline needs illustrations | Yes — design calls it |
| Placeholder images for prototyping | "Generate placeholder images for the mockup" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Need full brand identity | Brand system, not just images | `/blox:brand` |
| Need page layout or components | UI design, not assets | `/blox:design` |
| Need video content or storyboard | Video, not static image | `/blox:video` |
| Need to write code | Implementation, not assets | `/blox:build` |
| Need to edit existing photos | Photo editing requires specialized tools | Manual editing tool |

---

## BASIC vs PREMIUM MODE

The skill auto-detects available plugins and adjusts its capabilities:

| Feature | Basic (no plugin) | Premium (image-generation plugin) |
|---------|-------------------|-----------------------------------|
| Prompt crafting | Full optimized prompt with all details | Same prompt, sent to AI engine |
| Generation | Text prompt for user to use elsewhere | Direct AI image generation |
| Iteration | Revised prompt text | Re-generate with adjustments |
| Variations | Multiple prompt variants | Multiple image variants |
| Output | Markdown prompt block | Actual image file saved to project |
| Formats | N/A | PNG, JPEG, WebP (engine-dependent) |

**Plugin detection (runs at start):**
```
IF image-generation plugin installed:
  → Enable direct AI image generation
  → Enable iterative refinement with visual feedback
  → Note: "Image generation plugin detected — I can generate images directly"

IF image-generation NOT installed:
  → Basic mode — generate detailed, optimized prompts
  → Note: "Running in basic mode — I'll create detailed prompts you can use
    with any AI image tool (Midjourney, DALL-E, Stable Diffusion, etc.)"
  → Suggest: "Install the image-generation plugin for direct generation:
    /plugin add anthropics/image-generation"
```

---

## SKILL LOGIC

> **4-step pipeline from image request to generated asset.**
> Step 1 is automatic (context loading).
> Step 2 is conditional (only if multiple engines available).
> Step 3 generates the optimized prompt.
> Step 4 generates the image or outputs the prompt.

### Step 1: CONTEXT

Load brand guidelines and understand the image purpose before generating anything.

**Actions:**

```
1a. Read brand context (if it exists):
    - docs/brand-guidelines.md → brand personality, voice, visual style
    - design-tokens.css / design-tokens.json → colors (hex values), typography
    - GOLDEN_PRINCIPLES.md → visual/brand rules

    IF brand guidelines exist:
      → Extract: primary color, secondary color, accent colors (hex values)
      → Extract: brand personality (warm/cool, bold/subtle, modern/classic)
      → Extract: typography style (serif/sans-serif, font names)
      → Extract: Do's and Don'ts for visuals
      → Note: "Brand context loaded — generating within your brand system"

    IF brand guidelines do NOT exist:
      → Note: "No brand guidelines found. I'll ask about style preferences.
        Run /blox:brand first for a cohesive visual identity."
      → Ask: "Any color or style preferences for this image?"
      → Continue — do NOT block

1b. Classify the image request:
    Parse the user's description to identify the image type:

    CLASSIFICATION:
    - LOGO        → Brand mark, wordmark, icon mark, combination mark
    - HERO        → Full-width banner image for landing page or section header
    - ICON        → Small UI element, navigation icon, feature icon
    - ILLUSTRATION→ Conceptual drawing, diagram, decorative art
    - PHOTO       → Photorealistic image (product shot, lifestyle, environment)
    - SOCIAL      → Social media graphic (OG image, cover photo, post)
    - PATTERN     → Repeating background pattern, texture
    - MOCKUP      → Product mockup, device frame, environment placement

    Each type has different prompt optimization strategies (applied in Step 3).

1c. Determine output specifications:
    Based on image type, set default dimensions and format:

    | Type | Default Size | Aspect Ratio | Format |
    |------|-------------|--------------|--------|
    | LOGO | 1024x1024 | 1:1 | PNG (transparent bg) |
    | HERO | 1920x1080 | 16:9 | WebP or JPEG |
    | ICON | 512x512 | 1:1 | SVG preferred, PNG fallback |
    | ILLUSTRATION | 1200x1200 | 1:1 or custom | PNG |
    | PHOTO | 1920x1280 | 3:2 | JPEG |
    | SOCIAL | 1200x630 | ~1.9:1 (OG) | PNG or JPEG |
    | PATTERN | 512x512 | 1:1 (tileable) | PNG |
    | MOCKUP | 1920x1080 | 16:9 | PNG |

    Ask the user ONLY if their request is ambiguous:
    "What size do you need? (I default to [default] for [type])"
```

**Output:** Brief summary of brand context, image classification, and specs.
Proceed to Step 2 or Step 3 (skip Step 2 if only one engine or no plugin).

---

### Step 2: ENGINE SELECTION

**Only applies when multiple image generation tools are available.**

```
IF multiple image-generation engines detected:
  → Present options:
    "Which image engine should I use?
     a) [Engine A] — [strength description]
     b) [Engine B] — [strength description]
     c) Auto — I'll pick the best one for [image type]"

  Engine strengths (for recommendation):
    Gemini Imagen  → Photorealistic images, product shots, lifestyle
    DALL-E         → Creative illustrations, abstract concepts, artistic styles
    Stable Diffusion → Fine control, inpainting, specific art styles
    Midjourney     → Aesthetic quality, cinematic, stylized art

IF one engine available:
  → Use it, note which one: "Using [engine name] for generation."

IF no engine available (basic mode):
  → Skip to Step 3 — output will be text prompt only
  → Note: "No image engine available. I'll create an optimized prompt."
```

---

### Step 3: PROMPT CRAFTING

Generate an optimized image generation prompt based on context, brand, and purpose.

**Prompt structure — universal formula:**

```
[SUBJECT] + [STYLE] + [COLORS] + [COMPOSITION] + [MOOD] + [TECHNICAL]

Where:
  SUBJECT     = What the image shows (the core visual content)
  STYLE       = Art style (photorealistic, flat illustration, watercolor, etc.)
  COLORS      = Color palette from brand, or user-specified colors
  COMPOSITION = Layout, framing, perspective, focal point
  MOOD        = Emotional tone (warm, professional, energetic, serene)
  TECHNICAL   = Aspect ratio, quality keywords, negative prompts
```

**Type-specific prompt optimization:**

```
LOGO prompts:
  - Add: "simple, clean, scalable, works at small sizes"
  - Add: "isolated on [white/dark/transparent] background"
  - Add: "no text unless specified" (text in AI images is unreliable)
  - Style keywords: "minimal, geometric, iconic, vector-style"
  - IMPORTANT: AI-generated logos are STARTING POINTS — always note
    that professional refinement may be needed for final brand mark

HERO prompts:
  - Add: "wide composition, space for text overlay on [left/right/center]"
  - Add: "depth of field, cinematic lighting"
  - Consider: Will text be overlaid? Leave visual breathing room
  - Add brand colors as accent or atmosphere colors

ICON prompts:
  - Add: "simple, clear silhouette, recognizable at 24px"
  - Add: "flat design, single color, no gradients" (for UI icons)
  - OR: "detailed, colorful" (for feature/marketing icons)
  - Consider: Icon set consistency — reference existing icons if present

ILLUSTRATION prompts:
  - Add: style reference matching brand personality
  - Warm brands → "hand-drawn, organic lines, soft colors"
  - Tech brands → "geometric, clean lines, isometric, flat"
  - Playful brands → "colorful, whimsical, cartoon-style"

PHOTO prompts:
  - Add: "photorealistic, natural lighting, [specific environment]"
  - Add: "shallow depth of field" for product focus
  - Add: "lifestyle photography" for people/environment shots
  - NEVER generate recognizable real people — use abstract or from-behind

SOCIAL prompts:
  - Add: platform-specific dimensions (OG: 1200x630, IG: 1080x1080)
  - Add: "bold, eye-catching, clear focal point"
  - Add: "space for text overlay" if title/caption needed

PATTERN prompts:
  - Add: "seamless, tileable, repeating pattern"
  - Add: "no visible seams or edges"
  - Use brand colors as the palette

MOCKUP prompts:
  - Add: "product mockup, [device/environment] frame"
  - Add: "realistic perspective, natural shadows"
```

**Brand integration (MANDATORY if brand exists):**

```
IF brand guidelines loaded:
  → Inject brand primary color: "incorporating [hex] as primary color"
  → Inject brand personality: "[warm/bold/clean/etc.] style"
  → Inject brand don'ts as negative prompt: "NOT [don't items]"
  → Verify style alignment with brand personality

IF no brand guidelines:
  → Use user-provided preferences or neutral defaults
```

**Negative prompt (what to AVOID):**

```
Universal negatives:
  - "blurry, low quality, distorted, deformed"
  - "text, watermark, signature" (unless text is explicitly requested)
  - "cropped, cut off"

Type-specific negatives:
  LOGO: "complex, detailed background, photorealistic"
  ICON: "detailed background, 3D unless specified, shadows"
  PHOTO: "cartoon, illustration, anime, drawing"
```

**Present the crafted prompt to the user:**

```
"Here's the optimized prompt for your [image type]:

 Prompt: [full prompt text]
 Negative: [negative prompt]
 Size: [width]x[height]
 Style: [style name]

 [IF premium mode]: Generate this image? (y/n)
 [IF basic mode]: Copy this prompt to your preferred image tool.
   Recommended tools: Midjourney, DALL-E, Stable Diffusion, Leonardo.ai

 Want to adjust anything before generating?"
```

**Wait for user confirmation.**
- "yes" / "generate" → proceed to Step 4
- User adjusts → update prompt, re-present
- User wants a completely different direction → go back to classification

---

### Step 4: GENERATE & ITERATE

Generate the image and offer refinement options.

**Premium mode (image-generation plugin available):**

```
4a. Generate the image using the selected engine:
    → Send the crafted prompt to the image-generation plugin
    → Display the generated image to the user

4b. Offer refinement options:
    "Here's your [image type]. What do you think?

     a) Looks good — save it
     b) More vibrant colors
     c) Different angle / composition
     d) Different style (more [option1] / less [option2])
     e) Completely different approach
     f) Generate 2 more variations to compare"

4c. Iteration loop:
    IF user picks a refinement (b-f):
      → Adjust the prompt based on feedback
      → Re-generate
      → Show new result alongside previous ("Before → After")
      → Offer refinement options again
      → Maximum 5 iterations — after that, suggest finalizing:
        "We've iterated 5 times. Pick the best version to save,
         or describe exactly what's missing."

    IF user picks (a) — save:
      → Proceed to saving (4d)

4d. Save the generated image:
    DETERMINE save location:
      IF assets/ directory exists → save to assets/
      IF public/images/ exists → save to public/images/
      IF src/assets/ exists → save to src/assets/
      IF none exist → create assets/ and save there

    FILE NAMING convention:
      [type]-[description]-[date].[ext]
      Examples:
        logo-bella-vita-2026-03-17.png
        hero-homepage-restaurant-2026-03-17.webp
        icon-booking-calendar-2026-03-17.png

    SAVE the image file to the determined location.
```

**Basic mode (no plugin):**

```
4a. Output the complete prompt package:
    "Your image generation prompt:

     ━━━ PROMPT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     [Full optimized prompt text]
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Negative prompt: [negative prompt]
     Recommended size: [width]x[height]
     Recommended style: [style keywords]

     Use this prompt with:
     - Midjourney: paste in Discord, add --ar [ratio] --v 6
     - DALL-E: paste directly in ChatGPT or API
     - Stable Diffusion: paste as positive prompt, use negative prompt field
     - Leonardo.ai: paste in prompt field, select [recommended model]

     When you have the image, tell me and I'll help integrate it
     into the project."

4b. Offer prompt variations:
    "Want me to create alternative prompts?
     a) Same subject, different style
     b) Same style, different composition
     c) Multiple size variants (logo, social, hero)"

4c. When user has the image (returns with it):
    → Help integrate: determine save location, naming, commit
```

**Post-generation actions (both modes):**

```
UPDATE project files:
  IF CONTEXT_CHAIN.md exists:
    → Add entry: "[date] — [image type] generated by /blox:image"
    → Note: "[description], saved to [path]"

GIT COMMIT (if git repo exists AND image was saved):
  git add [image-path]
  git commit -m "asset: [image type] — [brief description]"
```

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| No brand guidelines | Ask for basic style preferences, continue | "No brand found. What colors/style do you prefer?" |
| Plugin not installed | Switch to basic mode (prompt output) | "No image plugin. Here's a detailed prompt for any AI tool." |
| Plugin API key missing | Guide setup, fall back to basic mode | "GEMINI_API_KEY not set. Get it at aistudio.google.com/apikey" |
| Generation fails (API error) | Retry once, then fall back to prompt output | "Generation failed. Here's the prompt to use manually." |
| Image quality poor | Offer refinement or prompt adjustment | "Not ideal? Let me adjust: a) more detail b) different style c) try again" |
| No write permission (assets/) | Output prompt in chat | "Can't save files. Here's your prompt — save the image manually." |
| Ambiguous request | Ask ONE clarifying question | "What type of image? a) Logo b) Hero c) Icon d) Illustration e) Other" |
| Brand colors conflict with image purpose | Note the conflict, suggest alternatives | "Brand red may not work for a calming hero image. Suggest using the secondary blue instead?" |

---

## INVARIANTS

1. **Brand consistency** — if brand guidelines exist, use brand colors and style in every prompt
2. **Appropriate content** — never generate violent, explicit, or misleading images
3. **Save to project assets/** — generated images go into the project, not just chat output
4. **Commit generated images** — every saved image gets a git commit
5. **ONE question per message** — never bundle multiple questions
6. **Maximum 5 refinement iterations** — avoid infinite generation loops
7. **Honest about limitations** — AI-generated logos are starting points, not final brand marks
8. **No recognizable real people** — never generate images of specific real individuals
9. **Negative prompts always included** — prevent common quality issues
10. **Graceful degradation** — every error has a fallback, nothing blocks the flow

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Image generated (autopilot from brand) | Return to `/blox:brand` flow | After Step 4 — logo concept for brand |
| Image generated (autopilot from design) | Return to `/blox:design` flow | After Step 4 — page asset for design |
| Image generated (standalone) | Suggest next step | After Step 4 — user decides |
| No plugin installed | Suggest `/blox:setup` | Step 2 — install image-generation plugin |
| Brand context missing | Suggest `/blox:brand` | Step 1 — if no brand files found |
| Image saved, needs quality check | `/blox:check` | At review time — brand consistency |
| Multiple images needed for design | Batch generation (loop Step 3-4) | When design needs multiple assets |

---

## VERIFICATION

### Success Indicators
- Brand context loaded before prompt crafting (or noted if absent)
- Image type correctly classified (LOGO, HERO, ICON, etc.)
- Prompt includes all 6 elements: subject, style, colors, composition, mood, technical
- Brand colors and personality injected into prompt (if brand exists)
- Negative prompt included to prevent quality issues
- Appropriate dimensions set for image type
- [Premium] Image generated and shown to user for approval
- [Premium] Refinement offered with clear options (a-f)
- [Premium] Approved image saved to project assets/ directory
- [Premium] Saved image committed to git
- [Basic] Complete prompt package output with tool-specific instructions
- [Basic] Prompt variations offered
- CONTEXT_CHAIN.md updated (if exists)
- No recognizable real people in generated images
- No AI attribution in any generated or documentation file

### Failure Indicators (STOP and fix!)
- Generating without loading brand context first (INVARIANT 1 violation)
- Image contains inappropriate content (INVARIANT 2 violation)
- Image generated but not saved to project (INVARIANT 3 violation — premium mode)
- Image saved but not committed (INVARIANT 4 violation — premium mode)
- Multiple questions asked in one message (INVARIANT 5 violation)
- More than 5 refinement iterations without suggesting finalization (INVARIANT 6)
- AI logo presented as "final" without noting it needs professional refinement (INVARIANT 7)
- Prompt missing negative prompt section (INVARIANT 9 violation)
- Plugin error with no fallback to basic mode (INVARIANT 10 violation)

---

## EXAMPLES

### Example 1: Logo for restaurant (Premium mode — chained from /blox:brand)

```
/blox:brand Step 6 chains to /blox:image for logo concept

STEP 1 — Context:
  Brand loaded: Bella Vita — Warm, Authentic, Family-friendly
  Colors: Terracotta (#C75B39) primary, Olive Green (#6B7C3F) secondary
  Typography: Playfair Display (serif headings), Lato (body)
  Personality: warm, earthy, Italian heritage
  Never: corporate, fast-food, pretentious
  Image type: LOGO
  Size: 1024x1024, PNG with transparent background

  "Brand context loaded. Creating logo concepts for Bella Vita."

STEP 2 — Engine Selection:
  One engine available (image-generation plugin).
  "Using Gemini Imagen for generation."

STEP 3 — Prompt Crafting:
  "Here's the optimized prompt for your logo:

   Prompt: Minimalist restaurant logo mark for 'Bella Vita', Italian
   family restaurant. Warm terracotta (#C75B39) and olive green (#6B7C3F)
   color palette. Elegant serif style echoing Italian heritage. Simple
   iconic mark featuring subtle olive branch or vine motif. Clean lines,
   scalable design, works at small sizes. Isolated on transparent
   background. Warm, authentic, inviting mood.

   Negative: complex details, photorealistic, corporate feel, fast-food
   style, blurry, low quality, text, watermark

   Size: 1024x1024
   Style: minimal, iconic, vector-style

   Generate this logo concept? (y/n)"

User: "y"

STEP 4 — Generate & Iterate:
  [Image generated and displayed]

  "Here's your logo concept. What do you think?

   a) Looks good — save it
   b) More vibrant colors
   c) Different symbol (try a different Italian motif)
   d) More modern / less classic
   e) Completely different approach
   f) Generate 2 more variations to compare"

User: "f"

  [2 more variations generated]

  "Here are 3 logo concepts. Which one works best?
   Pick a number (1-3), or describe adjustments."

User: "1 is great, save it"

  "Logo saved to assets/logo-bella-vita-2026-03-17.png

   Note: This is an AI-generated concept — a great starting point.
   For the final brand mark, consider professional refinement for:
   - Perfect geometry and alignment
   - Vector format (SVG) for unlimited scaling
   - Print-ready color profiles (CMYK)

   Returning to brand identity flow."

→ Returns to /blox:brand Step 6
```

### Example 2: Hero image for landing page (Premium mode — standalone)

```
User: /blox:image "hero image for my SaaS dashboard landing page"

STEP 1 — Context:
  Brand loaded: DevFlow — Clean, Fast, Developer-friendly
  Colors: Electric Blue (#3B82F6) primary, Slate (#475569) secondary
  Personality: modern, technical, no-nonsense
  Image type: HERO
  Size: 1920x1080, WebP

  "Brand context loaded — designing a hero image for DevFlow."

STEP 2 — Engine Selection:
  "Using image-generation plugin."

STEP 3 — Prompt Crafting:
  "Here's the optimized prompt:

   Prompt: Wide cinematic hero image for developer SaaS landing page.
   Abstract visualization of data flowing through a modern dashboard
   interface. Electric blue (#3B82F6) glowing accents on dark slate
   (#0F172A) background. Clean, futuristic, technical aesthetic.
   Subtle depth of field with geometric elements suggesting code and
   data pipelines. Space for text overlay on the left third.
   Professional, modern, developer-focused mood.

   Negative: cartoon, illustration, cluttered, stock photo feel,
   blurry, low quality, text, watermark, people faces

   Size: 1920x1080 (16:9)
   Style: cinematic, technical, modern

   Generate? (y/n)"

User: "yes but make it less abstract, show an actual dashboard screen"

  [Prompt adjusted to include dashboard UI elements]

  "Updated prompt — now features a realistic dashboard visualization.
   Generate? (y/n)"

User: "y"

STEP 4 — Generate & Iterate:
  [Image generated]

  "Here's your hero image. What do you think?

   a) Looks good — save it
   b) More vibrant colors
   c) Different angle / composition
   d) More depth / dimension
   e) Completely different approach
   f) Generate 2 more variations"

User: "a"

  "Hero image saved to public/images/hero-dashboard-landing-2026-03-17.webp

   Tip: Reference this in your landing page component:
   <Image src='/images/hero-dashboard-landing-2026-03-17.webp'
          alt='DevFlow dashboard visualization with data pipeline interface' />"
```

### Example 3: Icons for UI (Basic mode — no plugin)

```
User: /blox:image "navigation icons for my dashboard — home, analytics,
       users, settings, notifications"

STEP 1 — Context:
  Brand loaded: minimal, blue primary
  Image type: ICON (batch — 5 icons)
  Size: 512x512 each, SVG preferred

  "Brand context loaded. Creating icon prompts for 5 navigation icons."
  "No image plugin detected — generating optimized prompts."

STEP 3 — Prompt Crafting (batch — one prompt per icon):
  "Here are your icon generation prompts:

   ━━━ ICON 1: HOME ━━━━━━━━━━━━━━━━━━━━━━━━━━
   Simple flat icon of a house/home. Single color (#3B82F6).
   Clean geometric lines, minimal detail, recognizable at 24px.
   Flat design, no shadows, no gradients. Isolated on transparent
   background.
   Negative: 3D, detailed, photorealistic, shadows, gradient
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ━━━ ICON 2: ANALYTICS ━━━━━━━━━━━━━━━━━━━━━
   Simple flat icon of a bar chart with upward trend. Single color
   (#3B82F6). Clean geometric lines, minimal detail, recognizable
   at 24px. Flat design, no shadows, no gradients. Isolated on
   transparent background.
   Negative: 3D, detailed, photorealistic, shadows, gradient
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ━━━ ICON 3: USERS ━━━━━━━━━━━━━━━━━━━━━━━━━
   [similar pattern for people/users icon]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ━━━ ICON 4: SETTINGS ━━━━━━━━━━━━━━━━━━━━━━
   [similar pattern for gear/cog icon]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ━━━ ICON 5: NOTIFICATIONS ━━━━━━━━━━━━━━━━━
   [similar pattern for bell icon]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Use these prompts with any AI image tool.

   Pro tip: For UI icons, consider using an icon library instead
   (Lucide, Heroicons, Phosphor) — they guarantee visual consistency
   across the set. AI generation works better for custom/unique icons.

   Want alternative prompt styles?"
```

### Example 4: Social media graphic (Basic mode)

```
User: /blox:image "Open Graph image for sharing my blog posts"

STEP 1 — Context:
  Brand loaded: warm brand, coral primary
  Image type: SOCIAL (OG image)
  Size: 1200x630 (OG standard)

  "Brand context loaded."
  "No image plugin — generating prompt."

STEP 3 — Prompt Crafting:
  "Here's your OG image prompt:

   ━━━ PROMPT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Social media Open Graph card template. Warm coral (#FF6B6B) gradient
   background flowing from bottom-left to top-right. Clean white space
   in center-left for title text overlay. Subtle geometric pattern
   decoration in corners. Modern, warm, inviting. Bold and eye-catching
   at thumbnail size.
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Negative: text, busy, cluttered, dark, blurry, low quality
   Size: 1200x630
   Style: modern, warm, social-media-optimized

   Use with Midjourney: paste + --ar 1200:630 --v 6
   Use with DALL-E: paste directly, specify 1200x630

   Want variations? a) Different color mood b) Different composition
   c) Template for multiple posts (consistent style)"
```

### Example 5: No brand context — style discovery

```
User: /blox:image "illustration for my about page"

STEP 1 — Context:
  No brand guidelines found.
  Image type: ILLUSTRATION

  "No brand guidelines found. A few quick questions:

   What style fits your project?
   a) Clean and modern (flat design, geometric)
   b) Warm and hand-drawn (organic, sketchy)
   c) Bold and colorful (vibrant, energetic)
   d) Professional and minimal (corporate, subtle)
   e) Other — describe your style"

User: "b"

  "Any specific colors to use?"

User: "earthy tones, greens and browns"

STEP 3 — Prompt Crafting:
  "Here's the optimized prompt:

   Prompt: Hand-drawn illustration for a personal website about page.
   Warm, organic style with sketchy line work. Earth tone color palette
   featuring forest greens, warm browns, and cream. Person working at a
   desk surrounded by plants and books (seen from behind or in profile,
   no face detail). Cozy, authentic, personal mood. Watercolor texture
   in background.

   Negative: digital, corporate, geometric, photorealistic, blurry,
   low quality, face details

   Size: 1200x1200
   Style: hand-drawn, watercolor, organic

   Generate? (y/n) [or use the prompt with your preferred tool]"
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Engineering patterns (asset management)
- `skills/brand/SKILL.md` — Brand identity (consumed for visual consistency)
- `skills/design/SKILL.md` — UI/component design (chains here for page assets)
- `skills/check/SKILL.md` — Quality review (brand consistency check)
- `registry/curated-plugins.yaml` — Plugin detection (image-generation plugin)
