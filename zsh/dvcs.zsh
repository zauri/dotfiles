# Purpose		I consider version control system to be one of the most
#			important tool invented - especially for computer
#			scientists and developers - and I use them every day,
#			so I am pretty particular about how they should work
#
#
# Based heavily on	よんちゅ <http://yonchu.hatenablog.com/>
# Author		Kannan Thambiah <pygospa@gmail.com>
# Latest Version	https://github.com/pygospa/dotfiles


#------------------------------------------------------------------------------
# Modules
#
autoload -Uz vcs_info; vcs_info;


#------------------------------------------------------------------------------
# Variables
#
if [[ -x `which -p git` ]]; then	# Always use less not vimpager for git
	export GIT_PAGER=`which -p less`
fi


#------------------------------------------------------------------------------
# Aliases
#
if [[ -x `which -p git` ]]; then	# I am a lazy bum
	alias g='git'
fi


#------------------------------------------------------------------------------
# Auxiliary functions
#
# This functions will open the remote remote repository of the current local
# directory in the browser if it is pointing to github or bitbucket.
#
# OS X has 'open' command for opening different files with the associated
# program directly from CLI.
# Linux does not have open but different other possiblities:
# - $BROWSER (if that variable is set)
# - /path/to/browser
# - xdg-open (if that is installed)

bitb() {
	bbpath="$(hg paths 2>/dev/null | grep 'bitbucket.org' | head -1)"
	bburl="$(echo $bbpath | sed -e's|.*\(bitbucket.org.*\)|http://\1|')"

	if [[ `uname -s` == Darwin ]]; then
		[[ -n $bburl ]] && open $bburl || echo "No BitBucket path found!"
	elif [[ `uname -s` == Linux ]]; then
		[[ -n $bburl ]] && $BROWSER $bburl || echo "No BitBucket path found!"
	fi
}

