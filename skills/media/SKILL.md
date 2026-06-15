---
name: blox-media
description: "Create any visual or audio media in one flow — images, video, animation, audio, music. Generates via fal.ai (cost shown before paid runs), edits real footage (video-use), and renders/animates (HyperFrames). Use when the project needs media created, edited, upscaled, transcribed, or voiced."
user-invocable: true
argument-hint: "[describe the media you want]"
---

## Language Protocol
Detect the user's language from the conversation. All user-facing output follows THEIR language;
these instructions stay in English for maintainability.

## Context Discovery
Reads project + brand state at runtime via Read/Glob/Grep/Bash. Pulls brand context from
`docs/brand-guidelines.md` / design tokens when present (consistency).

# /blox:media

> **Purpose:** One pipeline for all media — GENERATE (fal.ai) → EDIT real footage (video-use)
> → ANIMATE/RENDER (HyperFrames) → AUDIO (local Parakeet/Kokoro ⇢ ElevenLabs). The user never
> needs to know which model to use; this skill picks it, shows the cost, and runs it.

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-media
category: domain
complements: [blox-design, blox-brand, blox-ui, blox-slides]

### Triggers — when the agent invokes automatically
trigger_keywords: [image, picture, photo, generate, render, video, animation, animate, audio, voiceover, tts, music, upscale, transcribe, kep, video, hang, zene, animacio]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke for any media creation/editing: generate an image/video, animate, upscale,
  transcribe, isolate audio, or produce a voiceover. Routed from /blox:design for visual
  tasks, or invoked directly. For brand identity use /blox:brand; for UI specs use /blox:ui.
auto_invoke: false
priority: recommended

---

## PREFLIGHT (always first)
Run the design/media doctor and report readiness BEFORE paid/heavy work:
`bash "${CLAUDE_PLUGIN_ROOT}/skills/setup/scripts/doctor.sh"`. State what's ready and what a
requested capability needs (key/tool/package) with the exact fix. Capabilities degrade gracefully
(e.g. no FAL_KEY → can still plan + quote; no ELEVENLABS_API_KEY → local Parakeet/Kokoro only).

## GENERATE (images / video / audio via fal.ai)
The generator is `${CLAUDE_PLUGIN_ROOT}/skills/media/scripts/generate.py`, driven by the curated
tiered registry. The user never names a model.

1. Classify the request into a TASK: `text_to_image | image_edit | image_to_video | upscale_image | upscale_video | tts`.
2. Refine the user's brief into a strong prompt (lighting, composition, mood). Show it; let them edit.
3. **Quote cost BEFORE running** (mandatory):
   `python3 "${CLAUDE_PLUGIN_ROOT}/skills/media/scripts/generate.py" cost --task <task> [--tier ...] [--count N] [--duration S]`
   State the model + refined prompt + the cost line, then wait for an explicit yes.
   - On "cheaper/faster" → re-quote with `--tier budget`. On "4K/best" → `--tier premium`.
   - If cost prints "verify live" (price not cached), WebFetch the fal.ai model page for the per-unit price first; don't guess.
4. Run: `python3 ".../generate.py" run --task <task> --prompt "<refined>" --title "<slug>" [--tier ...] [--image <start frame>] [--input-image <ref> ...] [--input <upscale src>] [--duration 5] [--aspect-ratio 16:9] [--resolution 2K]`.
   Default video duration 5s; only go to 10s after the user approves a 5s draft. For character
   consistency use `--task image_edit` with `--input-image` anchors.
5. See all options anytime: `python3 ".../generate.py" list`.

## EDIT real footage → see references/video-editing.md (video-use)
## ANIMATE / RENDER / scroll-embed → see references/animation-render.md (HyperFrames; Remotion fallback in references/remotion-rules/)
## AUDIO (TTS / transcription / diarization / isolation / dubbing) → see references/audio.md

## INVARIANTS
- Never run a paid generation without quoting cost and getting a yes.
- Never invent a price when the registry says "verify live" — fetch it.
- Save outputs to a dated folder; keep prompt.md provenance.
- Pull brand context (palette/type/voice) when it exists, for consistency.

## REFERENCES
- `skills/media/registry/models.json` — curated fal.ai tiered registry (task × budget/balanced/premium)
- `skills/media/scripts/generate.py` — list / cost / run
- `references/video-editing.md` — video-use real-footage workflow
- `references/animation-render.md` — HyperFrames render + Remotion fallback
- `references/audio.md` — Parakeet/Kokoro local ⇢ ElevenLabs premium
