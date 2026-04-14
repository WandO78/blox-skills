# Ingest Workflow

**Purpose:** Read a source, distill it into structured wiki notes, and integrate it
into the vault's knowledge graph.

---

## Steps

### Step 1 — Identify source

Determine the source type:

- **File in `raw/` folder** — already in the vault, ready to read
- **URL** — suggest saving via Web Clipper first for permanence:
  "I see this is a URL. For long-term reference, consider saving it to your vault's
  `raw/` folder using Obsidian Web Clipper. Should I proceed with the live URL, or
  would you like to save it first?"
- **Pasted text** — save to `raw/` before processing:
  ```
  obsidian create name="raw/[descriptive-name]" content="[pasted text]" vault="[VaultName]" silent
  ```
- **Inline content from chat** — treat as pasted text; save to `raw/` first

If the source is a URL and the user wants to proceed without saving, note that the
content may change or disappear over time. Proceed with the user's choice.

---

### Step 2 — Read source

Read the full content using the appropriate method:

- **File in vault:**
  ```
  obsidian read path="raw/filename.md" vault="[VaultName]"
  ```
- **Non-vault file** (filesystem path given): use the Read tool directly
- **URL:** fetch the content via available web tools
- **Images in markdown:** note image references — they cannot be read inline by
  the agent. Flag them: "This source contains images that I cannot read directly.
  I will note their references. You can describe them or I can view them separately
  if needed."

Read the complete source before proceeding — do not summarize from a partial read.

---

### Step 3 — Discuss with user

Before writing any notes, present the key findings and ask for guidance:

1. **Main topics identified** — list the primary subjects covered in the source
2. **Notable claims or data points** — highlight specific facts, numbers, or
   assertions worth capturing
3. **Connections to existing vault knowledge** — search the index first:
   ```
   obsidian read file="index" vault="[VaultName]"
   ```
   Then search for related terms:
   ```
   obsidian search query="[key terms from source]" vault="[VaultName]" format=json limit=10
   ```
   Report any existing notes that relate to this source.
4. **Ask the user:**
   "What aspects are most important for this project? Anything you want me to
   emphasize, skip, or dig deeper on?"

Wait for the user's response before writing notes. This step ensures the distillation
reflects what the user actually needs, not just what the source contains.

---

### Step 4 — Write summary note

Create a distilled wiki note in `wiki/` using the Obsidian CLI:

```
obsidian create name="[Topic Name]" content="..." vault="[VaultName]" silent
```

**Note structure:**

```markdown
---
title: [Topic Name]
tags:
  - [relevant/tags]
date: [today]
source: "[[raw/source-filename]]"
related:
  - "[[Related Note 1]]"
  - "[[Related Note 2]]"
---

# [Topic Name]

> [!abstract]
> One-paragraph summary of the source.

## Key Points
- Point 1 with [[wikilinks]] to related concepts
- Point 2

## Details
[Detailed notes organized by subtopic]

## Connections
- Related to [[Existing Note]] because...
- Contradicts/supports [[Another Note]] regarding...

## Open Questions
- What about...?
```

**Guidelines for note content:**

- Write in the user's language (Language Protocol)
- Use `[[wikilinks]]` for any concept that has or should have its own note
- Tags should follow the vault's existing tag conventions — check `obsidian tags`
  before creating new ones
- The `source` frontmatter field links back to the raw file
- The `related` frontmatter field lists the most important cross-links
- Sections are optional — omit `Open Questions` if there are none, skip `Connections`
  if the source is a standalone topic
- Keep the abstract to one paragraph — brevity forces clarity
- For long sources, see "Multi-page/long sources" in Handling Special Cases below

---

### Step 5 — Update related notes

Search the vault for existing notes that should reference the new information:

```
obsidian search query="[key terms]" vault="[VaultName]" format=json
```

For each candidate note, check its backlinks to understand its context:

```
obsidian backlinks file="[Related Note]" vault="[VaultName]"
```

Read the candidate note:

```
obsidian read file="[Related Note]" vault="[VaultName]"
```

For each related note that should reference the new note:

1. Append a wikilink in the appropriate section:
   ```
   obsidian append file="[Related Note]" vault="[VaultName]" content="- See also: [[Topic Name]]"
   ```
2. If the new source changes or extends a claim in the existing note, update the
   relevant passage. Read the note first, then use `obsidian append` or edit via
   the appropriate section.

Keep changes minimal — add a link and update only directly affected claims.

---

### Step 6 — Update index.md

Add a one-line entry under the appropriate category in `wiki/index.md`:

```
obsidian append file="index" vault="[VaultName]" content="- [[Topic Name]] — one-line summary"
```

Match the category to the existing index structure (Sources, Concepts, Decisions,
Entities, Analysis). If the new note fits a category not yet in the index, add the
category heading first:

