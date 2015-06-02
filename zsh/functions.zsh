# File			~/.zsh/functions.zsh
#
# Purpose		Contains self-defined functions
#
# Author		Kannan Thambiah <pygospa@gmail.com>
# Lates Version		github.com/pygospa/dotfiles


# Determine which prompt symbol to use (according to what kind of directory one
# is in)

prompt_char() {
    git branch >/dev/null 2>/dev/null && echo '±' && return
    hg root >/dev/null 2>/dev/null && echo '☿' && return
    svn info >/dev/null 2>/dev/null && echo '○' && return
    echo '$'
}

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

# Most awesome function to have in your zshrc!
# Thx to anon (http://stackoverflow.com/questions/171563/whats-in-your-zshrc/904023#904023)
function mandelbrot {
   local lines columns colour a b p q i pnew
   ((columns=COLUMNS-1, lines=LINES-1, colour=0))
   for ((b=-1.5; b<=1.5; b+=3.0/lines)) do
       for ((a=-2.0; a<=1; a+=3.0/columns)) do
           for ((p=0.0, q=0.0, i=0; p*p+q*q < 4 && i < 32; i++)) do
               ((pnew=p*p-q*q+a, q=2*p*q+b, p=pnew))
           done
           ((colour=(i/4)%8))
            echo -n "\\e[4${colour}m "
        done
        echo
    done
}

# Create small urls via http://goo.gle using curl(1).
# API reference: https://code.google.com/apis/urlshortener
function zu() {
    emulate -L zsh
    setopt extended_glob

    if [[ -z $1 ]]; then
        print "USAGE: zurl <URL>"
        return 1
    fi

    local PN url prog api json contenttype item
    local -a data
    PN=$0
    url=$1

    # Prepend 'http://' to given URL where necessary for later output.
    if [[ ${url} != http(s|)://* ]]; then
        url='http://'${url}
    fi

    if [[ -x `which curl` ]]; then
        prog=curl
    else
        print "curl is not available, but mandatory for ${PN}. Aborting."
        return 1
    fi
    api='https://www.googleapis.com/urlshortener/v1/url'
    contenttype="Content-Type: application/json"
    json="{\"longUrl\": \"${url}\"}"
    data=(${(f)"$($prog --silent -H ${contenttype} -d ${json} $api)"})
    # Parse the response
    for item in "${data[@]}"; do
        case "$item" in
            ' '#'"id":'*)
                item=${item#*: \"}
                item=${item%\",*}
                printf '%s\n' "$item"
                return 0
                ;;
        esac
    done
    return 1
}

# Create Directoy and \kbd{cd} to it
mkcd() {
    if (( ARGC != 1 )); then
        printf 'usage: mkcd <new-directory>\n'
        return 1;
    fi
    if [[ ! -d "$1" ]]; then
        command mkdir -p "$1"
    else
        printf '`%s'\'' already exists: cd-ing.\n' "$1"
    fi
    builtin cd "$1"
}

# grep for running process, like: 'any vim'
any() {
    emulate -L zsh
    unsetopt KSH_ARRAYS
    if [[ -z "$1" ]] ; then
        echo "any - grep for process(es) by keyword" >&2
        echo "Usage: any <keyword>" >&2 ; return 1
    else
        ps xauwww | grep -i "${grep_options[@]}" "[${1[1]}]${1[2,-1]}"
    fi
}


# cd to directory and list files
cdls() {
    emulate -L zsh
    cd $1 && ls -a
}

# List files which have been accessed within the last {\it n} days, {\it n} defaults to 1
accessed() {
    emulate -L zsh
    print -l -- *(a-${1:-1})
}

# List files which have been changed within the last {\it n} days, {\it n} defaults to 1
changed() {
    emulate -L zsh
    print -l -- *(c-${1:-1})
}

# List files which have been modified within the last {\it n} days, {\it n} defaults to 1
modified() {
    emulate -L zsh
    print -l -- *(m-${1:-1})
}

# If there's an env.sh file in the directory you're changing into, it gets
# sourced. Ideal if you e.g. work with different instances of ROCK
# (http://rock-robotics.org/stable/)
function autosource {
	if [[ -s "$PWD/env.sh" ]] && [[ -r "$PWD/env.sh" ]]; then
		source "$PWD/env.sh"
		echo -e "\033[0;31m ! Autosourced $PWD/env.sh ! \033[0m"
	fi
}
chpwd_functions=( "${chpwd_functions[@]}" autosource )
