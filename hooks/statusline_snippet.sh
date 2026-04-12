#!/usr/bin/env bash
# Claude Conversations — Status line snippet
# Add this to your existing statusline command script (~/.claude/statusline-command.sh)
# Shows conversation log freshness: "Conv: 2m ago", "Conv: DUE", or "Conv: --"

INTERVAL="${CLAUDE_CONV_INTERVAL:-300}"

today=$(date +%Y-%m-%d)
conv_file="./conversations/${today}.md"
last_write_file="./conversations/.last_write"
[ ! -f "$conv_file" ] && conv_file=""
[ ! -f "$last_write_file" ] && last_write_file=""

if [ -n "$conv_file" ]; then
  mod_epoch=$(stat -c %Y "$conv_file" 2>/dev/null || stat -f %m "$conv_file" 2>/dev/null)
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
  fi
elif [ -n "$last_write_file" ]; then
  # conversations/ dir exists but no log for today yet — check if reminder is overdue
  mod_epoch=$(stat -c %Y "$last_write_file" 2>/dev/null || stat -f %m "$last_write_file" 2>/dev/null)
  if [ -n "$mod_epoch" ]; then
    now_epoch=$(date +%s)
    diff_sec=$(( now_epoch - mod_epoch ))
    if [ "$diff_sec" -ge "$INTERVAL" ]; then
      echo "Conv: DUE"
    else
      echo "Conv: --"
    fi
  else
    echo "Conv: --"
  fi
else
  echo "Conv: --"
fi
