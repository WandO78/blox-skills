---
name: blox-setup
description: "Install and update recommended plugins for your project. Run this after /blox:idea or anytime to check your plugin ecosystem."
user-invocable: true
argument-hint: "[--all | --check-only]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(status output, install prompts, state file entries) MUST be written in the user's
language. The skill logic instructions below are in English for maintainability,
but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:setup

> **Purpose:** Check, install, and update recommended plugins for the user's project.
> Reads the curated plugin registry, scans the project tech stack, shows a grouped
> status dashboard, and offers to install missing plugins interactively.
> Run after `/blox:idea`, after installing blox-skills, or anytime to audit your plugin ecosystem.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-setup
category: setup
complements: [blox-idea, blox-plan, _internal/detect]

### Triggers — when the agent invokes automatically
trigger_keywords: [setup, install, plugin, update, upgrade]
trigger_files: [.blox/plugin-state.yaml, registry/curated-plugins.yaml]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the user explicitly runs /blox:setup, when /blox:idea chains
  to it during autopilot, or when starting work on a project with a new tech stack.
  Reads registry/curated-plugins.yaml, scans the project, shows grouped status,
  and offers to install missing plugins interactively.
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| After installing blox-skills | First run: "What plugins do I need?" | No — user invokes |
| `/blox:idea` chains to it | Autopilot: master plan generated, now setup plugins | No — idea invokes |
| User wants to check/update | "Are my plugins up to date?" | No — user invokes |
| New tech stack detected | Project gained Python or React code | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| During active coding | Detection would interrupt flow | `_internal/detect` (non-blocking) |
| No project directory exists | Nothing to scan | Create a project first |
| Already ran setup this session | Results haven't changed | Check `.blox/plugin-state.yaml` |

---

## ARGUMENTS

| Flag | Effect |
|------|--------|
| *(none)* | Interactive mode — show status, offer to install missing plugins one by one |
| `--all` | Install all missing relevant plugins without asking (batch mode) |
| `--check-only` | Show grouped status only — do NOT offer to install anything |

---

## SKILL LOGIC

> **5-step pipeline. Always shows the full status dashboard before any install prompts.**
> The pipeline is SAFE: it never installs anything without user consent (unless `--all` flag).

### Step 1: Read Registry

Load the curated plugin registry bundled with blox-skills:

```
READ registry/curated-plugins.yaml

PARSE two sections:
  1. plugins[] — curated tier (tested, compatible, guaranteed)
  2. known[]   — known tier (exists, trigger defined, not fully tested)

FOR EACH entry, extract:
  - plugin: name
  - source: GitHub user/repo (for /plugin add command)
  - tier: curated | known
  - category: orchestration | code-quality | design | testing | deploy | integration | research
  - triggers: detection rules (files, deps, skills, conditions, always, always_on_code)
  - requires: env vars, system prerequisites (optional)
  - priority: critical | high | medium | low
  - description: short description

COLLECT into: all_plugins[]
```

### Step 2: Scan Project

Detect the project tech stack and match plugins against it:

```
SCAN PROJECT FILES:
  1. package.json        → Node.js, frontend frameworks (React, Next.js, Vue, Svelte)
  2. requirements.txt    → Python
  3. pyproject.toml      → Python (modern)
  4. Cargo.toml          → Rust
  5. go.mod              → Go
  6. pom.xml             → Java (Maven)
  7. build.gradle        → Java/Kotlin (Gradle)
  8. Gemfile             → Ruby
  9. *.csproj            → C# / .NET
  10. CMakeLists.txt     → C/C++
  11. Makefile            → C/C++ / generic build
  12. docker-compose.yml → Docker
  13. vercel.json         → Vercel deployment
  14. next.config.*       → Next.js
  15. supabase/config.toml → Supabase
  16. playwright.config.* → Playwright testing
  17. .git               → Git repository
  18. .gitlab-ci.yml     → GitLab CI

FOR EACH plugin in all_plugins[]:
  EVALUATE triggers (same logic as _internal/detect):

  1. triggers.always: true
     → MATCH unconditionally if any code project detected

  2. triggers.always_on_code: true
     → MATCH if project contains .ts, .js, .py, .java, .go, .rs, .cs, or other source files

  3. triggers.files: [glob patterns]
     → MATCH if any glob matches a file in the project directory

  4. triggers.deps: [package names]
     → MATCH if any dep name appears in any dependency manifest
       (package.json dependencies/devDependencies, requirements.txt, pyproject.toml, etc.)

  5. triggers.skills: [skill names]
     → MATCH if the project has used or would benefit from these blox skills
       (check phase files, .blox/ directory for skill usage history)

  6. triggers.conditions: [condition strings]
     → EVALUATE each condition:
       "github remote detected"     → git remote -v contains github.com
       "gitlab remote detected"     → git remote -v contains gitlab
       "web project detected"       → index.html, or package.json with react/vue/svelte/next
       "known framework detected"   → Next.js, Django, Rails, FastAPI, Express, etc.
       "claude_agent_sdk import detected" → grep for claude_agent_sdk in .py files

  IF any trigger matches → add to: relevant_plugins[]
  IF no triggers match   → add to: skipped_plugins[] (with reason)
```

