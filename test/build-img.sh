#!/bin/bash

set -ex

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run \
    --rm \
    --volume "${work_dir}":/data:Z \
    archlinux bash /data/build-internal.sh
