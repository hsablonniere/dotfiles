function gbd --description "Delete local branch and local tracking reference"
  if test (count $argv) -eq 0
    echo "Usage: gbd <branch-name>"
    return 1
  end
  
  set -l branch $argv[1]
  
  # Delete local branch
  git branch -d $branch 2>/dev/null; or git branch -D $branch
  
  # Delete local tracking reference if it exists
  git branch -dr origin/$branch 2>/dev/null
end

complete -c gbd -f -k -a '(git for-each-ref --sort=-committerdate refs/heads --format="%(refname:short)" 2>/dev/null | grep -v "^$(git branch --show-current 2>/dev/null)$")'