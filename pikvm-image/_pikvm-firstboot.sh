#!/bin/bash
set -ex
if [ "$1" != --do-the-thing ]; then
    exit 1
fi

rw

rm -f /etc/ssh/ssh_host_*
ssh-keygen -v -A

rm -f /etc/kvmd/nginx/ssl/*
kvmd-gencert --do-the-thing

if grep -q 'X-kvmd\.otgmsd' /etc/fstab; then
	umount /dev/mmcblk0p3
	parted /dev/mmcblk0 -a optimal -s resizepart 3 100%
	yes | mkfs.ext4 -F -m 0 /dev/mmcblk0p3
	mount /dev/mmcblk0p3
fi

systemctl disable pikvm-firstboot
ro
