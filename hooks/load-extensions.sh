#!/bin/bash
# Load wando-skills extensions into session context.
# This hook is PRIVATE — stripped from public blox-skills by the sync action.
#
# Detects if the current project is a corporate (Veolia) project and loads
# relevant extension context. The extensions inform /blox:idea and /blox:scan
# about corporate conventions when generating/updating CLAUDE.md.

EXTENSIONS_DIR="${CLAUDE_PLUGIN_ROOT}/extensions"

# Exit silently if no extensions directory
if [ ! -d "$EXTENSIONS_DIR" ]; then
  exit 0
fi

# Detect corporate project signals
IS_CORPORATE=false

# Signal 1: GitLab remote
if git remote -v 2>/dev/null | grep -q "gitlab"; then
  IS_CORPORATE=true
fi

# Signal 2: .gitlab-ci.yml exists
if [ -f ".gitlab-ci.yml" ]; then
  IS_CORPORATE=true
fi

# Signal 3: CLAUDE.md mentions Veolia/VEMO
if grep -qi "veolia\|vemo" CLAUDE.md 2>/dev/null; then
  IS_CORPORATE=true
fi

if [ "$IS_CORPORATE" = true ]; then
  echo "Corporate project detected. Loading wando-skills extensions:"
  echo ""
  echo "## Corporate Conventions (from wando-skills extensions)"
  echo ""
  # Output veolia.md content as session context
  if [ -f "$EXTENSIONS_DIR/veolia.md" ]; then
    # Extract key conventions (not the full file, just actionable rules)
    echo "### Git"
    echo "- GitLab for repos, branch: feature/TICKET-description"
    echo "- MR required, no direct push to main"
    echo ""
    echo "### Tech Stack Defaults"
    echo "- Backend: FastAPI (Python 3.11+), Frontend: React + TypeScript"
    echo "- Infrastructure: GCP (Cloud Run, Cloud SQL, Secret Manager)"
    echo "- CI/CD: GitLab CI, Auth: Corporate SSO (SAML/OIDC)"
    echo ""
    echo "### Compliance"
    echo "- No PII in logs, GDPR compliance, AI attribution MUST NOT appear in code"
    echo ""
    echo "When generating or updating CLAUDE.md for this project, include these conventions."
  fi

  # Output project type hints
  if [ -f "$EXTENSIONS_DIR/project-types.md" ]; then
    echo ""
    echo "### Project Type Detection (T1-T7 available)"
    echo "Use dynamic detection first, but T1-T7 categories available in extensions/project-types.md for reference."
  fi
fi

exit 0