### Step 3: Check Installation Status

For each relevant plugin, determine its current state:

```
LOAD .blox/plugin-state.yaml (if exists)

FOR EACH plugin in relevant_plugins[]:

  CHECK installation:
    METHOD 1: Scan ~/.claude/plugins/ for plugin directory name
    METHOD 2: Check .blox/plugin-state.yaml for status: installed
    IF either confirms → mark as INSTALLED

  CHECK declined:
    READ .blox/plugin-state.yaml
    IF plugin entry exists AND status == "declined" → mark as DECLINED

  CHECK env requirements:
    IF plugin has requires.env:
      FOR EACH env_var in requires.env:
        CHECK: is env_var set in the current environment?
        IF set     → add to env_ok[]
        IF missing → add to env_missing[]

  CLASSIFY into one of:
    ✅ INSTALLED       — plugin directory found
    ⬆️ UPDATE_AVAILABLE — installed but newer version exists (if version tracking exists)
    ❌ NOT_INSTALLED   — relevant but not installed, not declined
    ⏭️ DECLINED        — user previously declined (in plugin-state.yaml)

FOR EACH plugin in skipped_plugins[]:
  CLASSIFY as:
    ⏭️ SKIPPED — not relevant for this project (with reason)
```

### Step 4: Display Grouped Status

Show all results grouped by category with emoji status indicators:

```
GROUP plugins by category, then sort within each group by priority (critical first).

DISPLAY FORMAT (example):

  🔧 Orchestration (1/1)
    ✅ superpowers — up to date

  🛡️ Code Quality (2/3)
    ✅ security-guidance — installed
    ✅ typescript-lsp — installed
    ❌ pyright-lsp — not installed
       → Install: /plugin add anthropics/pyright-lsp

  🎨 Design (1/2)
    ✅ frontend-design — installed
    ❌ image-generation — not installed
       → Install: /plugin add anthropics/image-generation
       ⚠️ Requires: GEMINI_API_KEY

  🧪 Testing (0/1)
    ⏭️ playwright — skipped (no web project detected)

  🚀 Deploy (1/1)
    ✅ vercel — installed

  🔗 Integration (2/3)
    ✅ github — installed
    ❌ supabase — not installed
       → Install: /plugin add anthropics/supabase
       ⚠️ Requires: SUPABASE_URL, SUPABASE_ANON_KEY
    ⏭️ context7 — skipped (no known framework detected)

  🔍 Research (0/1)
    ⏭️ firecrawl — skipped (not triggered)

CATEGORY ICONS:
  🔧 orchestration
  🛡️ code-quality
  🎨 design
  🧪 testing
  🚀 deploy
  🔗 integration
  🔍 research

EMOJI LEGEND:
  ✅ installed and up to date
  ⬆️ update available
  ❌ not installed (relevant for this project)
  ⏭️ skipped (not relevant) or previously declined
  ⚠️ missing requirement (env var or system dep)

CATEGORY COUNTER: (installed/relevant) — only counts relevant plugins, not skipped ones

AFTER CATEGORY GROUPS, show API key summary:

  🔑 API Keys
    ✅ GITHUB_TOKEN — configured
    ⚠️ VERCEL_TOKEN — missing (needed for /blox:deploy)
       💡 Setup: vercel.com/account/tokens → Create Token
                 export VERCEL_TOKEN="tvl_..." in shell profile
    ⚠️ GEMINI_API_KEY — missing (needed for image generation)
       💡 Setup: aistudio.google.com/apikey → Create API Key
                 export GEMINI_API_KEY="..." in shell profile

  Only show API key section if there are env requirements (ok or missing).
  For each missing key, provide:
    1. The specific URL where the user can create the key
    2. The exact export command to add to their shell profile

FINISH with summary line:

  📊 Summary: 8/12 relevant plugins installed
```

