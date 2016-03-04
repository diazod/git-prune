gprune() {
  __print_remote_branches() {
    echo "Fetching branches..."
    git fetch --prune
    __remote_branches=$(git branch -r --merged| grep -v '/release'| grep -v "HEAD" | grep -v '/master$' | grep -v "/$1$")
    if [[ -n "$__remote_branches" ]]; then
      echo "These REMOTE branches will be removed:"
      echo "$__remote_branches"
    fi
  }

  __print_local_branches() {
    __local_branches=$(git branch --merged | grep -v 'release' | grep -v 'master$' | grep -v "$1$")
    if [[ -n "$__local_branches" ]]; then
      echo "These LOCAL branches will be removed:"
      echo "$__local_branches"
    fi
  }

  __prune_remote_branches() {
    git push origin `git branch -r --merged | grep -v '/master$' | grep -v '/release'| grep -v "HEAD" | grep -v "/$1$" | grep -v "develop" |grep -v "staging"|sed 's/origin\//:/g' | tr -d '\n'`
  }

  __prune_local_branches() {
    git branch -d `git branch --merged | grep -v 'master$'  | grep -v 'release' |grep -v "develop" |grep -v "staging"| grep -v "$1$" | sed 's/origin\///g' | tr -d '\n'`
  }

  isRemote=false
  isLocal=false
  custom_command=''

  branch_to_compare=$1
  case $branch_to_compare in
    ("-r" | "--remote") isRemote=true;;
    ("-l" | "--local") isLocal=true;;
    (*)
      isRemote=false
      isLocal=false
    ;;
  esac

  if $isRemote || $isLocal; then
    custom_command=$1
    branch_to_compare=$2
  fi
  if [[ -z "$branch_to_compare" ]]; then
      branch_to_compare=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  fi

  if [[ -z "$branch_to_compare" ]]; then
    echo "The branch name is invalid"
  else
    remote_branches=$(git branch -r --merged| grep -v '/release'| grep -v "HEAD" | grep -v '/master$' | grep -v "/$branch_to_compare$")
    local_branches=$(git branch --merged | grep -v 'release' | grep -v 'master$' | grep -v "$branch_to_compare$")

    echo "Current branch: $branch_to_compare"
    if ([ -z "$remote_branches" ] && $isRemote ]) || ([ -z "$local_branches" ] && $isLocal ]) || ([ -z "$remote_branches" ] && [ -z "$local_branches" ]); then
      echo "There aren't any new merged branches into $branch_to_compare"
    else
      if $isRemote; then
        __print_remote_branches "$branch_to_compare"
      elif $isLocal; then
        __print_local_branches "$branch_to_compare"
      else
        __print_local_branches "$branch_to_compare"
        __print_remote_branches "$branch_to_compare"
      fi
      echo "Are you sure you want to delete these branches?"
      select yn in "Yes" "No"; do
          case $yn in
              Yes )
                echo "Deleting branches..."
                if $isRemote; then
                  __prune_remote_branches "$branch_to_compare"
                elif $isLocal; then
                  __prune_local_branches "$branch_to_compare"
                else
                  __prune_remote_branches "$branch_to_compare"
                  __prune_local_branches "$branch_to_compare"
                fi
              break;;
              No ) echo "No changes done";;
          esac
      done
    fi
  fi
}
