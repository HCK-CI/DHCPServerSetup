#!/bin/bash

set -e

pacman --noconfirm -Syy linux linux-firmware mkinitcpio dhcpcd

mkdir -p /data/build

prefix="$(md5sum /data/initramfs/check-net.sh | cut -d' ' -f1)"

cp -v /boot/vmlinuz-linux "/data/build/${prefix}-vmlinuz-linux"
cp -v /data/initramfs/hooks/install/check_net /usr/lib/initcpio/install/check_net
cp -v /data/initramfs/hooks/hooks/check_net /usr/lib/initcpio/hooks/check_net

mkinitcpio \
    --kernel /boot/vmlinuz-linux \
    --config /data/initramfs/mkinitcpio.conf \
    --generate "/data/build/${prefix}-initramfs.img.zstd"

lsinitcpio -a "/data/build/${prefix}-initramfs.img.zstd"