gith() {
	# Get remote origin
	ghpath="$(git config --get remote.origin.url)"

	# If remote origin does not contain 'github' try getting remote github
	if [[ -z "$(echo $ghpath | grep github)" ]]; then
		ghpath="$(git config --get remote.github.url)"
	fi

	# If remote origin was empty or neither remote origin nor remote github
	# contain a url with 'github' in it, there's probably no remote github
	# repository
	if [ -z $ghpath ] || [[ -z `echo $ghpath | grep github` ]]; then
		echo "No GitHub path found!"
		exit 1;
	fi

	# Else turn the ssh github link into an https github link
	ghpath="${ghpath/git\@github\.com\:/https://github.com/}"
	ghurl="${ghpath/\.git//tree/}"
	branch="$(git symbolic-ref HEAD 2>/dev/null)" || branch="(unnamed branch)"
	branch=${branch##refs/heads/}
	ghurl=$ghurl$branch

	# If on OS X just use the command 'open' to open it in standard browser
	if [[ `uname -s` == Darwin ]]; then
		open $ghurl
		# Else use the $BROWSER variable
	elif [[ `uname -s` == Linux ]]; then
		[[ -n $bburl ]] && $BROWSER $bburl || echo "No GitHub path found!"
	fi
}



###############################################################################
#                                                                             #
# This part is based on the excelent work of yonchu                           #
# <https://github.com/yonchu/zsh-vcs-prompt>                                  #
#                                                                             #
# It displays information about the repository in the current directory, such #
# as current branch, if the repository is ahead or behind it's remote how     #
# many files have been added/modified/removed/unknown, etc. using the command #
# prompt								      #
#                                                                             #
# I've incorporated the zshrc.sh, which is to be sourced into this file       #
# because to me this is a more clean way to organize my zsh configs and to    #
# find stuff when I want to change it                                         #
#                                                                             #
###############################################################################


## Logging level.
#   2:Output error to stderr.
#   1:Output error to the file (ZSH_VCS_PROMPT_DIR/zsh-vcs-prompt.log).
#   O/W:Suppress all errors.
ZSH_VCS_PROMPT_LOGGING_LEVEL=${ZSH_VCS_PROMPT_LOGGING_LEVEL:-'2'}

## Threshold micro sec to logging running time of zsh-vcs-prompt.
#  If not set, don't print and measure running time.
ZSH_VCS_PROMPT_LOGGING_THRESHOLD_MICRO_SEC=${ZSH_VCS_PROMPT_LOGGING_THRESHOLD_MICRO_SEC:-''}

## Enable caching, if set 'true'.
ZSH_VCS_PROMPT_ENABLE_CACHING=${ZSH_VCS_PROMPT_ENABLE_CACHING:-'false'}

## Use the python script (lib/gitstatus-fast.py) by default.
ZSH_VCS_PROMPT_USING_PYTHON=${ZSH_VCS_PROMPT_USING_PYTHON:-'true'}

## The branch name to print unmerged commits count.
#  If not set, don't print count.
ZSH_VCS_PROMPT_MERGE_BRANCH=${ZSH_VCS_PROMPT_MERGE_BRANCH:-'master'}
export ZSH_VCS_PROMPT_MERGE_BRANCH

## Symbols.
ZSH_VCS_PROMPT_AHEAD_SIGIL=${ZSH_VCS_PROMPT_AHEAD_SIGIL:-' ↑'}
ZSH_VCS_PROMPT_BEHIND_SIGIL=${ZSH_VCS_PROMPT_BEHIND_SIGIL:-' ↓'}
ZSH_VCS_PROMPT_STAGED_SIGIL=${ZSH_VCS_PROMPT_STAGED_SIGIL:-' ✚'}
ZSH_VCS_PROMPT_CONFLICTS_SIGIL=${ZSH_VCS_PROMPT_CONFLICTS_SIGIL:-' ✖'}
ZSH_VCS_PROMPT_UNSTAGED_SIGIL=${ZSH_VCS_PROMPT_UNSTAGED_SIGIL:-' ●'}
ZSH_VCS_PROMPT_UNTRACKED_SIGIL=${ZSH_VCS_PROMPT_UNTRACKED_SIGIL:-' …'}
ZSH_VCS_PROMPT_STASHED_SIGIL=${ZSH_VCS_PROMPT_STASHED_SIGIL:-' ⚑'}
ZSH_VCS_PROMPT_CLEAN_SIGIL=${ZSH_VCS_PROMPT_CLEAN_SIGIL:-' ✔'}

## Hide count if set 'true'.
ZSH_VCS_PROMPT_HIDE_COUNT=${ZSH_VCS_PROMPT_HIDE_COUNT:-'false'}

## Prompt formats.
#   #s : The VCS name (e.g. git svn hg).
#   #a : The action name.
#   #b : The current branch name.
#
#   #c : The ahead status.
#   #d : The behind status.
#
#   #e : The staged status.
#   #f : The conflicted status.
#   #g : The unstaged status.
#   #h : The untracked status.
#   #i : The stashed status.
#   #j : The clean status.

if [ -n "$BASH_VERSION" ]; then
    ### Bash
    ## Git.
    # No action.
    if [ -z "$ZSH_VCS_PROMPT_GIT_FORMATS" ]; then
        ZSH_VCS_PROMPT_GIT_FORMATS=' (#s)[#b#c#d|#e#f#g#h#i#j]'
    fi
    # No action using python.
    # Default is empty.
    if [ -z "$ZSH_VCS_PROMPT_GIT_FORMATS_USING_PYTHON" ]; then
        ZSH_VCS_PROMPT_GIT_FORMATS_USING_PYTHON=''
    fi
    # Action.
    if [ -z "$ZSH_VCS_PROMPT_GIT_ACTION_FORMATS" ]; then
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS=' (#s)[#b:#a#c#d|#e#f#g#h#i#j]'
    fi

    ## Other vcs.
    # No action.
    if [ -z "$ZSH_VCS_PROMPT_VCS_FORMATS" ]; then
        ZSH_VCS_PROMPT_VCS_FORMATS=' (#s)[#b]'
    fi
    # Action.
    if [ -z "$ZSH_VCS_PROMPT_VCS_ACTION_FORMATS" ]; then
        ZSH_VCS_PROMPT_VCS_ACTION_FORMATS=' (#s)[#b:#a]'
    fi

    ## Initialize.
    ## The exe directory.
    ZSH_VCS_PROMPT_DIR=$(cd "$(dirname "$BASH_SOURCE")" && pwd)
else
    ### ZSH
    ## Git.
    # No action.
    if [ -z "$ZSH_VCS_PROMPT_GIT_FORMATS" ]; then
        # Branch name
        ZSH_VCS_PROMPT_GIT_FORMATS="${MAGENTA}[${YELLOW}#b${NC}"
        # Ahead and Behind
        ZSH_VCS_PROMPT_GIT_FORMATS+="${GREEN}#c${RED}#d${MAGENTA} |${NC}"
        # Staged
        ZSH_VCS_PROMPT_GIT_FORMATS+="${GREEN}#e${NC}"
        # Conflicts
        ZSH_VCS_PROMPT_GIT_FORMATS+="${RED}#f${NC}"
        # Unstaged
        ZSH_VCS_PROMPT_GIT_FORMATS+="${ORANGE}#g${NC}"
        # Untracked
        ZSH_VCS_PROMPT_GIT_FORMATS+="${VIOLET}#h${NC}"
        # Stashed
        ZSH_VCS_PROMPT_GIT_FORMATS+="${CYAN}#i${NC}"
        # Clean
        ZSH_VCS_PROMPT_GIT_FORMATS+="${GREEN}#j${MAGENTA}]${NC}"
    fi
    # No action using python.
    if [ -z "$ZSH_VCS_PROMPT_GIT_FORMATS_USING_PYTHON" ]; then
        # Default is empty.
        ZSH_VCS_PROMPT_GIT_FORMATS_USING_PYTHON=''
    fi
    # Action.
    if [ -z "$ZSH_VCS_PROMPT_GIT_ACTION_FORMATS" ]; then
        # VCS name
        # Branch name
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${MAGENTA}[${YELLOW}#b${NC}"
        # Action
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${RED}#a${NC}"
        # Ahead and Behind
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${GREEN}#c${RED}#d${MAGENTA} |${NC}"
        # Staged
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${GREEN}#e${NC}"
        # Conflicts
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${RED}#f${NC}"
        # Unstaged
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${ORANGE}#g${NC}"
        # Untracked
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${VIOLET}#h${NC}"
        # Stashed
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${CYAN}#i${NC}"
        # Clean
        ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+="${GREEN}#j${MAGENTA}]${NC}"
    fi

    ## Other vcs.
    # No action.
    if [ -z "$ZSH_VCS_PROMPT_VCS_FORMATS" ]; then
        # VCS name
#        ZSH_VCS_PROMPT_VCS_FORMATS='(%{%B%F{yellow}%}#s%{%f%b%})'
        # Branch name
        ZSH_VCS_PROMPT_VCS_FORMATS+="${MAGENTA}[${YELLOW}#b${MAGENTA}]${NC}"
    fi
    # Action.
    if [ -z "$ZSH_VCS_PROMPT_VCS_ACTION_FORMATS" ]; then
        # VCS name
#        ZSH_VCS_PROMPT_VCS_ACTION_FORMATS='(%{%B%F{yellow}%}#s%{%f%b%})'
        # Branch name
        ZSH_VCS_PROMPT_VCS_ACTION_FORMATS+="${MAGENTA}[${YELLOW}#b"
        # Action
        ZSH_VCS_PROMPT_VCS_ACTION_FORMATS+="${MAGENTA}:${RED}#a${MAGENTA}]${NC}"
    fi

    ## Initialize.
    ## The exe directory.
    autoload -Uz +X is-at-least
    if is-at-least 4.3.10; then
        # "A" flag (turn a file name into an absolute path with symlink
        # resolution) is only available on 4.3.10 and latter
        ZSH_VCS_PROMPT_DIR="${${funcsourcetrace[1]%:*}:A:h}"
    else
        ZSH_VCS_PROMPT_DIR="${${funcsourcetrace[1]%:*}:h}"
    fi

    if [ -z "$colors" ]; then
        autoload -Uz +X colors
        colors
    fi

    ## Source "lib/vcsstatus*.sh".
    # Enable to use the function _zsh_vcs_prompt_vcs_detail_info
    source $ZSH_VCS_PROMPT_DIR/lib/vcsstatus.sh

    # Register precmd hook function
    autoload -Uz +X add-zsh-hook
    add-zsh-hook precmd _zsh_vcs_prompt_precmd_hook_func
fi

# Setup logging.
ZSH_VCS_PROMPT_LOG_FILE="$ZSH_VCS_PROMPT_DIR/zsh-vcs-prompt.log"
ZSH_VCS_PROMPT_ERROR_COUNT=0
function _zsh_vcs_prompt_check_log_file() {
    if [ "$ZSH_VCS_PROMPT_LOGGING_LEVEL" != '1' ]; then
        return
    fi
    # Create the log file.
    if [ ! -f "$ZSH_VCS_PROMPT_LOG_FILE" ]; then
        touch "$ZSH_VCS_PROMPT_LOG_FILE"
        ZSH_VCS_PROMPT_LOG_UPDATED_AT=
    fi
    # Get updated time of the log file.
    local dt
    case "${OSTYPE}" in
        freebsd*|darwin*)
            dt=($(/bin/ls -lT "$ZSH_VCS_PROMPT_LOG_FILE" | awk '{print $9$6$7$8}' | tr -d ':'))
            ;;
        linux*)
            dt=$(/bin/ls -l --time-style=long-iso "$ZSH_VCS_PROMPT_LOG_FILE" | awk '{print $6$7}' | sed 's/[:-]//g')
            ;;
    esac
    if [ -z "$ZSH_VCS_PROMPT_LOG_UPDATED_AT" ]; then
        ZSH_VCS_PROMPT_LOG_UPDATED_AT=$dt
        return 0
    fi
    # Check if error occurs.
    if [ "$ZSH_VCS_PROMPT_LOG_UPDATED_AT" != "$dt" ]; then
        ZSH_VCS_PROMPT_ERROR_COUNT=$((${ZSH_VCS_PROMPT_ERROR_COUNT} + 1))
        if [ "$ZSH_VCS_PROMPT_ERROR_COUNT" = '1' ]; then
            echo "[zsh-vcs-prompt] Error: please check the log file ($ZSH_VCS_PROMPT_LOG_FILE)" 1>&2
        fi
        ZSH_VCS_PROMPT_VCS_STATUS="!!${ZSH_VCS_PROMPT_VCS_STATUS}"
        ZSH_VCS_PROMPT_LOG_UPDATED_AT=$dt
    fi
}
_zsh_vcs_prompt_check_log_file

