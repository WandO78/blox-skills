---
name: blox-internal-detect
description: "Runtime plugin detection — scans project for trigger matches against curated registry, suggests missing plugins. Called by other skills automatically."
user-invocable: false
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(plugin suggestions, prompts, state file entries) MUST be written in the user's
language. The skill logic instructions below are in English for maintainability,
but all OUTPUT facing the user follows THEIR language.

---

## Current Plugin State (auto-detected)

- Registry: !`head -5 registry/curated-plugins.yaml 2>/dev/null`
- Plugin state: !`cat .blox/plugin-state.yaml 2>/dev/null`
- Installed plugins: !`ls ~/.claude/plugins/ 2>/dev/null`

# _internal/detect

> **Purpose:** Runtime plugin detection engine. Scans project files for trigger
> matches against the curated plugin registry, checks installation status, and
> suggests missing plugins to the user. This skill runs invisibly during other
> skills' execution — it NEVER blocks work and asks about each plugin at most once
> per session.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-internal-detect
category: engine
complements: [blox-setup, blox-plan, blox-build]

### Triggers — when the agent invokes automatically
trigger_keywords: [detect, plugin, install, missing]
trigger_files: [registry/curated-plugins.yaml, .blox/plugin-state.yaml]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke automatically during blox skill execution when files are created or
  modified, when a skill needs a capability that a plugin provides, and at
  master plan generation (/blox:plan) to pre-check needed plugins.
  Reads registry/curated-plugins.yaml, scans project, prompts for missing plugins.
auto_invoke: true
priority: mandatory

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| File created/modified during skill | User creates `.tsx` file during `/blox:build` | Yes |
| `/blox:plan` master plan generation | Pre-check all plugins needed for the plan | Yes |
| Skill needs plugin capability | `/blox:image` needs image-generation plugin | Yes |
| `/blox:setup` environment check | Verify all recommended plugins installed | Yes |
| New dependency added | `package.json` gains `@playwright/test` | Yes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| User already declined the plugin this session | Respect user's choice — don't re-ask | Skip silently |
| Plugin is already installed | Nothing to suggest | Skip silently |
| No trigger matches found | No relevant plugins to suggest | Skip silently |
| Offline / no network | Cannot install plugins without network | Log and skip |

---

## SKILL LOGIC

> **4-step detection pipeline. Runs silently — only surfaces when a suggestion is needed.**
> The entire pipeline is NON-BLOCKING: work always continues regardless of plugin status.

### Step 1: Scan Project

Read the curated plugin registry and scan the project for trigger matches:

```
READ registry/curated-plugins.yaml
  PARSE: plugins[] (curated tier) and known[] (known tier)

FOR EACH plugin entry:
  EVALUATE triggers:

  1. triggers.files — glob patterns against project directory
     SCAN: ls/glob for matching file extensions and paths
     Example: "**/*.ts" matches any TypeScript file in the project

  2. triggers.deps — package/dependency names
     SCAN these dependency manifests:
       - package.json: dependencies + devDependencies keys
       - requirements.txt: package names (line by line)
       - pyproject.toml: [project.dependencies] and [tool.poetry.dependencies]
       - Gemfile: gem names
       - go.mod: require blocks
       - Cargo.toml: [dependencies]
       - pom.xml: <dependency> groupId/artifactId
       - build.gradle: dependencies block
     MATCH: if any listed dep name appears in any manifest

  3. triggers.skills — blox skill invocations
     MATCH: if the current skill being executed matches a trigger skill name
     Example: triggers.skills: ["blox:image"] matches when /blox:image is running

  4. triggers.conditions — contextual conditions
     EVALUATE:
       - "github remote detected" → check `git remote -v` for github.com
       - "gitlab remote detected" → check `git remote -v` for gitlab
       - "web project detected" → check for index.html, package.json with react/vue/svelte/next
       - "known framework detected" → check for Next.js, Django, Rails, FastAPI, etc.
       - "claude_agent_sdk import detected" → grep for claude_agent_sdk in .py files

  5. triggers.always — always matches (e.g., superpowers)
     MATCH: unconditionally if any code project is detected

  6. triggers.always_on_code — matches any project with code files
     MATCH: if project contains .ts, .js, .py, .java, .go, .rs, .cs, or other source files

COLLECT all matched plugins into: matched_plugins[]
```

