#!/bin/bash
# Do not edit in chroot, copied from sailfish_linux_chroot

source /root/.bashrc
source /usr/share/sfchroot/variables.sh
eval $TRACE_CMD

#[ ! -f /run/dbus/pid ] && dbus-daemon --system --fork
[ ! -f /run/sshd.pid ] && /usr/sbin/sshd -p $SSH_PORT

$@

