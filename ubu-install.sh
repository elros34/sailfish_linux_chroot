#!/bin/bash
set -e
#set -x
source ubu-variables.sh
source ubu-common.sh

if [ $# -eq 0 ]; then
    echo "supported arguments: kwin, lxde, xfce4, weston, qxcompositor, glibc"
	exit 1
fi

copy_configs() {
	if [ x$1 == "xkwin" ]; then
    	mkdir -p $CHROOT_DIR/home/$USER_NAME/.kde4/share/config/
    	cp -f configs/kwinrc $CHROOT_DIR/home/$USER_NAME/.kde4/share/config/	
	elif [ x$1 == "xlxde" ]; then
		echo "lxde"
	elif [ x$1 == "xxfce4" ]; then
		echo "xfce4"
	elif [ x$1 == "xweston" ]; then
		cp -f configs/weston.ini $CHROOT_DIR/home/$USER_NAME/.config/
	elif [ x$1 == "xqxcompositor" ]; then
    	mkdir -p $CHROOT_DIR/usr/local/bin/
    	cp xwayland/Xwayland $CHROOT_DIR/usr/local/bin/
	elif [ x$1 == "xglibc" ]; then
   	    mkdir -p $CHROOT_DIR/glibc
    	/bin/cp -r -f glibc/*.deb $CHROOT_DIR/glibc
	fi
}

MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -gt 5 ]; then
	copy_configs $1
	echo "$CHROOT_DIR already mounted"
	echo "chrooting"
	ubu_chroot /usr/share/ubu_chroot/install.sh $@
	ubu_cleanup
	exit
elif [ $MOUNTS -gt 0 ]; then
	echo "$CHROOT_DIR partially mounted"
	./ubu-close.sh
	exit 1
fi

mount -t ext2 -o loop $CHROOT_IMG $CHROOT_DIR

ubu_mount
copy_configs $1
ubu_chroot /usr/share/ubu_chroot/install.sh $@
ubu_cleanup


