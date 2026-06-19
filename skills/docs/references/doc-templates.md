# /blox:docs — Document Templates

> Verbatim output templates for Step 2 (Generate Docs), per document type.
> SKILL.md keeps the scan → generate → validate → save logic and the
> generate-trigger menu; this holds the section-by-section templates. Load the
> relevant block when generating that document type. Everything is derived from
> actual code — never fabricated.

## 2a: README.md

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

## 2b: API Documentation

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

## 2c: ARCHITECTURE.md

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

## 2d: Component Documentation (UI libraries)

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

## 2e: Changelog

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
