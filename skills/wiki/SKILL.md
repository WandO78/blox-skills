---
name: blox-wiki
description: "Obsidian-based knowledge management for any project using the Karpathy LLM Wiki pattern. Use when the user mentions wiki, vault, obsidian, knowledge base, ingest sources, search vault, lint notes, or wants structured information management in their project."
user-invocable: true
argument-hint: "init | ingest [source] | query [question] | lint | sync"
---

## Language Protocol

Detect the user's language from the conversation context. All generated content
(vault notes, index entries, log entries, lint reports, sync suggestions) MUST be
written in the user's language. The skill logic instructions below are in English
for maintainability, but all OUTPUT facing the user follows THEIR language.

---

# OBSIDIAN KNOWLEDGE BASE

> "The tedious part of maintaining a knowledge base is not the reading
> or the thinking — it's the bookkeeping."
> — Andrej Karpathy

The Karpathy LLM Wiki pattern treats the AI as a knowledge worker that reads,
distills, and organizes information into a structured wiki. Obsidian is the
storage layer — durable, searchable, link-rich. The AI reads sources, writes
summaries, maintains an index, and keeps the vault healthy over time.

**The pattern:** Source material goes in raw. The AI distills it into wiki notes.
Wiki notes link to each other. An index provides the entry point. A log tracks
every change. The vault grows organically as the project evolves.

---

## Context Discovery

This skill uses the Obsidian CLI for all vault operations. At runtime:

1. Read `CLAUDE.md` for the `## Obsidian` section — vault name(s), paths, folder structure
2. Detect Obsidian CLI availability (see Prerequisites)
3. Read `wiki/index.md` in the vault for current knowledge map

No pre-loading of vault content — the skill reads on demand via CLI.

---

## AUTO-DISCOVERY

> **Mandatory section** — `/blox:plan` uses THIS to find this skill.

### Identification
name: blox-wiki
category: knowledge-management
complements: [blox-idea, blox-plan, blox-done, blox-scan]

### Triggers — when the agent invokes automatically
trigger_keywords: [wiki, vault, obsidian, knowledge base, ingest, "search the vault", "what do we know", lint, "vault health", orphan, sync vault]
trigger_files: [wiki/index.md]
trigger_deps: []

### Phase integration
when_to_use: |
  Invoke when the user wants structured knowledge management via Obsidian.
  This includes: initializing a project vault, ingesting sources (articles,
  docs, PDFs, notes) into distilled wiki notes, querying the vault for
  synthesized answers, linting the vault for structural health, or syncing
  the vault with recent project changes. The vault is the project's durable
  knowledge layer — separate from Claude Memory (preferences) and blox
  control files (operational state).
auto_invoke: false
priority: recommended

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| Set up knowledge base for a project | "Set up an Obsidian vault for this project" | No — user invokes |
| Ingest a source into the vault | "Ingest this article into the wiki" | No — user invokes |
| Search for knowledge | "What do we know about auth patterns?" | No — user invokes |
| Check vault health | "Lint the vault" / "Any orphan notes?" | No — user invokes |
| Sync vault with project changes | "Sync the wiki with recent commits" | No — user invokes |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| Project assessment | Different purpose — evaluates project state | `/blox:scan` |
| Writing documentation | Documentation lives in `docs/`, not the vault | `/blox:docs` |
| Storing user preferences | Preferences go in Claude Memory | Claude Memory |
| Operational state tracking | Phase files, checklists, context chain | Blox control files |
| Quick notes that do not need structure | Simple notes do not need a vault | Plain markdown |

---

## PREREQUISITES

### Obsidian CLI Detection

The Obsidian CLI is **required** for all vault operations. Detect it using platform-native binary resolution:

1. `which obsidian` or `command -v obsidian` (PATH lookup)
2. macOS: `/Applications/Obsidian.app/Contents/MacOS/obsidian-cli`
3. Linux: `/opt/Obsidian/obsidian-cli` or `~/.local/bin/obsidian-cli`
4. Windows: `%LOCALAPPDATA%\Obsidian\obsidian-cli.exe`

**If not found:**
Tell the user: "Obsidian CLI not found. Please start Obsidian and enable the CLI
(Settings → General → Advanced → Command-line interface), then try again."

**No fallback mode.** The CLI is required for all operations. Do NOT attempt filesystem
workarounds (reading `.md` files directly, parsing `.obsidian/` config). The CLI handles
vault locking, plugin state, and link resolution correctly — raw filesystem access does not.

### Multi-Vault Targeting

All CLI commands accept `vault="Name"` to target a specific vault. This is critical when
the user has multiple vaults open.

**Rules:**
- Always use `vault="Name"` explicitly — never rely on a default vault
- Read the vault name from `CLAUDE.md` (set during init)
- Never write to a shared (read-only) vault without explicit user permission
- If the vault name contains spaces, quote it: `vault="My Vault"`

---

## SKILL LOGIC

> **5 operations: init, ingest, query, lint, sync.**
> Each operation is independent. The user invokes them via the argument hint.

### Operation: init

> **Goal:** Set up Obsidian as the knowledge layer for the current project.