### Step 2: Check Installation Status

For each matched plugin, determine if it needs attention:

```
LOAD .blox/plugin-state.yaml (if exists)

FOR EACH plugin in matched_plugins[]:

  CHECK installation:
    METHOD 1: Scan ~/.claude/plugins/ for plugin directory
    METHOD 2: Check .blox/plugin-state.yaml for status: installed
    IF either confirms installed → mark as INSTALLED

  CHECK declined:
    READ .blox/plugin-state.yaml
    IF plugin entry exists AND status == "declined":
      IF declined_at is from THIS session → mark as DECLINED_THIS_SESSION
      (Session = current conversation / current date)

  CLASSIFY:
    INSTALLED         → skip (silent, no action)
    DECLINED_THIS_SESSION → skip (silent, don't re-ask)
    NOT_INSTALLED     → proceed to Step 3
    UNKNOWN           → proceed to Step 3

  SUB-CHECK: API Key Requirements
    IF plugin has requires.env:
      FOR EACH env_var in requires.env:
        CHECK: is env_var set in the current environment?
        IF missing → add to missing_env[] for this plugin
      NOTE: missing env vars are REPORTED, never block installation
```

### Step 3: Prompt User

For each plugin that needs installation, prompt the user based on tier:

```
FOR EACH uninstalled plugin (sorted by priority: critical > high > medium > low):

  IF plugin.tier == "curated":
    DISPLAY:
    ┌─────────────────────────────────────────────────────────┐
    │ The [plugin.plugin] plugin [plugin.description].        │
    │ Install? Run: /plugin add [plugin.source]               │
    │                                                         │
    │ (y/n)                                                   │
    └─────────────────────────────────────────────────────────┘

    IF plugin has missing_env[]:
      APPEND:
      "Note: requires [env_var1], [env_var2] — set these after installation."

  IF plugin.tier == "known":
    DISPLAY:
    ┌─────────────────────────────────────────────────────────┐
    │ The [plugin.plugin] plugin [plugin.description].        │
    │ (community plugin — not fully tested with blox)         │
    │ Install? Run: /plugin add [plugin.source]               │
    │                                                         │
    │ (y/n)                                                   │
    └─────────────────────────────────────────────────────────┘

BATCHING RULES:
  - If 1-2 plugins to suggest: show individually
  - If 3+ plugins to suggest: group into a single summary list
    and let user pick which to install
  - CRITICAL priority plugins: always show first, individually

WAIT for user response:
  "y" / "yes" → record as ACCEPTED, tell user to run the install command
  "n" / "no"  → record as DECLINED
  No response / skip → record as DECLINED (don't block)
```

### Step 4: Track State

Update `.blox/plugin-state.yaml` to persist detection state:

```
IF .blox/ directory does not exist:
  CREATE .blox/ directory

IF .blox/plugin-state.yaml does not exist:
  CREATE with header:
    # blox plugin state — auto-managed by _internal/detect
    # Do not edit manually unless you know what you're doing.
    last_scan: [YYYY-MM-DD]
    plugins: {}

FOR EACH plugin that was checked in this run:
  UPDATE .blox/plugin-state.yaml:
    plugins:
      [plugin-name]:
        status: installed | declined | suggested
        tier: curated | known
        installed_at: [YYYY-MM-DD] or null
        declined_at: [YYYY-MM-DD] or null
        last_checked: [YYYY-MM-DD]
        missing_env: [list of missing env vars] or null
        trigger_match: [what triggered the detection, e.g., "files: *.tsx"]

UPDATE top-level:
  last_scan: [YYYY-MM-DD]
```

---

