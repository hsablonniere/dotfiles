function gcy --description "Git commit YOLO - generate commit message with Claude Code"
  echo "Running git diff --cached ..."
  set git_diff (git diff --cached)
  
  if test -z "$git_diff"
    echo "No staged changes to commit"
    return 1
  end
  
  set prompt "Generate a git commit message for the following changes. Return ONLY the commit message, nothing else - no explanations, no code blocks, no markdown formatting, no additional text.

CRITICAL RULES (MUST FOLLOW):
1. Format: type: lowercase description (e.g., 'feat: add new feature')
2. Subject line must be lowercase (sentence-case) after the colon
3. EVERY LINE must be 100 characters or LESS - COUNT THE CHARACTERS
4. Body lines that exceed 100 chars MUST be split into multiple shorter lines
5. Add blank line between subject and body

Example of correct format:
feat: add cli framework analysis

Add 12 detailed analysis documents covering popular CLI frameworks including argument
parsing approaches, flag conventions, and command structures across different languages.

Staged changes:

$git_diff"
  
  echo "Prompting Claude Code to create the commit message ..."
  set json_response (echo "$prompt" | claude --print --output-format json --model haiku)
  
  echo "  status: "(echo $json_response | jq -r '.subtype')
  echo "  duration: "(echo $json_response | jq -r '.duration_ms')"ms"
  echo "  tokens: "(echo $json_response | jq -r '.usage.input_tokens')"/"(echo $json_response | jq -r '.usage.output_tokens')
  set commit_message "$(echo $json_response | jq -r '.result')"
  
  if test $status -eq 0 -a -n "$commit_message"
    echo ''
    echo -e (set_color blue)"$commit_message"(set_color normal)
    echo ''
    git commit -m "$commit_message"
  else
    echo "Failed to generate commit message"
    return 1
  end
end
