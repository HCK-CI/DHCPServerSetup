#!/bin/bash

set -e

get_distribution() {
  lsb_dist=""

  if [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
  fi

  echo "$lsb_dist" | tr '[:upper:]' '[:lower:]'
}

get_network_mask_from_prefix() {
  value=$(( 0xffffffff ^ ((1 << (32 - ${1})) - 1) ))
  echo "$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}
