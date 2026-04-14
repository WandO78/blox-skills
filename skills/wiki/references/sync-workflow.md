# Sync Workflow — Project-Vault Consistency

Purpose: Detect drift between the project's current state and the vault's knowledge.
Unlike lint (vault-internal health), sync checks project-vault alignment.

**Important distinction:**
- **lint** = vault internal health (broken links, orphans, tags)
- **sync** = project ↔ vault consistency (stale knowledge, unrecorded decisions)

---

## Steps (in order)

### 1. Find Last Sync Point

Read `wiki/log.md` for the most recent sync or session entry:

```
obsidian read path="wiki/log.md" vault="VaultName"
```

Scan for the latest entry of type `sync` or `session`. The date from that entry
is the **baseline** — everything after this date needs checking.

If no previous sync entry exists, use the vault init date as the baseline.

### 2. Scan Recent Project Activity

Read git log since the baseline date:

```bash
git log --oneline --since="[last sync date]"
```

From the output, identify commits that signal knowledge-worthy changes:
- New features or capabilities added
- Architectural changes (frameworks, patterns, structures)
- Technology decisions (new dependencies, dropped dependencies)
- Configuration changes (database, deployment, auth, environment)
- Significant refactors (reasoning likely worth capturing)
- Bug fixes that reveal assumptions or constraints

### 3. Check for Unrecorded Decisions

Compare the commits identified in Step 2 against vault content.

For each significant change, search the vault:

```
obsidian search query="[changed component or technology]" vault="VaultName" format=json
```

Flag cases where a meaningful project change has no corresponding vault entry:
- Architectural changes (new frameworks, patterns) → should be a vault decision note
- Config changes (database, deployment, auth) → should be documented
- Significant refactors → design reasoning should be captured

### 4. Find Stale Vault Notes

Find vault notes that describe project state that has since changed.

For each changed component from Step 2, search the vault:

```
obsidian search query="[changed component]" vault="VaultName" format=json
```

Read the matching notes and compare their claims against the current code state.
Flag notes where the described state no longer matches reality.

Examples of stale content:
- A note says "we use SQLite" but the project switched to PostgreSQL
- A note references v1 API endpoints when v2 is now live
- A note describes a monolith architecture after a move to microservices

### 5. Check for Unprocessed Sources

List files in the `raw/` folder:

```
obsidian files folder="raw" vault="VaultName"
```

Read log.md and check the ingest entries. Compare the raw/ file list against
logged ingest events. Flag files present in raw/ that have never been ingested.

### 6. Check Phase Alignment

If blox phase files exist in the project (`.blox/phase-*.md` or similar):

- Read the current phase file for outcomes and decisions recorded there
- Search the vault for matching topics
- Flag phase decisions or outcomes not reflected in any vault note

---

## Drift Report Format

After completing all checks, generate a structured report:

```markdown
# Sync Report — [date]

## Unrecorded (project changed, vault didn't)
- [ ] New dependency: Added Redis for caching — no vault note
- [ ] Architecture: Moved to microservices pattern — vault still says monolith
- [ ] Config: Switched from SQLite to PostgreSQL — vault note outdated

## Stale (vault says X, project says Y)
- [ ] [[Database Choice]] says SQLite — project now uses PostgreSQL
- [ ] [[API Design]] references v1 endpoints — v2 is live

## Unprocessed (raw sources not yet ingested)
- [ ] raw/meeting-notes-2026-04-10.md — not in log.md
- [ ] raw/competitor-analysis.pdf — not in log.md

## Suggestions
- Create note: "Redis Caching Decision" with reasoning
- Update note: [[Database Choice]] with migration context
- Ingest: raw/meeting-notes-2026-04-10.md
```

---

## Execution

For each finding, suggest a concrete action before applying anything:

| Finding | Action |
|---|---|
| Unrecorded decision | Create a new vault note capturing the decision and reasoning |
| Stale note | Update the note with current state, note what changed and when |
| Unprocessed source | Run the ingest workflow for the file |
| Phase misalignment | Update vault from phase file decisions |

**Always ask user approval before making any changes.**

---

## Log Entry

After completing sync, append to log.md:

```
## [YYYY-MM-DD] sync | X unrecorded, Y stale, Z unprocessed
```