**Step 1 — Check for existing configuration:**
Read `CLAUDE.md` and look for an `## Obsidian` section. If found, report the
existing configuration and ask if the user wants to reconfigure.

**Step 2 — Ask for primary vault:**
Ask the user: "Which Obsidian vault should this project use? Give me the vault name
as it appears in Obsidian. If you haven't created one yet, create it in Obsidian
first, then tell me the name."

**Step 3 — Verify vault exists:**
Run `obsidian vaults verbose` and confirm the named vault appears in the output.
If not found, tell the user to create it in Obsidian and try again.

**Step 4 — Create folder structure in the vault:**
Using the Obsidian CLI, create the following folders and seed files:

```
raw/              — Raw source material (articles, PDFs, notes)
raw/assets/       — Binary assets referenced by raw sources
wiki/             — Distilled knowledge notes
wiki/index.md     — Master index of all wiki topics
wiki/log.md       — Changelog of all vault modifications
```

Create `wiki/index.md` with:
```markdown
---
title: Knowledge Index
tags:
  - meta/index
date: [today's date]
---

# Knowledge Index

> Master index for [project name]. Updated on every ingest.

## Sources
<!-- Processed source summaries -->

## Concepts
<!-- Key concepts and definitions -->

## Decisions
<!-- Architecture, technology, and design decisions -->

## Entities
<!-- People, systems, organizations -->

## Analysis
<!-- Comparisons, evaluations, synthesis -->
```

Create `wiki/log.md` with:
```markdown
---
title: Vault Log
tags:
  - meta/log
date: [today's date]
---

# Vault Log

> Chronological record of vault operations. Append-only.
> Format: `## [YYYY-MM-DD] <type> | <title>`

## [today's date] init | Vault initialized for [project name]
- Primary vault: [vault name]
- Connected to project: [project path]
```

**Step 5 — Ask about shared vaults:**
Ask the user: "Do you have any shared or reference vaults that this project should
read from (but not write to)? For example, a team knowledge base or a personal
reference vault. (Skip if none.)"

If the user names shared vaults, verify each exists via `obsidian vaults verbose`
and record them as read-only.

**Step 6 — Generate CLAUDE.md section:**
Read `references/schema-template.md` for the exact format. Generate an `## Obsidian`
section in `CLAUDE.md` containing:
- Primary vault name and path
- Folder structure (raw/, wiki/)
- Shared vaults (if any, marked read-only)
- Conventions (wikilinks, frontmatter tags, log updates)

Append this section to the existing `CLAUDE.md`. Do NOT overwrite existing content.

**Step 7 — Confirm to user:**
Show a summary of what was created and configured. Include the vault name, folder
structure, and any shared vaults. Tell the user they can now run
`/blox:wiki ingest [source]` to start adding knowledge.

---

### Operation: ingest

> **Goal:** Read a source, distill it into a wiki note, and integrate it into the vault.

Read `references/ingest-workflow.md` for the detailed workflow.

**Summary:**
1. Read the source material (URL, file path, or pasted text)
2. Discuss the source with the user — what is important, what to capture
3. Write a distilled wiki note in `wiki/` with proper frontmatter, wikilinks, and tags
4. Update related existing notes with backlinks to the new note
5. Update `wiki/index.md` with the new topic entry
6. Update `wiki/log.md` with the ingest event
7. Save the original source in `raw/` for reference

---

### Operation: query

> **Goal:** Search the vault and synthesize an answer from existing knowledge.

Read `references/query-workflow.md` for the detailed workflow.

**Summary:**
1. Read `wiki/index.md` to understand the knowledge map
2. Search the vault using `obsidian search` and `obsidian search:context`
3. Read the most relevant notes
4. Synthesize an answer from vault knowledge, citing source notes with wikilinks
5. Offer to save the synthesis as a new wiki note if it adds value

---

### Operation: lint

> **Goal:** Check vault structural health and report issues.

Read `references/lint-workflow.md` for the detailed workflow.

**Summary:**
1. Check for broken wikilinks (`obsidian unresolved`)
2. Find orphan notes with no incoming links (`obsidian orphans`)
3. Find dead-end notes with no outgoing links (`obsidian deadends`)
4. Identify stale notes (not updated in configurable period)
5. Check tag consistency (similar tags that should be merged)
6. Generate a health report with findings and severity
7. Offer to fix issues (broken links, orphan cleanup, tag normalization)

---

### Operation: sync

> **Goal:** Sync the vault with recent project changes so knowledge stays current.

Read `references/sync-workflow.md` for the detailed workflow.

**Summary:**
1. Read git log for recent commits since last sync
2. Identify unrecorded decisions (architectural changes, new patterns, config changes)
3. Find stale notes that contradict current code
4. Check for unprocessed sources in `raw/`
5. Suggest vault updates — new notes, note revisions, index updates
6. Execute approved updates with full log entries

---

## FOUR INFORMATION LAYERS

> Each layer has a purpose. No duplication across layers.

