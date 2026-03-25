# Tech Stack Defaults — Wando Private Extension

> Personal tech stack preferences. Loaded by /blox:idea and /blox:plan
> as DEFAULTS — the user can always override.
> NOT included in the public blox-skills.

## Backend (priority order)

When the project needs a backend, suggest in this order:

| Priority | Language | Framework | When to use |
|----------|----------|-----------|-------------|
| 1 | Go | Gin / Echo / stdlib | Default for new projects — fast, simple, great concurrency |
| 2 | Java | Spring Boot | Enterprise, when Go ecosystem lacks a needed library |
| 3 | Rust | Actix / Axum | Performance-critical, systems-level, WASM |
| 4 | .NET | ASP.NET Core | Windows ecosystem, corporate .NET requirement |

**Exception:** Corporate/Veolia projects use FastAPI (Python) — see veolia.md.

## Frontend (priority order)

When the project needs a frontend, suggest in this order:

| Priority | Framework | When to use |
|----------|-----------|-------------|
| 1 | Next.js (App Router) | Default — SSR, SSG, API routes, Vercel deploy |
| 2 | React + Vite | SPA without SSR needs, simpler setup |

## Frontend Libraries (always include)

These are the default frontend libraries for ALL frontend projects:

| Library | Purpose | Notes |
|---------|---------|-------|
| Tailwind CSS | Styling | Utility-first, dark mode support |
| shadcn/ui | Components | Copy-paste components, Radix UI primitives |
| Zustand | State management | Lightweight, no boilerplate, TS-friendly |

## Additional defaults

| Category | Default | Alternative |
|----------|---------|------------|
| Auth | Clerk / Supabase Auth | Auth0 for enterprise |
| Database | Supabase (Postgres) | Neon for serverless-first |
| Deploy | Vercel | Docker + Cloud Run for BE-heavy |
| CI/CD | GitHub Actions | GitLab CI for corporate |
| Testing | Vitest + Playwright | Jest if legacy |
| Monorepo | Turborepo | Only if >2 packages |
| ORM | Prisma | Drizzle if perf-critical |

## How skills consume this

When `/blox:idea` or `/blox:plan` needs to suggest a tech stack:
1. Read this file from extensions/
2. Present the #1 priority as the default
3. User confirms or picks alternative
4. Never force — always allow override
