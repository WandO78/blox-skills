# Blox Media Pipeline — Implementation Plan (Plan 3 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the clean `blox:media` cornerstone — one flow for image · video · animation · audio — driven by the fal.ai tiered registry (Plan 1) with cost-quoted-before-paid generation, plus references that wire in video-use (ingest/trim/edit), HyperFrames (animate/render), and the audio tiers (Parakeet/Kokoro local → ElevenLabs premium).

**Architecture:** A fresh skill `skills/media/` (replaces old `blox:image`/`blox:video` — their removal happens in Plan 4). A single `scripts/generate.py` reads `registry/models.json` (built in Plan 1) and exposes `list` / `cost` (offline) and `run` (needs `FAL_KEY`). The SKILL.md is lean orchestration + the cost protocol; engine details (video-use, HyperFrames, audio) live in `references/` loaded on demand. Remotion rules are carried over from the old video skill as a HyperFrames-adjacent fallback.

**Tech Stack:** Python 3 (`fal_client` for generation, imported lazily so `list`/`cost` work without it), ffmpeg/ffprobe (upscale fps logic), markdown skill. Runtime path: `${CLAUDE_PLUGIN_ROOT}/skills/media/...`. Branch `feat/design-media-consolidation`.

**Spec:** `docs/superpowers/specs/2026-06-15-blox-design-media-consolidation-design.md` · **Depends on:** Plan 1 (registry).

---

## File Structure
- Create: `skills/media/scripts/generate.py` (fal.ai generation driven by the tiered registry)
- Create: `skills/media/scripts/test_generate.py` (offline tests: registry load, tier resolution, cost math)
- Create: `skills/media/config.json` (output dir)
- Create: `skills/media/SKILL.md` (clean orchestration + cost protocol + pipeline)
- Create: `skills/media/references/video-editing.md` (video-use ingest/trim/edit workflow)
- Create: `skills/media/references/animation-render.md` (HyperFrames + Remotion render workflow)
- Create: `skills/media/references/audio.md` (Parakeet/Kokoro local → ElevenLabs premium)
- Create: `skills/media/references/remotion-rules/` (copied from `skills/video/remotion-rules/`)

> `skills/media/registry/{models.json,validate_registry.py,test_validate_registry.py}` already exist from Plan 1.

---

## Task 1: `generate.py` driven by the tiered registry (TDD on the offline logic)

**Files:** Create `skills/media/scripts/generate.py`, `skills/media/scripts/test_generate.py`, `skills/media/config.json`

- [ ] **Step 1: Write the failing offline tests** — `skills/media/scripts/test_generate.py`:

```python
import sys, pathlib, importlib.util
HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location("gen", HERE / "generate.py")
gen = importlib.util.module_from_spec(spec); spec.loader.exec_module(gen)

def test_registry_loads_six_tasks():
    reg = gen.load_registry()
    assert len(reg["tasks"]) == 6

def test_resolve_defaults_to_task_default_tier():
    fal_id, entry = gen.resolve("text_to_image", None)
    assert entry["tier"] == "balanced" and fal_id == "fal-ai/nano-banana-pro"

def test_resolve_explicit_tier():
    fal_id, entry = gen.resolve("text_to_image", "budget")
    assert fal_id == "fal-ai/flux/schnell"

def test_cost_per_image_known_price():
    entry = gen.resolve("text_to_image", "budget")[1]
    q = gen.estimate_cost(entry, count=4, duration=None)
    assert q["known"] is True and abs(q["usd"] - 0.012) < 1e-9

def test_cost_per_second_known_price():
    entry = gen.resolve("upscale_video", "balanced")[1]
    q = gen.estimate_cost(entry, count=1, duration=10)
    assert q["known"] is True and abs(q["usd"] - 0.20) < 1e-9

def test_cost_null_price_is_unknown():
    entry = gen.resolve("image_to_video", "balanced")[1]
    q = gen.estimate_cost(entry, count=1, duration=5)
    assert q["known"] is False  # price_usd null -> verify live

def test_deep_get():
    assert gen.deep_get({"images":[{"url":"x"}]}, "images[0].url") == "x"
```

