#!/bin/bash
set -e
source ubu-variables.sh
eval $TRACE_CMD

export ON_DEVICE=0
if [ -f /etc/sailfish-release ] || [ -f /parentroot/etc/sailfish-release ]; then
    ON_DEVICE=1
fi

ubu_host_user_exe() {
    if [ $(whoami) == "root" ]; then
        su $HOST_USER -l -c "$@"
    else
        $@
    fi
}

ubu_ssh() {
    ubu_host_user_exe "ssh -p 2228 -o StrictHostKeyChecking=no $USER_NAME@localhost $@"
}

ubu_chroot() {
    rsync -a $(readlink -f /etc/resolv.conf) $CHROOT_DIR/etc/
    rsync -a scripts/*.sh $CHROOT_DIR/usr/share/ubu_chroot/
    rsync -a ubu-variables.sh $CHROOT_DIR/usr/share/ubu_chroot/
    chmod a+x $CHROOT_DIR/usr/share/ubu_chroot/*
    rsync -a scripts/dotuburc $CHROOT_DIR/home/$USER_NAME/.uburc
    HOSTNAME="$(hostname)"
    if ! grep -q $HOSTNAME $CHROOT_DIR/etc/hosts ; then
        echo "127.0.1.1 $HOSTNAME" >> $CHROOT_DIR/etc/hosts
    fi 
    #ssh-copy-id -o StrictHostKeyChecking=no  -i /home/$HOST_USER/.ssh/id_rsa.pub $USER_NAME@localhost -p 2228

    if [ ! -f "$HOST_HOME_DIR/.ssh/id_rsa.pub" ]; then
        ubu_host_user_exe "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
    fi

    #TODO remove duplicates
    if ! grep -q "$(cat $HOST_HOME_DIR/.ssh/id_rsa.pub)" $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys ; then
        cat $HOST_HOME_DIR/.ssh/id_rsa.pub >> $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys
    fi

    # hw keyboard
    if [ x$ON_DEVICE == x"1" ] && [ x$SYNC_XKEYBOARD == x"1" ] && [ -d $CHROOT_DIR/usr/share/X11/xkb ] && [ ! -f .xkeyboard_synced ] && [ -f $CHROOT_DIR/usr/share/ubu_chroot/.create_finished ]; then
        /bin/cp -rf /usr/share/X11/xkb $CHROOT_DIR/usr/share/X11/
        XKB_LAYOUT=$(ubu_host_user_exe "dconf read /desktop/lipstick-jolla-home/layout")
        XKB_MODEL=$(ubu_host_user_exe "dconf read /desktop/lipstick-jolla-home/model")
        XKB_RULES=$(ubu_host_user_exe "dconf read /desktop/lipstick-jolla-home/rules")
        XKB_OPTIONS=$(ubu_host_user_exe "dconf read /desktop/lipstick-jolla-home/options")
        # default values
        : "${XKB_LAYOUT:=us}"
        : "${XKB_MODEL:=jollasbj}"
        : "${XKB_RULES:=evdev}"
        SETXKBMAP="setxkbmap -layout $XKB_LAYOUT -rules $XKB_RULES -model $XKB_MODEL -option $XKB_OPTIONS"
        sed -i "/^Exec=/s|=.*|=$SETXKBMAP|" configs/setxkbmap.desktop
        mkdir -p $CHROOT_DIR/home/$USER_NAME/.config/autostart/
        print_info "set xkeyboard config in ~/.config/autostart/setxkbmap.desktop"
        /bin/cp -f configs/setxkbmap.desktop $CHROOT_DIR/home/$USER_NAME/.config/autostart/   
        touch .xkeyboard_synced
    fi

    print_info "chrooting $CHROOT_DIR"
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
    mount --rbind --make-rslave --read-only / $CHROOT_DIR/parentroot
    mount --rbind --make-rslave $HOST_HOME_DIR $CHROOT_DIR/home/host-user
    mount --bind /tmp $CHROOT_DIR/tmp

    if [ x$ON_DEVICE == x"1" ]; then
        # wayland
        mount --bind /run/display $CHROOT_DIR/run/display

        # libhybris
        mount --bind --make-slave --read-only /system $CHROOT_DIR/parentroot/system

        # audio muted by default
        if [ x$ENABLE_AUDIO == x"1" ] && [ -d $CHROOT_DIR/run/user/100000 ]; then
            mkdir -p $CHROOT_DIR/run/user/100000/pulse
            mount --bind /run/user/100000/pulse $CHROOT_DIR/run/user/100000/pulse
            mount --bind /var/lib/dbus $CHROOT_DIR/var/lib/dbus
            if [ -d $CHROOT_DIR/home/$USER_NAME/.config/pulse ]; then
                mount -o bind,ro /home/$HOST_USER/.config/pulse $CHROOT_DIR/home/$USER_NAME/.config/pulse
            fi
        fi
        # If mounted image is stored in sdcard then --rbind triggers some kind of bug in kernel or umount tool so it's impossible to release loopX device.
        #mount --rbind --make-slave /run/media/$HOST_USER $CHROOT_DIR/media/sdcard || true
        for dir in $(ls /run/media/$HOST_USER); do
            if mountpoint --quiet "/run/media/$HOST_USER/$dir" ; then
                mkdir -p $CHROOT_DIR/media/sdcard/$dir
                mount --bind --make-slave "/run/media/$HOST_USER/$dir" $CHROOT_DIR/media/sdcard/$dir || true
            fi
        done
    fi
}

# /var/run -> /run
ubu_cleanup_procs() {
    if [ -f $CHROOT_DIR/run/sshd.pid ]; then
        kill "$(cat $CHROOT_DIR/run/sshd.pid)" || true
        /bin/rm -f $CHROOT_DIR/run/sshd.pid
    fi

    if [ -f $CHROOT_DIR/run/dbus/pid ]; then
        kill "$(cat $CHROOT_DIR/run/dbus/pid)" || true
        /bin/rm -f $CHROOT_DIR/run/dbus/pid
    fi

    if [ -f $CHROOT_DIR/run/display/wayland-ubu-1.lock ]; then
        kill "$(ubu_qxcompositor_pid)" || true
        /bin/rm -f $CHROOT_DIR/run/display/wayland-ubu-1.lock
    fi

    if [ -f $CHROOT_DIR/tmp/.X0-lock ]; then
        /bin/rm -f $CHROOT_DIR/tmp/.X0-lock
    fi

    fuser -kv $CHROOT_DIR || true
    sleep 1
}

ubu_umount() {
    umount $CHROOT_DIR/media/sdcard/*  || true
    #rm -fd $CHROOT_DIR/media/sdcard/*
    umount -R $CHROOT_DIR || true
    for dir in $(mount | grep $CHROOT_DIR | cut -f 3 -d" " | sort -r); do
        print_info "unmounting $dir"
        if [ x$1 == x"force" ]; then
            umount -flR $CHROOT_DIR || true
        else
            umount -R $dir || true
        fi
    done
    umount -R $CHROOT_DIR || true
}

# Clean up
ubu_cleanup() {
    print_info "Active processes: "
    fuser -v $CHROOT_DIR 2>&1 | grep -ve USER -ve '^&' || true
    if [ x$1 == x"force" ]; then
        ubu_cleanup_procs
        ubu_umount
        CNT="$(fuser -v $CHROOT_DIR 2>/dev/null | wc -w)"
        if [ $CNT -gt 0 ]; then
            sfossdk_cleanup_procs
            print_info "$CHROT_DIR busy!\nDo you want to force unmount (y/N)?"
            read yn
            if [ x$yn == "xy" ]; then
                ubu_umount force
            else
                ubu_umount
            fi
        fi
    else
        # unmount only if nothing was started by the user
        CNT="$(fuser -v $CHROOT_DIR 2>/dev/null | wc -w)"
        if [ $CNT -gt 1 ]; then
            # mount, unionfs, #dbus-daemon (dbus-launch), sshd, systemd-logind ?
            RES="$(fuser -v $CHROOT_DIR 2>&1 || true)"
            if [ $CNT -eq 4 ] && [ -n "$(echo $RES | grep 'unionfs.*systemd-logind')" ] || \
               [ $CNT -eq 3 ] && [ -n "$(echo $RES | grep unionfs)" ] || \
               [ $CNT -le 2 ]; then
                ubu_cleanup_procs
                ubu_umount
            else
                print_info "chroot in use"
            fi
        else # only mount
            ubu_cleanup_procs
            ubu_umount
        fi    
    fi

    if [ -z "$(mount | grep $CHROOT_DIR)" ]; then
        print_info "Unmount completed"
    fi
}

ubu_mount_img() {
    mount -t ext4 -o loop,noatime $CHROOT_IMG $CHROOT_DIR
}

ubu_ssh_pid() {
    pgrep -u root -x -f '/usr/sbin/sshd -p 2228'
}

ubu_qxcompositor_pid() {
    pgrep -u $HOST_USER -f 'qxcompositor --wayland-socket-name ../../display/wayland-ubu-1'
}

uburc_sed() {
    sed -i $1 scripts/dotuburc
    sed -i $1 $CHROOT_DIR/home/$USER_NAME/.uburc
}


