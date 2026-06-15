# Blox Slides + Router + Cleanup + Release — Implementation Plan (Plan 4 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Finish the design package: add the `blox:slides` cornerstone (absorbing the loose marp-slides skill), rewrite the `blox:design` router so ALL design routes correctly (image/video/animation/audio → `blox:media`; presentations → `blox:slides`), remove the now-replaced `blox:image`/`blox:video` skills + fix cross-references, then bump the plugin to **2.0.0** and validate. STOP before any push-to-main/sync (that publishes — user-gated).

**Architecture:** All edits in `wando-skills` on branch `feat/design-media-consolidation`. New `skills/slides/` carries a lean SKILL.md + a `references/marp-guide.md` (the marp v2 knowledge) + `references/examples/` (22 decks). Corporate/Veolia themes are NOT copied into this public skill (the repo syncs to public blox-skills) — only generic dark/light templates; any corporate theme lives in `extensions/` (private, stripped on sync). The router rewrite swaps image/video routing for media and adds slides. Old image/video skills are deleted and their references repointed to `blox:media`.

**Tech Stack:** Markdown skills, `scripts/validate.sh`, `scripts/bump-version.sh major`. **Global loose-dir cleanup of `~/.claude/skills` and the merge/sync are deliberately OUT of this plan — they are user-gated final steps (see end).**

**Spec:** `docs/superpowers/specs/2026-06-15-blox-design-media-consolidation-design.md` · **Depends on:** Plans 1-3.

---

## File Structure
- Create: `skills/slides/SKILL.md`, `skills/slides/references/marp-guide.md`, `skills/slides/references/examples/` (22 decks)
- Modify: `skills/design/SKILL.md` (router: image/video→media, add slides)
- Delete: `skills/image/`, `skills/video/`
- Modify: `skills/ui/SKILL.md`, `skills/brand/SKILL.md` (repoint `/blox:image`→`/blox:media`), `registry/curated-plugins.yaml` (blox:image→blox:media; fold blox:video/remotion note into blox:media)
- Modify (version): `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.sync/plugin.json`, `.sync/marketplace.json` (via bump-version.sh)

---

## Task 1: blox:slides cornerstone (absorb marp-slides)

**Files:** Create `skills/slides/SKILL.md`, `skills/slides/references/marp-guide.md`, copy examples.

