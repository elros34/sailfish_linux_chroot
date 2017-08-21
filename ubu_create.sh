#!/bin/bash
set -e
#set -x
TARGET_URL=http://cdimage.ubuntu.com/ubuntu-base/releases/17.04/release/ubuntu-base-17.04-base-armhf.tar.gz
CHROOT_IMG=ubuntu-17.04-armhf.ext2
TARBALL=ubuntu-base-17.04-base-armhf.tar.gz
CHROOT_DIR=/.ubuntu

if [ $(whoami) != "root" ]
then
    echo "run me as root!"
    exit 1
fi

dd if=/dev/zero bs=1M count=3000 of=$CHROOT_IMG
mkfs.ext2 $CHROOT_IMG
mkdir -p $CHROOT_DIR
mount -t ext2 -o loop $CHROOT_IMG $CHROOT_DIR

if [ ! -e $TARBALL ]
then
	wget $TARGET_URL
fi

tar --numeric-owner -pxvzf $TARBALL -C $CHROOT_DIR/

if [ ! -e /etc/sailfish-release ]
then
	cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin/
fi

/bin/cp -f /etc/resolv.conf $CHROOT_DIR/etc/

mkdir -p $CHROOT_DIR/usr/share/ubu_chroot/
cp -f scripts/* $CHROOT_DIR/usr/share/ubu_chroot/
chmod a+x $CHROOT_DIR/usr/share/ubu_chroot/*

if [ -n "$(mount | grep $CHROOT_DIR/)" ]
then
	./ubu_close.sh
	exit 1
fi

mount --bind /dev $CHROOT_DIR/dev
mount --bind /dev/pts $CHROOT_DIR/dev/pts
mount --bind /dev/shm $CHROOT_DIR/dev/shm
mount --bind /proc $CHROOT_DIR/proc
mount --bind /sys $CHROOT_DIR/sys
mkdir $CHROOT_DIR/home/host_user

chroot $CHROOT_DIR /bin/bash /usr/share/ubu_chroot/create.sh

