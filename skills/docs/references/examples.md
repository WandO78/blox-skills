# /blox:docs — Worked Examples

> Additional walkthroughs of the scan → generate → validate → save pipeline.
> SKILL.md keeps two short inline examples (new README, README update); these
> cover API docs, component docs, and changelog generation.

## Example: API documentation for a Python FastAPI project

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

## Example: Component documentation for a React library

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

## Example: Changelog from git history

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