- [ ] **Step 1: Copy the 22 example decks (public, generic) into the skill**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
mkdir -p skills/slides/references/examples
cp ~/.claude/skills/marp-slides/examples/*.md skills/slides/references/examples/
ls skills/slides/references/examples | wc -l   # expect 22
```

- [ ] **Step 2: Build `skills/slides/references/marp-guide.md` from the loose marp-slides SKILL.md body — but STRIP the corporate/Veolia section**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
# Start from the marp v2 knowledge, then remove the corporate-themes block (absolute Veolia path must NOT go public).
python3 - <<'PY'
import re, pathlib
src = pathlib.Path.home() / ".claude/skills/marp-slides/SKILL.md"
text = src.read_text(encoding="utf-8")
# drop YAML frontmatter
text = re.sub(r"^---\n.*?\n---\n", "", text, count=1, flags=re.S)
# remove the "## Corporate Themes" section up to the next "## " heading (keeps it out of the PUBLIC skill)
text = re.sub(r"\n## Corporate Themes.*?(?=\n## )", "\n", text, flags=re.S)
header = ("# MARP deck guide (vendored from marp-slides v2)\n"
          "# Generic dark/light templates, components, SVG charts, export.\n"
          "# Corporate/branded themes are NOT here — they live in the private extensions/ tree.\n\n")
(pathlib.Path("skills/slides/references/marp-guide.md")).write_text(header + text.strip() + "\n", encoding="utf-8")
print("marp-guide.md written")
PY
grep -ci 'veolia' skills/slides/references/marp-guide.md   # MUST be 0
wc -l skills/slides/references/marp-guide.md
```
Expected: `veolia` count is **0**; file is substantial (~180+ lines). If the count is not 0, manually remove any Veolia/absolute-path lines before proceeding.

- [ ] **Step 3: Write `skills/slides/SKILL.md`** (use exactly this):
```markdown
---
name: blox-slides
description: "Create presentation decks — MARP markdown slides (charts, dashboards, dark/light themes) or HTML decks, designed on real principles and brand. Use when the user wants slides, a deck, a presentation, or a pitch."
user-invocable: true
argument-hint: "[describe the deck you need]"
---

## Language Protocol
Detect the user's language from the conversation. All deck CONTENT follows THEIR language;
these instructions stay in English.

## Context Discovery
Reads project + brand state at runtime via Read/Glob/Grep/Bash. Pulls brand context
(`docs/brand-guidelines.md`, design tokens) when present so decks are on-brand.

# /blox:slides

> **Purpose:** Build presentation decks that look designed, not defaulted. Applies real
> slide-design principles + a QA gate, pulls brand context, and pulls images/charts from
> /blox:media. Output as MARP markdown (default) or HTML; animated/scroll-embeddable decks
> via HyperFrames.

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-slides
category: domain
complements: [blox-design, blox-brand, blox-media]

### Triggers — when the agent invokes automatically
trigger_keywords: [slides, slide, deck, presentation, pitch, keynote, powerpoint, marp, prezentacio, dia, bemutato]
trigger_files: []
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the user wants a presentation / deck / pitch. Routed from /blox:design for
  presentation tasks, or invoked directly. Uses /blox:brand for identity and /blox:media for
  any generated imagery. For non-slide UI use /blox:ui.
auto_invoke: false
priority: recommended

---

## DESIGN RULES & QA GATE (apply to every deck)
Slides ARE design — ground them in the bundled knowledge, never wing it:
- **Principles & QA gate:** the 21-point checklist at
  `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/qa-checklist.md` is written
  for slide design (one idea/slide, ≤3s glanceable, ≥40% whitespace, ≤4 type sizes, 8pt grid,
  WCAG contrast). Run every deck through it before delivering. Deeper rationale:
  `.../power-design/design-principles.md`.
- **Palettes / font pairings:** query `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/ui-ux-pro-max/search.py`.

## BUILD A DECK
1. **Read 2-3 matching example decks first** from `references/examples/` (22 curated decks: dashboards,
   editorial, how-to, travel, hero…) — they are the quality bar for composition and density.
2. Follow `references/marp-guide.md` for themes (dark/light), components (metric cards, status dots,
   charts), interactive elements, image rules, and export. Default 16:9, generic dark template unless
   brand says otherwise.
3. Pull **brand** context (palette/type/voice) when present so the deck is on-brand. Generate any
   needed images/charts via **/blox:media** (cost shown before paid generation).
4. **Export (MARP):** `npx @marp-team/marp-cli slides.md --pdf --allow-local-files` (also `--pptx`, `--html`).
   Relative image paths only.
5. **Animated / scroll-embeddable deck?** Use HyperFrames (HTML→MP4 / player web component) —
   see `${CLAUDE_PLUGIN_ROOT}/skills/media/references/animation-render.md`.

> Corporate/branded themes (e.g. a company template) are NOT bundled here; if the project has one
> in the private extensions tree, load it from there. Otherwise use the generic templates.

## INVARIANTS
- Read example decks before generating. Run the QA gate before delivering.
- One idea per slide; never overflow (it clips silently).
- Relative image paths only. Pull brand context when it exists.

## REFERENCES
- `references/marp-guide.md` — MARP themes, components, charts, export (vendored from marp-slides v2)
- `references/examples/` — 22 curated reference decks (read before generating)
- `${CLAUDE_PLUGIN_ROOT}/references/design-knowledge/power-design/qa-checklist.md` — 21-point QA gate
- `skills/media/references/animation-render.md` — HyperFrames for animated/scroll decks
```

- [ ] **Step 4: Validate + commit**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
grep -q "^name: blox-slides" skills/slides/SKILL.md && grep -q "## AUTO-DISCOVERY" skills/slides/SKILL.md && echo "skill ok"
ls skills/slides/references/examples | wc -l
grep -ci veolia skills/slides/references/marp-guide.md   # 0
./scripts/validate.sh | tail -3
git add skills/slides
git commit -m "feat(slides): add blox:slides (absorbs marp-slides, generic themes only)"
```
Expected: `skill ok`, 22 examples, veolia=0, VALIDATION PASSED (24 skills).

---

## Task 2: Rewrite the blox:design router (image/video → media; + slides)