# vcs info status (cache data).
ZSH_VCS_PROMPT_VCS_STATUS=


## This function is called in PROMPT or RPROMPT.
function vcs_super_info() {
    # Update vcs status.
    if [ -n "$BASH_VERSION" -o "$ZSH_VCS_PROMPT_ENABLE_CACHING" != 'true' ]; then
        if [ "$ZSH_VCS_PROMPT_LOGGING_LEVEL" = '2' ]; then
            _zsh_vcs_prompt_update_vcs_status
        elif [ "$ZSH_VCS_PROMPT_LOGGING_LEVEL" = '1' ]; then
            _zsh_vcs_prompt_check_log_file
            _zsh_vcs_prompt_update_vcs_status 2>> "$ZSH_VCS_PROMPT_LOG_FILE"
            _zsh_vcs_prompt_check_log_file
        else
            _zsh_vcs_prompt_update_vcs_status 2>/dev/null
        fi
    fi
    echo "$ZSH_VCS_PROMPT_VCS_STATUS"
}

## The hook function to update vcs status.
function _zsh_vcs_prompt_precmd_hook_func() {
    # Update vcs status.
    if [ "$ZSH_VCS_PROMPT_ENABLE_CACHING" = 'true' ]; then
        if [ "$ZSH_VCS_PROMPT_LOGGING_LEVEL" = '2' ]; then
            _zsh_vcs_prompt_update_vcs_status
        elif [ "$ZSH_VCS_PROMPT_LOGGING_LEVEL" = '1' ]; then
            _zsh_vcs_prompt_check_log_file
            _zsh_vcs_prompt_update_vcs_status 2>> "$ZSH_VCS_PROMPT_LOG_FILE"
            _zsh_vcs_prompt_check_log_file
        else
            _zsh_vcs_prompt_update_vcs_status 2>/dev/null
        fi
    fi
    return 0
}

