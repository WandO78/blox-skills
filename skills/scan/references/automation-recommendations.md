# /blox:scan — Automation Opportunity Catalog (Step 4e)

Reference tables for the informational "Automation Opportunities" report section. This
content has NO impact on the Quality Score. The matching rules (max 3 each, only for
detected tech) stay in SKILL.md.

## MCP Server recommendations — match against detected tech stack

| Detected Signal | Recommended MCP Server | Why |
|----------------|----------------------|-----|
| PostgreSQL / Prisma / SQLAlchemy | `postgres-mcp` or `supabase-mcp` | Direct DB queries from Claude |
| React / Next.js / Vue / Angular | `playwright-mcp` (Microsoft) | Browser automation + E2E testing |
| Rapidly changing libraries (Next.js, Prisma, FastAPI) | `context7` (Upstash) | Live docs lookup — prevents stale API usage |
| GitHub remote (.git/config → github.com) | `github-mcp` | PR management, issue tracking |
| GitLab remote (.git/config → gitlab) | `gitlab-mcp` | MR management, CI pipeline |
| Docker / docker-compose.yml | `docker-mcp` | Container management |
| AWS SDK / boto3 / aws-cdk | `aws-mcp` | Cloud resource management |
| Sentry / error tracking | `sentry-mcp` | Error debugging context |
| Slack integration / notifications | `slack-mcp` | Team notifications |

## Hook recommendations — match against detected tooling

| Detected Signal | Recommended Hook | Type | Trigger |
|----------------|-----------------|------|---------|
| `.prettierrc` / prettier in deps | Auto-format on edit | PostToolUse | `npx prettier --write $FILE` |
| `.eslintrc` / eslint in deps | Auto-lint on edit | PostToolUse | `npx eslint --fix $FILE` |
| `ruff.toml` / ruff in deps | Auto-format Python | PostToolUse | `ruff format $FILE && ruff check --fix $FILE` |
| `tsconfig.json` | Type-check on edit | PostToolUse | `npx tsc --noEmit` |
| `.env` files present | Block .env edits | PreToolUse | Deny Write/Edit to `.env*` files |
| `package-lock.json` / lock files | Block lock file edits | PreToolUse | Deny Write/Edit to lock files |
| `jest.config` / vitest.config | Auto-test on edit | PostToolUse | Run related tests after file change |
| `pytest.ini` / conftest.py | Auto-test Python | PostToolUse | `pytest $FILE_DIR -x --no-header -q` |
