# Project Types — Wando Private Extension

> These project type definitions are specific to wando's portfolio.
> They are NOT included in the public blox-skills.

## T1: Full-stack webapp (enterprise)
- **Stack (new):** Go + Next.js + PostgreSQL + GCP (see tech-defaults.md)
- **Stack (legacy):** FastAPI + React + GCP (existing projects — maintain)
- **Examples:** VEMO PM, vdpsa, HUB
- **Patterns:** Monorepo, CI/CD with GitLab, SAP integration
- **Zone focus:** Z2-Z4 heavy (enterprise needs robust foundation + hardening)

## T2: Full-stack webapp (personal)
- **Stack:** Next.js + Go + Supabase + Vercel (see tech-defaults.md)
- **Examples:** Vreelo, Lunoa, IMPACTED
- **Patterns:** Rapid prototyping, Vercel deploy, Supabase auth
- **Zone focus:** Z0-Z3 fast (ship quickly, iterate)

## T3: Research / Planning
- **Stack:** Markdown only, no code
- **Examples:** Risten, skill-library
- **Patterns:** Document-driven, brainstorm-heavy
- **Zone focus:** Z0-Z1 only

## T4: Apps Script
- **Stack:** CLASP + Google APIs
- **Examples:** Veolia timesheets, report generators
- **Patterns:** Google ecosystem, limited testing
- **Zone focus:** Z2-Z3 (quick build, minimal hardening)

## T5: Home Assistant IoT
- **Stack:** YAML + Python
- **Examples:** HA automations, custom components
- **Patterns:** Declarative config, event-driven
- **Zone focus:** Z3-Z6 (build + maintain cycle)

## T6: One-off task
- **Stack:** Varies
- **Patterns:** No skill library needed, quick execution
- **Zone focus:** None (single session)

## T7: Data Pipeline
- **Stack:** Python ETL + harness
- **Examples:** Data migration scripts
- **Patterns:** Batch processing, validation, idempotency
- **Zone focus:** Z2-Z4 (foundation + hardening critical)
