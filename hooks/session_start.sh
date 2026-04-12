#!/usr/bin/env bash
# Claude Conversations — SessionStart hook
# Fires at the beginning of every Claude Code session.
# Creates the per-session timestamp baseline and reminds Claude to log.

TIMESTAMP_DIR="$HOME/.claude/conversation_timestamps"

# Create timestamp directory and per-session baseline
mkdir -p "$TIMESTAMP_DIR" 2>/dev/null
touch "$TIMESTAMP_DIR/.conv_last_write_$PPID" 2>/dev/null

echo "CONVERSATION LOGGING ACTIVE: Log this session to <working-subfolder>/conversations/$(date +%Y-%m-%d).md — save to the subfolder you are actively working in. If the folder is a git repo, ensure conversations/ is in .gitignore."