```
obsidian append file="index" vault="[VaultName]" content="\n## [New Category]\n- [[Topic Name]] — one-line summary"
```

---

### Step 7 — Update log.md

Append a log entry recording what was done:

```
obsidian append file="log" vault="[VaultName]" content="## [YYYY-MM-DD] ingest | [Source Title]\n- Source: [[raw/filename]]\n- Wiki note: [[Topic Name]]\n- Related notes updated: [[Note1]], [[Note2]]"
```

If no related notes were updated, omit that line. Always include the source reference
and the wiki note created.

---

### Step 8 — Report

Show the user a summary of what was done:

- **Created:** `wiki/[Topic Name].md` — one-sentence description
- **Updated:** list each note that was modified with the type of change
- **Index:** the new entry that was added
- **Log:** confirm the log entry was written
- **Skipped/flagged:** anything that was not captured, with reason

If the source contained images that were not read, remind the user here.

---

## Handling Special Cases

### Multi-page / long sources

Break the source into logical sections and create one note per major topic:

1. Read the full source first to understand its structure
2. Identify 2–5 major themes or topics
3. Discuss the breakdown with the user before creating notes
4. Create one wiki note per topic, each with its own frontmatter and wikilinks
5. Create a parent overview note that links to all sub-notes:
   ```markdown
   # [Source Title] — Overview
   > [!abstract]
   > Summary of the full source.

   ## Topics
   - [[Sub-topic 1]]
   - [[Sub-topic 2]]
   ```
6. Add the overview note to the index; sub-notes are discoverable via wikilinks

### Contradicting existing knowledge

When the new source contradicts an existing note:

1. Do NOT silently overwrite the existing claim
2. Flag the conflict with a warning callout in the new note:
   ```markdown
   > [!warning] Contradicts [[Existing Note]]
   > This source claims X. [[Existing Note]] states Y. Source: [[raw/filename]].
   > **Resolution needed** — see [[Existing Note]] for context.
   ```
3. Also add a reciprocal flag in the existing note:
   ```
   obsidian append file="[Existing Note]" vault="[VaultName]" content="\n> [!warning] Contradicted by [[Topic Name]]\n> [[Topic Name]] presents conflicting information. Review needed."
   ```
4. Inform the user: "I found a conflict between this source and [[Existing Note]].
   I've flagged both notes. Which claim should take precedence?"
5. Let the user decide — do not resolve the conflict autonomously

### Sources without clear structure

When a source lacks clear organization (raw notes, transcripts, brainstorms):

1. Ask the user: "This source doesn't have a clear structure. How would you like
   me to organize it? Options: (a) extract key concepts as separate notes,
   (b) create a single note with loose sections, (c) save as-is in raw/ and skip
   wiki distillation for now."
2. Follow the user's choice
3. For option (c), still update log.md to record that the source was saved but
   not yet distilled

### Images in sources

When a source references or embeds images:

1. Note all image references in your internal reading
2. In the wiki note, reference images using Obsidian embed syntax:
   `![[raw/assets/image-filename.png]]`
3. Flag to the user: "This source contains images at [references]. I can view them
   separately for additional context if needed."
4. If image content is critical (diagrams, charts with data), ask the user to
   describe them or view them using available tools before finalizing the note

---

## Example Session

**User:** "Ingest this article about vector databases: raw/vector-db-comparison.md"

**Agent:**
1. Reads `raw/vector-db-comparison.md` from vault
2. Reads `wiki/index.md` to check existing knowledge
3. Searches for `vector database` — finds `[[Embeddings Overview]]` note exists
4. Presents to user: "This article compares Pinecone, Weaviate, and Chroma on
   latency, cost, and filtering capabilities. Key data: Pinecone leads on managed
   hosting, Weaviate on self-hosted flexibility, Chroma on local dev simplicity.
   I found an existing `[[Embeddings Overview]]` note that this connects to. What
   aspects matter most for your project?"
5. User: "Focus on the cost comparison and local dev options."
6. Creates `wiki/Vector DB Comparison.md` with cost-focused content, links to
   `[[Embeddings Overview]]`
7. Updates `[[Embeddings Overview]]` with a link to the new note
8. Appends to `wiki/index.md` under Analysis
9. Appends to `wiki/log.md`
10. Reports: "Created [[Vector DB Comparison]], updated [[Embeddings Overview]],
    added to index under Analysis."

---

## CLI Syntax Reminder

- ALL Obsidian CLI commands use `key=value` syntax: `file="Name"`, `content="..."`, `vault="Name"`
- Always include `vault="VaultName"` on every command — never rely on a default vault
- Always use `silent` flag on `create` to avoid opening the note in Obsidian
- Use `obsidian read` before any `obsidian append` to understand existing note structure
