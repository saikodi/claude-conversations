#!/usr/bin/env bash
# Claude Conversations — SessionEnd hook
# Cleans up the per-session timestamp file when the session terminates.

TIMESTAMP_DIR="$HOME/.claude/conversation_timestamps"
TIMESTAMP_FILE="$TIMESTAMP_DIR/.conv_last_write_$PPID"

if [ -f "$TIMESTAMP_FILE" ]; then
    rm "$TIMESTAMP_FILE" 2>/dev/null
fi
