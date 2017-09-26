#!/bin/bash
set -e
#set -x
source ubu_variables.sh
CHROOT_DIR=/.ubuntu

if [ $# -eq 0 ]
then
    echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1
fi

if [ -z "$(mount | grep $CHROOT_DIR)" ]
then
    echo "$CHROOT_DIR not mounted"
    exit 1
fi

if [ $1 == "kwin" ]
then
    mkdir -p $CHROOT_DIR/home/$USER_NAME/.kde4/share/config/
    cp -f configs/kwinrc $CHROOT_DIR/home/$USER_NAME/.kde4/share/config/
	
elif [ $1 == "lxde" ] 
then
	echo "lxde"

elif [ $1 == "weston" ]
then
	cp -f configs/weston.ini $CHROOT_DIR/home/$USER_NAME/.config/

elif [ $1 == "qxcompositor" ]
then
    mkdir -p $CHROOT_DIR/usr/local/bin/
    cp xwayland/Xwayland $CHROOT_DIR/usr/local/bin/

elif [ $1 == "glibc" ]
then
    mkdir -p $CHROOT_DIR/glibc
    /bin/cp -r -f glibc/*.deb $CHROOT_DIR/glibc
fi

./ubu_chroot.sh /usr/share/ubu_chroot/install.sh $@


