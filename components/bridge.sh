#!/bin/bash

set -e

create_bridge_network_manager() {
  log_info "Creating bridge $bridge via network manager"

  nmcli conn add type bridge con-name "$bridge" ifname "$bridge"
  nmcli conn modify "$bridge" ipv4.addresses "$bridge_ip/$bridge_prefix"
  nmcli conn modify "$bridge" ipv4.method manual
  nmcli conn up "$bridge"
}

create_bridge_netplan() {
  log_info "Creating bridge $bridge via netplan"

  cat >"/etc/netplan/auto_hck_$bridge.yaml" <<EOC
network:
  version: 2
  bridges:
    $bridge:
      addresses: [$bridge_ip/$bridge_prefix]
      dhcp4: false
      dhcp6: false
EOC

  netplan apply
}

configure_bridge_rhel() {
  log_info "Creating bridge $bridge via network scripts"

  cat >"/etc/sysconfig/network-scripts/ifcfg-$bridge" <<EOC
DEVICE=$bridge
TYPE=Bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$bridge_ip
NETMASK=$bridge_subnet_mask
BROADCAST=$bridge_subnet.255
NETWORK=$bridge_subnet.0
EOC

  service network restart
}

check_bridge() {
  log_info "Checking bridge $bridge configuration"

  if brctl show | grep -qe "$bridge"; then
    ip addr show dev "$bridge" | grep -qe "$bridge_ip/$bridge_prefix"
  else
    return 1
  fi
}

configure_bridge_and_check() {
  if check_bridge; then
    log_info "DHCP bridge already exist, configuration skipped."
    return 0
  fi

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      if command_exists netplan; then
        if netplan get all | grep -q NetworkManager; then
          create_bridge_network_manager
        else
          create_bridge_netplan
        fi
      else
        create_bridge_network_manager
      fi
      ;;

    fedora)
      create_bridge_network_manager
      ;;

    *)
      log_fatal "Unsupported distributive. Please create bridge manually."
      ;;
  esac

  return check_bridge
}
