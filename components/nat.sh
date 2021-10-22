#!/bin/bash

set -e

configure_nat() {
  log_info "Configuring NAT"

  log_info "Enabling IP forwarding"
  echo 'net.ipv4.ip_forward=1' > /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf

  log_info "Enabling NAT masquerade"
  switches=( $(ip route ls | \
    awk '/^default / {
          for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; } }
         }'
        ) )

  switch="${switches[0]}"
  log_info "Selected external interface: ${switch}"

  iptables -t nat -A POSTROUTING -o "${switch}" -j MASQUERADE

  iptables -A FORWARD -i "${bridge}" -j ACCEPT
  iptables -A FORWARD -o "${bridge}" -j ACCEPT
}