**Known plugins disclaimer:** When displaying known-tier plugins, append `(community)` after the name:

```
  ❌ csharp-lsp (community) — not installed
     → Install: /plugin add anthropics/csharp-lsp
     ℹ️ Community plugin — not fully tested with blox
```

### Step 5: Interactive Install

After showing the full status (Step 4), offer to install missing plugins:

```
IF --check-only flag:
  STOP HERE. Do not offer installation. Display only.

IF --all flag:
  FOR EACH ❌ NOT_INSTALLED plugin (sorted by priority: critical > high > medium > low):
    DISPLAY: "Installing [plugin]... Run: /plugin add [source]"
    INSTRUCT user to run the /plugin add command
    After user confirms install:
      UPDATE .blox/plugin-state.yaml → status: installed, installed_at: today
    IF plugin has missing env vars:
      DISPLAY env setup instructions (URL + export command)

IF no flags (interactive mode):
  COUNT missing = number of ❌ NOT_INSTALLED plugins

  IF missing == 0:
    DISPLAY: "All relevant plugins are installed! ✅"
    SKIP to state update.

  IF missing == 1-2:
    FOR EACH ❌ plugin:
      ASK: "Install [plugin]? (y/n)"
      y → instruct user to run /plugin add [source], then verify
      n → record as declined in .blox/plugin-state.yaml

  IF missing >= 3:
    ASK: "Install all [N] missing plugins? (y/n/select)"
    y     → install all (same as --all)
    n     → decline all, record in state
    select → show numbered list, user picks (e.g., "1,3,5")

  AFTER all install decisions:
    IF plugin has missing env vars:
      DISPLAY env setup instructions for ALL installed plugins that need them
```

**After all installs/declines, update state (Step 5b):**

```
IF .blox/ directory does not exist:
  CREATE .blox/ directory

IF .blox/plugin-state.yaml does not exist:
  CREATE with header:
    # blox plugin state — auto-managed by /blox:setup and _internal/detect
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
        trigger_match: [what triggered the detection, e.g., "files: **/*.tsx"]

UPDATE top-level:
  last_scan: [YYYY-MM-DD]
```

---

## STATE FILE FORMAT

The `.blox/plugin-state.yaml` file tracks all plugin state (shared with `_internal/detect`):

```yaml
# blox plugin state — auto-managed by /blox:setup and _internal/detect
# Do not edit manually unless you know what you're doing.
last_scan: 2026-03-17
plugins:
  superpowers:
    status: installed
    tier: curated
    installed_at: 2026-03-15
    declined_at: null
    last_checked: 2026-03-17
    missing_env: null
    trigger_match: "always: true"
  frontend-design:
    status: declined
    tier: curated
    installed_at: null
    declined_at: 2026-03-17
    last_checked: 2026-03-17
    missing_env: null
    trigger_match: "files: **/*.tsx"
  image-generation:
    status: suggested
    tier: curated
    installed_at: null
    declined_at: null
    last_checked: 2026-03-17
    missing_env: [GEMINI_API_KEY]
    trigger_match: "skills: blox:image"
```

---

## API KEY REFERENCE

Specific setup instructions for each known API key requirement:

| Env Var | Plugin | URL | Export Command |
|---------|--------|-----|---------------|
| `VERCEL_TOKEN` | vercel | `vercel.com/account/tokens` | `export VERCEL_TOKEN="tvl_..."` |
| `GITHUB_TOKEN` | github | `github.com/settings/tokens` | `export GITHUB_TOKEN="ghp_..."` |
| `GEMINI_API_KEY` | image-generation | `aistudio.google.com/apikey` | `export GEMINI_API_KEY="..."` |
| `FIRECRAWL_API_KEY` | firecrawl | `firecrawl.dev/dashboard` | `export FIRECRAWL_API_KEY="fc-..."` |
| `SUPABASE_URL` | supabase | `supabase.com/dashboard` → Project Settings → API | `export SUPABASE_URL="https://xxx.supabase.co"` |
| `SUPABASE_ANON_KEY` | supabase | `supabase.com/dashboard` → Project Settings → API | `export SUPABASE_ANON_KEY="eyJ..."` |

