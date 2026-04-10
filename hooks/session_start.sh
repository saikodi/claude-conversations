#!/usr/bin/env bash
# Claude Conversations — SessionStart hook
# Fires at the beginning of every Claude Code session.
# Reminds Claude to log conversations to the active working subfolder.

echo "CONVERSATION LOGGING ACTIVE: Log this session to <working-subfolder>/conversations/$(date +%Y-%m-%d).md — save to the subfolder you are actively working in. If the folder is a git repo, ensure conversations/ is in .gitignore."
