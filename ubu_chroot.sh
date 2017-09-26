#!/bin/bash
set -e
#set -x
source ubu_variables.sh
CHROOT_DIR=/.ubuntu
CHROOT_IMG=ubuntu-17.04-armhf.ext2
HOST_USER=nemo
HOME_DIR=/home/$HOST_USER
export ON_DEVICE=0

if [ -f /etc/sailfish-release ]
then
    ON_DEVICE=1
fi

if [ ! -d $CHROOT_DIR ]
then
	mkdir $CHROOT_DIR
fi

if [ -n "$(mount | grep $CHROOT_DIR)" ]
then
	echo "$CHROOT_DIR already mounted"
	echo "chrooting"
	chroot $CHROOT_DIR /usr/share/ubu_chroot/chroot.sh env -i TERM="$TERM" PATH="$PATH" USER=root HOME=/root /bin/bash $@
	exit
fi

if [ ! -e $CHROOT_DIR ]
then
	mkdir $CHROOT_DIR
fi

mount -t ext2 -o loop $CHROOT_IMG $CHROOT_DIR

mount --bind /proc $CHROOT_DIR/proc
mount --bind /sys $CHROOT_DIR/sys
mount --bind /dev $CHROOT_DIR/dev
mount --bind /dev/pts $CHROOT_DIR/dev/pts
mount --bind /dev/shm $CHROOT_DIR/dev/shm
#mount --bind /run $CHROOT_DIR/run
if [ $ON_DEVICE -eq 1 ]
then
    mkdir -p $CHROOT_DIR/run/display
    mount --bind /run/display $CHROOT_DIR/run/display
    mount --bind $HOME_DIR $CHROOT_DIR/home/host_user
    mount --bind /media $CHROOT_DIR/media
    # libhybris
    mount -o bind,ro / $CHROOT_DIR/sfos/
    mount -o bind,ro /system $CHROOT_DIR/sfos/system

    # hw keyboard
    mount -o bind,ro /usr/share/X11/xkb $CHROOT_DIR/usr/share/X11/xkb
    
    #mount --bind /var/lib/dbus $CHROOT_DIR/var/lib/dbus
    #mount --bind /var/run/dbus $CHROOT_DIR/var/run/dbus
    #mount -o bind,ro $HOME_DIR/.config/pulse $CHROOT_DIR/home/nemo/.config/pulse
fi

mount --bind /tmp $CHROOT_DIR/tmp

/bin/cp -f /etc/resolv.conf $CHROOT_DIR/etc/

echo "chrooting"
chroot $CHROOT_DIR /usr/share/ubu_chroot/chroot.sh env -i TERM="$TERM" PATH="$PATH" USER=root HOME=/root /bin/bash $@

#export QT_IM_MODULE=qtvirtualkeyboard

#xhost +

