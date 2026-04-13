#!/usr/bin/env bash
# Claude Conversations — SessionEnd hook
# Cleans up the per-session timestamp file when the session terminates.
#
# Reads session_id from stdin JSON (passed by Claude Code) for per-session timestamp isolation.

# Read stdin JSON and extract session_id
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)

if [ -n "$SESSION_ID" ]; then
    rm -f "$HOME/.claude/conversation_timestamps/.conv_last_write_$SESSION_ID" 2>/dev/null
fi
