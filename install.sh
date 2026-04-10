#!/usr/bin/env bash
set -e

# Claude Conversations — Installer
# Adds persistent conversation logging to Claude Code.
# Run once. Works on macOS, Linux, and Windows (Git Bash/WSL).

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SNIPPET_FILE="$(cd "$(dirname "$0")" && pwd)/claude-md-snippet.md"
HOOK_FILE="$(cd "$(dirname "$0")" && pwd)/hooks/session_start.sh"

echo ""
echo "  Claude Conversations — Installer"
echo "  ================================="
echo ""

# Check Claude Code is installed
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "  ERROR: ~/.claude not found. Install Claude Code first."
    echo "  https://docs.anthropic.com/en/docs/claude-code/overview"
    exit 1
fi

# Create scripts directory
mkdir -p "$SCRIPTS_DIR"

# Copy hook script
STATUSLINE_FILE="$(cd "$(dirname "$0")" && pwd)/hooks/statusline_snippet.sh"

cp "$HOOK_FILE" "$SCRIPTS_DIR/claude_conversations_hook.sh"
chmod +x "$SCRIPTS_DIR/claude_conversations_hook.sh"
echo "  [OK] Hook script installed to $SCRIPTS_DIR/claude_conversations_hook.sh"

# Copy statusline snippet
if [ -f "$STATUSLINE_FILE" ]; then
    cp "$STATUSLINE_FILE" "$SCRIPTS_DIR/claude_conversations_statusline.sh"
    chmod +x "$SCRIPTS_DIR/claude_conversations_statusline.sh"
    echo "  [OK] Statusline snippet installed to $SCRIPTS_DIR/claude_conversations_statusline.sh"
fi

# Add hook to settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    # Create settings.json with the hook
    cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/claude_conversations_hook.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo "  [OK] Created $SETTINGS_FILE with SessionStart hook"
else
    # Check if hook already exists
    if grep -q "claude_conversations_hook" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  [OK] Hook already registered in settings.json (skipped)"
    else
        echo ""
        echo "  MANUAL STEP REQUIRED:"
        echo "  Your settings.json already exists. Add this hook to your SessionStart hooks:"
        echo ""
        echo '  {'
        echo '    "type": "command",'
        echo '    "command": "bash ~/.claude/scripts/claude_conversations_hook.sh"'
        echo '  }'
        echo ""
        echo "  File: $SETTINGS_FILE"
        echo ""

        # Attempt auto-merge if jq is available
        if command -v jq &> /dev/null; then
            read -p "  Attempt automatic merge? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                HOOK_ENTRY='{"type":"command","command":"bash ~/.claude/scripts/claude_conversations_hook.sh"}'

                # Check if SessionStart exists
                if jq -e '.hooks.SessionStart' "$SETTINGS_FILE" > /dev/null 2>&1; then
                    # Append to existing SessionStart hooks
                    jq --argjson hook "$HOOK_ENTRY" '.hooks.SessionStart[0].hooks += [$hook]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
                else
                    # Create SessionStart section
                    jq --argjson hook "$HOOK_ENTRY" '.hooks.SessionStart = [{"matcher":"","hooks":[$hook]}]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
                fi
                echo "  [OK] Hook auto-merged into settings.json"
            fi
        fi
    fi
fi

# Append CLAUDE.md snippet
if [ ! -f "$CLAUDE_MD" ]; then
    cp "$SNIPPET_FILE" "$CLAUDE_MD"
    echo "  [OK] Created $CLAUDE_MD with conversation logging instructions"
elif grep -q "Conversation Logging" "$CLAUDE_MD" 2>/dev/null; then
    echo "  [OK] Conversation logging instructions already in CLAUDE.md (skipped)"
else
    echo "" >> "$CLAUDE_MD"
    cat "$SNIPPET_FILE" >> "$CLAUDE_MD"
    echo "  [OK] Appended conversation logging instructions to $CLAUDE_MD"
fi

echo ""
echo "  Installation complete."
echo ""
echo "  What happens next:"
echo "  1. Start a new Claude Code session in any project"
echo "  2. Claude will automatically log conversations to <your-working-folder>/conversations/"
echo "  3. Conversations are saved as YYYY-MM-DD.md with state transitions"
echo "  4. Git repos get conversations/ added to .gitignore automatically"
echo "  5. When you reference a past session, Claude searches the logs before saying 'I don't know'"
echo ""
echo "  For more info: https://github.com/saikodi/claude-conversations"
echo ""
