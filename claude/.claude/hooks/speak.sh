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

# Get the last assistant text response (full text, not just first line)
last_response=$(tac "$transcript_path" | jq -rs '[.[] | select(.type=="assistant")] | .[0].message.content[]? | select(.type=="text") | .text' 2>/dev/null)

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
