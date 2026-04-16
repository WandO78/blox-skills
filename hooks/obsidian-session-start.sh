#!/bin/bash
# Obsidian Vault Context Hook — SessionStart
# Fires on SessionStart to load vault context into the agent.
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

# Check if Obsidian CLI is available
CLI=""
if command -v obsidian >/dev/null 2>&1; then
  CLI="obsidian"
elif [ -x "/Applications/Obsidian.app/Contents/MacOS/obsidian-cli" ]; then
  CLI="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"
fi

if [ -z "$CLI" ]; then
  echo "---"
  echo "OBSIDIAN VAULT: $VAULT_NAME (CLI not available — start Obsidian)"
  echo "---"
  exit 0
fi

# Get last log entry
LAST_LOG=$($CLI read path="wiki/log.md" vault="$VAULT_NAME" 2>/dev/null | grep "^## \[" | head -1)

# Get wiki note count
NOTE_COUNT=$($CLI files folder="wiki" ext=md vault="$VAULT_NAME" total 2>/dev/null)

echo "---"
echo "OBSIDIAN VAULT: $VAULT_NAME | ${NOTE_COUNT:-0} wiki notes"
if [ -n "$LAST_LOG" ]; then
  echo "Last: $LAST_LOG"
fi
echo "Read wiki/index.md for knowledge map. Use /blox:wiki for operations."
echo "---"
