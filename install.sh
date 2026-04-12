#!/usr/bin/env bash
set -e

# Claude Conversations — Installer
# Adds persistent conversation logging to Claude Code.
# Run once. Works on macOS, Linux, and Windows (Git Bash/WSL).

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SNIPPET_FILE="$REPO_DIR/claude-md-snippet.md"
HOOK_FILE="$REPO_DIR/hooks/session_start.sh"
POST_TOOL_HOOK="$REPO_DIR/hooks/post_tool_reminder.sh"
SESSION_END_HOOK="$REPO_DIR/hooks/session_end.sh"
STATUSLINE_FILE="$REPO_DIR/hooks/statusline_snippet.sh"
TIMESTAMP_DIR="$CLAUDE_DIR/conversation_timestamps"

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

# Verify required files exist
if [ ! -f "$HOOK_FILE" ]; then
    echo "  ERROR: Hook file not found at $HOOK_FILE"
    exit 1
fi

if [ ! -f "$SNIPPET_FILE" ]; then
    echo "  ERROR: CLAUDE.md snippet not found at $SNIPPET_FILE"
    exit 1
fi

# Create scripts directory
mkdir -p "$SCRIPTS_DIR"

# Copy hook scripts
cp "$HOOK_FILE" "$SCRIPTS_DIR/claude_conversations_hook.sh"
chmod +x "$SCRIPTS_DIR/claude_conversations_hook.sh"
echo "  [OK] SessionStart hook installed to $SCRIPTS_DIR/claude_conversations_hook.sh"

cp "$POST_TOOL_HOOK" "$SCRIPTS_DIR/claude_conversations_reminder.sh"
chmod +x "$SCRIPTS_DIR/claude_conversations_reminder.sh"
echo "  [OK] PostToolUse hook installed to $SCRIPTS_DIR/claude_conversations_reminder.sh"

cp "$SESSION_END_HOOK" "$SCRIPTS_DIR/claude_conversations_session_end.sh"
chmod +x "$SCRIPTS_DIR/claude_conversations_session_end.sh"
echo "  [OK] SessionEnd hook installed to $SCRIPTS_DIR/claude_conversations_session_end.sh"

# Create timestamp directory
mkdir -p "$TIMESTAMP_DIR"
echo "  [OK] Timestamp directory created at $TIMESTAMP_DIR"

# Copy statusline snippet
if [ -f "$STATUSLINE_FILE" ]; then
    cp "$STATUSLINE_FILE" "$SCRIPTS_DIR/claude_conversations_statusline.sh"
    chmod +x "$SCRIPTS_DIR/claude_conversations_statusline.sh"
    echo "  [OK] Statusline snippet installed to $SCRIPTS_DIR/claude_conversations_statusline.sh"
fi

# Add hooks to settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    # Create settings.json with both hooks
    cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/scripts/claude_conversations_hook.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/scripts/claude_conversations_reminder.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/scripts/claude_conversations_session_end.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS

    # Validate the created JSON (only if jq is available)
    if command -v jq &>/dev/null && ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
        echo "  ERROR: Failed to create valid settings.json"
        rm "$SETTINGS_FILE"
        exit 1
    fi
    echo "  [OK] Created $SETTINGS_FILE with SessionStart + PostToolUse hooks"
