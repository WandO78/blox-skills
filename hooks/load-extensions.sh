#!/bin/bash
# Load wando-skills extensions into session context.
# This hook is PRIVATE — stripped from public blox-skills by the sync action.
#
# Detects project type (corporate vs personal) and loads relevant conventions.
# These inform /blox:idea and /blox:scan when generating/updating CLAUDE.md.

EXTENSIONS_DIR="${CLAUDE_PLUGIN_ROOT}/extensions"

# Exit silently if no extensions directory
if [ ! -d "$EXTENSIONS_DIR" ]; then
  exit 0
fi

# ── Detect project type ──────────────────────────────────────────

IS_CORPORATE=false
IS_PERSONAL=false

# Corporate signals (Veolia)
if git remote -v 2>/dev/null | grep -q "gitlab"; then
  IS_CORPORATE=true
fi
if [ -f ".gitlab-ci.yml" ]; then
  IS_CORPORATE=true
fi
if grep -qi "veolia\|vemo" CLAUDE.md 2>/dev/null; then
  IS_CORPORATE=true
fi

# Personal signals (own projects)
if git remote -v 2>/dev/null | grep -q "github.com/WandO78\|github.com/wando"; then
  IS_PERSONAL=true
fi
if [ -f "vercel.json" ] || [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
  IS_PERSONAL=true
fi
if grep -qi "supabase" .env.local .env .env.example 2>/dev/null; then
  IS_PERSONAL=true
fi

# ── Corporate context ────────────────────────────────────────────

if [ "$IS_CORPORATE" = true ]; then
  echo "## Project Context: Corporate (Veolia)"
  echo ""
  echo "### Git"
  echo "- GitLab for repos, branch: feature/TICKET-description"
  echo "- MR required, no direct push to main"
  echo "- Git identity: Zsolt Winkler <zsolt.winkler@veolia.com>"
  echo ""
  echo "### Tech Stack Defaults"
  echo "- **BE priority:** Go > Java > Rust > .NET (NEW projects)"
  echo "- **FE priority:** Next.js (App Router) > React + Vite"
  echo "- **FE libs:** Tailwind CSS, shadcn/ui, Zustand (always)"
  echo "- **Legacy:** FastAPI (Python) in existing projects — maintain, don't rewrite"
  echo "- **Infra:** GCP (Cloud Run, Cloud SQL, Secret Manager)"
  echo "- **CI/CD:** GitLab CI | **Auth:** Corporate SSO (SAML/OIDC)"
  echo "- When suggesting tech stack, use these as DEFAULTS — user can override."
  echo ""
  echo "### Compliance"
  echo "- No PII in logs, GDPR compliance"
  echo "- AI attribution MUST NOT appear in code or commits"
  echo ""
  echo "Apply these conventions when generating/updating CLAUDE.md."
  exit 0
fi

# ── Personal context ─────────────────────────────────────────────

if [ "$IS_PERSONAL" = true ]; then
  echo "## Project Context: Personal (WandO78)"
  echo ""
  echo "### Git"
  echo "- GitHub for repos (github.com/WandO78)"
  echo "- Git identity: WandO78 <winklerzs@gmail.com>"
  echo "- AI attribution MUST NOT appear in code or commits"
  echo ""

  # Load tech defaults if available
  TECH_DEFAULTS="$EXTENSIONS_DIR/tech-defaults.md"
  if [ -f "$TECH_DEFAULTS" ]; then
    echo "### Tech Stack Defaults (from extensions/tech-defaults.md)"
    echo "- **BE priority:** Go > Java > Rust > .NET"
    echo "- **FE priority:** Next.js (App Router) > React + Vite"
    echo "- **FE libs:** Tailwind CSS, shadcn/ui, Zustand (always)"
    echo "- **DB:** Supabase (Postgres) | **Auth:** Clerk / Supabase Auth"
    echo "- **Deploy:** Vercel | **CI:** GitHub Actions | **Test:** Vitest + Playwright"
    echo "- When suggesting tech stack, use these as DEFAULTS — user can override."
    echo "- For full details: read extensions/tech-defaults.md"
  else
    echo "### Preferred Stack"
    echo "- Next.js + Supabase + Vercel (web apps)"
    echo "- Tailwind CSS, TypeScript strict"
  fi
  echo ""
  echo "### Deploy"
  echo "- Vercel for web apps (auto-deploy from GitHub)"
  echo "- GitHub Actions for CI"
  echo "- Home Assistant + YAML + Python (IoT)"
  echo ""
  echo "Apply these conventions when generating/updating CLAUDE.md."
  exit 0
fi

# ── Unknown project ──────────────────────────────────────────────
# No corporate or personal signals detected — exit silently.
# The blox skills work fine without extensions context.
exit 0
