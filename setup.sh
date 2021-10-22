#!/bin/bash

set -e

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${work_dir}/components/logger.sh"
source "${work_dir}/components/helpers.sh"
source "${work_dir}/components/bridge.sh"
source "${work_dir}/components/nat.sh"
source "${work_dir}/components/install.sh"
source "${work_dir}/components/config.sh"

cfg_file="/etc/dhcp/dhcpd.conf"
dns_servers=""

print_usage() {
    cat <<EOU
  Usage:
    ${BASH_SOURCE[0]} <bridge_name> <bridge_subnet> [options] [--help]

  Options:
    --config-only                   - create new config file w/o server installation
    --test-only                     - run tests of existing setup w/o server reconfiguration
    --run-test                      - run tests after server installation/configuration
    --get-config-file               - get configuration file path and exit
    --dns-servers                   - add Google DNS (8.8.8.8) to DHCP config (default: no DNS)
    --dns-servers=1.1.1.1,8.8.8.8   - add specified DNS servers to DHCP config (default: no DNS)
    --qemu-bin=<path>               - path to QEMU binary for run tests
    --help                          - show this information
EOU
}

run_install=1
run_config=1
run_test=0

bridge_name=""
bridge_subnet=""
qemu_bin="qemu-system-x86_64"

for i in "$@"; do
  case $i in
    --get-config-file)
      echo "${cfg_file}"
      exit 0
      ;;
    --config-only)
      run_install=0
      run_test=0
      run_config=1
      ;;
    --test-only)
      run_install=0
      run_config=0
      run_test=1
      ;;
    --run-test)
      run_test=1
      ;;
    --dns-servers)
      dns_servers="8.8.8.8"
      ;;
    --dns-servers=*)
      dns_servers="${i/*=/}"
      ;;
    --qemu-bin=*)
      qemu_bin="${i/*=/}"
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      if [ -z "${bridge}" ]; then
        bridge="${i}"
      elif [ -z "${bridge_subnet}" ]; then
        bridge_subnet="${i}"
      else
        log_error "Unknown option: ${i}"
        print_usage
        exit 1
      fi
      ;;
  esac
done

bridge_ip="${bridge_subnet}1"
bridge_prefix="24"
bridge_subnet_mask="$(get_network_mask_from_prefix "${bridge_prefix}")"

if [ "${run_install}" = "1" ]; then
  log_info "Running install stage"

  configure_bridge_and_check
  configure_nat
  install_server
fi

if [ "${run_config}" = "1" ]; then
  log_info "Running config stage"

  configure_server
  restart_server
fi

if [ "${run_test}" == "1" ]; then
  log_info "Running test stage"

  check_bridge ||
    log_fatal "Failed to verify DHCP bridge configuration"

  prefix="$(md5sum "${work_dir}/test/initramfs/check-net.sh" | cut -d' ' -f1)"

  if [ ! -f "${work_dir}/test/build/${prefix}-initramfs.img.zstd" ] ||
     [ ! -f "${work_dir}/test/build/${prefix}-vmlinuz-linux" ]; then
    log_info "Generating image for testing DHCP configuration"
    bash "${work_dir}/test/build-img.sh" ||
      log_fatal "Failed to generate image for testing DHCP configuration"
  fi

  bash "${work_dir}/test/run-test.sh" "${qemu_bin}" "${bridge}" ||
    log_fatal "Failed to test DHCP configuration"
fi
log_info "DHCP configuration finished"