| Layer | What goes there | Examples | Persistence |
|-------|----------------|----------|-------------|
| **Obsidian Vault** | Durable project knowledge | Architecture decisions, API docs, research summaries, patterns | Permanent, versioned |
| **Claude Memory** | User preferences and habits | "User prefers Go for backends", "Always use dark mode" | Cross-project, per-user |
| **Blox control files** | Operational state | Phase files, checklists, context chain, quality scores | Per-project, session-driven |
| **CLAUDE.md** | Project rules and identity | Tech stack, conventions, installed skills, vault config | Per-project, stable |

**Rule:** If information belongs in one layer, it does NOT go in another.
- A design decision → vault (not CLAUDE.md)
- A user preference → Claude Memory (not vault)
- A phase checklist → blox control file (not vault)
- A project convention → CLAUDE.md (not vault)

---

## OBSIDIAN CLI QUICK REFERENCE

> All commands accept `vault="Name"` for multi-vault targeting.
> Output formats: `json`, `tsv`, `csv`. Use `total` flag for counts only.

### Read / Write

| Command | Description |
|---------|-------------|
| `obsidian read file="Note Name"` | Read note by name (wikilink-style) |
| `obsidian read path="folder/note.md"` | Read note by exact path |
| `obsidian create name="Note Name" content="..." silent` | Create note without opening |
| `obsidian append file="Note Name" content="..."` | Append to note |
| `obsidian prepend file="Note Name" content="..."` | Prepend to note |
| `obsidian move file="Note Name" to="folder/path"` | Move or rename |
| `obsidian delete file="Note Name"` | Delete note |

### Search

| Command | Description |
|---------|-------------|
| `obsidian search query="text" format=json limit=10` | Full-text search |
| `obsidian search:context query="text" format=json` | Search with surrounding context |

### Links

| Command | Description |
|---------|-------------|
| `obsidian backlinks file="Note Name" format=json` | Notes linking TO this note |
| `obsidian links file="Note Name"` | Notes this note links TO |
| `obsidian orphans` | Notes with no incoming links |
| `obsidian deadends` | Notes with no outgoing links |
| `obsidian unresolved verbose` | Broken wikilinks with source files |

### Properties

| Command | Description |
|---------|-------------|
| `obsidian property:set name="key" value="val" file="Note Name"` | Set frontmatter property |
| `obsidian property:read name="key" file="Note Name"` | Read frontmatter property |
| `obsidian property:remove name="key" file="Note Name"` | Remove frontmatter property |
| `obsidian properties file="Note Name" format=yaml` | List all properties |

### Tags

| Command | Description |
|---------|-------------|
| `obsidian tags sort=count counts` | All tags with occurrence counts |
| `obsidian tag name="tagname" verbose` | Tag details with file list |

### Daily Notes

| Command | Description |
|---------|-------------|
| `obsidian daily:read` | Read today's daily note |
| `obsidian daily:append content="text"` | Append to today's daily note |

### Vault Info

| Command | Description |
|---------|-------------|
| `obsidian vaults verbose` | List vaults with paths |
| `obsidian vault info=path` | Current vault path |
| `obsidian files folder="wiki" ext=md` | List files filtered by folder/extension |
| `obsidian folders` | List all folders |

### Tasks

| Command | Description |
|---------|-------------|
| `obsidian tasks todo verbose` | Incomplete tasks grouped by file |
| `obsidian tasks done` | Completed tasks |

---

## WRITING VAULT NOTES

Follow Obsidian Flavored Markdown as described in `references/obsidian-syntax.md`.

**Key rules:**
- Use `[[wikilinks]]` for internal links (not markdown links)
- Every note gets YAML frontmatter with at least `tags`
- Use callouts for warnings, tips, and important information (`> [!note]`, `> [!warning]`)
- Use `![[embed]]` syntax to embed other notes or images
- Tags use `#tag` inline or `tags: [tag1, tag2]` in frontmatter
- Prefer frontmatter tags for consistency

---

## VERIFICATION

### Success indicators
- **init:** CLAUDE.md has `## Obsidian` section, vault has `raw/`, `wiki/`, `wiki/index.md`, `wiki/log.md`
- **ingest:** New wiki note created with frontmatter and wikilinks, index updated, log updated, source saved in raw/
- **query:** Answer synthesized from vault notes with wikilink citations, optional save offered
- **lint:** Health report generated with broken links, orphans, dead-ends, stale notes, tag issues
- **sync:** Unrecorded decisions identified, stale notes flagged, updates suggested and executed

### Failure indicators (STOP and fix!)
- Obsidian CLI not detected and no error shown to user
- Writing to a shared (read-only) vault without permission
- Creating notes without frontmatter or wikilinks
- Skipping index or log updates after any write operation
- Using filesystem access instead of Obsidian CLI
- Duplicating information across layers (vault vs Memory vs CLAUDE.md)

---

## REFERENCES

- `references/schema-template.md` — CLAUDE.md Obsidian section template
- `references/ingest-workflow.md` — Detailed ingest operation workflow
- `references/query-workflow.md` — Detailed query operation workflow
- `references/lint-workflow.md` — Detailed lint operation workflow
- `references/sync-workflow.md` — Detailed sync operation workflow
- `references/obsidian-syntax.md` — Obsidian Flavored Markdown reference
