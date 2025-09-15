function cdup --description "change to the root of the current git repository"
  cd (git rev-parse --show-cdup)
end
