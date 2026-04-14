# schema-template.md — CLAUDE.md Section Template for /blox:wiki init

## Agent Usage Instructions

When `/blox:wiki init` runs, use this file as the source for generating the
`## Obsidian Knowledge Base` section in the project's CLAUDE.md.

Steps:
1. Collect the required values from the user or infer from the project context.
2. Replace all `{{PLACEHOLDER}}` tokens with real values.
3. For optional blocks marked `{{#SHARED_VAULTS}} ... {{/SHARED_VAULTS}}`:
   omit the entire block if there are no shared vaults; repeat the inner row
   once per shared vault if there are any.
4. Append the rendered section to the project's CLAUDE.md (or insert it after
   the last existing top-level section if CLAUDE.md already exists).
5. Create `<PRIMARY_VAULT_PATH>/wiki/index.md` and
   `<PRIMARY_VAULT_PATH>/wiki/log.md` using Part 2 and Part 3 below,
   replacing their placeholders with the same values.

Placeholders that must be filled at init time:
- `{{PRIMARY_VAULT_NAME}}` — human-readable name of the primary vault
- `{{PRIMARY_VAULT_PATH}}` — absolute filesystem path to the primary vault root
- `{{CLI_PATH}}` — absolute path to the Obsidian CLI binary
- `{{PROJECT_PATH}}` — absolute path to the project root
- `{{DATE}}` — today's date in YYYY-MM-DD format
- `{{SHARED_VAULT_NAME}}`, `{{SHARED_VAULT_PATH}}`, `{{SHARED_VAULT_DESCRIPTION}}` — per shared vault (optional)

---

## Part 1: CLAUDE.md Section Template

```markdown
## Obsidian Knowledge Base

### Vaults
| Vault | Path | Role | Access |
|-------|------|------|--------|
| {{PRIMARY_VAULT_NAME}} | {{PRIMARY_VAULT_PATH}} | Project knowledge base | read-write |
{{#SHARED_VAULTS}}
| {{SHARED_VAULT_NAME}} | {{SHARED_VAULT_PATH}} | {{SHARED_VAULT_DESCRIPTION}} | read-only |
{{/SHARED_VAULTS}}

### Obsidian CLI
- Binary: {{CLI_PATH}}
- All vault commands use `vault="{{PRIMARY_VAULT_NAME}}"` for targeting
- CLI requires running Obsidian instance

### Vault Structure
- `raw/` — unprocessed source files (PDFs, exports, raw notes)
- `raw/assets/` — images and binary assets referenced by raw sources
- `wiki/` — processed knowledge notes
- `wiki/index.md` — content catalog, updated on every ingest
- `wiki/log.md` — append-only chronological event log

### Writing Rules
- Internal links: [[wikilink]] (NEVER plain markdown links between vault notes)
- Every note gets YAML frontmatter: title, tags, date, related
- Tags: #topic/subtopic hierarchy
- Embeds: ![[file]] syntax
- Callouts: > [!type] syntax
- Cross-vault references: textual, not wikilinks

### Information Boundaries
| Information type | Where it goes |
|-----------------|---------------|
| Durable knowledge (research, decisions, context) | Obsidian Vault |
| User preferences, workflow feedback | Claude Memory |
| Operational state (phase, checkpoint) | Blox control files |
| Rules, configuration, vault paths | CLAUDE.md (this section) |

Rule: Each layer stores ONLY its own responsibility. Never duplicate across layers.

### Automatic Operations
- Session end: write summary note to vault wiki/
- Phase close (/blox:done): record outcomes and decisions
- New source in raw/: signal user for processing
- Significant decisions: suggest recording in vault

### Operations Reference
- ingest: Process source -> summary + related notes + index + log
- query: Search vault -> synthesize answer -> optionally save
- lint: Check health -> broken links, orphans, stale content
- sync: Compare project state with vault -> identify drift
```

---

## Part 2: Initial index.md Content

Write this to `{{PRIMARY_VAULT_PATH}}/wiki/index.md` at init time.

```markdown
---
title: Knowledge Index
tags:
  - meta/index
date: {{DATE}}
---

# {{PRIMARY_VAULT_NAME}} — Knowledge Index

> Content catalog for this vault. Updated on every ingest.

## Sources

## Concepts

## Decisions

## Entities

## Analysis
```

---

## Part 3: Initial log.md Content

Write this to `{{PRIMARY_VAULT_PATH}}/wiki/log.md` at init time.

```markdown
---
title: Vault Log
tags:
  - meta/log
date: {{DATE}}
---

# {{PRIMARY_VAULT_NAME}} — Event Log

> Chronological record of vault operations. Append-only.
> Format: ## [YYYY-MM-DD] <type> | <title>

## [{{DATE}}] init | Vault created
- Primary vault: {{PRIMARY_VAULT_NAME}}
- Path: {{PRIMARY_VAULT_PATH}}
- Connected to project: {{PROJECT_PATH}}
```
