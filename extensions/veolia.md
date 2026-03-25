# Veolia Corporate Patterns — Wando Private Extension

> Corporate-specific patterns for Veolia projects.
> NOT included in the public blox-skills.

## Corporate Conventions

### Git
- GitLab for corporate repos (not GitHub)
- Branch naming: `feature/TICKET-description`
- MR required, no direct push to main

### Tech Stack (same priorities as personal — see tech-defaults.md)

**Backend (priority order):**
1. Go (Gin/Echo) — default for new projects
2. Java (Spring Boot) — enterprise/heavy integration
3. Rust (Actix/Axum) — performance-critical
4. .NET (ASP.NET Core) — Windows ecosystem requirement

**Frontend (priority order):**
1. Next.js (App Router) — default
2. React + Vite — SPA without SSR

**Frontend libs (always):** Tailwind CSS, shadcn/ui, Zustand

**Existing projects:** FastAPI (Python 3.11+) is legacy — maintain, don't rewrite unless major refactor planned.

**Infrastructure:** GCP (Cloud Run, Cloud SQL, Cloud Storage)
**CI/CD:** GitLab CI
**Database:** PostgreSQL (Cloud SQL)
**Auth:** Corporate SSO (SAML/OIDC)

### SAP Integration
- SAP RFC calls via pyrfc
- Master data sync patterns
- Error handling: retry with exponential backoff

### Compliance
- No PII in logs
- Data retention policies apply
- GDPR compliance on user data
- AI attribution: must NOT appear in corporate code

### Documentation
- Confluence for corporate docs
- JIRA for issue tracking
- Architecture Decision Records (ADR) in repo
