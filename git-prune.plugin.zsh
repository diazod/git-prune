gprune() {
  __prune_remote_branches() {
    git push origin `git branch -r --merged "$1" | grep -v "HEAD" | grep -v '/release' | grep -v '/master$' | grep -v "/staging" | grep -v "/develop$" | grep -v "/$1$" | sed 's/origin\//:/g' | tr -d '\n'`
  }

  __prune_local_branches() {
    git branch -d `git branch --merged "$1" | grep -v 'master$'  | grep -v 'release' | grep -v "develop$" | grep -v "staging" | grep -v "$1$" | sed 's/origin\///g' | tr -d '\n'`
  }

  __print_remote_branches() {
    __remote_branches=$(git branch -r --merged "$1" | grep -v "HEAD" | grep -v '/release' | grep -v '/master$' | grep -v "/staging" | grep -v "/develop$" | grep -v "/$1$")

    if [[ -n "$__remote_branches" ]]; then
      echo "These REMOTE branches will be removed:"
      echo "$__remote_branches"
    fi
  }

  __print_local_branches() {
    __local_branches=$(git branch --merged "$1" | grep -v 'master$'  | grep -v 'release' | grep -v "develop$" | grep -v "staging" | grep -v "$1$")
    if [[ -n "$__local_branches" ]]; then
      echo "These LOCAL branches will be removed:"
      echo "$__local_branches"
    fi
  }

  usage="usage:
gprune [ -r | --remote | -b | --both ] <branch-name>

options:
<branch-name>
This is the base branch which the plugin will use to compare the merged branches, for example:
given the branches \"master\", \"develop\" and \"example\", you are currently in the branch
\"develop\" and the branch named \"example\" is already merged into it but not into \"master\"
the plugin will delete the branch \"example\".

-r, --remote
Defines that only remote branches which were merged should be removed from the repository.

-b, --both
Defines that both remote and local branches which were merged
should be removed from the repository.

-s, --setup
Defines the protected branches, which won't be deleted in the process.
"

  isHelp=false
  isRemote=false
  isLocal=false
  isVersion=false
  remote_branches=""
  local_branches=""

  branch_to_compare=$1

  case $branch_to_compare in
    ("-h" | "--help") isHelp=true;;
    ("-v" | "--version") isVersion=true;;
    ("-r" | "--remote") isRemote=true;;
    ("-b" | "--both")
      isRemote=true
      isLocal=true
    ;;
    (*) isLocal=true;;
  esac

  if $isVersion; then
    echo "v1.0.2"
    return
  fi

  if $isHelp; then
    echo "$usage"
    return
  fi

  if $isRemote; then
    branch_to_compare=$2
  fi

  if [[ -z "$branch_to_compare" ]]; then
    branch_to_compare=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  fi

  if [[ -z "$branch_to_compare" ]]; then
    echo "The branch name is invalid"
  else
    if ([ $isRemote = true ]) then
      echo "Fetching remote branches..."
      git fetch --prune
      remote_branches=$(git branch -r --merged "$branch_to_compare" | grep -v "HEAD" | grep -v '/release' | grep -v '/master$' | grep -v "/staging" | grep -v "/develop$" | grep -v "/$branch_to_compare$")
    fi

    if ($isLocal) then
      local_branches=$(git branch --merged "$branch_to_compare" | grep -v 'master$'  | grep -v 'release' | grep -v "develop$" | grep -v "staging" | grep -v "$branch_to_compare$")
    fi

    echo "Current branch: $branch_to_compare"

    if ([ -z "$remote_branches" ] && [ -z "$local_branches" ]) then
      echo "There aren't any new merged branches into $branch_to_compare"
    else
      if $isLocal; then
        __print_local_branches "$branch_to_compare"
      fi
      if $isRemote; then
        __print_remote_branches "$branch_to_compare"
      fi

      declare choice=true

      while $choice; do
        read "yn?Are you sure you want to delete these branches? (Y/n): "

        yn=${yn:-enter}

        if [ $yn = "Y" -o $yn = "y" -o $yn = 'enter' ]; then
          echo "Deleting branches..."

          if ($isRemote) then
            __prune_remote_branches "$branch_to_compare"
          fi
          if ($isLocal) then
            __prune_local_branches "$branch_to_compare"
          fi

          choice=false
        elif [ $yn = "N" -o $yn = "n" ]; then
          choice=false
        fi
      done
    fi
  fi
}
