function gb --description "List branches or switch to branch (create if needed)"
  if test (count $argv) -eq 0
    begin
      echo "Branch"(printf '\x1e')"Commit"(printf '\x1e')"Message"(printf '\x1e')"Date"(printf '\x1e')"Time"(printf '\x1e')"Author"
      git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)|%(objectname:short)|%(subject)|%(committerdate:iso)|%(authorname)' | awk -v sep=(printf '\x1e') -F '|' '{
        split($4, dt, " ")
        date=dt[1]; time=dt[2]
        print $1 sep $2 sep $3 sep date sep time sep $5
      }'
    end | tw --separator (printf '\x1e') --quote-char (printf '\x1f')
  else
    git switch -c $argv 2>/dev/null; or git switch $argv
  end
end

function __gb_format_branches
  git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)|%(objectname:short)|%(subject)|%(committerdate:short)' 2>/dev/null | awk -F '|' '{print $1 "\t" $3 " | " $4 " | " $2}'
end

complete -c gb -f -k -a '(__gb_format_branches)'
