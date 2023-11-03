#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    echo "Example: sudo bash create-lxd-bridge.sh"
    exit
fi

# Check if we have the brctl command
if ! [ -x "$(command -v brctl)" ]; then
    echo "Installing the required bridge-utils package."
    apt-get install bridge-utils >&2
    if ! [ -x "$(command -v brctl)" ]; then
        echo "Error: brctl is not installed." >&2
        exit 255
    fi
fi

# Check if we already have the "lxdbridge" bridge
brctl show lxdbridge >&2
if [ $? -eq 0 ]; then
    echo "[ON] The bridge 'lxdbridge' already exists."
else
    echo "[OK] Adding bridge 'lxdbridge'."
    brctl addbr lxdbridge >&2

    brctl show lxdbridge >&2
    if [ $? -eq 0 ]; then
        echo "[ON] The bridge 'lxdbridge' already exists."
    else
        echo "[ERROR] Unable to create bridge 'lxdbridge'."
        exit 255
    fi
fi

# get default interface
export DEFAULT_IF=$(/sbin/ip route | awk '/^default/ { print $5 }')
if [ "${DEFAULT_IF}" = "lxdbridge" ]; then
    echo "[ERROR] The default route is already for bridge 'lxdbridge'."
    echo "[ABORT] The bridge appears to be configured 'lxdbridge'."
    exit 255
fi

brctl addif lxdbridge "${DEFAULT_IF}"

brctl show lxdbridge | grep "${DEFAULT_IF}"
if [ $? -eq 0 ]; then
    echo "[OK] Interface '${DEFAULT_IF}' has been added to bridge 'lxdbridge'."
else
    echo "[ERROR] Unable to add interface '${DEFAULT_IF}' to bridge 'lxdbridge'."
    exit 255
fi

# netplan config file
CONFIG_NETPLAN_FILE=$(grep -r "${DEFAULT_IF}:" /etc/netplan/ | awk '{sub(/:.*/, ""); print}')

# Backup of the current netplan file
cp "${CONFIG_NETPLAN_FILE}" /root

# resolve template
$(envsubst <netplan/netplancfg.yaml >"${CONFIG_NETPLAN_FILE}")

# apply netplan configuration
netplan apply

exit
