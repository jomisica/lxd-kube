#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    echo "Example: sudo bash install.sh"
    exit
fi

# verificar se temos o comando brctl
if ! [ -x "$(command -v brctl)" ]; then
    echo "Error: brctl is not installed." >&2
    echo "Instalando o pacote necessário."
    apt-get install bridge-utils >&2
fi

# Verificar se já temeos a bridge "lxdbridge"
brctl show lxdbridge >&2
if [ $? -eq 0 ]; then
    echo "[OK] A bridge 'lxdbridge' já existe."
else
    echo "[OK] Adicionando a bridge 'lxdbridge'."
    brctl addbr lxdbridge >&2

    brctl show lxdbridge >&2
    if [ $? -eq 0 ]; then
        echo "[OK] A bridge 'lxdbridge' já existe."
    else
        echo "[ERROR] Não foi possivel criar a bridge 'lxdbridge'."
        exit 255
    fi
fi

# get default interface
export DEFAULT_IF=$(/sbin/ip route | awk '/^default/ { print $5 }')

brctl addif lxdbridge "${DEFAULT_IF}"

# netplan config file
CONFIG_NETPLAN_FILE=$(grep -r "${DEFAULT_IF}:" /etc/netplan/ | awk '{sub(/:.*/, ""); print}')
if [ $? -eq 0 ]; then
    echo "[OK] A bridge 'lxdbridge' já existe."
fi

$(envsubst <lxc/install/createbridge/netplancfg.yaml > "${CONFIG_NETPLAN_FILE}")

netplan apply

exit
