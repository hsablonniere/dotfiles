#!/bin/bash

# Check if TTS is enabled
if [ ! -f ~/.local/state/speak-enabled ]; then
  exit 0
fi

# Kill any existing TTS process first
fish -c "speak-shutup" 2>/dev/null

# Read hook input from stdin
input=$(cat)

# Extract transcript path
transcript_path=$(echo "$input" | jq -r '.transcript_path')

# Stop hook can fire before the final assistant text is flushed to the
# transcript. Wait until the file has been idle for ~400ms (max ~3s).
prev_mtime=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  mtime=$(stat -c %Y "$transcript_path" 2>/dev/null || echo 0)
  now=$(date +%s)
  if [ "$mtime" = "$prev_mtime" ] && [ $((now - mtime)) -ge 1 ]; then
    break
  fi
  prev_mtime=$mtime
  sleep 0.2
done

# Get the last assistant text block (each block is its own JSONL entry,
# and the final entry is often a tool_use, so we pick the last text anywhere)
last_response=$(jq -rs '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text] | last' "$transcript_path" 2>/dev/null)

# Clean markdown and speak in background
if [ -n "$last_response" ]; then
  echo "$last_response" | sed -E '
    s/```[a-z]*//g;         # Remove code block markers
    s/```//g;               # Remove closing code blocks
    s/\*\*([^*]+)\*\*/\1/g; # Bold **text** -> text
    s/\*([^*]+)\*/\1/g;     # Italic *text* -> text
    s/^#+\s*//;             # Remove # headers
    s/^[-*]\s+//;           # Remove list markers
    s/^[0-9]+\.\s+//;       # Remove numbered lists
    s/`([^`]+)`/\1/g;       # Inline code `text` -> text
    s/\[([^\]]+)\]\([^)]+\)/\1/g;  # Links [text](url) -> text
    s/^>\s*//;              # Remove blockquotes
  ' | fish -c "speak" &
fi

exit 0
