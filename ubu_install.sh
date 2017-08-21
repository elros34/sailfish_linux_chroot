#!/bin/bash
set -e
#set -x
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
    mkdir -p $CHROOT_DIR/home/nemo/.kde4/share/config/
    cp -f configs/kwinrc $CHROOT_DIR/home/nemo/.kde4/share/config/
	
elif [ $1 == "lxde" ] 
then
	echo "lxde"

elif [ $1 == "weston" ]
then
	cp -f configs/weston.ini $CHROOT_DIR/home/nemo/.config/

elif [ $1 == "qxcompositor" ]
then
    mkdir -p $CHROOT_DIR/usr/local/bin/
    cp xwayland/Xwayland $CHROOT_DIR/usr/local/bin/

elif [ $1 == "glibc" ]
then
    tar -xvzf glibc/glibc_2.23.tar.gz -C $CHROOT_DIR/
    /bin/cp -r -f $CHROOT_DIR/glibc_root/* $CHROOT_DIR/
    cd $CHROOT_DIR/lib/ 
    ln -sf arm-linux-gnueabihf/*so.* . #FIXME
    cd -
fi

./ubu_chroot.sh /usr/share/ubu_chroot/install.sh $@


