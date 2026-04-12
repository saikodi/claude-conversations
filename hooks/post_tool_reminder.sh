#!/usr/bin/env bash
# Claude Conversations — PostToolUse hook
# Fires after every tool call. Checks if conversation log is overdue and reminds Claude to write it.
# The reminder goes into Claude's context so it acts on it — this is the deterministic enforcement mechanism.

# Configurable interval in seconds (default: 5 minutes)
INTERVAL="${CLAUDE_CONV_INTERVAL:-300}"

# Look for conversations/ directory in current working directory
CONV_DIR="./conversations"
LAST_WRITE_FILE="$CONV_DIR/.last_write"

# If conversations/ doesn't exist, skip silently.
# SessionStart hook handles creation. Nothing to log yet.
if [ ! -d "$CONV_DIR" ]; then
    exit 0
fi

# If .last_write doesn't exist, create it silently as baseline.
# This prevents firing on the very first tool call of a session.
# The next check after INTERVAL seconds will be the first real reminder.
if [ ! -f "$LAST_WRITE_FILE" ]; then
    touch "$LAST_WRITE_FILE" 2>/dev/null
    exit 0
fi

# Check age of .last_write
mod_epoch=$(stat -c %Y "$LAST_WRITE_FILE" 2>/dev/null || stat -f %m "$LAST_WRITE_FILE" 2>/dev/null)
if [ -z "$mod_epoch" ]; then
    exit 0
fi

now_epoch=$(date +%s)
age=$(( now_epoch - mod_epoch ))

if [ "$age" -ge "$INTERVAL" ]; then
    # Touch the file NOW to prevent repeated reminders on every subsequent tool call.
    # Next reminder fires INTERVAL seconds from now regardless of whether Claude writes.
    touch "$LAST_WRITE_FILE" 2>/dev/null

    today=$(date +%Y-%m-%d)
    elapsed_min=$(( age / 60 ))

    echo "CONVERSATION LOG DUE (${elapsed_min}m since last write): Write conversation transcript to ./conversations/${today}.md now. Append to existing content if the file exists. Follow the transcript format in CLAUDE.md — verbatim quotes, tool calls, failed approaches, state transitions. Write asynchronously (background agent or run_in_background). Do NOT block the user's work."
fi
