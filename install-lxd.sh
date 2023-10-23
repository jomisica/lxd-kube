#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    echo "Example: sudo bash install-lxd.sh"
    exit
fi

# Check if we have the brctl command
if ! [ -x "$(command -v lxd)" ]; then
    echo "Installing the required lxd-installer package."
    apt update
    NEEDRESTART_MODE=a apt upgrade -y
    NEEDRESTART_MODE=a apt -y install lxd-installer
    if ! [ -x "$(command -v lxd)" ]; then
        echo "Error: lxd is not installed." >&2
        exit 255
    fi
fi

# Configure LXC with the preseed
cat "lxc/preseed/preseed.yaml" | lxd init --preseed

groups ${SUDO_USER} | grep lxd
if [ $? -eq 0 ]; then
    echo "[ON] The user '${SUDO_USER}' is already a member of 'lxd'."
else
    adduser ${SUDO_USER} lxd
fi


exit
