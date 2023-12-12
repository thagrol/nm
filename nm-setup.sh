#!/bin/bash
set -e
if [ "$EUID" -ne 0 ]; then
    echo "Must be root"
    exit 1
fi

if [ -z $1 ]; then
    echo "Usage $0 iface [iface ... iface]"
    exit 2
fi

for iface in "$@"; do
    # Check if configurations exist ...
    N=$(ls -1l /etc/NetworkManager/system-connections/${iface}[.-]* 2>/dev/null |
        wc -l)

    # ... and delete them.
    if [ "$N" != 0 ]; then
	sudo rm /etc/NetworkManager/system-connections/${iface}[.-]*
	sudo nmcli con reload
    fi


    # create dhcp profile
    /usr/bin/nmcli con add \
        con-name "$iface"-dhcp \
        ifname "$iface" \
        type ethernet \
        connection.autoconnect-priority 100 \
        connection.autoconnect-retries 2
    
    # create link local profile
    /usr/bin/nmcli con add \
        con-name "$iface"-linklocal \
        type ethernet \
        ifname "$iface" \
        connection.autoconnect-priority 50 \
        ipv4.method link-local \
        ipv4.link-local enabled
done

/usr/bin/nmcli con reload

exit 0

