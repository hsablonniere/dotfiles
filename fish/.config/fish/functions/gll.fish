function gll --description "Git log from branch to root commit"
  set -l target_branch
  
  if test (count $argv) -eq 0
    set target_branch (git branch --show-current)
  else
    set target_branch $argv[1]
  end
  
  git log --color --graph --pretty=format:'%C(bold blue)%h%Creset %C(bold yellow)%cs%Creset %C(bold green)%<(10,trunc)%an%Creset %s%C(yellow)%d%Creset' --abbrev-commit $target_branch
end

complete -c gll -f -a '(git branch --format="%(refname:short)" 2>/dev/null)'
