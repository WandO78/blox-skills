# SKILL.md Template — Reference

> **Source:** TEMPLATES.md Section 2
> **Used by:** `/writing-skills` (superpowers), `/wando:init`
> This file is a COPY of the SKILL.md template for reference purposes.
> The SOURCE OF TRUTH is TEMPLATES.md Section 2.

---

```markdown
---
name: [skill-name]
description: "[1-2 sentences — Claude uses THIS to decide on auto-invocation]"
version: "1.0.0"
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion]
# context: fork          # only if it needs to run as a subagent
# agent: Explore         # only if a specific subagent type is needed
# disable-model-invocation: true  # only if EXCLUSIVELY user-invocable
---

# /wando:[skill-name]

---

## AUTO-DISCOVERY

> **Mandatory section** — `/wando:plan` uses THIS to find this skill.

### Identification
name: [skill-name]
category: [init | plan | quality | learn | advanced | media | infra]
complements: [[other-skill-1], [other-skill-2]]

### Triggers — when the agent invokes automatically
trigger_keywords: [[keyword1], [keyword2], [keyword3]]
trigger_files: [[filename pattern]]
trigger_deps: [[dependency name]]

### Phase integration
when_to_use: |
  [Multi-line description — EXACTLY when to use and when NOT.]
auto_invoke: [true | false]
priority: [mandatory | recommended | optional]

---

## WHEN TO USE

| Trigger | Example | Auto-invoke? |
|---------|---------|-------------|
| [event] | [concrete example] | [yes/no] |

## WHEN NOT TO USE

| Case | Why NOT | Use Instead |
|------|---------|-------------|
| [case] | [reason] | [alternative] |

---

## SKILL LOGIC

### Step 1: [Step name]
[Instructions]

### Step N: [Last step]
[Instructions]

---

## SKILL INTEGRATIONS

| When this happens... | Call | When |
|---------------------|------|------|
| [event] | `/[other-skill]` | [trigger] |

---

## VERIFICATION

### Success indicators
- [checkable item]

### Failure indicators (STOP and fix!)
- [warning sign]

---

## EXAMPLES (optional)

## REFERENCES (optional)

- `references/[filename].md` — [description]
```
