gprune() {
  # Configuration file path
  __gprune_config_file="$HOME/.gprune_config"

  # Load protected branches configuration
  __load_protected_branches() {
    if [[ -f "$__gprune_config_file" ]]; then
      source "$__gprune_config_file"
    fi

    # Set default protected branches if config doesn't exist or is empty
    if [[ -z "$GPRUNE_PROTECTED_BRANCHES" ]]; then
      GPRUNE_PROTECTED_BRANCHES=("master" "release")
    fi
  }

  # Build grep patterns for protected branches
  __build_grep_patterns() {
    local patterns=()
    for branch in "${GPRUNE_PROTECTED_BRANCHES[@]}"; do
      patterns+=("-e" "/$branch\$")
      patterns+=("-e" "/$branch")
    done
    echo "${patterns[@]}"
  }

  __prune_remote_branches() {
    local grep_patterns=($(echo $(__build_grep_patterns)))
    git push origin `git branch -r --merged "$1" | grep -v "HEAD" | grep -v "${grep_patterns[@]}" | grep -v "/$1$" | sed 's/origin\//:/g' | tr -d '\n'`
  }

  __prune_local_branches() {
    local grep_patterns=($(echo $(__build_grep_patterns | sed 's|/||g')))
    git branch -d `git branch --merged "$1" | grep -v "${grep_patterns[@]}" | grep -v "$1$" | sed 's/origin\///g' | tr -d '\n'`
  }

  __print_remote_branches() {
    local grep_patterns=($(echo $(__build_grep_patterns)))
    __remote_branches=$(git branch -r --merged "$1" | grep -v "HEAD" | grep -v "${grep_patterns[@]}" | grep -v "/$1$")

    if [[ -n "$__remote_branches" ]]; then
      echo "These REMOTE branches will be removed:"
      echo "$__remote_branches"
    fi
  }

  __print_local_branches() {
    local grep_patterns=($(echo $(__build_grep_patterns | sed 's|/||g')))
    __local_branches=$(git branch --merged "$1" | grep -v "${grep_patterns[@]}" | grep -v "$1$")
    if [[ -n "$__local_branches" ]]; then
      echo "These LOCAL branches will be removed:"
      echo "$__local_branches"
    fi
  }

  usage="usage:
gprune [ -r | --remote | -b | --both | -s | --setup ] <branch-name>

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
Interactive setup to configure protected branches that won't be deleted.
Use: gprune --setup

-c, --config
Show current protected branches configuration.
Use: gprune --config
"

  # Setup and configuration functions
  __setup_protected_branches() {
    echo "Current protected branches configuration:"
    __load_protected_branches
    echo "Protected branches: ${GPRUNE_PROTECTED_BRANCHES[*]}"
    echo ""
    echo "Enter new protected branches (space-separated, or press Enter to keep current):"
    read -r new_branches

    if [[ -n "$new_branches" ]]; then
      echo "GPRUNE_PROTECTED_BRANCHES=($new_branches)" > "$__gprune_config_file"
      echo "Configuration saved to $__gprune_config_file"
      echo "New protected branches: $new_branches"
    else
      echo "Configuration unchanged."
    fi
  }

  __show_config() {
    __load_protected_branches
    echo "Protected branches configuration:"
    echo "Config file: $__gprune_config_file"
    echo "Protected branches: ${GPRUNE_PROTECTED_BRANCHES[*]}"
  }

  isHelp=false
  isRemote=false
  isLocal=false
  isVersion=false
  isSetup=false
  isConfig=false
  remote_branches=""
  local_branches=""

  # Load configuration at start
  __load_protected_branches

  branch_to_compare=$1

  case $branch_to_compare in
    ("-h" | "--help") isHelp=true;;
    ("-v" | "--version") isVersion=true;;
    ("-s" | "--setup") isSetup=true;;
    ("-c" | "--config") isConfig=true;;
    ("-r" | "--remote") isRemote=true;;
    ("-b" | "--both")
      isRemote=true
      isLocal=true
    ;;
    (*) isLocal=true;;
  esac

  if $isVersion; then
    echo "v1.1.0"
    return
  fi

  if $isHelp; then
    echo "$usage"
    return
  fi

  if $isSetup; then
    __setup_protected_branches
    return
  fi

  if $isConfig; then
    __show_config
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
      local grep_patterns=($(echo $(__build_grep_patterns)))
      remote_branches=$(git branch -r --merged "$branch_to_compare" | grep -v "HEAD" | grep -v "${grep_patterns[@]}" | grep -v "/$branch_to_compare$")
    fi

    if ($isLocal) then
      local grep_patterns=($(echo $(__build_grep_patterns | sed 's|/||g')))
      local_branches=$(git branch --merged "$branch_to_compare" | grep -v "${grep_patterns[@]}" | grep -v "$branch_to_compare$")
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