function _zsh_vcs_prompt_update_vcs_status() {
    if [ -n "$ZSH_VCS_PROMPT_LOGGING_THRESHOLD_MICRO_SEC" ]; then
        local start=$("$ZSH_VCS_PROMPT_DIR/lib/curret_time.pl")
    fi

    # Parse raw data.
    local raw_data
    raw_data=$(vcs_super_info_raw_data)
    if [ -z "$raw_data" ]; then
        ZSH_VCS_PROMPT_VCS_STATUS=
        return
    fi

    local -a vcs_status
    if [ -n "$BASH_VERSION" ]; then
        local IFS_SAVE
        IFS_SAVE=$IFS
        IFS=$'\n'
        vcs_status=($raw_data)
        IFS=$IFS_SAVE
        vcs_status=("" "${vcs_status[@]}")
    else
        vcs_status=("${(f)raw_data}")
    fi

    local using_python=${vcs_status[1]}
    local vcs_name=${vcs_status[2]}
    local action=${vcs_status[3]}
    local branch=${vcs_status[4]}
    local ahead=${vcs_status[5]}
    local behind=${vcs_status[6]}
    local staged=${vcs_status[7]}
    local conflicts=${vcs_status[8]}
    local unstaged=${vcs_status[9]}
    local untracked=${vcs_status[10]}
    local stashed=${vcs_status[11]}
    local clean=${vcs_status[12]}
    local unmerged=${vcs_status[13]}

    # Select formats.
    local used_formats
    if [ "$vcs_name" = 'git' -o "$vcs_name" = 'hg' ]; then
        used_formats=$ZSH_VCS_PROMPT_GIT_ACTION_FORMATS
        # Check action.
        if [ -z "$action" -o "$action" = '0' ]; then
            action=
            if [ "$using_python" = '1' -a -n "$ZSH_VCS_PROMPT_GIT_FORMATS_USING_PYTHON" ]; then
                used_formats=$ZSH_VCS_PROMPT_GIT_FORMATS_USING_PYTHON
            else
                used_formats=$ZSH_VCS_PROMPT_GIT_FORMATS
            fi
        fi
    else
        used_formats=$ZSH_VCS_PROMPT_VCS_ACTION_FORMATS
        # Check action.
        if [ -z "$action" -o "$action" = '0' ]; then
            action=
            used_formats=$ZSH_VCS_PROMPT_VCS_FORMATS
        fi
    fi

    # Escape slash '/'.
    branch=$(echo "$branch" | sed 's%/%\\/%g')
    # Set unmerged count.
    if [ -n "$unmerged" -a "$unmerged" != '0' ]; then
        branch="${branch}(${unmerged})"
    fi

    # Set sigil.
    ahead=$(_zsh_vcs_prompt_set_sigil "$ahead" "$ZSH_VCS_PROMPT_AHEAD_SIGIL")
    behind=$(_zsh_vcs_prompt_set_sigil "$behind" "$ZSH_VCS_PROMPT_BEHIND_SIGIL")
    staged=$(_zsh_vcs_prompt_set_sigil "$staged" "$ZSH_VCS_PROMPT_STAGED_SIGIL")
    conflicts=$(_zsh_vcs_prompt_set_sigil "$conflicts" "$ZSH_VCS_PROMPT_CONFLICTS_SIGIL")
    unstaged=$(_zsh_vcs_prompt_set_sigil "$unstaged" "$ZSH_VCS_PROMPT_UNSTAGED_SIGIL")
    untracked=$(_zsh_vcs_prompt_set_sigil "$untracked" "$ZSH_VCS_PROMPT_UNTRACKED_SIGIL")
    stashed=$(_zsh_vcs_prompt_set_sigil "$stashed" "$ZSH_VCS_PROMPT_STASHED_SIGIL")
    if [ "$clean" = '1' ]; then
        clean=$ZSH_VCS_PROMPT_CLEAN_SIGIL
    elif [ "$clean" = '0' ]; then
        clean=
    fi

    # Compose prompt status.
    local prompt_info
    prompt_info=$(echo "$used_formats" | sed \
        -e "s/#s/$vcs_name/" \
        -e "s/#a/$action/" \
        -e "s/#b/$branch/" \
        -e "s/#c/$ahead/" \
        -e "s/#d/$behind/" \
        -e "s/#e/$staged/" \
        -e "s/#f/$conflicts/" \
        -e "s/#g/$unstaged/" \
        -e "s/#h/$untracked/" \
        -e "s/#i/$stashed/" \
        -e "s/#j/$clean/")

    ZSH_VCS_PROMPT_VCS_STATUS=$prompt_info

    # Check running time.
    if [ -n "$ZSH_VCS_PROMPT_LOGGING_THRESHOLD_MICRO_SEC" ]; then
        local end=$("$ZSH_VCS_PROMPT_DIR/lib/curret_time.pl")
        local elapse=$(($end - $start))
        if [ "$elapse" -gt "$ZSH_VCS_PROMPT_LOGGING_THRESHOLD_MICRO_SEC" ]; then
            elapse=$(_zsh_vcs_prompt_microsec2datetime "$elapse")
            echo "[zsh-vcs-prompt][$(date +'%D %H:%M:%S')] Running time: $elapse ($(pwd))" 1>&2
        fi
    fi
}

