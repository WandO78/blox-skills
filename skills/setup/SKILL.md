---
name: blox-setup
description: "Slim doctor: report whether blox's companion skills and media/build prerequisites are present, with exact fix commands. Never blocks. Run after /blox:idea or anytime."
user-invocable: true
argument-hint: "[--check-only]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(status output, fix hints) MUST be written in the user's language. The skill logic
instructions below are in English for maintainability, but all OUTPUT facing the
user follows THEIR language.

---

## Context Discovery

This skill reads state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:setup

> **Purpose:** Report whether blox's companion skills + media/build prerequisites
> are present, with exact fix commands. This is a slim DOCTOR — it checks two fixed
> things and never blocks:
>   1. **blox companions** — the sibling skills blox defers to (superpowers, frontend-design, plannotator).
>   2. **media/build prerequisites** — API keys, system tools, and packages the media pipeline needs.
>
> It does NOT scan your project for arbitrary plugins or recommend an external
> ecosystem. It reports readiness for the things blox actually depends on, so you
> know what to install before paid or heavy work begins.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-setup
category: setup
complements: [blox-idea, blox-plan]

### Triggers — when the agent invokes automatically
trigger_keywords: [setup, doctor, prerequisites, companions, check]
trigger_files: [registry/requirements.yaml]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the user runs /blox:setup, when /blox:idea chains to it after plan
  generation, or before any design/media work to report readiness. Reads
  registry/requirements.yaml + runs scripts/doctor.sh, then reports which blox
  companions and media/build prerequisites are present (✓) or missing (✗) with the
  exact fix command. Never installs anything; never blocks.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| After installing blox-skills | First run: "What does blox need?" | No — user invokes |
| `/blox:idea` chains to it | Autopilot: master plan generated, now report readiness | No — idea invokes |
| Before design/media work | "Am I ready to generate images/video?" | No — user invokes |
| User wants a readiness check | "Are my prerequisites set up?" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| During active coding | Don't interrupt flow for a status report | Continue; fix prereqs when needed |
| You only need a project health assessment | This checks blox deps, not project quality | `/blox:scan` |

---

## DESIGN/MEDIA PREFLIGHT

> **When the user requests a design/media capability** (UI, image, video, audio, brand,
> TTS, diarization, dubbing, render) — run the doctor and report readiness BEFORE any
> paid or heavy work, so the user has cost and feasibility transparency up front.

```
RUN  skills/setup/scripts/doctor.sh   → ✓/✗ report of companions, API keys, tools, packages, components
READ registry/requirements.yaml       → needed_for + exact fix command per requirement

FOR the requested capability:
  - Report what is READY (✓) and what is MISSING (✗) with the exact fix command.
  - State that capabilities DEGRADE GRACEFULLY: missing prerequisites mean a fallback
    or skipped step, never a crash (e.g. no FAL_KEY → local Kokoro TTS instead of premium).
  - Only proceed to paid/heavy work after the user has seen the readiness summary.
```

---

## ARGUMENTS

| Flag | Effect |
|------|--------|
| *(none)* | Run the doctor, show the readiness report, and list exact fix commands for anything missing. |
| `--check-only` | Same report. (This skill never installs anything anyway — the flag is a no-op kept for compatibility.) |

---

## SKILL LOGIC

> **The doctor checks TWO fixed things and reports. It never installs, never blocks.**

### Step 1: Run the doctor script

```
RUN: bash skills/setup/scripts/doctor.sh
  → Exits 0 always (informational only).
  → Prints ✓/✗ for blox companions, API keys, system tools, python packages, components.
  → For each ✗, prints the exact fix command.
```

### Step 2: Read the requirements registry

```
READ registry/requirements.yaml
  → companions[]      — superpowers / frontend-design / plannotator (name, needed_for, how)
  → api_keys[]        — FAL_KEY, ELEVENLABS_API_KEY (name, needed_for, how)
  → system_tools[]    — ffmpeg, node, python3, espeak-ng, git (cmd, min, needed_for, how)
  → python_packages[] — fal-client, kokoro, parakeet-mlx (pkg, needed_for, how)
  → components[]      — video-use, hyperframes (name, needed_for, how)

Use this to enrich the doctor output with needed_for context and the canonical fix command.
```

### Step 3: Report readiness

Present a grouped, readable summary:

```
🧩 blox companions
  ✓ superpowers — methodology pillar blox defers to (STRONGLY recommended)
  ✗ frontend-design — production frontend handoff from /blox:ui
     → /plugin install frontend-design
  ✗ plannotator — plan/code annotation UI (optional)
     → /plugin install plannotator

🔑 API keys
  ✓ FAL_KEY
  ✗ ELEVENLABS_API_KEY — diarization, dubbing, premium TTS, video-use transcription
     → export ELEVENLABS_API_KEY=... in ~/.zshrc

🛠 System tools
  ✓ ffmpeg / node / python3 / git
  ✗ espeak-ng — Kokoro local TTS phonemizer → brew install espeak-ng

📦 Python packages
  ✓ fal-client
  ✗ parakeet-mlx → pip install parakeet-mlx

🧱 Components
  ✓ video-use cloned
  ℹ hyperframes — fetched on demand (npx --yes hyperframes)
```

**Rules:**
- ALWAYS show what is present (✓) and what is missing (✗) with the exact fix command.
- companions are NOT mandatory. State the graceful-degradation reality:
  without `superpowers`, blox skills run in a lighter standalone mode; without
  `frontend-design`, /blox:ui still produces code but without the production handoff;
  `plannotator` is purely optional.
