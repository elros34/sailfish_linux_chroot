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
source ./common.sh

sfchroot_createsh_img_and_extract() {
    if [ "$(df -TP . | awk '/dev/{print $2}')" == "vfat" ]; then
        print_info "Using fat partition for bash scripts is probably bad idea"
        sleep 3
    fi

    if [ $(whoami) != "root" ]; then
        print_info "run me as root!"
        exit 1
    fi
 
    [ -z "$(which rsync)" ] && sfchroot_pkcon install -y rsync
    [ -z "$(which sudo)" ] && sfchroot_pkcon install -y sudo
    
    # Never mount /dev twice
    if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 5 ]; then
        print_info "$CHROOT_DIR already mounted"
        ./close.sh
        exit 1
    fi

    FREE_SPACE="$(df -h $(dirname $CHROOT_IMG) | tail -n1 | awk '{print $4}')"
    print_info "$FREE_SPACE space available ($IMG_SIZE needed), continue? [Y/n]"
    read yn
    if [ "$yn" == "n" ]; then
        ./close.sh
        exit 1
    fi

    if [ -f $CHROOT_IMG ]; then
        print_info "$CHROOT_IMG exists, do you want to overwrite it? [y/N]"
        read yn
        if [ "$yn" == "y" ]; then
            sfchroot_cleanup
            /bin/rm -f $CHROOT_IMG
        else
            ./close.sh
            exit 1
        fi
    fi

    print_info "Creating image..."
    dd if=/dev/zero bs=1 count=0 seek=$IMG_SIZE of=$CHROOT_IMG
    chown $HOST_USER:$HOST_USER $CHROOT_IMG
    mkfs.ext4 -O ^has_journal,^metadata_csum,^64bit $CHROOT_IMG
    e2fsck -yf $CHROOT_IMG
    mkdir -p $CHROOT_DIR
    echo "$CHROOT_DIR" > .copied
    chown $HOST_USER:$HOST_USER .copied
    
    sfchroot_mount_img
    touch $CHROOT_DIR/.nomedia
    touch $CHROOT_DIR/.chroot
    ln -fs $CHROOT_DIR $DISTRO
    chown $HOST_USER:$HOST_USER $DISTRO

    if [[ "$(uname -r)" == "3.0"* ]]; then
        TARGET_URL=$TARGET_URL2
    else
        print_info "Your kernel version is $(uname -r). Do you want to use kernel 3.0 compatible tarball? [y/N]"
        read yn
        if [ "$yn" == "y" ]; then
            TARGET_URL=$TARGET_URL2
        fi 
    fi

    TARBALL=$(basename $TARGET_URL)
    if [ ! -e $TARBALL ] || [ $(du -m $TARBALL | cut -f1) -lt 20 ]; then
        rm -f $TARBALL
        curl -O -J -L $TARGET_URL
        chown $HOST_USER:$HOST_USER $TARBALL
    fi
    
    if [ $(du -m $TARBALL | cut -f1) -lt 20 ]; then
        print_info "Can't download tarball"
        exit 1
    fi

    print_info "Extracting..."
    if [[ $TARBALL == *"tar.gz" ]]; then
        tar --numeric-owner -pxzf $TARBALL -C $CHROOT_DIR/
    elif [[ $TARBALL == *"tar.7z" ]]; then
        sfchroot_pkcon install -y p7zip-full
        7z x -so $TARBALL | tar --numeric-owner -pxf - -C $CHROOT_DIR/
    fi

    ARCH=$(uname -m)
    if [[ $ARCH == "x86"* ]]; then
        sfchroot_pkcon install -y qemu-user-static 
        cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin/
    fi
}

sfchroot_createsh_prepare_dirs() {
    mkdir -p $CHROOT_DIR/usr/share/sfchroot/
    mkdir -p $CHROOT_DIR/home/host-user
    chown $HOST_USER:$HOST_USER $CHROOT_DIR/home/host-user
    mkdir -p $CHROOT_DIR/home/$USER_NAME
    mkdir -p $CHROOT_DIR/run/display
    mkdir -p $CHROOT_DIR/media/sdcard
    mkdir -p $CHROOT_DIR/run/dbus # /var/run -> /run
    mkdir -p $CHROOT_DIR/var/lib/dbus
    mkdir -p $CHROOT_DIR/parentroot
}

sfchroot_createsh_prepare_ssh() {
    mkdir -p $CHROOT_DIR/home/$USER_NAME/.ssh/
    touch $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys
    chmod 0600 $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys
    sfchroot_host_user_exe "ssh-keygen -R [localhost]:$SSH_PORT" || true
}

sfchroot_createsh_chroot() {
    sfchroot_mount
    sfchroot_prepare_and_chroot /usr/share/sfchroot/create.sh
    # test connection and update known_hosts
    sfchroot_chroot /usr/share/sfchroot/chroot.sh true
    sfchroot_host_user_exe "ssh -p $SSH_PORT -o StrictHostKeyChecking=no $USER_NAME@localhost true" || true
    sfchroot_cleanup
}

sfchroot_createsh_install_desktops() {
    if [ "$ON_DEVICE" == "1" ]; then
        sfchroot_install_desktop "$DISTRO_PREFIX-shell.desktop"
        sfchroot_install_desktop "$DISTRO_PREFIX-close.desktop"
    fi
}

sfchroot_createsh_install_qdevel-su() {
    [ "$ON_DEVICE" == "0" ] && return 
    if [ -z "$(which qdevel-su)" ]; then
        sfchroot_pkcon install -y qdevel-su
        if [ -z "$(which qdevel-su)" ] ; then
            sfchroot_add_repo_and_install qdevel-su "http://repo.merproject.org/obs/home:/elros34:/sailfishapps"
        fi
    fi
}

sfchroot_createsh() {
    sfchroot_createsh_img_and_extract
    sfchroot_createsh_prepare_dirs
    sfchroot_createsh_prepare_ssh
    sfchroot_createsh_chroot
    sfchroot_createsh_install_desktops
}

sfchroot_createsh_install_helper() {
    shPath=/usr/local/bin/"$DISTRO_PREFIX"chroot.sh
    sed "s|SFCHROOT_PATH|$PWD|g" "$DISTRO_PREFIX"chroot.sh > $shPath
    echo $shPath >> .copied
    chmod a+x $shPath
}




