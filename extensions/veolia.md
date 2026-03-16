# Veolia Corporate Patterns — Wando Private Extension

> Corporate-specific patterns for Veolia projects.
> NOT included in the public blox-skills.

## Corporate Conventions

### Git
- GitLab for corporate repos (not GitHub)
- Branch naming: `feature/TICKET-description`
- MR required, no direct push to main

### Tech Stack
- Backend: FastAPI (Python 3.11+)
- Frontend: React + TypeScript
- Infrastructure: GCP (Cloud Run, Cloud SQL, Cloud Storage)
- CI/CD: GitLab CI
- Database: PostgreSQL
- Auth: Corporate SSO (SAML/OIDC)

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
