#!/bin/bash

set -ex

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${work_dir}/../components/helpers.sh"

if command_exists docker; then
    cli=docker
elif command_exists podman; then
    cli=podman
else
    echo Compatible OCI runtime does not exist.
fi

$cli run \
    --rm \
    --volume "${work_dir}":/data:Z \
    --pull always \
    archlinux bash /data/build-internal.sh
