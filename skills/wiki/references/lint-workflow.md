# Lint Workflow — Vault Health Check

Purpose: Check vault structural health, find issues, suggest fixes.

---

## Checks (in order)

### 1. Broken Wikilinks

Command: `obsidian unresolved verbose vault="VaultName"`

Lists all `[[references]]` pointing to non-existent notes.

For each broken link:
- Suggest creating the missing note (if the topic is valid)
- Or suggest fixing the link text (if it's a typo or rename)

### 2. Orphan Notes

Command: `obsidian orphans vault="VaultName"`

Notes with no incoming links — nothing links to them.

For each orphan:
- Should it be linked from a related note?
- Should it be added to index.md?
- Is it obsolete and should be archived/deleted?

### 3. Dead-End Notes

Command: `obsidian deadends vault="VaultName"`

Notes with no outgoing links — they link to nothing.

For each dead-end:
- Identify related topics the note could link to
- Add connections to improve vault graph density

### 4. Index Coverage

Command: `obsidian files folder="wiki" ext=md vault="VaultName"`

Compare the file list against entries in index.md.

Flag:
- Notes that exist but are missing from index.md
- Index entries pointing to notes that no longer exist (deleted notes)

### 5. Stale Content

Check log.md for notes not updated recently (threshold: 30+ days without activity).

Cross-reference with recent project activity to determine if staleness is intentional.

Flag:
- Notes that haven't been updated in 30+ days
- Notes whose content contradicts recent decisions in log.md

### 6. Tag Consistency

Command: `obsidian tags sort=count counts vault="VaultName"`

Analyze the full tag list for:
- Near-duplicate tags (typos or inconsistent naming, e.g. `#auth` vs `#authentication`)
- Tags used only once (orphan tags — may indicate naming inconsistency)
- Flat tags that should be nested (e.g. `#backend` and `#backend-api` → `#backend/api`)

### 7. Frontmatter Completeness

Sample wiki notes and check each for required frontmatter properties:
- `title` — note title
- `tags` — at least one tag
- `date` — creation or last-update date

Flag notes with any missing properties.

### 8. Contradictions (hardest check)

Read notes on the same topic and flag claims that contradict each other.

Strategy:
- Use keyword overlap and wikilink proximity to find candidate pairs
- Read both notes and compare factual claims, decisions, or statuses
- Flag pairs where one note says X and another says not-X on the same topic

---

## Report Format

Generate a structured report with severity levels after completing all checks:

```markdown
# Vault Health Report — [YYYY-MM-DD]

## Errors (must fix)
- [ ] Broken link: [[Missing Note]] referenced from [[Source Note]]
- [ ] Index entry points to deleted note: [[Old Note]]

## Warnings (should fix)
- [ ] Orphan note: [[Isolated Note]] — no incoming links
- [ ] Stale note: [[Old Decision]] — last updated 60 days ago
- [ ] Incomplete frontmatter: [[Quick Note]] — missing title, date

## Info (consider)
- [ ] Dead-end: [[Leaf Note]] — no outgoing links
- [ ] Similar tags: #auth and #authentication — merge?
- [ ] Possible contradiction: [[Note A]] vs [[Note B]] on topic X
```

---

## Fix Process

For each finding, offer a concrete fix before applying anything:

| Finding | Fix |
|---|---|
| Broken link | Create the missing note, or correct the link text |
| Orphan note | Add a link from a relevant note or from index.md |
| Stale note | Review and update content, or move to an archive folder |
| Tag inconsistency | Rename tags vault-wide (confirm before executing) |
| Missing frontmatter | Add the missing properties to the note |
| Dead-end | Add outgoing links to related topics |
| Contradiction | Present both claims to user, decide which is current |

**Always ask user approval before applying any fixes.**

---

## Log Entry

After completing lint, append to log.md:

```
## [YYYY-MM-DD] lint | X errors, Y warnings, Z info
```
