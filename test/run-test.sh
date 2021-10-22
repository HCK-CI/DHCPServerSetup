#!/bin/bash

set -e

qemu_bin="${1}"
dhcp_bridge="${2}"

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cat >"${work_dir}/if_up.sh" <<EOF
#!/bin/bash
set -e

ip link set "\${1}" up
ip link set "\${1}" master "${dhcp_bridge}"
EOF
chmod +x "${work_dir}/if_up.sh"

prefix="$(md5sum "${work_dir}/initramfs/check-net.sh" | cut -d' ' -f1)"

"${qemu_bin}" \
    -display none \
    -no-user-config \
    -nodefaults \
    --enable-kvm \
    -cpu host \
    -m 128 \
    -netdev tap,id=mynet0,script="${work_dir}/if_up.sh",downscript=no \
    -device e1000e,netdev=mynet0,mac=56:00:05:00:dd:dd \
    -netdev tap,id=mynet1,script="${work_dir}/if_up.sh",downscript=no \
    -device virtio-net-pci,netdev=mynet1,mac=56:00:15:00:dd:dd \
    -kernel "${work_dir}/build/${prefix}-vmlinuz-linux" \
    -append "console=ttyS0" \
    -initrd "${work_dir}/build/${prefix}-initramfs.img.zstd" \
    -serial stdio |
        tee "${work_dir}/full-test.log" |
        grep --line-buffered -e'^CHECK:' |
        tee "${work_dir}/check-test.log"

if grep -qe 'FAIL' "${work_dir}/check-test.log"; then
    exit 1
fi
