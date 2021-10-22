#!/bin/bash

set -e

configure_server() {
  log_info "Generating DHCP server configuration"

  cat >"${cfg_file}" <<EOC
default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;
EOC

  if [ -n "${dns_servers}" ]; then
    cat >>"${cfg_file}" <<EOC
option domain-name "local";
option domain-name-servers ${dns_servers};
EOC
  fi

  cat >>"${cfg_file}" <<EOC
subnet ${bridge_subnet}0 netmask $bridge_subnet_mask {
  option routers $bridge_ip;
  range ${bridge_subnet}200 ${bridge_subnet}254;
EOC

  # QemuHCK setup manager
  for i in {2..99}; do
    i2=$(printf "%02d" "${i}")

    cat >>"${cfg_file}" <<EOC
  host qemuhck${i2} {
    hardware ethernet 56:00:${i2}:00:dd:dd;
    fixed-address ${bridge_subnet}${i};
  }

EOC
  done

  # VirtHCK setup manager
  for i in {2..99}; do
    i2=$(printf "%02d" "${i}")

    cat >>"${cfg_file}" <<EOC
  host virthck${i2} {
    hardware ethernet 56:00:${i2}:00:${i2}:dd;
    fixed-address ${bridge_subnet}${i};
  }
EOC
  done

  cat >>"${cfg_file}" <<EOC
}
EOC
}
