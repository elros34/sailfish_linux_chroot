#!/bin/bash
# Do not edit, copied from sailfish_ubu_chroot

source /root/.bashrc
source /usr/share/ubu_chroot/ubu-variables.sh
eval $TRACE_CMD

#if [ ! -f /run/dbus/pid ]; then
    #dbus-daemon --system --fork
#fi

if [ ! -f /run/sshd.pid ]; then
    /usr/sbin/sshd -p 2228
fi

# libhybris
if [ -d "/parentroot/usr/libexec/droid-hybris/system/" ] && [ -z "$(mount | grep 'unionfs on /system')" ]; then
    unionfs -o allow_other,nonempty /parentroot/usr/libexec/droid-hybris/system/:/parentroot/system/ /system || true
fi

$@