## STATE FILE FORMAT

The `.blox/plugin-state.yaml` file tracks all detection state:

```yaml
# blox plugin state — auto-managed by _internal/detect
# Do not edit manually unless you know what you're doing.
last_scan: 2026-03-16
plugins:
  superpowers:
    status: installed
    tier: curated
    installed_at: 2026-03-15
    declined_at: null
    last_checked: 2026-03-16
    missing_env: null
    trigger_match: "always: true"
  frontend-design:
    status: declined
    tier: curated
    installed_at: null
    declined_at: 2026-03-16
    last_checked: 2026-03-16
    missing_env: null
    trigger_match: "files: **/*.tsx"
  image-generation:
    status: suggested
    tier: curated
    installed_at: null
    declined_at: null
    last_checked: 2026-03-16
    missing_env: [GEMINI_API_KEY]
    trigger_match: "skills: blox:image"
```

---

## INVARIANTS

1. **Never blocks** — work always continues regardless of plugin status. Detection is advisory only.
2. **Asks once per session** — declined plugins are recorded and not re-asked in the same session.
3. **Context-aware** — trigger conditions prevent irrelevant suggestions (e.g., no Playwright for a CLI tool).
4. **Syncs with setup** — what _detect discovers feeds into the next `/blox:setup` run.
5. **Never auto-installs** — the user ALWAYS decides. _detect only suggests and provides the command.
6. **Registry is the source of truth** — only plugins listed in `registry/curated-plugins.yaml` are suggested.
7. **Minimal noise** — if nothing is missing, _detect is completely silent. No output, no logging.

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| `/blox:plan` generates master plan | _detect pre-scans for all needed plugins | Before plan output |
| `/blox:build` creates/modifies files | _detect checks new file types against triggers | After file operations |
| `/blox:setup` runs environment check | _detect provides full plugin status report | During setup |
| User installs a plugin | _detect updates `.blox/plugin-state.yaml` | Post-install |
| `/blox:idea` creates project scaffolding | _detect scans initial file types | After scaffolding |

---

## VERIFICATION

### Success indicators
- All trigger matches checked against project files accurately
- User prompted for missing curated/known plugins with correct tier messaging
- State tracked in `.blox/plugin-state.yaml` with correct status for each plugin
- Declined plugins not re-prompted in the same session
- Missing API keys reported but never blocking installation or work
- Critical priority plugins prompted before medium/low priority
- Silent operation when all plugins are installed or no triggers match
- No AI attribution in plugin-state.yaml or prompts (no Co-Authored-By, Claude, Opus, Anthropic)

### Failure indicators (STOP and fix!)
- Prompting user for a plugin they already declined this session (INVARIANT 2 violation)
- Blocking execution while waiting for user response (INVARIANT 1 violation)
- Auto-installing a plugin without user consent (INVARIANT 5 violation)
- Suggesting a plugin not in the curated registry (INVARIANT 6 violation)
- Suggesting Playwright for a Python-only CLI project (INVARIANT 3 violation — trigger conditions not evaluated)
- Noisy output when nothing is missing (INVARIANT 7 violation)
- `.blox/plugin-state.yaml` corrupted or invalid YAML after update

---

## EXAMPLES

### Example 1: React project detected during /blox:build

**Situation:** User creates a `.tsx` file during `/blox:build` execution.

**Step 1 — Scan:** `.tsx` matches two plugins:
- `typescript-lsp` (triggers.files: `**/*.tsx`)
- `frontend-design` (triggers.files: `**/*.tsx`)

**Step 2 — Check:**
- `typescript-lsp`: not in `~/.claude/plugins/`, not in plugin-state → NOT_INSTALLED
- `frontend-design`: not in `~/.claude/plugins/`, not in plugin-state → NOT_INSTALLED

**Step 3 — Prompt:**
```
The typescript-lsp plugin provides TypeScript language server for type checking
and diagnostics.
Install? Run: /plugin add anthropics/typescript-lsp (y/n)

The frontend-design plugin provides frontend component design with accessibility
and responsive patterns.
Install? Run: /plugin add anthropics/frontend-design (y/n)
```

