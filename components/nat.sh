#!/bin/bash

set -e

configure_nat() {
  log_info "Configuring NAT"

  if command_exists firewall-cmd; then
    firewall-cmd -q --add-forward --permanent
    firewall-cmd -q --add-masquerade --permanent
    firewall-cmd -q --reload
  elif command_exists ufw; then
    switches=( $(ip route ls | \
      awk '/^default / {
            for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; } }
           }'
          ) )

    switch="${switches[0]}"
    log_info "Selected external interface: ${switch}"

    echo net/ipv4/ip_forward=1 >> /etc/ufw/sysctl.conf
    cat >> /etc/ufw/before.rules <<EOF
*nat
-A POSTROUTING -o "${switch}" -j MASQUERADE
COMMIT
EOF

    ufw route allow in on "${bridge}"
    ufw route allow out on "${bridge}"
    ufw reload
  else
    log_fatal "No supported netfilter frontend found."
  fi
}
