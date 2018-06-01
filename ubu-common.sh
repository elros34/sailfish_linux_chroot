#!/bin/bash
set -e
#set -x

export ON_DEVICE=0
if [ -f /etc/sailfish-release ]; then
    ON_DEVICE=1
fi

ubu_chroot() {
	rsync $(readlink -f /etc/resolv.conf) $CHROOT_DIR/etc/
	rsync scripts/*.sh $CHROOT_DIR/usr/share/ubu_chroot/
	rsync ubu-variables.sh $CHROOT_DIR/usr/share/ubu_chroot/
	chmod a+x $CHROOT_DIR/usr/share/ubu_chroot/*
	rsync scripts/.uburc $CHROOT_DIR/home/$USER_NAME/
	
	echo "chrooting $CHROOT_DIR"
	chroot $CHROOT_DIR /usr/bin/env -i \
    	HOME=/root TERM="$TERM" PS1='[\u@ubu-chroot: \w]# ' \
    	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games \
    	/bin/bash --login $@
}

ubu_mount() {
	if [ ! -d $CHROOT_DIR ]; then
		mkdir $CHROOT_DIR
	fi
	mount --bind /dev $CHROOT_DIR/dev
	mount --bind /dev/pts $CHROOT_DIR/dev/pts
	mount --bind /dev/shm $CHROOT_DIR/dev/shm
	mount --bind /sys $CHROOT_DIR/sys
	mount --bind /proc $CHROOT_DIR/proc
	#mount --bind /run $CHROOT_DIR/run
    mount --bind /run/display $CHROOT_DIR/run/display || true
	mount --rbind --make-rslave $HOST_HOME_DIR $CHROOT_DIR/home/host-user
	mount --rbind --make-rslave /media $CHROOT_DIR/media
	
	if [ x$ON_DEVICE == "x1" ]; then
    	# libhybris
    	mount -o bind,ro / $CHROOT_DIR/sfos/
    	mount -o bind,ro /system $CHROOT_DIR/sfos/system
	
    	# hw keyboard
    	mount -o bind,ro /usr/share/X11/xkb $CHROOT_DIR/usr/share/X11/xkb || true
    	
    	#mount --bind /var/lib/dbus $CHROOT_DIR/var/lib/dbus
    	#mount --bind /var/run/dbus $CHROOT_DIR/var/run/dbus
    	#mount -o bind,ro $HOME_DIR/.config/pulse $CHROOT_DIR/home/nemo/.config/pulse
	fi
	
	#mount --bind /tmp $CHROOT_DIR/tmp
	rsync ubu-variables.sh $CHROOT_DIR/usr/share/ubu_chroot/
}

ubu_umount() {
	umount -R $CHROOT_DIR || true
	for dir in $(mount | grep $CHROOT_DIR | cut -f 3 -d" " | sort -r); do
		echo "unmounting $dir"
		if [ x$1 == "xforce" ]; then
			umount -flR $CHROOT_DIR || true
		else
			umount -R $dir || true
		fi
	done
}

# Clean up
ubu_cleanup() {
	if [ x$1 == "xforce" ]; then
		ubu_umount
		if [ $(fuser -v $CHROOT_DIR 2>&1 | wc -l) -ne 0 ]; then 
			echo "Chroot still in use"
			fuser -kv $CHROOT_DIR
			ubu_umount
			if [ $(fuser -v $CHROOT_DIR 2>&1 | wc -l) -ne 0 ]; then
				echo "$CHROT_DIR busy!\nDo you want to force unmount (y/n)?"
				read yn
				if [ x$yn == "xy"]; then
					ubu_umount force
					exit
				fi
			fi
		fi
	else
		if [ -n "$(fuser -v $CHROOT_DIR 2>&1 | grep unionfs)" ]; then
			if [ "$(fuser -v $CHROOT_DIR 2>&1 | wc -l)" -eq 3 ]; then 
				ubu_umount
				exit
			fi
		fi
		
		if [ $(fuser -v $CHROOT_DIR 2>&1 | wc -l) -eq 0 ]; then 
			ubu_umount
		fi
	fi
}

