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

apt install -y git pass python-is-python3 python3-pip pulseaudio
snap install discord
snap install -y code --classic

#
# Set up Git, store token with pass+gpg encryption
#

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

#
# Install Miniconda
#

mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
source ~/miniconda3/bin/activate
conda init --all
conda config --set auto_activate false
pip install uv

exec bash

#
# PulseAudio setup
#
sed -i '/; default-sample-rate = 44100/c\default-sample-rate = 192000' /etc/pulse/daemon.conf
sed -i '/; default-sample-format = s16le/c\default-sample-format = s24le' /etc/pulse/daemon.conf
pulseaudio -k
pulseaudio -D



