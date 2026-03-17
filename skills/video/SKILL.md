---
name: blox-video
description: "Create video content — storyboards, scripts, shot lists. FUTURE: AI video generation when plugins become available."
user-invocable: true
argument-hint: "[describe the video you need]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(storyboard scenes, script dialogue, shot list descriptions, timing notes) MUST
be written in the user's language. The skill logic instructions below are in
English for maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:video

> **Purpose:** Create video pre-production content — storyboards, scripts, shot
> lists, and timing plans. Produces everything needed to create a video, whether
> the user shoots it themselves, hires a videographer, or uses AI video tools.
>
> **FUTURE/PLANNED:** Video generation plugins (Veo, Sora, Kling, etc.) are not
> yet available as Claude Code plugins. When they become available, this skill
> will support direct video generation — the same way `/blox:image` works with
> the image-generation plugin today. Until then, this skill focuses on
> pre-production: the creative planning that makes any video production better.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-video
category: domain
complements: [blox-brand, blox-design, blox-image]

### Triggers — when the agent invokes automatically
trigger_keywords: [video, animation, storyboard, script, shot list, promo video, explainer, videó, animáció, forgatókönyv]
trigger_files: [docs/brand-guidelines.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the project needs video content planning: product demos, explainer
  videos, promo clips, social media videos, onboarding tutorials, or any video
  pre-production. Produces storyboards, scripts, and shot lists. FUTURE: direct
  AI video generation when plugins become available.
  Do NOT use for static images (use /blox:image), for brand identity (use
  /blox:brand), or for UI design (use /blox:design).
auto_invoke: false
priority: optional

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Product demo video needed | "Plan a demo video for our SaaS product" | No — user invokes |
| Explainer or tutorial video | "Create a storyboard for an onboarding video" | No — user invokes |
| Promo video for launch | "Script a 30-second promo for our launch" | No — user invokes |
| Social media video content | "Plan a TikTok/Reels video showcasing the app" | No — user invokes |
| Animated feature walkthrough | "Storyboard an animation showing the booking flow" | No — user invokes |
| Testimonial/case study video | "Plan a customer success video" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Need static images or logos | Static assets, not video | `/blox:image` |
| Need brand identity | Brand system, not video | `/blox:brand` |
| Need UI/UX design | Interface design, not video | `/blox:design` |
| Need to write code | Implementation, not content | `/blox:build` |
| Need to edit existing video | Video editing requires specialized tools | DaVinci Resolve, Premiere, CapCut |

---

## BASIC vs PREMIUM MODE

> **Current status: BASIC MODE ONLY.**
> Premium mode will be enabled when video generation plugins become available.

| Feature | Basic (current — no plugin) | Premium (FUTURE — video plugin) |
|---------|----------------------------|-------------------------------|
| Storyboard | Scene-by-scene visual description | AI-generated scene previews |
| Script | Full narration/dialogue text | Script + AI voiceover |
| Shot list | Detailed camera/timing specs | Shot list + AI video clips |
| Animation | Frame-by-frame description | Direct AI animation generation |
| Output | Markdown documents | Video files (.mp4, .webm) |
| Iteration | Text-based refinement | Visual refinement with AI |

**Plugin detection (runs at start):**
```
CURRENTLY: No video generation plugins exist in the Claude Code ecosystem.

FUTURE detection logic (to be activated when plugins ship):
  IF video-generation plugin installed:
    → Enable direct AI video generation
    → Enable scene-by-scene preview generation
    → Note: "Video generation plugin detected — I can generate video directly"

  IF video-generation NOT installed:
    → Basic mode — generate storyboard, script, shot list
    → Note: "Video generation plugins are not yet available.
      I'll create a complete pre-production package: storyboard, script,
      and shot list you can use with any video tool or production team."

CURRENT behavior:
  → Always basic mode
  → Note: "I'll create a complete pre-production package for your video."
```

---

## SKILL LOGIC

> **3-step pipeline for video pre-production.**
> Each step produces a standalone document. Together they form a complete
> video production brief. The user confirms the storyboard before script
> and shot list are generated.

### Step 1: STORYBOARD

Create a scene-by-scene visual description with direction notes.

**Actions:**

```
1a. Read brand context (if it exists):
    - docs/brand-guidelines.md → brand personality, colors, visual style
    - design-tokens.css → colors for on-screen elements
    - Existing images in assets/ → available visual assets to reference

    IF brand guidelines exist:
      → Extract: color palette for on-screen graphics
      → Extract: brand personality for video tone
      → Extract: Do's and Don'ts for visual style
      → Note: "Brand context loaded — video will follow brand guidelines"

    IF brand guidelines do NOT exist:
      → Ask: "What tone should this video have?
        a) Professional and polished
        b) Casual and friendly
        c) Energetic and exciting
        d) Minimal and clean
        e) Other — describe"
      → Continue — do NOT block

1b. Classify the video type:
    Parse the user's description to determine video format:

    CLASSIFICATION:
    - DEMO       → Product walkthrough showing features in action
    - EXPLAINER  → Concept explanation with visuals (what + how + why)
    - PROMO      → Short promotional clip for launch or marketing
    - TUTORIAL   → Step-by-step instructional video
    - SOCIAL     → Short-form for TikTok, Reels, YouTube Shorts (< 60s)
    - TESTIMONIAL→ Customer story or case study
    - ANIMATION  → Animated sequence (motion graphics, character animation)
    - TRAILER    → Teaser/hype video for upcoming launch

    Each type has different structural patterns (applied below).

1c. Determine video specifications:
    Based on video type, set defaults:

    | Type | Duration | Aspect Ratio | Platform |
    |------|----------|-------------|----------|
    | DEMO | 60-180s | 16:9 | YouTube, website |
    | EXPLAINER | 60-120s | 16:9 | YouTube, website |
    | PROMO | 15-30s | 16:9 + 9:16 | Multi-platform |
    | TUTORIAL | 120-300s | 16:9 | YouTube, docs |
    | SOCIAL | 15-60s | 9:16 | TikTok, Reels |
    | TESTIMONIAL | 60-120s | 16:9 | Website, YouTube |
    | ANIMATION | 30-90s | 16:9 | Website, social |
    | TRAILER | 15-45s | 16:9 | Website, social |

    Ask ONLY if duration is critical:
    "How long should this video be? (I suggest [default] for [type])"

1d. Generate the storyboard:
    Scene-by-scene breakdown with visual direction.
```

**Storyboard format:**

```markdown
# Storyboard: [Video Title]

> **Type:** [DEMO/EXPLAINER/PROMO/etc.]
> **Duration:** ~[N] seconds
> **Aspect ratio:** [16:9 / 9:16 / both]
> **Platform:** [target platforms]
> **Tone:** [brand personality or user-specified tone]

---

## Scene 1: [Scene Name] (0:00 - 0:XX)

**Visual:** [Detailed description of what the viewer sees.
Include framing, colors, motion, on-screen elements.]

**Audio:** [Music type, sound effects, voiceover summary]

**Text on screen:** [Any titles, captions, or call-to-action text]

**Transition to next:** [Cut / fade / slide / zoom / dissolve]

**Notes:** [Production notes — what assets are needed, special effects]

---

## Scene 2: [Scene Name] (0:XX - 0:XX)

[Same structure repeated for each scene]

---

## Scene N: [Closing Scene] (X:XX - X:XX)

**Visual:** [Final frame — logo, CTA, contact info]

**Audio:** [Music resolution, final voiceover line]

**Text on screen:** [CTA text, URL, social handles]

**Transition:** [End card / fade to black]
```

**Type-specific storyboard patterns:**

```
DEMO:
  Scene 1: Hook — show the problem (5-10s)
  Scene 2: Solution intro — "Here's [product name]" (5-10s)
  Scene 3-N: Feature walkthrough — one feature per scene (10-15s each)
  Final scene: CTA — "Try it free" / "Sign up" (5-10s)

EXPLAINER:
  Scene 1: Hook — relatable problem or question (10-15s)
  Scene 2: Context — why this matters (10-15s)
  Scene 3: Solution — how it works (simple) (20-30s)
  Scene 4: Benefits — what you get (15-20s)
  Final scene: CTA (5-10s)

PROMO:
  Scene 1: Attention grab — bold visual or statement (3-5s)
  Scene 2-3: Key value props — fast cuts (5-8s each)
  Final scene: Brand + CTA (3-5s)

TUTORIAL:
  Scene 1: What we'll build/learn (10-15s)
  Scene 2: Prerequisites (5-10s)
  Scene 3-N: Step-by-step (30-60s each, depends on complexity)
  Final scene: Summary + next steps (10-15s)

SOCIAL:
  Scene 1: Hook in first 2 seconds — pattern interrupt (2-3s)
  Scene 2: Core message or transformation (10-20s)
  Scene 3: Payoff or reveal (5-10s)
  Final: CTA or follow prompt (3-5s)

TESTIMONIAL:
  Scene 1: Customer intro + problem they faced (15-20s)
  Scene 2: Discovery — how they found the solution (10-15s)
  Scene 3: Results — specific outcomes, metrics (20-30s)
  Final scene: Recommendation + CTA (10-15s)

ANIMATION:
  Scene 1: Opening visual — set the world/context (5-10s)
  Scene 2-N: Animated sequence — concept visualization (varies)
  Final scene: Resolution + brand (5-10s)

TRAILER:
  Scene 1: Tease — glimpse of what's coming (3-5s)
  Scene 2-3: Building excitement — features/highlights (5-8s each)
  Scene 4: Release date / availability (3-5s)
  Final: Brand mark + anticipation builder (3-5s)
```

**Present the storyboard and wait for user confirmation.**
- User confirms → proceed to Step 2
- User adjusts scenes → update and re-present
- User wants different approach → re-classify and regenerate

---

### Step 2: SCRIPT

Generate the full narration, dialogue, and timing based on the confirmed storyboard.

**Script format:**

```markdown
# Script: [Video Title]

> **Total duration:** ~[N] seconds
> **Reading pace:** ~150 words/minute (natural narration speed)
> **Word count:** ~[N] words

---

## Scene 1: [Scene Name]
**Time:** 0:00 - 0:XX

**[NARRATOR]:**
"[Exact narration text. Written conversationally, matching brand voice.
 Timed to fit the scene duration at natural reading pace.]"

**[ON-SCREEN TEXT]:**
[Title or caption that appears during this scene]

**[SFX]:**
[Sound effect: whoosh, click, notification chime, etc.]

**[MUSIC]:**
[Music direction: upbeat intro begins, builds energy, resolves]

---

## Scene 2: [Scene Name]
**Time:** 0:XX - 0:XX

**[NARRATOR]:**
"[Continue narration...]"

[Continue for all scenes]

---

## DELIVERY NOTES

**Narration style:** [Conversational / Professional / Energetic / Calm]
**Accent/dialect:** [Neutral / British / specific preference]
**Pace:** [Fast-paced for promo / Measured for tutorial / Natural for explainer]
**Emphasis words:** [Key words to stress in narration, marked with *asterisks*]
```

**Script rules:**
- Match brand voice from brand-guidelines.md (if loaded)
- Use conversational language — write for ears, not eyes
- Keep sentences short (< 20 words per sentence for narration)
- Time narration to scene duration (~2.5 words per second)
- Mark emphasis words and pauses
- Include SFX and music cues at the moment they occur
- CTA text is explicit and actionable ("Visit [url]" not "Check it out")

**Do NOT ask for confirmation at this step** — generate based on the confirmed
storyboard. Present the full script and proceed to Step 3.

---

### Step 3: SHOT LIST

Generate the technical shot list for production.

**Shot list format:**

```markdown
# Shot List: [Video Title]

> **Total shots:** [N]
> **Equipment needed:** [Camera type, lighting, microphone, etc.]
> **Location(s):** [Where each shot takes place]

---

| # | Scene | Shot Description | Camera | Duration | Movement | Assets Needed |
|---|-------|-----------------|--------|----------|----------|--------------|
| 1 | Sc.1 | Wide establishing shot of [subject] | Wide lens | 3s | Static / slow pan | [location/prop] |
| 2 | Sc.1 | Close-up on [detail] | Macro/close | 2s | Static | [prop/screen] |
| 3 | Sc.2 | Screen recording of [feature] | Screen capture | 8s | Mouse-guided | [app running] |
| 4 | Sc.2 | Over-shoulder of user interacting | Medium shot | 5s | Slight dolly in | [actor/device] |
| ... | ... | ... | ... | ... | ... | ... |

---

## ASSET CHECKLIST

Assets to prepare before production:

### Visual Assets
- [ ] [Logo animation / intro bumper]
- [ ] [Screen recordings of product features]
- [ ] [Stock footage clips needed: describe each]
- [ ] [Graphics / overlays / lower thirds]
- [ ] [End card template with CTA]

### Audio Assets
- [ ] [Background music track — mood: [description], license: [type]]
- [ ] [Sound effects: list each needed SFX]
- [ ] [Voiceover recording — script from Step 2]

### Production Needs
- [ ] [Lighting setup: [describe]]
- [ ] [Location access: [where]]
- [ ] [Props/devices: [list]]
- [ ] [Talent/actors: [describe roles]]

---

## POST-PRODUCTION NOTES

**Editing style:** [Fast cuts for promo / Smooth transitions for explainer]
**Color grading:** [Brand colors influence — warm/cool/neutral]
**Text animations:** [Style of on-screen text: minimal fade / dynamic motion]
**Music timing:** [Key moments where music should hit: scene transitions, CTA]
**Export specs:**
  - Primary: [resolution, codec, bitrate — e.g., 1920x1080, H.264, 8Mbps]
  - Social: [platform-specific specs — e.g., 1080x1920 for Reels, 1080x1080 for IG]
  - Web: [optimized for web — e.g., WebM, 4Mbps, lazy-loadable]
```

**Shot type reference (for camera column):**

```
Wide shot (WS)      — Full scene, establishing context
Medium shot (MS)    — Waist-up for people, partial for objects
Close-up (CU)       — Detail focus, face, specific UI element
Extreme close-up    — Tiny detail (button click, text)
Over-the-shoulder   — Behind person looking at screen/subject
Top-down / bird's eye — Looking straight down at desk/device
Screen recording    — Direct capture of software/app
B-roll              — Supplementary footage (office, team, environment)
```

**Save all documents:**

```
CREATE:
  docs/video/[video-name]-storyboard.md  — Storyboard from Step 1
  docs/video/[video-name]-script.md      — Script from Step 2
  docs/video/[video-name]-shot-list.md   — Shot list from Step 3

UPDATE (if exists):
  CONTEXT_CHAIN.md  — Add entry:
    "[date] — Video pre-production by /blox:video"
    Phase: Video Content
    Status: completed
    What happened: [video type] storyboard, script, and shot list
      created for [description].
    Next session task: Video production (external) or continue project build
```

**Git commit (if git repo exists):**
```
git add docs/video/
git commit -m "content: video pre-production — [video name] storyboard, script, shot list"
```

**Completion message:**
```
"Video pre-production complete!

 Files created:
 - docs/video/[name]-storyboard.md (scene-by-scene visual plan)
 - docs/video/[name]-script.md (full narration + timing)
 - docs/video/[name]-shot-list.md (camera specs + asset checklist)

 Next steps:
 - Record voiceover using the script
 - Capture screen recordings for product shots
 - Source background music (suggest: Artlist, Epidemic Sound, or royalty-free)
 - Edit using the storyboard as your timeline blueprint

 When video generation plugins become available, run /blox:video again
 to generate video clips directly from these storyboards."
```

---

## ERROR HANDLING

Every error has a graceful fallback — the skill NEVER blocks.

| Error | Fallback | User sees |
|-------|----------|-----------|
| No brand guidelines | Ask for tone preference, continue | "No brand found. What tone should this video have?" |
| Ambiguous video request | Ask ONE clarifying question | "What type of video? a) Demo b) Explainer c) Promo d) Tutorial e) Social clip" |
| Duration unclear | Use type-appropriate default | "I'll plan for ~[default]s — the standard for [type] videos." |
| No write permission (docs/) | Output everything in chat | "Can't create files. Here's your complete video plan — copy it to your project." |
| User wants AI generation | Explain current limitation, provide alternatives | "Video generation plugins aren't available yet. I've created a full production plan you can use with any video tool." |
| Too many scenes for duration | Consolidate or split into series | "That's a lot for [N]s. Suggest: a) Consolidate into fewer scenes b) Make it a 2-part series" |
| No existing visual assets | Note in asset checklist | "You'll need to create/source these visual assets before production." |

---

## INVARIANTS

1. **Brand consistency** — if brand guidelines exist, video tone and colors follow them
2. **Appropriate content** — never plan violent, explicit, or misleading video content
3. **Save to docs/video/** — all pre-production documents saved as project artifacts
4. **Commit generated documents** — every saved document gets a git commit
5. **ONE question per message** — never bundle multiple questions
6. **Realistic timing** — narration word count matches scene duration (~150 words/minute)
7. **Storyboard confirmed before script** — never write a script without approved scenes
8. **Complete asset checklist** — every needed asset is listed, nothing left implicit
9. **Platform-appropriate specs** — export specs match target platform requirements
10. **Graceful degradation** — every error has a fallback, nothing blocks the flow
11. **Honest about limitations** — clearly state video generation is FUTURE, not current

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| Video needs images/thumbnails | `/blox:image` | During Step 1 — generate scene preview images |
| Video pre-production complete | Suggest next step | After Step 3 — user decides production approach |
| Brand context missing | Suggest `/blox:brand` | Step 1 — if no brand files found |
| Video plan needs quality review | `/blox:check` | At review time — brand voice consistency |
| Video is part of launch plan | Links to `/blox:deploy` timeline | Launch planning phase |
| Storyboard scene needs specific visual | `/blox:image` for concept art | Step 1 — visual reference for scenes |

---

## VERIFICATION

### Success Indicators
- Brand context loaded before storyboarding (or tone preference asked)
- Video type correctly classified (DEMO, EXPLAINER, PROMO, etc.)
- Storyboard includes ALL scenes with: visual, audio, text, transition, notes
- Scene timing adds up to target total duration (within 10% tolerance)
- Storyboard confirmed by user before script generation
- Script narration word count matches scene duration (~2.5 words/second)
- Script uses brand voice (if brand guidelines exist)
- Script includes: narration, on-screen text, SFX, music cues
- Shot list covers every scene from the storyboard
- Asset checklist is complete — visual, audio, production needs
- Export specs match target platform(s)
- All documents saved to docs/video/
- Documents committed to git
- CONTEXT_CHAIN.md updated (if exists)
- No AI attribution in any generated file
- FUTURE/PLANNED status clearly communicated — no false promises about generation

### Failure Indicators (STOP and fix!)
- Storyboarding without loading brand context first (INVARIANT 1 violation)
- Inappropriate video content planned (INVARIANT 2 violation)
- Documents only output in chat, not saved to files (INVARIANT 3 violation)
- Saved files not committed (INVARIANT 4 violation)
- Multiple questions in one message (INVARIANT 5 violation)
- Narration text too long for scene duration (INVARIANT 6 violation)
- Script written before storyboard confirmation (INVARIANT 7 violation)
- Assets needed but not listed in checklist (INVARIANT 8 violation)
- Export specs missing or wrong for target platform (INVARIANT 9 violation)
- Claiming video generation is available when it is not (INVARIANT 11 violation)

---

## EXAMPLES

### Example 1: Product demo video (SaaS dashboard)

```
User: /blox:video "demo video for our DevFlow dashboard product"

STEP 1 — Storyboard:
  Brand loaded: DevFlow — Clean, Fast, Developer-friendly
  Colors: Electric Blue (#3B82F6), Slate (#475569), dark mode
  Video type: DEMO
  Duration: ~90 seconds
  Platform: YouTube, website embed

  "Brand context loaded. Creating a demo storyboard for DevFlow."

  "Storyboard: DevFlow Product Demo

   Scene 1: The Problem (0:00 - 0:10)
   Visual: Developer frustrated at terminal, multiple tabs open,
   deployment failing. Dark, cluttered screen. Slight zoom in.
   Audio: Tense background music, keyboard sounds
   Text: 'Deploying shouldn't feel like this.'
   Transition: Quick cut to black

   Scene 2: Enter DevFlow (0:10 - 0:20)
   Visual: DevFlow logo animation on dark background. Then: clean
   dashboard appearing, Electric Blue (#3B82F6) accents glowing.
   Audio: Music shifts to confident, upbeat. Whoosh SFX on logo.
   Text: 'DevFlow — Ship faster, see everything.'
   Transition: Zoom into dashboard

   Scene 3: Pipeline View (0:20 - 0:40)
   Visual: Screen recording — navigating the deployment pipeline.
   Stages lighting up green as builds pass. Real-time logs scrolling.
   Audio: Narrator explains pipeline view. Subtle notification chimes.
   Text: Feature callouts as floating labels
   Transition: Slide left to next feature

   Scene 4: Team Insights (0:40 - 0:55)
   Visual: Screen recording — analytics dashboard. Charts showing
   deploy frequency, MTTR, change failure rate.
   Audio: Narrator highlights key metrics.
   Text: Metric values with animated counters
   Transition: Dissolve

   Scene 5: Real-time Alerts (0:55 - 1:10)
   Visual: Screen recording — alert configuration, then live alert
   appearing. Slack notification preview.
   Audio: Narrator on alerts. Alert chime SFX.
   Text: 'Know before your users do.'
   Transition: Cut

   Scene 6: CTA (1:10 - 1:20)
   Visual: DevFlow logo centered. Dark background with subtle blue
   particle animation. URL and 'Try Free' button.
   Audio: Music resolves. Narrator: 'Start shipping with confidence.'
   Text: 'devflow.io — Try free for 14 days'
   Transition: Fade to black

   Does this storyboard work? Want to adjust any scenes?"

User: "perfect, let's continue"

STEP 2 — Script:
  "Script: DevFlow Product Demo
   Duration: ~80 seconds | ~200 words

   Scene 1 (0:00 - 0:10):
   [NARRATOR]: (no narration — visual storytelling only)
   [SFX]: Keyboard typing, error beep
   [MUSIC]: Tense, building

   Scene 2 (0:10 - 0:20):
   [NARRATOR]: 'Meet DevFlow. One dashboard for your entire
   deployment pipeline.'
   [SFX]: Whoosh on logo reveal
   [MUSIC]: Shifts to confident, modern beat

   [continues for all scenes...]

   DELIVERY NOTES:
   Narration style: Confident, conversational, developer-to-developer
   Pace: Medium — not rushed, not slow
   Emphasis: *DevFlow*, *ship faster*, *real-time*, *try free*"

STEP 3 — Shot List:
  [Full shot list with screen recordings needed, asset checklist,
   export specs for YouTube (1080p H.264) and website (WebM)]

  "Video pre-production complete!

   Files created:
   - docs/video/devflow-demo-storyboard.md
   - docs/video/devflow-demo-script.md
   - docs/video/devflow-demo-shot-list.md

   Next steps:
   - Record 4 screen recordings of DevFlow features
   - Source confident, modern background music
   - Record voiceover (~200 words, ~80 seconds)"
```

### Example 2: Social media promo (short-form)

```
User: /blox:video "15-second Instagram Reel for our restaurant launch"

STEP 1 — Storyboard:
  Brand loaded: Bella Vita — Warm, Authentic, Family-friendly
  Video type: SOCIAL
  Duration: 15 seconds
  Aspect ratio: 9:16 (vertical)
  Platform: Instagram Reels

  "Storyboard: Bella Vita Launch Reel

   Scene 1: Hook (0:00 - 0:02)
   Visual: Close-up of fresh pasta being made by hand. Flour dust
   catching golden light. Vertical frame, filling screen.
   Audio: Trending audio hook / satisfying pasta sound
   Text: none — pure visual hook
   Transition: Quick cut

   Scene 2: The Kitchen (0:02 - 0:05)
   Visual: Fast montage — chef tossing pan, sauce bubbling, herbs
   being chopped. Warm terracotta (#C75B39) color grading.
   Audio: Kitchen sounds blending with music beat
   Text: 'Handmade. Every day.'
   Transition: Beat-synced cuts

   Scene 3: The Table (0:05 - 0:10)
   Visual: Beautiful plated dish arriving at a candlelit table.
   Slow motion pour of olive oil. Guest reaction (genuine smile).
   Audio: Music peaks, warm and inviting
   Text: 'Bella Vita'
   Transition: Slow dissolve

   Scene 4: CTA (0:10 - 0:15)
   Visual: Restaurant exterior at golden hour. Logo overlay.
   Booking info appearing with elegant animation.
   Audio: Music resolves softly
   Text: 'Now Open — Book your table | Link in bio'
   Transition: Fade

   This storyboard follows the social hook-content-CTA pattern.
   Want to adjust?"

User: "yes, go ahead"

STEP 2 — Script:
  [Minimal narration — social videos are visual-first]
  [Music and SFX cues detailed]
  [On-screen text timing precise to beat drops]

STEP 3 — Shot List:
  [5 shots, all food/atmosphere focused]
  [Asset checklist: food styling, golden hour timing, trending audio]
  [Export: 1080x1920, H.264, <15s for Reels upload]

  "Pre-production complete! This is a visual-first Reel — focus
   on beautiful food photography and satisfying editing rhythm."
```

### Example 3: Tutorial video (no brand context)

```
User: /blox:video "tutorial on how to set up authentication in our app"

STEP 1 — Storyboard:
  No brand guidelines found.

  "No brand guidelines found. What tone should this tutorial have?
   a) Professional and polished
   b) Casual and friendly (developer-to-developer)
   c) Minimal and efficient (just the steps)
   d) Other"

User: "b"

  Video type: TUTORIAL
  Duration: ~180 seconds (3 minutes)
  Platform: YouTube, docs site
  Tone: casual, developer-to-developer

  "Storyboard: Auth Setup Tutorial

   Scene 1: Intro (0:00 - 0:15)
   Visual: Split screen — code editor on left, browser preview
   on right. 'What we're building' header.
   Audio: Friendly narrator intro. Lo-fi background music.
   Text: 'Setting up Auth in 3 minutes'
   Transition: Slide down

   Scene 2: Prerequisites (0:15 - 0:30)
   Visual: Terminal showing required packages. Quick install commands.
   Audio: Narrator lists what you need.
   Text: Package names appearing as list items
   Transition: Cut

   Scene 3: Config Setup (0:30 - 1:00)
   Visual: Screen recording — creating auth config file,
   setting environment variables, connecting to provider.
   Audio: Step-by-step narration, casual tone.
   Text: Code callouts highlighting key lines
   Transition: Cut

   Scene 4: Login Flow (1:00 - 1:45)
   Visual: Screen recording — implementing login page, testing
   the flow, showing success state.
   Audio: Narrator walks through the code, explains choices.
   Text: 'Why we use [approach]' callout box
   Transition: Cut

   Scene 5: Protected Routes (1:45 - 2:30)
   Visual: Screen recording — adding route protection, testing
   unauthorized access redirect.
   Audio: Narrator explains middleware/guard pattern.
   Text: Before/after comparison
   Transition: Cut

   Scene 6: Wrap-up (2:30 - 3:00)
   Visual: Browser showing complete auth flow working.
   Summary slide with key takeaways.
   Audio: Narrator summarizes, suggests next video.
   Text: 'Full code: [repo link]' + 'Next: Role-based access'
   Transition: Fade + end card

   6 scenes, ~3 minutes. Confirm this structure?"

User: "looks good"

[Steps 2-3 follow with full script and shot list]
```

### Example 4: Animated explainer (concept visualization)

```
User: /blox:video "animated explainer of how our recommendation
       algorithm works — for the marketing page"

STEP 1 — Storyboard:
  Brand loaded.
  Video type: ANIMATION (explainer hybrid)
  Duration: ~60 seconds
  Platform: website marketing page

  "Storyboard: Recommendation Algorithm Explainer

   Scene 1: The Question (0:00 - 0:10)
   Visual: Abstract user icons browsing products. Thought bubbles
   with question marks. Animated in flat, geometric style using
   brand colors.
   Audio: Curious, building music. Narrator poses the question.
   Text: 'How do we know what you'll love?'

   Scene 2: Data Collection (0:10 - 0:25)
   Visual: User interactions visualized — clicks, views, purchases
   becoming colorful data points flowing into a central system.
   Motion graphics, smooth animations.
   Audio: Narrator explains data signals. Subtle data processing SFX.
   Text: Signal types appearing as floating labels

   Scene 3: The Algorithm (0:25 - 0:40)
   Visual: Data points being sorted, connected, patterns emerging.
   Neural network visualization (simplified, beautiful). Connections
   lighting up in brand primary color.
   Audio: Music builds. Narrator simplifies the AI process.
   Text: 'Pattern matching at scale'

   Scene 4: The Result (0:40 - 0:55)
   Visual: Personalized recommendations appearing on a device screen.
   User smiling (illustrated). Products perfectly matched.
   Audio: Satisfying 'click' moment. Music resolves warmly.
   Text: 'Your perfect match. Every time.'

   Scene 5: CTA (0:55 - 1:00)
   Visual: Brand logo + product screen. CTA button animated.
   Audio: Music ends. Narrator CTA.
   Text: 'Try it free — see your recommendations'

   This is best produced as a motion graphics animation.
   Tools: After Effects, Lottie, or Rive for web-native animation.
   Confirm?"

[Steps 2-3 follow with narration script and animation asset list]
```

---

## FUTURE: VIDEO GENERATION INTEGRATION

> **This section documents the planned premium mode for when video generation
> plugins become available. It is NOT currently functional.**

When video generation plugins (Veo, Sora, Kling, Runway, etc.) ship as Claude
Code plugins, this skill will extend with:

```
PLANNED Step 4: GENERATE & ITERATE (mirrors /blox:image Step 4)

4a. Generate video clips scene-by-scene using AI
4b. Show preview of each scene to user
4c. Offer refinement: "Adjust this scene? a) different pacing b) different
    angle c) different style d) looks good — next scene"
4d. Assemble scenes into final video
4e. Add narration (AI voiceover or user recording)
4f. Export in target format and save to project

The storyboard from Step 1 becomes the generation blueprint.
The script from Step 2 drives the voiceover.
The shot list from Step 3 maps to camera/style parameters.
```

This architecture means the pre-production work done TODAY in basic mode will
directly feed the generation pipeline TOMORROW — nothing is wasted.

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Engineering patterns (content strategy)
- `skills/brand/SKILL.md` — Brand identity (consumed for video tone and colors)
- `skills/image/SKILL.md` — Image generation (scene previews, thumbnails)
- `skills/design/SKILL.md` — UI/UX design (screen recordings reference design specs)
- `skills/check/SKILL.md` — Quality review (brand voice consistency in scripts)
- `registry/curated-plugins.yaml` — Plugin detection (future video plugins)
