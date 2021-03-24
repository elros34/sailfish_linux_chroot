#!/bin/bash
# Do not edit in chroot, copied from sailfish_linux_chroot

source /root/.bashrc
source /usr/share/sfchroot/variables.sh
eval $TRACE_CMD

#[ ! -f /run/dbus/pid ] && dbus-daemon --system --fork
[ ! -f /run/sshd.pid ] && /usr/sbin/sshd -p $SSH_PORT

# libhybris
if [ -d "/parentroot/usr/libexec/droid-hybris/system/" ] && [ -z "$(mount | grep 'unionfs on /system')" ]; then
    unionfs -o allow_other,nonempty,auto_unmount /parentroot/usr/libexec/droid-hybris/system/:/parentroot/system/ /system || true
fi

$@