User answers: `y` to typescript-lsp, `n` to frontend-design.

**Step 4 — Track:**
```yaml
plugins:
  typescript-lsp:
    status: installed
    tier: curated
    installed_at: 2026-03-16
    declined_at: null
    last_checked: 2026-03-16
    missing_env: null
    trigger_match: "files: **/*.tsx"
  frontend-design:
    status: declined
    tier: curated
    installed_at: null
    declined_at: 2026-03-16
    last_checked: 2026-03-16
    missing_env: null
    trigger_match: "files: **/*.tsx"
```

Work continues immediately — no interruption.

### Example 2: User declines, later creates another .py file

**Situation:** Earlier in the session, user declined `pyright-lsp`. Now another `.py` file is created.

**Step 1 — Scan:** `.py` matches `pyright-lsp` (triggers.files: `**/*.py`)

**Step 2 — Check:**
- `pyright-lsp`: plugin-state shows `status: declined`, `declined_at: 2026-03-16` (today = same session)
- Classification: DECLINED_THIS_SESSION

**Result:** Skip silently. No prompt. Work continues.

### Example 3: Known plugin with disclaimer

**Situation:** User creates a `.cs` file during `/blox:build`.

**Step 1 — Scan:** `.cs` matches `csharp-lsp` (known tier, triggers.files: `**/*.cs`)

**Step 2 — Check:** Not installed, not declined.

**Step 3 — Prompt:**
```
The csharp-lsp plugin provides C# language server for .NET projects.
(community plugin — not fully tested with blox)
Install? Run: /plugin add anthropics/csharp-lsp (y/n)
```

### Example 4: Plugin with missing API key

**Situation:** `/blox:plan` pre-scan detects `image-generation` plugin needed (skill trigger: `blox:image`).

**Step 2 — Check:** Not installed. `requires.env: [GEMINI_API_KEY]` — env var NOT set.

**Step 3 — Prompt:**
```
The image-generation plugin provides AI image generation for logos, illustrations,
and UI assets.
Install? Run: /plugin add anthropics/image-generation (y/n)

Note: requires GEMINI_API_KEY — set this after installation.
```

### Example 5: Batch suggestion during /blox:plan

**Situation:** `/blox:plan` pre-scans a new Next.js + Supabase project. Multiple plugins match.

**Step 1 — Scan:** Matches:
- `superpowers` (critical, always: true)
- `security-guidance` (high, always_on_code: true)
- `frontend-design` (high, files: `**/*.tsx`)
- `typescript-lsp` (medium, files: `**/*.ts`)
- `vercel` (medium, deps: `next`)
- `supabase` (medium, deps: `@supabase/supabase-js`)

**Step 2 — Check:** None installed.

**Step 3 — Prompt (batched, 3+ plugins):**
```
Detected 6 plugins that would improve this project:

CRITICAL:
  [1] superpowers — Universal skill orchestration
      /plugin add obra/superpowers

HIGH:
  [2] security-guidance — Security best practices for all code projects
      /plugin add anthropics/security-guidance
  [3] frontend-design — Frontend component design with accessibility
      /plugin add anthropics/frontend-design

MEDIUM:
  [4] typescript-lsp — TypeScript type checking and diagnostics
      /plugin add anthropics/typescript-lsp
  [5] vercel — Deploy to Vercel (requires VERCEL_TOKEN)
      /plugin add anthropics/vercel
  [6] supabase — Database, auth, storage (requires SUPABASE_URL, SUPABASE_ANON_KEY)
      /plugin add anthropics/supabase

Install all? (y) / Select specific? (e.g., 1,2,3) / Skip all? (n)
```

---

## REFERENCES

- `registry/curated-plugins.yaml` — Source of truth for all plugin definitions and triggers
- `references/patterns/knowledge-patterns.md` — Architecture invariant: non-blocking advisory detection
