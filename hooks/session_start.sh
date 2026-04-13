#!/usr/bin/env bash
# Claude Conversations — SessionStart hook
# Fires at the beginning of every Claude Code session.
# Creates the per-session timestamp baseline and reminds Claude to log.
#
# Reads session_id from stdin JSON (passed by Claude Code) for per-session timestamp isolation.

# Read stdin JSON and extract session_id
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)

TIMESTAMP_DIR="$HOME/.claude/conversation_timestamps"
mkdir -p "$TIMESTAMP_DIR" 2>/dev/null

if [ -n "$SESSION_ID" ]; then
    touch "$TIMESTAMP_DIR/.conv_last_write_$SESSION_ID" 2>/dev/null
fi

echo "CONVERSATION LOGGING ACTIVE: Log this session to <working-subfolder>/conversations/$(date +%Y-%m-%d).md — save to the subfolder you are actively working in. If the folder is a git repo, ensure conversations/ is in .gitignore."
