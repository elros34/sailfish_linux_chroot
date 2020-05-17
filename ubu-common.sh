#!/bin/bash
#
# Copyright (C) 2017 Preflex
# Copyright (C) 2017-2020 elros34
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

set -e
source ubu-variables.sh
eval $TRACE_CMD

export ON_DEVICE=0
if [ -f /etc/sailfish-release ] || [ -f /parentroot/etc/sailfish-release ]; then
    ON_DEVICE=1
fi

export HOST_USER="$(logname 2>/dev/null)"
if [ -z "$HOST_USER" ]; then
    HOST_USER="$(loginctl --no-legend list-users | awk '!/root/ {print $2}' | head -n1)"
fi
export HOST_HOME_DIR=/home/$HOST_USER

# Warning: "Last login .. pts" message in device but not in ssh (util-linux 2.33+git1)
ubu_host_user_exe() {
    if [ $(whoami) == "root" ]; then
        su $HOST_USER -l -c "$@"
    else
        $@
    fi
}

ubu_host_dconf() {
    LANG=C su $HOST_USER -l -c "dconf read $1" | grep -v "Last login" || true
}

ubu_ssh() {
    if [ $# -gt 0 ]; then
        ubu_host_user_exe "ssh -p 2228 -o StrictHostKeyChecking=no $USER_NAME@localhost $(printf '%q ' $@)"
    else
        ubu_host_user_exe "ssh -p 2228 -o StrictHostKeyChecking=no $USER_NAME@localhost $@"
    fi
}

ubu_ssh_tty() {
    ubu_host_user_exe "ssh -t -p 2228 -o StrictHostKeyChecking=no $USER_NAME@localhost $(printf '%q ' $@)"
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

    if ! grep -q "$(cat $HOST_HOME_DIR/.ssh/id_rsa.pub)" $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys ; then
        cat $HOST_HOME_DIR/.ssh/id_rsa.pub >> $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys
    fi

    # Make sure ChrootDirectory has right permissions to meet sshd requirements
    if [ "$(stat -c "%a %G:%U" $CHROOT_DIR)" != "755 root:root" ]; then
        chown root:root $CHROOT_DIR
        chmod 755 $CHROOT_DIR
    fi

    if [ "$ON_DEVICE" == "1" ] && [ ! -f .screen_dimensions_set ]; then
        WIDTH="$(ubu_host_dconf /lipstick/screen/primary/width)"
        HEIGHT="$(ubu_host_dconf /lipstick/screen/primary/height)"
        if [ -n "$WIDTH" ]; then
            uburc_sed "/^export DISPLAY_WIDTH=/s|=.*|=$WIDTH|"
            uburc_sed "/^export DISPLAY_HEIGHT=/s|=.*|=$HEIGHT|"
            touch .screen_dimensions_set
        fi
    fi

    # hw keyboard
    if [ "$ON_DEVICE" == "1" ] && [ "$SYNC_XKEYBOARD" == "1" ] && [ -d $CHROOT_DIR/usr/share/X11/xkb ] && [ ! -f .xkeyboard_synced ] && [ -f $CHROOT_DIR/usr/share/ubu_chroot/.create_finished ]; then
        /bin/cp -rf /usr/share/X11/xkb $CHROOT_DIR/usr/share/X11/
        XKB_LAYOUT="$(ubu_host_dconf /desktop/lipstick-jolla-home/layout)"
        XKB_MODEL="$(ubu_host_dconf /desktop/lipstick-jolla-home/model)"
        XKB_RULES="$(ubu_host_dconf /desktop/lipstick-jolla-home/rules)"
        XKB_OPTIONS="$(ubu_host_dconf /desktop/lipstick-jolla-home/options)"
        # default values
        : "${XKB_LAYOUT:=us}"
        : "${XKB_MODEL:=jollasbj}"
        : "${XKB_RULES:=evdev}"
        SETXKBMAP="setxkbmap -layout $XKB_LAYOUT -rules $XKB_RULES -model $XKB_MODEL -option $XKB_OPTIONS"
        sed -i "/^Exec=/s|=.*|=$SETXKBMAP|" configs/setxkbmap.desktop
        mkdir -p $CHROOT_DIR/home/$USER_NAME/.config/autostart/
        # FIXME
        print_info "set xkeyboard config in ~/.config/autostart/setxkbmap.desktop"
        /bin/cp -f configs/setxkbmap.desktop $CHROOT_DIR/home/$USER_NAME/.config/autostart/   
        chown -R 100000:100000 $CHROOT_DIR/home/$USER_NAME/.config/autostart/
        touch .xkeyboard_synced
    fi

    print_info "chrooting $CHROOT_DIR"
    chroot $CHROOT_DIR /usr/bin/env -i \
        HOME=/root TERM="$TERM" PS1='[\u@ubu-chroot: \w]# ' \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games \
        /bin/bash --login $@
}

ubu_mount() {
    [ ! -d $CHROOT_DIR ] && mkdir $CHROOT_DIR
    mount --bind /dev $CHROOT_DIR/dev
    mount --bind -o mode=620 /dev/pts $CHROOT_DIR/dev/pts
    mount --bind /dev/shm $CHROOT_DIR/dev/shm
    mount --bind /sys $CHROOT_DIR/sys
    mount --bind /proc $CHROOT_DIR/proc
    mount --bind --make-slave --read-only / $CHROOT_DIR/parentroot
    mount --bind --make-slave $HOST_HOME_DIR $CHROOT_DIR/home/host-user
    mount --bind /tmp $CHROOT_DIR/tmp

    if [ "$ON_DEVICE" == "1" ]; then
        # wayland
        mount --bind /run/display $CHROOT_DIR/run/display

        # libhybris
        if [ -d /system ]; then
            mkdir -p $CHROOT_DIR/system
            mount --bind --make-slave --read-only /system $CHROOT_DIR/parentroot/system
            if [ -L /vendor ]; then
                [ -d $CHROOT_DIR/vendor ] && rmdir $CHROOT_DIR/vendor
                ln -sf /parentroot/system/vendor $CHROOT_DIR/vendor
            elif [ -d /vendor ]; then
                [ -L $CHROOT_DIR/vendor ] && unlink $CHROOT_DIR/vendor
                mkdir -p $CHROOT_DIR/vendor
                mount --bind --make-slave --read-only /vendor $CHROOT_DIR/parentroot/vendor
            fi
        fi

        # audio muted by default
        if [ "$ENABLE_AUDIO" == "1" ] && [ -d $CHROOT_DIR/run/user/100000 ]; then
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

    print_info "killing:"
    fuser -kv --mount --ismountpoint $CHROOT_DIR || true
}

ubu_umount() {
    umount $CHROOT_DIR/media/sdcard/*  || true
    rmdir $CHROOT_DIR/media/sdcard/* || true
    umount -dR $CHROOT_DIR || true
    for dir in $(mount | grep $CHROOT_DIR | cut -f 3 -d" " | sort -r); do
        print_info "unmounting $dir"
        if [ "$1" == "force" ]; then
            umount -flR $CHROOT_DIR || true
        else
            umount -R $dir || true
        fi
    done

    if mountpoint -q $CHROOT_DIR; then
        fuser -kv --mount --ismountpoint $CHROOT_DIR || true
        umount -dR $CHROOT_DIR || true
    fi
}

# Clean up
ubu_cleanup() {
    if ! mountpoint -q $CHROOT_DIR ; then
        print_info "$CHROOT_DIR not mounted"
        return 0
    fi
    print_info "Active processes: "
    fuser -v --mount --ismountpoint $CHROOT_DIR 2>&1 | grep -ve USER -ve '^$' || true
    if [ "$1" == "force" ]; then
        ubu_cleanup_procs
        ubu_umount
        sleep 1
        CNT="$(fuser -v --ismountpoint $CHROOT_DIR 2>/dev/null | wc -w)"
        if [ $CNT -gt 0 ]; then
            ubu_cleanup_procs
            print_info "$CHROOT_DIR busy!\nDo you want to force unmount (y/N)?"
            read yn
            if [ "$yn" == "y" ]; then
                ubu_umount force
            else
                ubu_umount
            fi
        fi
    else
        # unmount only if nothing was started by the user
        CNT="$(fuser -v --ismountpoint $CHROOT_DIR 2>/dev/null | wc -w)"
        if [ $CNT -gt 1 ]; then
            # mount, unionfs, #dbus-daemon (dbus-launch), sshd, systemd-logind ?
            RES="$(fuser -v --ismountpoint $CHROOT_DIR 2>&1 || true)"
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

    if [ -n "$(losetup --associated $CHROOT_IMG)" ]; then
        print_info "$CHROOT_IMG still in use!"
    fi     
}

ubu_mount_img() {
    mount -t ext4 -o loop,noatime $CHROOT_IMG $CHROOT_DIR
}

ubu_ssh_pid() {
    pgrep -u root -f '/usr/sbin/sshd -p 2228'
}

ubu_qxcompositor_pid() {
    pgrep -u $HOST_USER -f 'qxcompositor --wayland-socket-name ../../display/wayland-ubu-1'
}

uburc_sed() {
    sed -i "$@" scripts/dotuburc
    sed -i "$@" $CHROOT_DIR/home/$USER_NAME/.uburc
}

ubu_install_desktop() {
    ICON="$(echo $1 | sed 's|desktop$|png|')"
    cd desktop
    find -name "$ICON" | cut -c3- | xargs -I ICON_PATH /bin/cp -f ICON_PATH /usr/share/ICON_PATH
    cd -
    sed "s|UBU_CHROOT_PATH|$(pwd)|g" "desktop/$1" > "/usr/share/applications/$1"
    update-desktop-database 2>&1 | grep -v x-maemo-highlight || true
}