- [ ] **Step 2: Run, confirm FAIL** — `cd skills/media/scripts && python3 -m pytest test_generate.py -v` → fails (generate.py missing).

- [ ] **Step 3: Write `skills/media/scripts/generate.py`** (use exactly this):

```python
"""blox:media — fal.ai generation driven by the tiered registry.

Offline (no FAL_KEY): `list`, `cost`.  Live (needs FAL_KEY): `run`.

  python generate.py list [--task TASK]
  python generate.py cost --task TASK [--tier budget|balanced|premium] [--count N] [--duration SECS]
  python generate.py run  --task TASK [--tier ...] --prompt "..." --title "slug"
                          [--input-image P ...] [--image P] [--input P]
                          [--count N] [--duration SECS] [--aspect-ratio R] [--resolution R]
                          [--folder DIR]

`run` resolves the model from registry/models.json, generates, downloads to a dated
folder, and writes prompt.md. Image tasks output PNG, video tasks MP4, tts MP3.
"""
from __future__ import annotations
import argparse, json, os, re, shutil, subprocess, sys, time, urllib.request
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
IMAGE_TASKS = {"text_to_image", "image_edit", "upscale_image"}
VIDEO_TASKS = {"image_to_video", "upscale_video"}
AUDIO_TASKS = {"tts"}

def load_registry() -> dict:
    return json.loads((SKILL_ROOT / "registry" / "models.json").read_text(encoding="utf-8"))

def load_config() -> dict:
    p = SKILL_ROOT / "config.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {"output_dir": "~/Documents/Blox Media"}

def resolve(task: str, tier: str | None):
    reg = load_registry()
    if task not in reg["tasks"]:
        raise SystemExit(f"unknown task '{task}'. Available: {list(reg['tasks'])}")
    spec = reg["tasks"][task]
    tier = tier or spec["default"]
    if tier not in spec["tiers"]:
        raise SystemExit(f"task '{task}' has no tier '{tier}'. Available: {list(spec['tiers'])}")
    return spec["tiers"][tier]["fal_id"], spec["tiers"][tier]

def estimate_cost(entry: dict, count: int = 1, duration: float | None = None) -> dict:
    price = entry.get("price_usd")
    unit = entry.get("unit")
    if price is None:
        return {"known": False, "unit": unit, "fal_id": entry["fal_id"]}
    if unit == "per_second":
        d = duration if duration is not None else (entry.get("default_args", {}).get("duration", 5))
        usd = price * d * count
    elif unit in ("per_image", "per_request"):
        usd = price * count
    else:
        usd = price * count
    return {"known": True, "usd": round(usd, 4), "unit": unit, "fal_id": entry["fal_id"]}

def slugify(text: str) -> str:
    s = re.sub(r"[^\w\s-]", "", text.lower()); s = re.sub(r"[-\s]+", "-", s).strip("-")
    return s[:50] or "untitled"

def expand_path(p: str) -> Path:
    return Path(os.path.expanduser(os.path.expandvars(p)))

def get_or_make_folder(output_dir: Path, title: str) -> Path:
    folder = output_dir / f"{time.strftime('%Y-%m-%d')}-{slugify(title)}"
    folder.mkdir(parents=True, exist_ok=True); return folder

def next_index(folder: Path, kind: str, ext: str) -> int:
    pat = re.compile(rf"^{kind}-(\d+)\.{ext}$")
    used = [int(m.group(1)) for f in folder.iterdir() if (m := pat.match(f.name))]
    return (max(used) + 1) if used else 1

def deep_get(obj, dotted: str):
    cur = obj
    for part in dotted.split("."):
        m = re.match(r"^(\w+)\[(\d+)\]$", part)
        cur = cur[m.group(1)][int(m.group(2))] if m else cur[part]
    return cur

def download(url: str, dest: Path) -> None:
    urllib.request.urlretrieve(url, dest)

def _require_key():
    if not os.environ.get("FAL_KEY"):
        raise SystemExit("FAL_KEY not set. export FAL_KEY=... in ~/.zshrc (get one at fal.ai/dashboard/keys)")

def _quote_line(task, tier_entry, count, duration):
    q = estimate_cost(tier_entry, count, duration)
    if q["known"]:
        return f"{q['fal_id']} ({task}): ~${q['usd']} ({q['unit']}, count={count}" + (f", {duration}s" if duration else "") + ")"
    return f"{q['fal_id']} ({task}): price not cached — verify live at https://fal.ai/models/{q['fal_id']} before quoting"

def cmd_list(args):
    reg = load_registry()
    tasks = [args.task] if args.task else list(reg["tasks"])
    for t in tasks:
        spec = reg["tasks"][t]
        print(f"\n{t}  (default: {spec['default']})")
        for name, e in spec["tiers"].items():
            price = f"${e['price_usd']}/{e['unit']}" if e.get("price_usd") is not None else f"{e['unit']} (verify live)"
            print(f"  - {name:9} {e['fal_id']:42} {price}  — {e['best_for']}")

def cmd_cost(args):
    _, entry = resolve(args.task, args.tier)
    print(_quote_line(args.task, entry, args.count, args.duration))

def cmd_run(args):
    _require_key()
    try:
        import fal_client
    except ImportError:
        raise SystemExit("fal_client not installed. pip install fal-client")
    fal_id, spec = resolve(args.task, args.tier)
    call = dict(spec.get("default_args", {}))
    if args.aspect_ratio: call["aspect_ratio"] = args.aspect_ratio
    if args.resolution: call["resolution"] = args.resolution
    if args.duration is not None: call["duration"] = args.duration

    out_dir = expand_path(load_config().get("output_dir", "~/Documents/Blox Media"))
    folder = expand_path(args.folder) if args.folder else get_or_make_folder(out_dir, args.title)
    folder.mkdir(parents=True, exist_ok=True)

    if args.task in AUDIO_TASKS:
        call["text"] = args.prompt; kind, ext = "audio", "mp3"
    elif args.task == "image_to_video":
        if not args.image: raise SystemExit("image_to_video needs --image (start frame)")
        call["image_url"] = fal_client.upload_file(str(expand_path(args.image)))
        call["prompt"] = args.prompt; kind, ext = "video", "mp4"
    elif args.task in ("upscale_image", "upscale_video"):
        if not args.input: raise SystemExit("upscale needs --input (source file)")
        src = fal_client.upload_file(str(expand_path(args.input)))
        call["video_url" if args.task == "upscale_video" else "image_url"] = src
        kind, ext = ("video", "mp4") if args.task == "upscale_video" else ("image", "png")
    else:  # text_to_image / image_edit
        call["prompt"] = args.prompt; kind, ext = "image", "png"
        if args.input_image:
            call["image_urls"] = [fal_client.upload_file(str(expand_path(p))) for p in args.input_image]

    sys.stderr.write(f"[blox:media] {args.task} via {fal_id} ...\n"); sys.stderr.flush()
    result = fal_client.subscribe(fal_id, arguments=call, with_logs=False)
    url = deep_get(result, spec["output_path"])
    idx = next_index(folder, kind, ext)
    out = folder / f"{kind}-{idx:02d}.{ext}"
    download(url, out)

    md = folder / "prompt.md"
    with md.open("a", encoding="utf-8") as f:
        f.write(f"\n## {args.task} ({fal_id})\n- file: {out.name}\n- prompt: {args.prompt}\n")
    print(json.dumps({"path": str(out), "folder": str(folder), "model": fal_id, "fal_url": url}))

def build_parser():
    p = argparse.ArgumentParser(prog="blox-media")
    sub = p.add_subparsers(dest="cmd", required=True)
    pl = sub.add_parser("list"); pl.add_argument("--task"); pl.set_defaults(func=cmd_list)
    pc = sub.add_parser("cost")
    pc.add_argument("--task", required=True); pc.add_argument("--tier"); pc.add_argument("--count", type=int, default=1)
    pc.add_argument("--duration", type=float, default=None); pc.set_defaults(func=cmd_cost)
    pr = sub.add_parser("run")
    pr.add_argument("--task", required=True); pr.add_argument("--tier")
    pr.add_argument("--prompt", default=""); pr.add_argument("--title", default="untitled")
    pr.add_argument("--input-image", dest="input_image", action="append")
    pr.add_argument("--image"); pr.add_argument("--input")
    pr.add_argument("--count", type=int, default=1); pr.add_argument("--duration", type=float, default=None)
    pr.add_argument("--aspect-ratio", dest="aspect_ratio"); pr.add_argument("--resolution")
    pr.add_argument("--folder"); pr.set_defaults(func=cmd_run)
    return p

if __name__ == "__main__":
    a = build_parser().parse_args(); a.func(a)
```