**Files:** Modify `skills/design/SKILL.md`

- [ ] **Step 1: Read the whole router** (`skills/design/SKILL.md`, 365 lines). Understand Step 1 (load brand), Step 2 CLASSIFY, Step 3 ROUTE, and the Examples.

- [ ] **Step 2: Apply this transformation consistently throughout the file** (preserve frontmatter shape + `## AUTO-DISCOVERY` block structure, but update their content as below):
  - **description** (line ~3): change to: `"Use when the user needs any visual/creative work — UI design, logo, image, video, animation, audio, or a presentation. Routes to the right specialized skill (/blox:ui, /blox:media, /blox:slides) after loading brand context and classifying the task."`
  - **AUTO-DISCOVERY complements** (line ~35): `complements: [blox-ui, blox-media, blox-slides, blox-brand]`
  - **trigger_keywords** (line ~38): add `presentation, slides, deck, animation, audio, prezentacio, dia` (keep existing).
  - **CLASSIFY (Step 2)**: replace the IMAGE and VIDEO keyword buckets with a single **MEDIA** bucket (→ `/blox:media`) covering image/logo/icon/illustration/hero/asset AND video/animation/motion/storyboard AND audio/voiceover/tts/music/upscale/transcribe (EN + HU). Add a **SLIDES** bucket (→ `/blox:slides`) for presentation/deck/slides/pitch (EN + HU). Keep UI bucket (→ `/blox:ui`) and BRAND (suggest `/blox:brand`).
  - **ROUTE (Step 3)**: replace `IMAGE → /blox:image` and `VIDEO → /blox:video` with `MEDIA → /blox:media`; add `SLIDES → /blox:slides`. Update the "invoke Skill(...)" lines accordingly (`blox:media`, `blox:slides`).
  - **All examples + phase-hint lines + WHEN-TO-USE table**: any `/blox:image` or `/blox:video` becomes `/blox:media`; add a presentation example routing to `/blox:slides`. Update the example narration text (e.g. "Routing to /blox:media").
  - **Compound flows** (e.g. logo first then page): `logo/image first → /blox:media`, then `page/UI → /blox:ui`.

- [ ] **Step 3: Verify no stale routing remains + validate**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
grep -nE 'blox:image|blox:video|blox-image|blox-video|/blox:image|/blox:video' skills/design/SKILL.md && echo "STALE REFS FOUND — fix them" || echo "no stale image/video routing"
grep -q 'blox:media' skills/design/SKILL.md && grep -q 'blox:slides' skills/design/SKILL.md && echo "media+slides routing present"
./scripts/validate.sh | tail -3
```
Expected: "no stale image/video routing", "media+slides routing present", VALIDATION PASSED.

- [ ] **Step 4: Commit**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
git add skills/design/SKILL.md
git commit -m "feat(design): route image/video/animation/audio→blox:media, add blox:slides"
```

---

## Task 3: Remove old image/video skills + repoint cross-references

**Files:** Delete `skills/image/`, `skills/video/`; modify `skills/ui/SKILL.md`, `skills/brand/SKILL.md`, `registry/curated-plugins.yaml`, and example mentions in `skills/_internal/detect/SKILL.md` + `skills/setup/SKILL.md`.

- [ ] **Step 1: Delete the replaced skills**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
git rm -r skills/image skills/video
```

- [ ] **Step 2: Repoint references `/blox:image` (and image-generation plugin mentions) → `/blox:media`** in `skills/ui/SKILL.md` (lines ~69, ~983, ~1314) and `skills/brand/SKILL.md` (lines ~51, ~72, ~690, ~924). Read each line and update: `/blox:image` → `/blox:media`; `skills/image/SKILL.md — Image/asset generation` → `skills/media/SKILL.md — Media generation (images, video, audio)`. The "if image-generation plugin available" caveats become "via /blox:media". Do NOT introduce `/blox:video` anywhere (media covers it).

- [ ] **Step 3: Update `registry/curated-plugins.yaml`** — the entry/triggers referencing `blox:image` (line ~98) → `blox:media`; the `blox:video` + Remotion entry (lines ~146-148): change the trigger skill to `blox:media` and the description to note Remotion rules are bundled in `blox:media` (`references/remotion-rules/`). Keep YAML valid.

- [ ] **Step 4: Update the illustrative example mentions** in `skills/_internal/detect/SKILL.md` (lines ~61, ~110, ~270, ~401) and `skills/setup/SKILL.md` (line ~416): change `blox:image` → `blox:media` in the examples so docs stay consistent. These are examples, not logic — keep surrounding text intact.

- [ ] **Step 5: Verify NO dangling references remain repo-wide + validate**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
grep -rnE 'blox:image|blox:video|blox-image|blox-video|skills/image|skills/video' skills registry references 2>/dev/null && echo "STILL HAS REFS — fix" || echo "clean: no image/video refs anywhere"
test ! -d skills/image && test ! -d skills/video && echo "old skills removed"
./scripts/validate.sh | tail -3
```
Expected: "clean: no image/video refs anywhere", "old skills removed", VALIDATION PASSED (24 skills: was 23 + slides − image − video = 22... NOTE expected count below).

