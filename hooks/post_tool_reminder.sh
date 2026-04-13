#!/usr/bin/env bash
# Claude Conversations — PostToolUse hook
# Fires after every tool call. Checks if conversation log is overdue and reminds Claude to write it.
# The reminder goes into Claude's context so it acts on it — this is the deterministic enforcement mechanism.
#
# Reads session_id from stdin JSON (passed by Claude Code) for per-session timestamp isolation.
# Timestamp files live in ~/.claude/conversation_timestamps/ keyed by session_id.

# Read stdin JSON and extract session_id
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0  # no session_id = can't track, skip silently

# Configurable interval in seconds (default: 5 minutes)
INTERVAL="${CLAUDE_CONV_INTERVAL:-300}"

TIMESTAMP_DIR="$HOME/.claude/conversation_timestamps"
TIMESTAMP_FILE="$TIMESTAMP_DIR/.conv_last_write_$SESSION_ID"

# If timestamp file doesn't exist, create it silently as baseline.
# This prevents firing on the very first tool call of a session.
# The next check after INTERVAL seconds will be the first real reminder.
if [ ! -f "$TIMESTAMP_FILE" ]; then
    mkdir -p "$TIMESTAMP_DIR" 2>/dev/null
    touch "$TIMESTAMP_FILE" 2>/dev/null
    exit 0
fi

# Check age of timestamp file
mod_epoch=$(stat -c %Y "$TIMESTAMP_FILE" 2>/dev/null || stat -f %m "$TIMESTAMP_FILE" 2>/dev/null)
if [ -z "$mod_epoch" ]; then
    exit 0
fi

now_epoch=$(date +%s)
age=$(( now_epoch - mod_epoch ))

if [ "$age" -ge "$INTERVAL" ]; then
    # Touch the file NOW to prevent repeated reminders on every subsequent tool call.
    # Next reminder fires INTERVAL seconds from now regardless of whether Claude writes.
    touch "$TIMESTAMP_FILE" 2>/dev/null

    today=$(date +%Y-%m-%d)
    elapsed_min=$(( age / 60 ))

    MSG="CONVERSATION LOG DUE (${elapsed_min}m since last write): Write conversation transcript to ./conversations/${today}.md now. Append to existing content if the file exists. Follow the transcript format in CLAUDE.md — verbatim quotes, tool calls, failed approaches, state transitions. Write asynchronously (background agent or run_in_background). Do NOT block the user's work."
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$MSG"
fi