- [ ] **Step 4: Write `skills/media/config.json`:**
```json
{
  "output_dir": "~/Documents/Blox Media",
  "_comment": "Output root. Each generation makes a dated subfolder. Tilde/env expansion supported."
}
```

- [ ] **Step 5: Run tests, confirm PASS, and smoke-test the offline commands**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills/skills/media/scripts
python3 -m pytest test_generate.py -v          # all pass
python3 generate.py list                        # prints 6 tasks with tiers/prices
python3 generate.py cost --task text_to_image --count 3     # known price -> ~$0.15
python3 generate.py cost --task image_to_video --duration 5 # null price -> "verify live"
```
Expected: tests pass; `list` shows 6 tasks; cost prints a dollar figure for text_to_image and a "verify live" line for image_to_video.

- [ ] **Step 6: Commit**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
git add skills/media/scripts/generate.py skills/media/scripts/test_generate.py skills/media/config.json
git commit -m "feat(media): registry-driven fal.ai generate.py (list/cost offline, run live)"
```

---

## Task 2: blox:media SKILL.md + references (+ carry over remotion-rules)

**Files:** Create `skills/media/SKILL.md`, `references/{video-editing,animation-render,audio}.md`, copy `references/remotion-rules/`

- [ ] **Step 1: Copy the Remotion rules from the old video skill**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
mkdir -p skills/media/references
cp -R skills/video/remotion-rules skills/media/references/remotion-rules
ls skills/media/references/remotion-rules | wc -l   # ~37 files
```

- [ ] **Step 2: Write `skills/media/references/video-editing.md`** (video-use workflow):
```markdown
# Video editing (real footage) — via video-use