> Skill count math: Plan-3 end = 23 (after +media). This plan: +slides (24), −image (23), −video (22). So validate should report **22 skills**.

- [ ] **Step 6: Commit**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
git add -A
git commit -m "refactor: remove blox:image/blox:video (replaced by blox:media), repoint refs"
```

---

## Task 4: Version bump to 2.0.0 + final validation

- [ ] **Step 1: Bump major version**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
./scripts/bump-version.sh major   # 1.14.1 -> 2.0.0
grep '"version"' .claude-plugin/plugin.json | head -1
```
Expected: prints `1.14.1 → 2.0.0` and plugin.json shows `2.0.0`.

- [ ] **Step 2: Final full validation**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
./scripts/validate.sh | tail -4
# registry + media tests still green:
( cd skills/media/registry && python3 -m pytest -q | tail -1 )
( cd skills/media/scripts  && python3 -m pytest -q | tail -1 )
```
Expected: VALIDATION PASSED (22 skills), both pytest suites pass.

- [ ] **Step 3: Commit the version bump**
```bash
cd /Users/wando/Documents/dev/skill/wando-skills
git add -A
git commit -m "chore: bump blox 1.14.1 → 2.0.0 (design/media consolidation)"
git log --oneline main..HEAD | head -20
```

- [ ] **Step 4: STOP. Do NOT push to main / do NOT run the sync.**
Pushing main triggers the GitHub Action that strips `extensions/` and publishes to public blox-skills. That is an outward-facing, user-gated step. Report that the branch is ready and hand the merge/publish decision to the user (superpowers:finishing-a-development-branch).

---

## Out of this plan — user-gated final steps (do NOT auto-run)
1. **Global loose-dir cleanup** of `~/.claude/skills/`: remove `react-best-practices` (dup of vercel:), `.removed-backup/` (image-generation, google-stitch), `marp-slides` (now absorbed into blox:slides), and the `claude-image-gen` marketplace. Present as a reviewed list; back up (move) rather than hard-delete where the user prefers. This touches the user's live global config, so confirm first.
2. **Merge `feat/design-media-consolidation` → main + sync** (publishes to public blox-skills). User decides when.
3. **Reinstall/refresh** the wando-marketplace plugin so the new `blox:media`/`blox:slides`/2.0.0 are active in sessions.

---

## Self-Review (completed by plan author)
- **Spec coverage:** blox:slides absorbing marp (§4/§5) → Task 1; router "all design → blox" (§4) → Task 2; clean replace of image/video (§4, decisions) → Task 3; 2.0.0 major bump (decision) → Task 4; cleanup + sync gated (§7) → "Out of this plan". Corporate/Veolia kept out of the public skill (extensions discipline, §8) → Task 1 Step 2 strips it (asserted veolia=0).
- **Placeholder scan:** bracketed tokens are runtime arg placeholders; the one script (marp-guide extraction) is complete and self-verifying (asserts veolia=0). Router edit is a transformation spec with exact before/after rules — appropriate for a 365-line existing file.
- **Consistency:** new skill names `blox-slides`/`blox-media` match their SKILL.md frontmatter; skill-count math is stated (ends at 22); every `blox:image`/`blox:video` reference site found by grep is assigned a task step (Task 3 Steps 2-4), and Task 3 Step 5 mechanically asserts zero remaining.
