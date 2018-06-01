#!/bin/bash
# Do not edit, copied from sailfish_ubu_chroot
set -x

source /root/.bashrc
source /usr/share/ubu_chroot/ubu-variables.sh

# libhybris
if [ -z "$(mount | grep 'unionfs on /system')" ]; then
    unionfs -o allow_other,nonempty /sfos/usr/libexec/droid-hybris/system/:/sfos/system/ /system || true
fi

$@