When an API key is missing, ALWAYS provide the URL and export command from this table.
If a key is not in this table, provide a generic instruction: "Check the plugin documentation for setup instructions."

---

## INVARIANTS

1. **Never auto-installs without consent** — unless `--all` flag is explicitly passed, every install requires user confirmation.
2. **Respects declined plugins** — declined plugins are recorded in `.blox/plugin-state.yaml` and not re-asked until the next `/blox:setup` run.
3. **Full status BEFORE install prompts** — always show the complete grouped dashboard before asking to install anything.
4. **Actionable API key instructions** — every missing env var includes the specific URL and exact export command.
5. **Skips irrelevant plugins** — trigger evaluation prevents suggesting Playwright for CLI projects, Supabase for projects without it, etc.
6. **Registry is source of truth** — only plugins listed in `registry/curated-plugins.yaml` are shown. Never suggest arbitrary plugins.
7. **State shared with _detect** — setup and `_internal/detect` read and write the same `.blox/plugin-state.yaml` file.

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| `/blox:idea` completes master plan | `/blox:setup` runs | After plan generation (autopilot chain) |
| Setup discovers deep project issues | `/blox:scan` | If structural problems found during scan |
| User installs a plugin | `_internal/detect` reads updated state | Next skill invocation |
| `/blox:plan` needs plugin pre-check | `_internal/detect` | During plan generation (lightweight check) |

**Chain from `/blox:idea`:**
When `/blox:idea` chains to setup, show only plugins needed for the master plan's phases:
```
Your plan needs 3 plugins. Install? (y/n/all)
```

---

## VERIFICATION

### Success indicators
- Grouped status dashboard displayed with correct category grouping and emoji indicators
- Category counters match actual installed/relevant counts
- Plugin trigger evaluation matches project tech stack accurately
- Missing plugins show the correct `/plugin add [source]` command
- API key section shows specific URL + export command for each missing key
- Known-tier plugins display `(community)` disclaimer
- Skipped plugins show reason (e.g., "no web project detected")
- `.blox/plugin-state.yaml` updated with correct status for each checked plugin
- Declined plugins recorded and not re-prompted in interactive mode
- Summary line shows accurate totals
- No AI attribution in plugin-state.yaml or output (no Co-Authored-By, Claude, Opus, Anthropic)

### Failure indicators (STOP and fix!)
- Installing a plugin without user consent and without `--all` flag (INVARIANT 1 violation)
- Re-prompting for a declined plugin in the same run (INVARIANT 2 violation)
- Showing install prompts before the full status dashboard (INVARIANT 3 violation)
- Missing API key without setup URL/command (INVARIANT 4 violation)
- Suggesting Playwright for a Python-only CLI project (INVARIANT 5 violation — triggers not evaluated)
- Suggesting a plugin not in `registry/curated-plugins.yaml` (INVARIANT 6 violation)
- `.blox/plugin-state.yaml` corrupted or invalid YAML after update
- Category counter mismatch (e.g., showing 3/4 when only 2 are installed)

---

## EXAMPLES

### Example 1: Fresh install on Next.js + Supabase project

**Situation:** User runs `/blox:setup` on a project with `package.json` containing `react`, `next`, and `@supabase/supabase-js`. Git remote points to GitHub.

**Step 1-2:** Registry loaded, project scanned. Matches:
- superpowers (always: true) — critical
- security-guidance (always_on_code: true) — high
- frontend-design (files: `**/*.tsx`) — high
- typescript-lsp (files: `**/*.ts`) — medium
- vercel (deps: `next`) — medium
- github (conditions: github remote) — medium
- supabase (deps: `@supabase/supabase-js`) — medium

**Step 3:** Only superpowers installed. 6 missing.

