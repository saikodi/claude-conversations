#!/usr/bin/env bash
# Claude Conversations — Status line snippet
# Add this to your existing statusline command script (~/.claude/statusline-command.sh)
# Shows conversation log freshness: "Conv: 2m ago", "Conv: DUE", or "Conv: --"

INTERVAL="${CLAUDE_CONV_INTERVAL:-300}"

TIMESTAMP_DIR="$HOME/.claude/conversation_timestamps"
TIMESTAMP_FILE="$TIMESTAMP_DIR/.conv_last_write_$PPID"

if [ -f "$TIMESTAMP_FILE" ]; then
    mod_epoch=$(stat -c %Y "$TIMESTAMP_FILE" 2>/dev/null || stat -f %m "$TIMESTAMP_FILE" 2>/dev/null)
    if [ -n "$mod_epoch" ]; then
        now_epoch=$(date +%s)
        diff_sec=$(( now_epoch - mod_epoch ))
        if [ "$diff_sec" -ge "$INTERVAL" ]; then
            echo "Conv: DUE"
        elif [ "$diff_sec" -lt 60 ]; then
            echo "Conv: ${diff_sec}s ago"
        elif [ "$diff_sec" -lt 3600 ]; then
            echo "Conv: $(( diff_sec / 60 ))m ago"
        else
            echo "Conv: $(( diff_sec / 3600 ))h ago"
        fi
    else
        echo "Conv: --"
    fi
else
    echo "Conv: --"
fi
