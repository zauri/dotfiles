#!/bin/sh
#
# Creates a backup of existing dotfiles and symlinks these dotfiles to home
# Copyright (c) 2017, Kannan Thambiah <pygospa@gmail.com>
# Licensed under the MIT license
# Latest version: https://github.com/pygospa/dotfiles


# Dotfilepath and files to exclude
DFP=$( (cd -P $(dirname $0) && pwd) )

# If we are on a macOS powered machine, exclude typical Linux only software
if [[ `uname -s` == Darwin ]]; then
  EXCL=( asound backup config/user-dirs.dirs install.sh LICENSE mutt muttrc\
	  ousted README.md uninstall.sh xinitrc Xresources )
# If we are on a non macOS powered Unix machine, exclude only the repository stuff
else
  EXCL=( backup install.sh LICENSE ousted README.md uninstall.sh )
fi

# Create a backup directory inside the dotfile path
mkdir -p $DFP/backup

# Copy pre-existing dotfiles that would be overwritten into $DFP/backup
# then symlink all the dotfiles
for file in *; do
  if ! [[ ${EXCL[*]} =~ "$file" ]]; then
    if [[ -f ~/.$file || -d ~/.$file ]]; then
      echo ""
      echo "mv ~/.$file $DFP/backup/$file"
      mv ~/.$file $DFP/backup/$file
    fi
    echo "ln -sf $DFP/$file ~/.$file"
    ln -sf $DFP/$file ~/.$file
  fi
done

