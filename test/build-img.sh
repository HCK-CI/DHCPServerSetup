#!/bin/bash

set -ex

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run \
    --rm \
    --mount type=bind,src="${work_dir}",dst=/data \
    archlinux bash /data/build-internal.sh