Use when the user has their OWN footage to cut/assemble (e.g. "edit these clips into a 3-min video").
Tool: video-use (transcript-driven editor). Prereq: `ffmpeg` + `ELEVENLABS_API_KEY`; clone at `~/Developer/video-use`
(see /blox:setup doctor). It is itself a skill — drive it per its SKILL.md. Flow:

1. Drop source files in a folder. Transcribe: `python helpers/transcribe_batch.py <dir>`
2. Pack transcripts: `python helpers/pack_transcripts.py --edit-dir <dir>/edit`
3. The agent reads the packed transcript and writes an EDL (`edl.json`: source/start/end/reason ranges) —
   cut filler, pick best takes, order beats.
4. Render: `python helpers/render.py edl.json -o final.mp4 --build-subtitles`
   (grade + 30ms fades + subtitles + -14 LUFS loudnorm). Overlays/animation come from HyperFrames
   (see animation-render.md) — video-use composites them.
Generated b-roll/clips from generate.py (image_to_video) can be added as additional sources.
```

- [ ] **Step 3: Write `skills/media/references/animation-render.md`** (HyperFrames + Remotion):
```markdown
# Animation & render — HTML→MP4

Primary engine: HyperFrames (agent-native, Apache-2.0). Use for motion graphics, kinetic captions,
lower-thirds, transitions, animated/scroll-embeddable decks, and final MP4 assembly.
Prereq: Node 22+ + ffmpeg (see /blox:setup doctor). In automated runs set `DO_NOT_TRACK=1`
and disable auto-update.

  npx hyperframes init <dir>      # scaffold an HTML composition
  npx hyperframes preview         # live browser preview
  npx hyperframes render -o out.mp4

Author the composition as index.html with timed `.clip` elements (`data-start`/`data-duration`/
`data-track-index`) and seekable timelines (GSAP/Lottie/CSS). For scroll-embeddable output use the
HyperFrames player web component.

Fallback (only if the project already uses Remotion): the 37 domain rule files in `remotion-rules/`
(load on demand) cover animations, captions, charts, 3D, transitions, audio. Prefer HyperFrames for new work.
```

- [ ] **Step 4: Write `skills/media/references/audio.md`** (tiers):
```markdown
# Audio — local-first, premium fallback

