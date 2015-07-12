# File			~/.zsh/envvars.zsh
#
# Purpose		There are certain environment variables that are
#			available on any *NIX machine and that I like to set
#			accordingly, regardless of the actual OS or machine I
#			am working on. These are collected here (specific
#			settings are found in the other files accordingly)
#
# Author		Kannan Thambiah <pygospa@gmail.com>
# Lates Version		github.com/pygospa/dotfiles
# License		CC BY-SA 4.0, if applicable and compatible to software
#			license


# Set the shell variable
export SHELL='/bin/zsh'

###### PATH ######

# Preceed path with ~/bin - a folder I alway create and where I keep software
# and scripts that I developed myself and that should be in path (temporarily).
export PATH="$HOME/bin:$PATH"

###### EDITOR ######

if [[ -x `which -p vim` ]]; then
	export EDITOR=`which -p vim`
else
	export EDITOR=`which -p vi`
fi

# vi should point to vim
if [[ -x `which -p vim` ]]; then
	alias vi=`which vim`
fi

###### PAGER ######
# Less is more ;)
#
if [[ -x `which -p less` ]]; then
	export PAGER=`which -p less`
else
	export PAGER=`which -p more`
fi

###### RVM ######
# Ruby version manager settings

if [[ -d "$HOME/.rvm/bin" ]]; then
	export PATH="$PATH:$HOME/.rvm/bin"
	[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
fi
