#!/usr/bin/env bash
set -e

# Claude Conversations — Uninstaller
# Removes the hooks and scripts. Does NOT delete existing conversation logs.

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

echo ""
echo "  Claude Conversations — Uninstaller"
echo "  ===================================="
echo ""

# Remove hook scripts
for script in claude_conversations_hook.sh claude_conversations_reminder.sh claude_conversations_statusline.sh; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        rm "$SCRIPTS_DIR/$script"
        echo "  [OK] Removed $script"
    else
        echo "  [--] $script not found (already removed?)"
    fi
done

echo ""
echo "  MANUAL STEPS:"
echo ""
echo "  1. Remove from settings.json:"
echo "     File: $SETTINGS_FILE"
echo "     Remove the claude_conversations_hook entry from hooks.SessionStart"
echo "     Remove the claude_conversations_reminder entry from hooks.PostToolUse"
echo ""
echo "  2. Remove from CLAUDE.md:"
echo "     File: $CLAUDE_MD"
echo "     Remove the entire 'Conversation Logging' section"
echo ""
echo "  3. Remove the Conv: section from ~/.claude/statusline-command.sh (if added)"
echo ""
echo "  4. Your existing conversation logs in */conversations/ are NOT deleted"
echo ""
echo "  If you need to restore settings.json from a backup:"
echo "  Look for settings.json.backup in $CLAUDE_DIR"
echo ""