else
    # Check if hooks already exist
    SESSION_HOOK_EXISTS=false
    POST_TOOL_HOOK_EXISTS=false
    SESSION_END_HOOK_EXISTS=false
    if grep -q "claude_conversations_hook" "$SETTINGS_FILE" 2>/dev/null; then
        SESSION_HOOK_EXISTS=true
        echo "  [OK] SessionStart hook already registered (skipped)"
    fi
    if grep -q "claude_conversations_reminder" "$SETTINGS_FILE" 2>/dev/null; then
        POST_TOOL_HOOK_EXISTS=true
        echo "  [OK] PostToolUse hook already registered (skipped)"
    fi
    if grep -q "claude_conversations_session_end" "$SETTINGS_FILE" 2>/dev/null; then
        SESSION_END_HOOK_EXISTS=true
        echo "  [OK] SessionEnd hook already registered (skipped)"
    fi

    if [ "$SESSION_HOOK_EXISTS" = false ] || [ "$POST_TOOL_HOOK_EXISTS" = false ] || [ "$SESSION_END_HOOK_EXISTS" = false ]; then
        SESSION_ENTRY='{"type":"command","command":"bash $HOME/.claude/scripts/claude_conversations_hook.sh"}'
        POST_TOOL_ENTRY='{"type":"command","command":"bash $HOME/.claude/scripts/claude_conversations_reminder.sh"}'
        SESSION_END_ENTRY='{"type":"command","command":"bash $HOME/.claude/scripts/claude_conversations_session_end.sh"}'

        MERGED=0
        if command -v jq &> /dev/null; then
            echo "  Automatic merge is available."
            read -p "  Auto-merge hooks into settings.json? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Create backup before modification
                cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
                echo "  [OK] Backup created at ${SETTINGS_FILE}.backup"

                if [ "$SESSION_HOOK_EXISTS" = false ]; then
                    # Check if hooks object exists
                    if ! jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
                        jq --argjson hook "$SESSION_ENTRY" '.hooks = {SessionStart: [{matcher:"", hooks: [$hook]}]}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    elif jq -e '.hooks.SessionStart' "$SETTINGS_FILE" > /dev/null 2>&1; then
                        jq --argjson hook "$SESSION_ENTRY" '.hooks.SessionStart[0].hooks += [$hook]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    else
                        jq --argjson hook "$SESSION_ENTRY" '.hooks.SessionStart = [{matcher:"", hooks: [$hook]}]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    fi

                    # Validate before replacing
                    if jq empty "${SETTINGS_FILE}.tmp" 2>/dev/null; then
                        mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
                        echo "  [OK] SessionStart hook auto-merged"
                        MERGED=1
                    else
                        rm "${SETTINGS_FILE}.tmp"
                        echo "  ERROR: Merge produced invalid JSON. Original saved to ${SETTINGS_FILE}.backup"
                        exit 1
                    fi
                fi

                if [ "$POST_TOOL_HOOK_EXISTS" = false ]; then
                    if jq -e '.hooks.PostToolUse' "$SETTINGS_FILE" > /dev/null 2>&1; then
                        jq --argjson hook "$POST_TOOL_ENTRY" '.hooks.PostToolUse[0].hooks += [$hook]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    else
                        jq --argjson hook "$POST_TOOL_ENTRY" '.hooks.PostToolUse = [{matcher:"", hooks: [$hook]}]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    fi

                    # Validate before replacing
                    if jq empty "${SETTINGS_FILE}.tmp" 2>/dev/null; then
                        mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
                        echo "  [OK] PostToolUse hook auto-merged"
                        MERGED=1
                    else
                        rm "${SETTINGS_FILE}.tmp"
                        echo "  ERROR: Merge produced invalid JSON. Original saved to ${SETTINGS_FILE}.backup"
                        exit 1
                    fi
                fi

                if [ "$SESSION_END_HOOK_EXISTS" = false ]; then
                    if jq -e '.hooks.SessionEnd' "$SETTINGS_FILE" > /dev/null 2>&1; then
                        jq --argjson hook "$SESSION_END_ENTRY" '.hooks.SessionEnd[0].hooks += [$hook]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    else
                        jq --argjson hook "$SESSION_END_ENTRY" '.hooks.SessionEnd = [{matcher:"", hooks: [$hook]}]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
                    fi

                    # Validate before replacing
                    if jq empty "${SETTINGS_FILE}.tmp" 2>/dev/null; then
                        mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
                        echo "  [OK] SessionEnd hook auto-merged"
                        MERGED=1
                    else
                        rm "${SETTINGS_FILE}.tmp"
                        echo "  ERROR: Merge produced invalid JSON. Original saved to ${SETTINGS_FILE}.backup"
                        exit 1
                    fi
                fi
            fi
        else
            echo "  jq is not installed — automatic merge unavailable."
        fi

        if [ "$MERGED" -eq 0 ]; then
            echo ""
            echo "  MANUAL STEP REQUIRED:"
            echo "  Add these hooks to your settings.json ($SETTINGS_FILE):"
            echo ""
            if [ "$SESSION_HOOK_EXISTS" = false ]; then
                echo "  SessionStart hook:"
                echo "  $SESSION_ENTRY"
                echo ""
            fi
            if [ "$POST_TOOL_HOOK_EXISTS" = false ]; then
                echo "  PostToolUse hook:"
                echo "  $POST_TOOL_ENTRY"
                echo ""
            fi
            if [ "$SESSION_END_HOOK_EXISTS" = false ]; then
                echo "  SessionEnd hook:"
                echo "  $SESSION_END_ENTRY"
                echo ""
            fi
            echo "  Example structure (if you don't have hooks yet):"
            echo ""
            echo '  {'
            echo '    "hooks": {'
            echo '      "SessionStart": [{"matcher":"","hooks":[<session hook>]}],'
            echo '      "PostToolUse": [{"matcher":"","hooks":[<posttool hook>]}],'
            echo '      "SessionEnd": [{"matcher":"","hooks":[<session end hook>]}]'
            echo '    }'
            echo '  }'
            echo ""
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
