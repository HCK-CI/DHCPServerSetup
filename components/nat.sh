#!/bin/bash

set -e

configure_nat() {
  log_info "Configuring NAT"

  firewall-cmd -q --add-forward --permanent
  firewall-cmd -q --add-masquerade --permanent
  firewall-cmd -q --reload
}