function _zsh_vcs_prompt_microsec2datetime() {
    local mc=$(($elapse % 1000000))
    local elapse_sec=$(($elapse / 1000000))
    local hh=$(($elapse_sec / 3600))
    local ss=$(($elapse_sec % 3600))
    local mm=$(($elapse_sec / 60))
    local ss=$(($elapse_sec % 60))
    echo "$hh:$mm:$ss.$mc"
}

# Helper function to set sigil.
#  $1: Count or flag.
#  $2: Sigil.
function _zsh_vcs_prompt_set_sigil() {
    if [ -z "$1" -o "$1" = '0' ]; then
        return
    fi
    if [ "$ZSH_VCS_PROMPT_HIDE_COUNT" = 'true' ]; then
        echo "$2"
        return
    fi
    echo "$2$1"
}


## Get the raw data of vcs info.
#
# Output:
#   using_python : Using python flag. (Using python : 1, Not using python : 0)
#   vcs_name  : The vcs name string.
#   action    : Action name string. (No action : 0)
#   branch    : Branch name string.
#   ahead     : Ahead count. (No ahead : 0)
#   behind    : Behind count. (No behind : 0)
#   staged    : Staged count. (No staged : 0)
#   conflicts : Conflicts count. (No conflicts : 0)
#   unstaged  : Unstaged count. (No unstaged : 0)
#   untracked : Untracked count.(No untracked : 0)
#   stashed   : Stashed count.(No stashed : 0)
#   clean     : Clean flag. (Clean is 1, Not clean is 0, Unknown is ?)
#   unmerged  : Unmerged commits count. (No unmerged commits : 0)
#
function vcs_super_info_raw_data() {
    local using_python=0

    # Use python
    if [ "$ZSH_VCS_PROMPT_USING_PYTHON" = 'true' ] \
        && type python > /dev/null 2>&1 \
        && type git > /dev/null 2>&1 \
        && [ "$(command git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then

        # The python script to get git status.
        local cmd_gitstatus="${ZSH_VCS_PROMPT_DIR}/lib/gitstatus-fast.py"
        # Get vcs status.
        local git_status
        git_status=$(python -E "$cmd_gitstatus")
        if [ -n "$git_status" ];then
            using_python=1
            local vcs_name='git'
            local vcs_action=0
            # Output result.
            echo "$using_python"
            echo "$vcs_name"
            echo "$vcs_action"
            echo "$git_status"
            return 0
        fi
    fi

    # When don't use python or error occurs in the python scritp.
    local vcs_status

    if (( $+functions[_zsh_vcs_prompt_vcs_detail_info] )) ; then
        ## zsh
        # Run the sourced function.
        vcs_status="$(_zsh_vcs_prompt_vcs_detail_info)"
    else
        ## bash
        # Run the external script
        local cmd_run_vcsstatus="${ZSH_VCS_PROMPT_DIR}/lib/run-vcsstatus.sh"
        vcs_status=$("$cmd_run_vcsstatus")
    fi

    if [ -z "$vcs_status" ]; then
        return 0
    fi

    # Output result.
    echo "$using_python"
    echo "$vcs_status"

    return 0
}

