#!/bin/bash

# Script must be run as root to install packages
if [ "$EUID" -ne 0 ]
  then echo "Root privileges are required to install packages. Please run as root."
  exit
fi

# 1. Ignore case completion

# If ~/.inputrc doesn't exist yet, first include the original /etc/inputrc so it won't get overriden
if [ ! -a ~/.inputrc ]; then echo '$include /etc/inputrc' > ~/.inputrc; fi

# Add shell-option to ~/.inputrc to enable case-insensitive tab completion
echo 'set completion-ignore-case On' >> ~/.inputrc


#
# Install packages
#

