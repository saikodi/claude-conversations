#!/usr/bin/env bash
set -e

# Claude Conversations — Uninstaller
# Removes the hook and CLAUDE.md instructions. Does NOT delete existing conversation logs.

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"

echo ""
echo "  Claude Conversations — Uninstaller"
echo "  ===================================="
echo ""

# Remove hook script
if [ -f "$SCRIPTS_DIR/claude_conversations_hook.sh" ]; then
    rm "$SCRIPTS_DIR/claude_conversations_hook.sh"
    echo "  [OK] Removed hook script"
else
    echo "  [--] Hook script not found (already removed?)"
fi

echo ""
echo "  MANUAL STEPS:"
echo "  1. Remove the claude_conversations_hook entry from ~/.claude/settings.json"
echo "  2. Remove the 'Conversation Logging' section from ~/.claude/CLAUDE.md"
echo "  3. Your existing conversation logs in */conversations/ are NOT deleted"
echo ""