- media prerequisites degrade gracefully too (no FAL_KEY → local Kokoro TTS, etc.).
- NEVER install anything. NEVER block. Report and hand the user the commands.

---

## BLOX COMPANIONS

The three sibling skills blox is designed to work with. These are FIXED — not
discovered from a registry, not project-specific.

| Companion | Why blox wants it | Recommendation | Install |
|-----------|-------------------|----------------|---------|
| `superpowers` | The methodology pillar blox defers to (TDD, plan execution, brainstorming, code review). Without it, blox skills run in a lighter standalone mode. | STRONGLY recommended | `/plugin install superpowers` |
| `frontend-design` | Production frontend code handoff from `/blox:ui`. | Recommended for frontend work | `/plugin install frontend-design` |
| `plannotator` | Plan / code annotation UI used by `/blox:plan` for visual review. | Optional | `/plugin install plannotator` |

**Detection:** look for the companion under `~/.claude/plugins/` (the doctor checks
`~/.claude/plugins/cache/*/<name>`). Found → ✓. Not found → ✗ with the install hint.

---

## MEDIA / BUILD PREREQUISITES

Sourced from `registry/requirements.yaml`. The media pipeline (/blox:media, /blox:ui,
/blox:slides) and the build toolchain rely on these. Each degrades gracefully if missing.

- **API keys:** `FAL_KEY` (fal.ai generation), `ELEVENLABS_API_KEY` (diarization, dubbing, premium TTS, video-use transcription).
- **System tools:** `ffmpeg`, `node` (22+), `python3` (3.10+), `espeak-ng`, `git`.
- **Python packages:** `fal-client`, `kokoro`, `parakeet-mlx`.
- **Components:** `video-use` (clone), `hyperframes` (fetched on demand via npx).

The canonical `needed_for` reason and `how` fix command for each live in
`registry/requirements.yaml` — that file is the source of truth, the doctor script mirrors it.

---

## INVARIANTS

1. **Never installs anything** — the doctor only reports and hands the user exact fix commands.
2. **Never blocks** — the script exits 0 always; missing prerequisites mean graceful degradation, not failure.
3. **Fixed scope** — checks exactly two things: blox companions and media/build prerequisites. Never scans the project for arbitrary plugins.
4. **Actionable fixes** — every ✗ includes the exact command (install / export / brew / pip / git clone).
5. **Requirements registry is the source of truth** — `registry/requirements.yaml` defines the prereqs; the doctor script mirrors it.
6. **No AI attribution in output** — no Co-Authored-By, Claude, Opus, Anthropic.

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| `/blox:idea` completes master plan | `/blox:setup` runs | After plan generation (autopilot chain) — reports readiness |
| User requests design/media work | `/blox:setup` (DESIGN/MEDIA PREFLIGHT) | Before any paid or heavy work |
| Setup surfaces deep project issues | `/blox:scan` | If the user wants a full project assessment |

---

## VERIFICATION

### Success indicators
- Doctor script runs and exits 0 (informational, never blocks)
- blox companions reported (superpowers / frontend-design / plannotator) with ✓/✗ and install hint
- Media/build prerequisites reported (API keys, system tools, python packages, components) with ✓/✗ and exact fix
- Every ✗ shows the exact fix command
- Graceful-degradation reality stated for missing items
- No AI attribution in output

### Failure indicators (STOP and fix!)
- Installing anything (INVARIANT 1 violation)
- Blocking or erroring on a missing prerequisite (INVARIANT 2 violation)
- Scanning the project for arbitrary/external plugins (INVARIANT 3 violation)
- A missing item shown without its fix command (INVARIANT 4 violation)
- AI attribution found in output

---

## EXAMPLES

### Example 1: Fresh machine, nothing set up

**User runs `/blox:setup`.** Doctor reports:

```
🧩 blox companions
  ✗ superpowers (STRONGLY recommended) → /plugin install superpowers
  ✗ frontend-design → /plugin install frontend-design
  ✗ plannotator (optional) → /plugin install plannotator

🔑 API keys
  ✗ FAL_KEY → export FAL_KEY=... in ~/.zshrc
  ✗ ELEVENLABS_API_KEY → export ELEVENLABS_API_KEY=...

🛠 System tools
  ✓ git    ✗ ffmpeg → brew install ffmpeg    ✗ node (need 22+) → brew install node
  ...

Nothing blocks. Install superpowers first for the full methodology; the rest as you
need media/build features. blox runs in a lighter standalone mode without them.
```

### Example 2: Everything ready

**User runs `/blox:setup` on a fully configured machine.**

```
🧩 blox companions: ✓ superpowers  ✓ frontend-design  ✓ plannotator
🔑 API keys: ✓ FAL_KEY  ✓ ELEVENLABS_API_KEY
🛠 System tools: ✓ ffmpeg  ✓ node  ✓ python3  ✓ espeak-ng  ✓ git
📦 Python packages: ✓ fal-client  ✓ kokoro  ✓ parakeet-mlx
🧱 Components: ✓ video-use  ℹ hyperframes (on demand)

All set. blox companions and media/build prerequisites are present.
```

### Example 3: Called by /blox:idea autopilot

**`/blox:idea` just generated a master plan; it chains to setup.** The doctor runs,
reports companions + prerequisites readiness, hands the user any fix commands, and
returns control to the autopilot flow without blocking.

---

## REFERENCES

- `registry/requirements.yaml` — Source of truth for media/build prerequisites + blox companions
- `skills/setup/scripts/doctor.sh` — The doctor script (companions + prerequisites check)
