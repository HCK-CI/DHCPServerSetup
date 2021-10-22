#!/bin/bash

set -e

install_server() {
  log_info "Installing DHCP server"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      apt-get install -y isc-dhcp-server
      systemctl enable isc-dhcp-server.service
      ;;

    fedora)
      dnf install -y dhcp-server
      systemctl enable dhcpd.service
      ;;

    *)
      log_fatal "Unsupported distributive. Please install ISC DHCP server."
      ;;
  esac
}

restart_server() {
  log_info "Restarting DHCP server"

  lsb_dist="$( get_distribution )"

  case "$lsb_dist" in
    ubuntu)
      systemctl restart isc-dhcp-server.service
      ;;

    fedora)
      systemctl restart dhcpd.service
      ;;

    *)
      log_fatal "Unsupported distributive. Please restart ISC DHCP server."
      ;;
  esac
}
