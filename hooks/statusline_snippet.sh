#!/usr/bin/env bash
# Claude Conversations — Status line snippet
# Add this to your existing statusline command script (~/.claude/statusline-command.sh)
# Shows when the conversation log was last written: "Conv: 2m ago" or "Conv: --"

today=$(date +%Y-%m-%d)
conv_file=$(find . -path "*/conversations/${today}.md" -type f 2>/dev/null | head -1)
if [ -n "$conv_file" ]; then
  mod_epoch=$(stat -c %Y "$conv_file" 2>/dev/null || stat -f %m "$conv_file" 2>/dev/null)
  if [ -n "$mod_epoch" ]; then
    now_epoch=$(date +%s)
    diff_sec=$(( now_epoch - mod_epoch ))
    if [ "$diff_sec" -lt 60 ]; then
      echo "Conv: ${diff_sec}s ago"
    elif [ "$diff_sec" -lt 3600 ]; then
      echo "Conv: $(( diff_sec / 60 ))m ago"
    else
      echo "Conv: $(( diff_sec / 3600 ))h ago"
    fi
  fi
else
  echo "Conv: --"
fi
