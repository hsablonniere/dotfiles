function gb --description "List branches or switch to branch (create if needed)"
  if test (count $argv) -eq 0
    git branch
  else
    git switch -c $argv 2>/dev/null; or git switch $argv
  end
end

complete -c gb -f -k -a '(git for-each-ref --sort=-committerdate refs/heads --format="%(refname:short)" 2>/dev/null)'
