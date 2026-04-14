# Obsidian Flavored Markdown — Syntax Reference

Quick lookup reference for Obsidian-specific markdown syntax. Use this when writing vault notes.

---

## Wikilinks (Internal Links)

```
[[Note Name]]                          Link to note
[[Note Name|Display Text]]             Custom display text
[[Note Name#Heading]]                  Link to heading
[[Note Name#^block-id]]                Link to block
[[#Heading in same note]]              Same-note heading link
```

**Block IDs:** Append `^block-id` to any paragraph. For lists and blockquotes, place on a separate line after the block.

**Rule:** Use `[[wikilinks]]` for all vault-internal links. Use `[text](url)` ONLY for external URLs. Obsidian tracks renames automatically for wikilinks.

---

## Embeds

```
![[Note Name]]                         Embed full note
![[Note Name#Heading]]                 Embed section
![[image.png]]                         Embed image
![[image.png|300]]                     Embed image with width
![[image.png|640x480]]                 Embed image with dimensions
![[document.pdf#page=3]]               Embed PDF page
![[audio.mp3]]                         Embed audio
```

External images: `![Alt text](https://example.com/image.png)` or `![Alt text|300](url)`

Embed search results:

````
```query
tag:#project status:done
```
````

---

## Callouts

```
> [!note]
> Basic callout.

> [!warning] Custom Title
> Callout with custom title.

> [!faq]- Collapsed by default
> Foldable callout (- collapsed, + expanded).
```

Nested callouts:

```
> [!question] Outer
> > [!note] Inner
> > Nested content
```

### Callout Types

| Type | Aliases | Color / Icon |
|------|---------|--------------|
| `note` | — | Blue, pencil |
| `abstract` | `summary`, `tldr` | Teal, clipboard |
| `info` | — | Blue, info |
| `todo` | — | Blue, checkbox |
| `tip` | `hint`, `important` | Cyan, flame |
| `success` | `check`, `done` | Green, checkmark |
| `question` | `help`, `faq` | Yellow, question mark |
| `warning` | `caution`, `attention` | Orange, warning |
| `failure` | `fail`, `missing` | Red, X |
| `danger` | `error` | Red, zap |
| `bug` | — | Red, bug |
| `example` | — | Purple, list |
| `quote` | `cite` | Gray, quote |

---

## Properties (Frontmatter)

```yaml
---
title: My Note Title
date: 2024-01-15
tags:
  - project
  - important
aliases:
  - Alternative Name
cssclasses:
  - custom-class
status: in-progress
rating: 4.5
completed: false
due: 2024-01-15T14:30:00
related: "[[Other Note]]"
---
```

**7 property types:** Text, Number, Checkbox, Date, Date+Time, List, Links

**Reserved properties:** `tags`, `aliases`, `cssclasses`

---

## Tags

```
#tag                    Inline tag
#nested/tag             Nested tag with hierarchy
#tag-with-dashes
#tag_with_underscores
```

Tags can contain: letters, numbers (not as first character), underscores, hyphens, forward slashes.
Can also be defined in the frontmatter `tags:` property.

---

## Comments

```
This is visible %%but this is hidden%% text.

%%
This entire block is hidden in reading view.
%%
```

---

## Other Obsidian-Specific Syntax

| Syntax | Result |
|--------|--------|
| `==Highlighted text==` | Highlight |
| `$e^{i\pi} + 1 = 0$` | Inline math (LaTeX) |
| `$$\frac{a}{b} = c$$` | Block math (LaTeX) |
| `` ```mermaid `` | Mermaid diagram (fenced block) |
| `[^1]` + `[^1]: text` | Footnote reference |
| `^[inline footnote]` | Inline footnote |

---

## Complete Example Note

```markdown
---
title: Project Alpha
date: 2024-01-15
tags:
  - project
  - active
aliases:
  - Alpha Project
status: in-progress
related: "[[Project Beta]]"
---

# Project Alpha

Overview of Project Alpha. See also [[Project Beta]] and [[Team Members#Alice]].

> [!tip] Key Insight
> This project depends on the [[API Design#^auth-block]] decision.

## Goals

- Deliver MVP by Q2 ^goals-block
- Integrate with [[Data Pipeline]]

## Notes

==Critical:== Review [[Risk Register]] before proceeding.

Current formula: $\text{velocity} = \frac{\Delta x}{\Delta t}$

%%Internal note: budget approval still pending%%

For external reference: [Spec document](https://example.com/spec.pdf)

![[architecture-diagram.png|600]]

> [!warning] Deadline
> Due 2024-03-31. Sync with [[Team Members|the team]] weekly.

[^1]: Source: internal planning doc v3.
```

---

## Quick Reference: Link vs Embed vs External

| Use case | Syntax |
|----------|--------|
| Internal note link | `[[Note Name]]` |
| Internal link with alias | `[[Note Name\|Display Text]]` |
| Embed note/section | `![[Note Name]]` or `![[Note#Section]]` |
| External URL | `[text](https://url)` |
| External image | `![alt](https://url)` or `![alt\|300](url)` |
