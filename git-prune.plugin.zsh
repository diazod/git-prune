gprune() {

  __print_remote_branches(){
    __remote_branches=$(git branch -r --merged | grep -v '/master$' | grep -v "/$branch_to_compare$")
    if [[ -n "$__remote_branches" ]]; then
      echo "This REMOTE branches will be removed:"
      echo "$__remote_branches"
    fi
  }

  __print_local_branches(){
    __local_branches=$(git branch --merged | grep -v 'master$' | grep -v "$current_branch$")
    if [[ -n "$__local_branches" ]]; then
      echo "This LOCAL branches will be removed:"
      echo "$__local_branches"
    fi
  }

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
    remote_branches=$(git branch -r --merged | grep -v '/master$' | grep -v "/$branch_to_compare$")
    local_branches=$(git branch --merged | grep -v 'master$' | grep -v "$branch_to_compare$")

    if [ -z "$remote_branches" ] && [ -z "$local_branches" ]; then
      echo "No existing branches have been merged into $current_branch."
    else
      echo "Current branch: $branch_to_compare"
      if $isRemote; then
        __print_remote_branches "$branch_to_compare"
      elif $isLocal; then
        __print_local_branches "$branch_to_compare"
      else
        __print_local_branches "$branch_to_compare"
        __print_remote_branches "$branch_to_compare"
      fi
    fi
  fi
}
