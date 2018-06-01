#!/bin/bash
set -e
#set -x
source ubu-variables.sh
source ubu-common.sh

MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -gt 5 ]; then
	echo "$CHROOT_DIR already mounted"
	echo "chrooting"
	if [ $# -gt 0 ]; then
		ubu_chroot /usr/share/ubu_chroot/chroot.sh $@
	else
		ubu_chroot /usr/share/ubu_chroot/chroot.sh su $USER_NAME -l
	fi
	ubu_cleanup
	exit
elif [ $MOUNTS -gt 0 ]; then
	echo "$CHROOT_DIR partially mounted"
	./ubu-close.sh
	exit 1
fi

mount -t ext2 -o loop $CHROOT_IMG $CHROOT_DIR

ubu_mount
if [ $# -gt 0 ]; then
	ubu_chroot /usr/share/ubu_chroot/chroot.sh $@
else
	ubu_chroot /usr/share/ubu_chroot/chroot.sh su $USER_NAME -l
fi
ubu_cleanup

