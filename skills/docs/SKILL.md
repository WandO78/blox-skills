---
name: blox-docs
description: "Generate project documentation — README, API docs, architecture overview, changelog. Reads existing code to create accurate docs."
user-invocable: true
argument-hint: "[what to document]"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(documentation text, commit messages, status updates) MUST be written in the
user's language. The skill logic instructions below are in English for
maintainability, but all OUTPUT facing the user follows THEIR language.

---

## Context Discovery

This skill reads project state at runtime using Read, Glob, Grep, and Bash tools. No pre-loading needed.

# /blox:docs

> **Documentation generator that reads code first.** Scans the actual codebase
> to produce accurate, up-to-date documentation: README, API docs, architecture
> overview, component docs, and changelog. Never invents — always derives from
> code. Respects existing doc style and never overwrites user-written content.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-docs
category: domain
complements: [blox-build, blox-done]

### Triggers — when the agent invokes automatically
trigger_keywords: [docs, documentation, readme, api docs, changelog, dokumentacio, leiras]
trigger_files: [README.md, ARCHITECTURE.md, CHANGELOG.md, docs/*, API.md, openapi.yaml, swagger.json]
trigger_deps: [typedoc, jsdoc, sphinx, mkdocs, rustdoc]

### Phase integration
when_to_use: |
  Invoke when the user wants to create or update project documentation.
  Works standalone or chained after /blox:build or before /blox:done.
  Reads actual code to generate accurate docs — never fabricates.
  Do NOT use for code-level inline comments (that's part of /blox:build),
  for project planning documents (use /blox:plan), or for writing
  non-technical content (use /blox:brand for marketing copy).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| No README exists | New project needs documentation | No — user invokes |
| README is outdated | "Update the README to reflect current state" | No — user invokes |
| API docs needed | "Document the API endpoints" | No — user invokes |
| Architecture changed | "Update ARCHITECTURE.md after refactor" | No — user invokes |
| Release preparation | "Generate a changelog for this release" | No — user invokes |
| Component library docs | "Document the component props and usage" | No — user invokes |
| Phase completion chain | `/blox:done` PSC-4 check finds docs outdated | No — user decides |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Inline code comments | Code comments are part of implementation | `/blox:build` |
| Planning documents | Phase files, master plans | `/blox:plan` |
| Marketing copy | Brand voice, landing page text | `/blox:brand` |
| No code exists yet | Nothing to document | `/blox:plan` or `/blox:build` first |
| Only need a project overview (no code) | Research/planning project | Write manually |

---

## SKILL LOGIC

> **4-step documentation pipeline.** Scan → Generate → Validate → Save.
> Each step reads code to ensure accuracy. The user chooses what to document.

### Step 1: Scan Project

**Purpose:** Build a comprehensive understanding of the project before writing any docs.

**Actions:**
1. **Read project identity:**
   - `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` — name, description, version, dependencies
   - `LICENSE` — license type
   - `.env.example` / `.env.template` — environment variables needed
   - Existing `README.md` — current style, user-written sections, structure

2. **Map code structure:**
   - Source directories and file tree (depth 3)
   - Entry points: `src/index.*`, `app/main.*`, `cmd/main.go`, `src/main.rs`
   - Module/package organization pattern
   - Key directories: routes, services, models, components, utils, middleware

3. **Scan API surface:**
   - Route definitions: HTTP method + path + handler function
   - Request/response types (TypeScript interfaces, Pydantic models, Go structs)
   - Middleware chain (auth, validation, logging)
   - OpenAPI/Swagger spec (if exists: `openapi.yaml`, `swagger.json`)
   - GraphQL schema (if exists: `schema.graphql`, `*.graphql`)

4. **Scan UI components (if frontend project):**
   - Component file list with exported component names
   - Props/types for each component (from TypeScript types, PropTypes, etc.)
   - Storybook stories (if available): `*.stories.*`
   - Component hierarchy and composition patterns

5. **Read existing docs:**
   - List all `.md` files in root and `docs/` directory
   - Identify user-written sections (these are PROTECTED — never overwrite)
   - Detect doc style: formal vs casual, emoji usage, heading style, code example format
   - Check for doc generation tools: TypeDoc, JSDoc, Sphinx, MkDocs, rustdoc

6. **Read Git history (for changelog):**
   - `git log --oneline --since="[last tag or last 30 days]"`
   - Identify conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`
   - Read tags: `git tag --sort=-version:refname | head -10`

**Output format:**
```
## Project Scan Results
- Name: [project name]
- Version: [version or "unversioned"]
- Language: [primary language]
- Framework: [Next.js | FastAPI | Express | Gin | ...]
- License: [MIT | Apache-2.0 | ...]
- Entry point: [path]
- Source files: [N] files in [M] directories
- API routes: [N] endpoints
- UI components: [N] components
- Existing docs: [list of .md files]
- Doc style: [formal | casual | technical | none detected]
- Commits since last release: [N]
```

---

### Step 2: Generate Docs

**Purpose:** Create or update documentation based on what the project needs.

**Trigger:** Present findings from Step 1 and ask the user what to generate:

```
"Project scan complete. Documentation options:
A) README.md — [create | update] ([sections that need work])
B) API docs — [N] endpoints to document
C) ARCHITECTURE.md — [create | update] from actual code structure
D) Component docs — [N] components to document
E) Changelog — [N] commits since [last tag / date]
F) All of the above

Which docs should I generate?"
```

**Actions per document type:**

#### 2a: README.md

Generate or update with these sections (skip if the project already has them and they're accurate):

```markdown
# [Project Name]

> [One-line description from package.json / pyproject.toml]

## Overview
[2-3 paragraph project description derived from code structure and purpose]

## Features
- [Feature 1 — derived from routes, components, services]
- [Feature 2]
- [...]

## Prerequisites
- [Runtime] >= [version] (from engines/python_requires/go directive)
- [Database] (if detected from deps/config)
- [Other services] (if detected)

## Installation
[Step-by-step install derived from actual project setup:]
```bash
git clone [repo URL if available]
cd [project name]
[package manager install command]
[environment setup]
```

## Quick Start
[Minimal steps to get the project running:]
```bash
[actual start command from package.json scripts / Makefile / main entry]
```

## Usage
[Key usage examples derived from API routes, CLI commands, or main features]

## API Reference
[Summary table of endpoints — link to full API docs if separate]

## Project Structure
[Directory tree derived from actual structure, annotated with purpose]

## Configuration
[Environment variables from .env.example with descriptions]

## Development
[Dev setup: how to run tests, lint, build — from package.json scripts / Makefile]

## Contributing
[Standard contributing guide — or skip if project is private/personal]

## License
[License type — from LICENSE file]
```

**User-written section protection:**
- If README.md already exists, identify sections written by the user
- Mark them with `<!-- USER-WRITTEN: do not auto-update -->` comments
- Update ONLY sections that are auto-generated or clearly outdated
- Append new sections at the end, don't reorganize user structure

#### 2b: API Documentation

For each API endpoint found in the codebase:

```markdown
# API Documentation

## Authentication
[Auth mechanism derived from middleware: JWT, API key, session, OAuth]

## Endpoints

### [HTTP Method] [Path]
**Description:** [Derived from handler function name and logic]
**Auth:** [Required | Optional | None]

**Request:**
- Headers: [required headers]
- Params: [path parameters with types]
- Query: [query parameters with types and defaults]
- Body: [request body schema — from TypeScript types, Pydantic models, Go structs]

```json
{
  "example": "request body derived from type definition"
}
```

**Response:**
- Status: [success status code]
- Body: [response schema]

```json
{
  "example": "response body derived from type definition"
}
```

**Errors:**
| Status | Description |
|--------|------------|
| 400 | [validation error — from error handler] |
| 401 | [unauthorized — from auth middleware] |
| 404 | [not found — from handler logic] |
```

**If OpenAPI/Swagger spec exists:** Read and verify it matches actual routes.
If discrepancies: report them and update the spec.

#### 2c: ARCHITECTURE.md

Generate from actual code structure:

```markdown
# Architecture Overview

## System Diagram
[ASCII diagram showing main components and data flow, derived from code]

## Tech Stack
- **Runtime:** [language + version]
- **Framework:** [web framework]
- **Database:** [DB type + ORM]
- **Cache:** [if detected]
- **Queue:** [if detected]
- **Frontend:** [framework + UI library]

## Directory Structure
[Annotated directory tree — actual structure, not aspirational]

## Data Flow
[How a request flows through the system: entry → middleware → handler → service → DB → response]

## Key Design Decisions
[Derived from code patterns: why certain libraries, patterns, or structures were chosen]

## Dependencies
[Key external dependencies with purpose — not the full dep list, just the important ones]
```

#### 2d: Component Documentation (UI libraries)

For each component:

```markdown
## [ComponentName]

**File:** `src/components/ComponentName.tsx`

### Props
| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| name | string | yes | — | [derived from usage context] |
| variant | "primary" \| "secondary" | no | "primary" | [derived from implementation] |

### Usage
```tsx
import { ComponentName } from '@/components/ComponentName';

<ComponentName name="Example" variant="primary" />
```

### Variants
[List variants with descriptions, derived from prop types and conditional rendering]

### Notes
[Any special behavior, side effects, or requirements derived from implementation]
```

#### 2e: Changelog

Generate from git history using conventional commits:

```markdown
# Changelog

## [version or "Unreleased"] — [date]

### Features
- [feat commit message] ([commit hash])
- [...]

### Bug Fixes
- [fix commit message] ([commit hash])
- [...]

### Improvements
- [refactor/perf commit message] ([commit hash])
- [...]

### Other
- [chore/ci/docs commit message] ([commit hash])
- [...]
```

**Grouping logic:**
- `feat:` → Features
- `fix:` → Bug Fixes
- `refactor:` / `perf:` → Improvements
- `chore:` / `ci:` / `docs:` / `build:` → Other
- Non-conventional commits → Other (include full message)

---

### Step 3: Validate

**Purpose:** Verify generated documentation is accurate before saving.

**Actions:**

1. **Code example validation:**
   - For each code example in generated docs: does the code reference actual files, functions, and types?
   - Import paths: do they resolve to real files?
   - CLI commands: do they match actual `scripts` in package.json or Makefile?
   - Environment variables: do they match `.env.example`?

2. **Link validation:**
   - Internal links (relative paths to files/directories): do the targets exist?
   - External links: note them for user review (don't validate live URLs)

3. **API accuracy:**
   - For each documented endpoint: does the route, method, and handler actually exist?
   - For each request/response schema: does it match the actual type definition?
   - For each error code: is that error actually thrown by the handler?

4. **Completeness check:**
   - Are there API routes NOT documented? → List them
   - Are there components NOT documented? → List them
   - Are there environment variables NOT documented? → List them

5. **Style consistency:**
   - Do new sections match the existing doc style?
   - Heading levels consistent?
   - Code block language tags present?
   - Consistent terminology (same thing called the same name everywhere)?

**Output format:**
```
## Validation Results
- Code examples: [N] checked, [M] valid, [K] need fixing
- Links: [N] internal (all valid / [K] broken), [M] external (not validated)
- API accuracy: [N] endpoints documented, [M] match implementation
- Completeness: [N] undocumented items remaining
- Style: [consistent | N inconsistencies found]

### Issues Found
| # | Type | Location | Issue | Fix |
|---|------|----------|-------|-----|
| 1 | Broken link | README.md:45 | Link to docs/api.md but file is docs/API.md | Fix case |
| 2 | Stale example | README.md:78 | npm start but script is npm run dev | Update command |
```

---

### Step 4: Save

**Purpose:** Write validated documentation to the appropriate locations and commit.

**Actions:**

1. **Write files to correct locations:**
   - `README.md` → project root
   - `ARCHITECTURE.md` → project root
   - `CHANGELOG.md` → project root
   - `API.md` or `docs/api.md` → match existing convention, or root if no convention
   - Component docs → `docs/components/` or alongside components (match project convention)

2. **Protect user-written content:**
   - If updating an existing file: use precise edits, not full overwrite
   - Sections marked `<!-- USER-WRITTEN -->` are NEVER touched
   - If unsure whether a section is user-written: preserve it and add new content below

3. **Commit:**
   - Stage specific documentation files (NEVER `git add -A` or `git add .`)
   - Commit message based on what was generated:
     - New docs: `docs: add [README | API docs | architecture overview | changelog]`
     - Updated docs: `docs: update [what] to reflect [reason]`
   - **NEVER** add `Co-Authored-By`, `Claude`, `Opus`, `Anthropic`, or any AI attribution

4. **Report:**
   ```
   ## Documentation Generated
   | # | File | Action | Sections |
   |---|------|--------|----------|
   | 1 | README.md | Created | Overview, Install, Usage, API, Structure |
   | 2 | docs/api.md | Updated | Added 5 new endpoints |
   | 3 | CHANGELOG.md | Created | 23 commits grouped by type |

   Committed: [commit hash] "docs: [message]"
   ```

---

## INVARIANTS

1. **Read code BEFORE writing docs** — accuracy over speed, always
2. **Never fabricate** — every claim in docs must be traceable to actual code
3. **Respect existing doc style** — match tone, formatting, heading conventions
4. **Don't overwrite user-written sections** — append, update auto-sections, but protect manual content
5. **API docs must match implementation** — if a route doesn't exist, don't document it
6. **Code examples must be runnable** — real imports, real function names, real paths
7. **Stage specific files** — never `git add -A` or `git add .`
8. **No AI attribution** — no Co-Authored-By, Claude, Opus, Anthropic in commits or docs
9. **Ask before generating** — present scan results first, let user choose what to document
10. **Validate before saving** — check accuracy before committing

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| `/blox:done` PSC-4 finds outdated docs | `/blox:docs` | User decides to update docs before close |
| Documentation complete, phase has checklist item | `_internal/checkpoint` | After commit, if checkpoint conditions met |
| API route structure unclear | `/blox:scan` | If project needs assessment before documenting |
| Brand voice needed for user-facing docs | `/blox:brand` | If docs need marketing tone (landing page, etc.) |
| Architecture has changed significantly | `/blox:design` | If architecture needs redesign, not just documentation |
| Docs generated during a phase | `/blox:build` | If doc generation is a checklist item |

---

## VERIFICATION

### Success Indicators
- Project scanned before any docs written (Step 1 completed first)
- Generated docs match actual code (API routes exist, imports resolve, commands work)
- Existing user-written sections preserved (no overwrites)
- Code examples reference real files, functions, and types
- API documentation matches actual route handlers and types
- Doc style matches existing project conventions
- All generated files committed with descriptive messages
- No AI attribution in commits or generated documentation
- Validation step completed with results documented

### Failure Indicators (STOP and fix!)
- Docs written without reading code first (INVARIANT 1 violation)
- Fabricated content: routes, functions, or features that don't exist in code
- User-written README sections overwritten or reorganized without permission
- Code examples with fake imports or non-existent functions
- API docs documenting endpoints that don't exist
- `git add -A` or `git add .` used instead of specific file staging
- AI attribution found in commits or generated documentation
- Docs generated without user choosing what to document (INVARIANT 9 violation)
- No validation step — docs committed without accuracy check

---

## EXAMPLES

### Example 1: New README for a TypeScript project

```
User: "/blox:docs"

Step 1: Scan Project
  Name: acme-api (from package.json)
  Version: 1.2.0
  Language: TypeScript
  Framework: Express
  License: MIT
  Source files: 34 files in 8 directories
  API routes: 18 endpoints
  Existing docs: None (no README.md)

  → "Project scan complete. No documentation exists. Options:
     A) README.md — create from scratch
     B) API docs — 18 endpoints to document
     C) ARCHITECTURE.md — create from code structure
     D) Component docs — N/A (backend only)
     E) Changelog — 47 commits, no tags
     F) All of the above"

User: "F"

Step 2: Generate Docs
  README.md: 12 sections generated from code analysis
  docs/api.md: 18 endpoints documented with request/response schemas
  ARCHITECTURE.md: system diagram + tech stack + data flow
  CHANGELOG.md: 47 commits grouped into 12 features, 8 fixes, 27 other

Step 3: Validate
  Code examples: 8/8 valid (imports resolve, commands exist)
  Links: 5 internal (all valid)
  API accuracy: 18/18 endpoints match implementation
  Style: consistent (technical tone, h2/h3 hierarchy)

Step 4: Save
  git add README.md docs/api.md ARCHITECTURE.md CHANGELOG.md
  git commit -m "docs: add README, API docs, architecture overview, changelog"
```

### Example 2: Update existing README after feature changes

```
User: "/blox:docs readme"

Step 1: Scan Project
  Existing README.md found (128 lines)
  User-written sections detected: Overview, Contributing (custom text)
  Outdated sections: API Reference (3 new endpoints), Installation (new env var)

  → "README.md exists. I can update these sections:
     - API Reference: add 3 new endpoints (GET /api/v2/*, POST /api/webhooks)
     - Installation: add WEBHOOK_SECRET env var
     - Project Structure: new src/webhooks/ directory
     User-written sections (Overview, Contributing) will NOT be touched."

User: "Go ahead"

Step 2: Generate updates for 3 sections
Step 3: Validate — all references correct
Step 4: Save (edit, not overwrite)
  git add README.md
  git commit -m "docs: update README with webhook endpoints and config"
```

### Example 3: API documentation for a Python FastAPI project

```
User: "/blox:docs api"

Step 1: Scan Project
  Framework: FastAPI (auto-generates OpenAPI)
  Existing: openapi.json at /docs (auto-generated)
  Routes: 24 endpoints across 5 routers

Step 2: Generate API docs
  Read FastAPI route decorators + Pydantic models
  Generate docs/api.md with:
  - 24 endpoints with full request/response schemas
  - Authentication section (OAuth2 with JWT)
  - Error response catalog (from HTTPException patterns)
  - Rate limiting info (from middleware)

Step 3: Validate
  Cross-referenced with openapi.json — 24/24 match
  Pydantic models verified: all field types and constraints accurate
  2 undocumented query parameters found → added

Step 4: Save
  git add docs/api.md
  git commit -m "docs: add API documentation for 24 endpoints with schemas"
```

### Example 4: Component documentation for a React library

```
User: "/blox:docs components"

Step 1: Scan Project
  Framework: React + TypeScript
  Components: 15 in src/components/
  Storybook: yes (stories for 8/15 components)
  Types: all components have TypeScript prop interfaces

Step 2: Generate component docs
  For each component: read exported interface, JSDoc comments, default values
  Generated: docs/components.md with:
  - 15 components documented
  - Props tables from TypeScript interfaces
  - Usage examples from Storybook stories (8 components) or derived from props (7 components)
  - Variant lists from union type props

Step 3: Validate
  All import paths valid
  All prop types match source interfaces
  Storybook examples cross-referenced with actual stories

Step 4: Save
  git add docs/components.md
  git commit -m "docs: add component documentation for 15 React components"
```

### Example 5: Changelog from git history

```
User: "/blox:docs changelog"

Step 1: Scan Project
  Tags: v1.0.0 (2026-02-01), v1.1.0 (2026-02-15), v1.2.0 (2026-03-01)
  Commits since v1.2.0: 31
  Conventional commits: 28/31 (90%)

Step 2: Generate Changelog
  ## Unreleased — 2026-03-17
  ### Features (8)
  - Add webhook integration for order events (abc1234)
  - Add bulk export for products (def5678)
  - [...]
  ### Bug Fixes (5)
  - Fix race condition in payment processing (ghi9012)
  - [...]
  ### Improvements (7)
  - Refactor auth middleware for clarity (jkl3456)
  - [...]
  ### Other (11)
  - [...]

Step 3: Validate — all commit hashes valid, dates correct
Step 4: Save
  git add CHANGELOG.md
  git commit -m "docs: add changelog — 31 changes since v1.2.0"
```

---

## REFERENCES

- `references/patterns/knowledge-patterns.md` — Evidence-based documentation patterns
- `skills/build/SKILL.md` — Code structure conventions that docs should reflect
- `skills/check/SKILL.md` — PSC-4 (docs updated) check that triggers this skill
- `skills/done/SKILL.md` — Phase closure docs requirement (Step 1 PSC-4)
