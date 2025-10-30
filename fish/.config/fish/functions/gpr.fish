function gpr --description "Create GitHub PR with AI-generated title and body"
  # Parse arguments
  set no_edit false
  for arg in $argv
    switch $arg
      case --no-edit -n
        set no_edit true
      case '*'
        echo "Unknown argument: $arg"
        return 1
    end
  end

  # Check if there's already a PR for this branch
  set current_branch (git branch --show-current)
  echo "Checking for existing PR for branch '$current_branch'..."
  
  set existing_pr (gh pr list --head $current_branch --json number --jq '.[0].number' 2>/dev/null)
  
  if test -n "$existing_pr"
    echo "Error: PR #$existing_pr already exists for branch '$current_branch'"
    return 1
  end
  
  # Get main branch name
  set main_branch (gbm | head -1)
  if test -z "$main_branch"
    echo "Error: Could not determine main branch (main/master)"
    return 1
  end
  
  echo "Getting commits and changes between '$current_branch' and '$main_branch'..."
  set commits (git log --oneline $main_branch..$current_branch)
  #set changes (git diff $main_branch..$current_branch)
  
  if test -z "$commits"
    echo "No commits found between '$current_branch' and '$main_branch'"
    return 1
  end
  
  set prompt "Generate a GitHub Pull Request title and body based on the following commits.

Requirements:
- Return ONLY title and body, don't including any comments or details of what you do
- Title should be concise and descriptive (under 72 characters)
- Use conventional commit style for the title if appropriate
- body should summarize the changes and include any relevant details
- body can use markdown formatting
- No markdown to emphasize title and body, put the title on the first line and then the body

Commits:
$commits"

  echo "Prompting Claude Code to create PR title and body..."
  set json_response (claude --print --output-format json --model haiku "$prompt")

  echo "  status: "(echo $json_response | jq -r '.subtype')
  echo "  duration: "(echo $json_response | jq -r '.duration_ms')"ms"
  echo "  tokens: "(echo $json_response | jq -r '.usage.input_tokens')"/"(echo $json_response | jq -r '.usage.output_tokens')

  set ai_response "$(echo $json_response | jq -r '.result')"

  if test "$no_edit" = true
    # Direct mode - no editing
    set pr_title (echo "$ai_response" | head -n 1 | string trim)
    set pr_body "$(echo "$ai_response" | tail -n +2)"

    echo ''
    echo "Title: $pr_title"
    echo ''
    echo "Body:"
    echo -e "$pr_body"
    echo ''

    if test -n "$pr_title"
      # Create a temporary body file for reliable content handling
      set body_file (mktemp -t "gpr-body.XXXXXX")
      echo "$pr_body" > "$body_file"

      gh pr create --title "$pr_title" --body-file "$body_file"
      rm -f "$body_file"
    else
      echo "Failed to generate PR title"
      return 1
    end
  else
    # Interactive mode - open vim for editing
    set tmp_file (mktemp -t "gpr-edit.XXXXXX")

    # Write AI response to temp file
    echo "$ai_response" > "$tmp_file"

    echo "Opening editor for PR content review..."
    vim "$tmp_file"

    if test $status -eq 0
      # Parse edited content
      set pr_title (cat "$tmp_file" | head -n 1 | string trim)
      set pr_body "$(cat "$tmp_file" | tail -n +2)"

      if test -n "$pr_title"
        # Create a separate body file for gh
        set body_file (mktemp -t "gpr-body.XXXXXX")
        echo "$pr_body" > "$body_file"

        gh pr create --title "$pr_title" --body-file "$body_file"
        rm -f "$body_file"
      else
        echo "No title found - PR creation cancelled"
        rm -f "$tmp_file"
        return 1
      end
    else
      echo "Editor cancelled - PR creation aborted"
      rm -f "$tmp_file"
      return 1
    end

    # Cleanup
    rm -f "$tmp_file"
  end
end
