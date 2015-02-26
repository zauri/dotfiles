# File			~/.zsh/darwin.zsh
#
# Purpose		This file contains system specific settings for Mac OS X 
#			operating systems
#
# Author		Kannan Thambiah <pygospa@gmail.com>
#
# Latest Version	https://github.com/pygospa/dotfiles
# License		CC BY-SA 4.0, if applicable and compatible to software
#			license

# Toggle Finder to show hidden files
alias show_hidden=' defaults write com.apple.finder AppleShowAllFiles -boolean true ; killall Finder'
alias hide_hidden=' defaults write com.apple.finder AppleShowAllFiles -boolean false ; killall Finder'

# Set easy to use commands for starting and stoping postgresql if
# available on system
if [[ -x `which pg_ctl` ]]; then
	alias pg-start=' pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start'
	alias pg-stop=' pg_ctl -D /usr/local/var/postgres stop -s -m fast'
fi

# Mac keeps path information in /etc/paths.d to automatically create path
# entries for new installed software. As we rewrite the path, we add them
# manually
for file in /etc/paths.d/*; do
	new="$(<$file)"
	export PATH="$PATH:$new"
done

# Use Firefox as default browser on OS X, if available
if [[ -x /Applications/Firefox.app/Contents/MacOS/firefox ]]; then
	export BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"
fi
