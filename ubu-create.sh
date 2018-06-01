#!/bin/bash
set -e
#set -x
source ubu-variables.sh
source ubu-common.sh

if [ $(whoami) != "root" ]
then
    echo "run me as root!"
    exit 1
fi

# Never mount /dev twice
if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 5 ]; then
	echo "$CHROOT_DIR already mounted"
	./ubu-close.sh
	exit 1
fi

dd if=/dev/zero bs=1 count=1 seek=$IMG_SIZE of=$CHROOT_IMG
mkfs.ext2 $CHROOT_IMG
mkdir -p $CHROOT_DIR
mount -t ext2 -o loop $CHROOT_IMG $CHROOT_DIR

if [ ! -e $TARBALL ] || [ $(du -m $TARBALL | cut -f1) -lt 20 ]; then
	rm $TARBALL || true
	curl -O -J $TARGET_URL
fi

echo "Extracting..."
tar --numeric-owner -pxzf $TARBALL -C $CHROOT_DIR/

ARCH=$(uname -m)
if [[ $ARCH == "x86"* ]]; then
	apt-get install qemu-user-static
	cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin/
fi

mkdir -p $CHROOT_DIR/usr/share/ubu_chroot/
mkdir -p $CHROOT_DIR/home/host-user
chown $HOST_USER:$HOST_USER $CHROOT_DIR/home/host-user
mkdir -p $CHROOT_DIR/home/$USER_NAME
mkdir -p $CHROOT_DIR/run/display
mkdir -p $CHROOT_DIR/sfos
mkdir -p $CHROOT_DIR/system
ln -s /system/vendor $CHROOT_DIR/vendor 

ubu_mount
ubu_chroot /usr/share/ubu_chroot/create.sh
ubu_cleanup


