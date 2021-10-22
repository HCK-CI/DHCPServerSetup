# DHCP Server - Setup script

This repository is a part of HCK-CI installer. It can be used directly, but better to use global installer instead.

In order to connect to the Studio machine in each HLK/HCK setup, we need to set up a DHCP server that will provide each studio with a unique IP address. The server will assign the IP address according to the machine MAC address with the following rule (replace XX with AutoHCK unique ID):

- 56:00:XX:00:XX:dd > 192.168.0.XX (VirtHCK unique ID)
- 56:00:XX:00:dd:dd > 192.168.0.XX (QemuHCK unique ID)

Run `setup.sh` with sudo, (root privileges), to download ISC DHCP server, install it as a service and configure it with the required IP assignment rule.

The script will also create a new bridge.
