# Query Workflow — /blox:wiki query

Detailed workflow for the `query` operation. The main SKILL.md delegates here.

**Purpose:** Search the vault for existing knowledge and synthesize an answer with citations.

---

## Step 1 — Understand the Question

Classify the question type before deciding how to search:

| Type | Example | Strategy |
|------|---------|----------|
| **Factual** | "What database do we use?" | Direct lookup — find the fact and return it |
| **Analytical** | "Why did we choose PostgreSQL?" | Decision context — look for ADRs, decision notes, rationale |
| **Comparative** | "How does approach A compare to B?" | Multi-source synthesis — gather notes on both, compare |
| **Exploratory** | "What do we know about auth?" | Broad search — gather all related notes, summarize coverage |

The question type determines how many notes to read and how deeply to synthesize.

---

## Step 2 — Search Strategy

Execute searches in this order. Stop when enough context is gathered.

**2a. Read the index first:**

```
obsidian read file="index" vault="VaultName"
```

Scan `wiki/index.md` to identify which topics and notes are likely relevant.
This avoids full-text searches when the index already points to the right note.

**2b. Full-text search on primary vault:**

```
obsidian search query="key terms" vault="VaultName" format=json
```

Use 2-4 keywords from the question. Run multiple targeted searches rather than
one broad query if the question has multiple aspects.

**2c. Search shared vaults (if configured in CLAUDE.md):**

Run the same query against each read-only vault listed under `## Obsidian`:

```
obsidian search query="key terms" vault="SharedVaultName" format=json
```

**2d. Tag-based discovery (if full-text search is thin):**

```
obsidian tags sort=count counts vault="VaultName"
```

Identify tags that match the question domain. Then follow those tags to related
notes that may not have matched the keyword search.

**2e. Backlink traversal (if a relevant note is found but context is shallow):**

```
obsidian backlinks file="Related Note" vault="VaultName"
```

Notes that link to a relevant note often provide additional context, decisions,
or viewpoints.

---

## Step 3 — Read Relevant Notes

Read the top candidate notes. For factual questions, 1-3 notes are usually enough.
For analytical or comparative questions, read more broadly.

```
obsidian read file="Note Name" vault="VaultName"
```

As you read:
- Follow `[[wikilinks]]` to connected notes when the link is clearly relevant
- Do NOT follow every link — use judgment to stay on topic
- For exploratory questions, prefer breadth; for factual questions, prefer depth

Build a working understanding of what the vault knows about the topic before
writing the answer.

---

## Step 4 — Synthesize the Answer

Compose an answer using the vault knowledge gathered. The answer structure
depends on the question type:

**Factual:**
- Direct statement of the fact
- Single citation: `[[Note Name]]`
- Confidence: high if found explicitly, low if inferred

**Analytical:**
- Explain the decision, context, or reasoning found in vault notes
- Cite the notes where the rationale lives
- Surface constraints or trade-offs if noted

**Comparative:**
- Side-by-side summary of each approach
- Where the vault has opinions or decisions, surface them explicitly
- Cite each source note per claim

**Exploratory:**
- Overview of what topics the vault covers on this theme
- Group findings by sub-topic
- Flag gaps: areas the question touches where the vault has little or nothing

**Every answer must include:**
- Clear answer with reasoning, not just raw note excerpts
- Citations using `[[wikilinks]]` to the vault notes used
- Confidence level: state whether the answer is well-supported (multiple notes
  converge) or limited (thin data, single source, or inferred)
- Gaps: name what information is missing that would improve the answer

---

## Step 5 — Offer to Save

If the synthesized answer represents meaningful new analysis — not just a fact
already in a single note — offer to save it:

> "This analysis could be valuable as a vault note. Save it to the wiki?"

If the user agrees:
- Create a note in `wiki/` using the same structure as ingest summaries (see
  `references/schema-template.md` for frontmatter conventions)
- Title the note to reflect the question, not the answer (e.g., "Why We Chose PostgreSQL")
- Include wikilinks back to the source notes used in the synthesis
- Update `wiki/index.md` with an entry under the relevant section
- Append to `wiki/log.md`:

```
## [YYYY-MM-DD] query | [Question summary]
- Synthesized from: [[Note A]], [[Note B]]
- Saved as: [[New Note Title]]
```

If the user declines or the answer is trivial (single-note lookup), do not save.

---

## Multi-Vault Queries

When `CLAUDE.md` lists shared vaults under `## Obsidian`:

- Search the primary vault first — it holds project-specific knowledge
- Search shared vaults second — they hold broader reference or team knowledge
- When citing, indicate which vault the information came from:
  - Primary vault: `[[Note Name]]` (implicit)
  - Shared vault: "See [VaultName] vault: Note Title"
- If a shared vault note directly answers the question, quote the relevant
  passage and identify its origin clearly
- NEVER write to a shared vault — read only

---

## Handling "No Results"

If the vault has no relevant knowledge for the question:

1. Tell the user what was searched and where:
   > "I searched for [terms] in [vault name] and found no relevant notes.
   > The index also does not list a topic that matches your question."

2. Suggest next steps:
   - "Would you like me to research this and ingest the findings into the vault?"
   - "If you have a source (article, doc, note), run `/blox:wiki ingest [source]`
     and I will distill it into vault knowledge."
   - Suggest specific likely sources if you can infer them from the question domain

Do not fabricate an answer from outside the vault. The point of the query
operation is to surface what the vault knows — not to answer from general
knowledge. If the vault has nothing, say so clearly.

---

## Example Queries

### Factual — "What database do we use?"

1. Read `wiki/index.md` → spot "Decisions" section, see `[[Database Choice]]`
2. `obsidian read file="Database Choice" vault="ProjectVault"`
3. Answer: "The project uses PostgreSQL. See [[Database Choice]]."
4. Confidence: high. No gaps.

---

### Analytical — "Why did we choose PostgreSQL?"

1. Read `wiki/index.md` → find `[[Database Choice]]` under Decisions
2. `obsidian read file="Database Choice" vault="ProjectVault"` → contains rationale
3. Follow wikilink to `[[Performance Evaluation]]` if referenced
4. Synthesize: decision drivers (JSONB support, existing ops expertise, query complexity), trade-offs considered (MySQL, SQLite), timestamp of decision
5. Answer with citations and confidence. If rationale is thin, note the gap.

---

### Comparative — "How does our auth approach compare to JWT-only?"

1. `obsidian search query="auth authentication JWT" vault="ProjectVault" format=json`
2. Read top results: `[[Auth Architecture]]`, `[[Security Decisions]]`
3. `obsidian backlinks file="Auth Architecture" vault="ProjectVault"` to find related notes
4. Synthesize: table or prose comparing current approach vs pure JWT, citing vault sources per point
5. Flag: if the vault has no prior JWT evaluation, note this as a gap

---

### Exploratory — "What do we know about auth?"

1. `obsidian search query="auth authentication session token" vault="ProjectVault" format=json`
2. `obsidian tags sort=count counts vault="ProjectVault"` — look for `#auth`, `#security` tags
3. Read all auth-related notes found
4. Answer: grouped overview — what patterns, decisions, open questions the vault covers on auth
5. List uncovered sub-topics as gaps
6. Offer to save the overview as `[[Auth — Knowledge Overview]]` if it adds value
