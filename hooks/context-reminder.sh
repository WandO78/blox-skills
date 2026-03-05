#!/bin/bash
# Context Persistence Hook — Layer 3 (Passive Reminders)
# Fires on UserPromptSubmit to keep the agent oriented after compaction.
#
# Install: Add to .claude/settings.json:
# {
#   "hooks": {
#     "UserPromptSubmit": [
#       {
#         "command": "bash hooks/context-reminder.sh",
#         "timeout": 2000
#       }
#     ]
#   }
# }
#
# See: references/CONTEXT_PERSISTENCE.md for full architecture.

START_HERE="START_HERE.md"

# Only fire in wando-managed projects
if [ ! -f "$START_HERE" ]; then
  exit 0
fi

# Extract active phase file path
ACTIVE_PHASE=$(grep -o '`plans/[^`]*`' "$START_HERE" 2>/dev/null | head -1 | tr -d '`')
if [ -z "$ACTIVE_PHASE" ]; then
  exit 0
fi

# Extract current state from phase file
if [ -f "$ACTIVE_PHASE" ]; then
  PHASE_STATUS=$(grep "^## Status:" "$ACTIVE_PHASE" 2>/dev/null | head -1 | sed 's/## Status: //')
  CURRENT_STEP=$(grep "^## Current Step:" "$ACTIVE_PHASE" 2>/dev/null | head -1 | sed 's/## Current Step: //')
  PHASE_NAME=$(head -1 "$ACTIVE_PHASE" 2>/dev/null | sed 's/^# //')
fi

# Only output if phase is active (not COMPLETED/PENDING)
if [ "$PHASE_STATUS" = "COMPLETED" ] || [ "$PHASE_STATUS" = "PENDING" ]; then
  exit 0
fi

echo "---"
echo "CONTEXT ANCHOR | $PHASE_NAME"
echo "Status: $PHASE_STATUS | Step: $CURRENT_STEP"
echo "If lost context: re-read phase file >>> CURRENT <<< section and relevant SKILL.md"
echo "---"
