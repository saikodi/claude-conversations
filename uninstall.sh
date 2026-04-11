#!/usr/bin/env bash
set -e

# Claude Conversations — Uninstaller
# Removes the hook and CLAUDE.md instructions. Does NOT delete existing conversation logs.

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

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

# Remove statusline script if it exists
if [ -f "$SCRIPTS_DIR/claude_conversations_statusline.sh" ]; then
    rm "$SCRIPTS_DIR/claude_conversations_statusline.sh"
    echo "  [OK] Removed statusline script"
fi

echo ""
echo "  MANUAL STEPS:"
echo ""
echo "  1. Remove from settings.json:"
echo "     File: $SETTINGS_FILE"
echo "     Remove this entry from hooks.SessionStart array:"
echo ""
echo '     {'
echo '       "type": "command",'
echo '       "command": "bash $HOME/.claude/scripts/claude_conversations_hook.sh"'
echo '     }'
echo ""
echo "  2. Remove from CLAUDE.md:"
echo "     File: $CLAUDE_MD"
echo "     Remove the entire 'Conversation Logging' section"
echo ""
echo "  3. Your existing conversation logs in */conversations/ are NOT deleted"
echo ""
echo "  If you need to restore settings.json from a backup:"
echo "  Look for settings.json.backup in $CLAUDE_DIR"
echo ""
