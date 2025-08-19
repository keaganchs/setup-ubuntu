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

apt install git pass python-is-python3 
snap install discord
snap install code --classic -y

git config --global credential.credentialStore gpg

clear

read -p "Name for git: " gitName
git config --global user.name $gitName

read -p "Email for git: " gitEmail
git config --global user.email $gitEmail

clear

echo "Generating GPG key to store git credentials..."
gpg --gen-key

read -p "Re-enter the name used to generate the GPG key: " passName

pass init $passName

clear

echo "Enter git token to be used for this device: "
pass insert git
