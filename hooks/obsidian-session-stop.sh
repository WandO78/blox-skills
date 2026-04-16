#!/bin/bash
# Obsidian Vault Reminder Hook — Stop
# Fires on Stop to remind the agent to suggest vault note if valuable knowledge was created.
# Only activates if the project has an Obsidian Knowledge Base section in CLAUDE.md.

CLAUDE_MD="CLAUDE.md"

# Only fire if CLAUDE.md has Obsidian section
if [ ! -f "$CLAUDE_MD" ]; then
  exit 0
fi

if ! grep -q "## Obsidian Knowledge Base" "$CLAUDE_MD" 2>/dev/null; then
  exit 0
fi

# Extract primary vault name
VAULT_NAME=$(grep -A1 "read-write" "$CLAUDE_MD" 2>/dev/null | head -1 | awk -F'|' '{print $2}' | xargs)
if [ -z "$VAULT_NAME" ]; then
  exit 0
fi

echo "---"
echo "OBSIDIAN REMINDER: Before closing, check if this session produced vault-worthy knowledge:"
echo "- Architectural or technology decisions"
echo "- Research findings or comparisons"
echo "- Important discoveries or contradictions"
echo "If yes: suggest writing a vault note to $VAULT_NAME before ending."
echo "If no: close normally."
echo "---"