**Step 4 output:**
```
🔧 Orchestration (1/1)
  ✅ superpowers — up to date

🛡️ Code Quality (1/2)
  ❌ security-guidance — not installed
     → Install: /plugin add anthropics/security-guidance
  ⏭️ pyright-lsp — skipped (no Python files detected)

🎨 Design (0/1)
  ❌ frontend-design — not installed
     → Install: /plugin add anthropics/frontend-design

🧪 Testing (0/0)
  ⏭️ playwright — skipped (no Playwright config or dependency)

🚀 Deploy (0/1)
  ❌ vercel — not installed
     → Install: /plugin add anthropics/vercel
     ⚠️ Requires: VERCEL_TOKEN

🔗 Integration (0/2)
  ❌ github — not installed
     → Install: /plugin add anthropics/github
     ⚠️ Requires: GITHUB_TOKEN
  ❌ supabase — not installed
     → Install: /plugin add anthropics/supabase
     ⚠️ Requires: SUPABASE_URL, SUPABASE_ANON_KEY

🔑 API Keys
  ⚠️ VERCEL_TOKEN — missing
     💡 Setup: vercel.com/account/tokens → Create Token
               export VERCEL_TOKEN="tvl_..." in shell profile
  ⚠️ GITHUB_TOKEN — missing
     💡 Setup: github.com/settings/tokens → Create Token
               export GITHUB_TOKEN="ghp_..." in shell profile
  ⚠️ SUPABASE_URL — missing
     💡 Setup: supabase.com/dashboard → Project Settings → API
               export SUPABASE_URL="https://xxx.supabase.co" in shell profile
  ⚠️ SUPABASE_ANON_KEY — missing
     💡 Setup: supabase.com/dashboard → Project Settings → API
               export SUPABASE_ANON_KEY="eyJ..." in shell profile

📊 Summary: 1/7 relevant plugins installed
```

**Step 5 (interactive, 5+ missing):**
```
Install all 6 missing plugins? (y/n/select)
```

User answers `select`, picks `1,2,3,4`. Setup instructs user to run the 4 `/plugin add` commands.

### Example 2: Check only mode

**Situation:** User runs `/blox:setup --check-only` on a mature Python project.

**Output:** Full grouped status dashboard (Steps 1-4) with summary line.
No install prompts. No questions asked. Read-only display.

```
📊 Summary: 4/5 relevant plugins installed

(--check-only mode: run /blox:setup to install missing plugins)
```

### Example 3: Called by /blox:idea autopilot

**Situation:** `/blox:idea` just generated a master plan for a React + Tailwind project. It chains to setup.

**Setup detects** that the plan's phases need: typescript-lsp, frontend-design, security-guidance.

**Compact output (chained mode):**
```
Your plan needs 3 plugins:
  [1] security-guidance — Security best practices
  [2] frontend-design — Frontend component design
  [3] typescript-lsp — TypeScript type checking

Install all? (y/n/select)
```

User answers `y`. Setup instructs user to run all 3 `/plugin add` commands, then updates state.

### Example 4: Everything installed

**Situation:** User runs `/blox:setup` on a project where all relevant plugins are already installed.

**Output:**
```
🔧 Orchestration (1/1)
  ✅ superpowers — up to date

🛡️ Code Quality (2/2)
  ✅ security-guidance — installed
  ✅ typescript-lsp — installed

🎨 Design (1/1)
  ✅ frontend-design — installed

🚀 Deploy (1/1)
  ✅ vercel — installed

🔗 Integration (1/1)
  ✅ github — installed

🔑 API Keys
  ✅ VERCEL_TOKEN — configured
  ✅ GITHUB_TOKEN — configured

📊 Summary: 6/6 relevant plugins installed

All relevant plugins are installed! ✅
```

### Example 5: Project with known-tier plugin match

**Situation:** User runs `/blox:setup` on a Java Maven project.

**Output includes:**
```
🛡️ Code Quality (1/2)
  ✅ security-guidance — installed
  ❌ jdtls-lsp (community) — not installed
     → Install: /plugin add anthropics/jdtls-lsp
     ℹ️ Community plugin — not fully tested with blox
```

---

## REFERENCES

- `registry/curated-plugins.yaml` — Source of truth for all plugin definitions and triggers
- `skills/_internal/detect/SKILL.md` — Runtime detection engine (shares plugin state)
- `references/patterns/knowledge-patterns.md` — Architecture invariant: never auto-install without consent
