function cdup --description "change to the root of the current git repository"
  set -l cd (git rev-parse --show-cdup); and cd $cd
end
