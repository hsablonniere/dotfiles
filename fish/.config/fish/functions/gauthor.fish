function gauthor --description "Amend commit to rewrite the author"
  git commit --amend --reset-author $argv
end