Default to the FREE/LOCAL tier; escalate to ElevenLabs only for what local can't do.

TTS / narration:
- DEFAULT: Kokoro (local, free, Apache-2.0). `pip install kokoro` + espeak-ng. English voices strongest.
  Or via fal.ai: generate.py `--task tts` (fal-ai/kokoro/american-english).
- ESCALATE to ElevenLabs (`ELEVENLABS_API_KEY`) for cloned/expressive/premium voices or weak languages.

Transcription / STT (for captions, or feeding video-use):
- DEFAULT: Parakeet v3 (local, free, CC-BY-4.0; 25 EU langs incl. Hungarian; word timestamps; runs on
  Apple Silicon via `parakeet-mlx`). No diarization.
- ESCALATE to ElevenLabs Scribe when you need speaker DIARIZATION (who-spoke-when, up to 32),
  audio-event tags, AUDIO ISOLATION (denoise), DUBBING, or forced alignment.
Note: ElevenLabs "isolation" = voice vs background (one clean track), NOT per-speaker stems.

Always check /blox:setup doctor for the relevant key/package before running.
```

- [ ] **Step 5: Write `skills/media/SKILL.md`** (lean orchestration). Use exactly this:
```markdown
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
```

- [ ] **Step 6: Validate and commit**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
grep -q "^name: blox-media" skills/media/SKILL.md && grep -q "## AUTO-DISCOVERY" skills/media/SKILL.md && echo "skill ok"
ls skills/media/references/remotion-rules | wc -l
./scripts/validate.sh | tail -3      # must include blox-media now, VALIDATION PASSED
git add skills/media/SKILL.md skills/media/references
git commit -m "feat(media): add blox:media skill + video/animation/audio references"
```
Expected: `skill ok`, ~37 remotion files, VALIDATION PASSED (now 23 skills).

---

## Task 3: Live smoke test (requires FAL_KEY — user provides)

- [ ] **Step 1: Confirm key, then cheapest possible live generation**
Ask the user to set `FAL_KEY` (via `! export FAL_KEY=...` in the prompt, or `~/.zshrc`). Then run the CHEAPEST task to confirm the live path end-to-end:
```bash
cd /Users/wando/Documents/dev/skill/wando-skills/skills/media/scripts
python3 generate.py cost --task text_to_image --tier budget --count 1   # ~$0.003
pip install fal-client 2>/dev/null | tail -1
python3 generate.py run --task text_to_image --tier budget --prompt "a single red maple leaf on white, studio photo" --title "smoke-test"
```
Expected: prints a JSON line with `path`/`fal_url`, and the PNG exists in `~/Documents/Blox Media/<date>-smoke-test/`. If `FAL_KEY` isn't provided, SKIP this task and note it — the offline `list`/`cost` already proved the registry path; live gen is verified later.

- [ ] **Step 2: Report** the result (or that it was skipped pending key). Do NOT commit generated media (it's outside the repo).

---

## Self-Review (completed by plan author)
- **Spec coverage:** clean blox:media replacing image/video (§4) → Tasks 1-2; cost-quote-before-paid + tier swap (§5) → generate.py `cost` + SKILL.md GENERATE step; video-use/HyperFrames/audio tiers (§3) → references; preflight/doctor integration (§6) → SKILL PREFLIGHT. Removal of old image/video skills + router wiring is deferred to Plan 4 (noted).
- **Placeholder scan:** bracketed tokens (`<task>`, `<slug>`, `[--tier ...]`) are runtime arg placeholders in skill instructions, not plan gaps. generate.py and tests are complete.
- **Consistency:** registry field names (`tasks`, `tiers`, `default`, `fal_id`, `tier`, `price_usd`, `unit`, `default_args`, `output_path`) match Plan 1's models.json and the validator exactly. `estimate_cost` units (`per_image`/`per_second`/`per_request`) match the seeded registry. Test expectations (text_to_image balanced=nano-banana-pro, budget=flux/schnell; upscale_video 0.02×10=0.20; image_to_video price null) match the seeded values.
