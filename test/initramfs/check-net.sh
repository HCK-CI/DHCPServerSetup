#!/bin/bash

set -ex

mkdir -p "/var/lib/dhcpcd"

interfaces=( $(ip l | sed -n '/LOOPBACK/b;/^[0-9]\+/p' | awk -F ": " '{ print $2 }') )
hosts=( 1.1.1.1 www.redhat.com )

for netdev in "${interfaces[@]}"; do
    echo "Processing: ${netdev}"

    if ! ip l set "${netdev}" up; then
        echo "CHECK: DEV ${netdev} LINK UP FAIL"
        continue
    else
        echo "CHECK: DEV ${netdev} LINK UP PASS"
    fi

    mac_addr="$(ip -f link -o addr show "${netdev}" | grep -o 'link/ether \([0-9a-f][0-9a-z]:\)\{5\}[0-9a-f][0-9a-z]' | cut -d' ' -f2)"

    # dhcpcd required additional initialization time for first run
    if ! dhcpcd --timeout 120 "${netdev}"; then
        echo "CHECK: DEV ${netdev} ${mac_addr} DHCP FAIL"
        continue
    else
        echo "CHECK: DEV ${netdev} ${mac_addr} DHCP PASS"
    fi

    ip_addr="$(ip -f inet -o addr show "${netdev}" | grep -o 'inet \([0-9]\+\.\)\{3\}[0-9]\+' | cut -d' ' -f2)"

    ip_data="$(cut -d'.' -f4 <<< "${ip_addr}")"
    mac_data="$(cut -d':' -f3 <<< "${mac_addr}")"

    if (( "${ip_data}" == "${mac_data}" )); then
        echo "CHECK: IP ${netdev} ${ip_addr} ${mac_addr} PASS"
    else
        echo "CHECK: IP ${netdev} ${ip_addr} ${mac_addr} FAIL"
    fi
done

for host in "${hosts[@]}"; do
    if ping -c 4 "${host}"; then
        echo "CHECK: PING ${host} PASS"
    else
        echo "CHECK: PING ${host} FAIL"
    fi
done
