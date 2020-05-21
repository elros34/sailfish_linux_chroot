#!/bin/bash
set -e

source ./variables.sh
source ./common.sh
eval $TRACE_CMD

_sfchroot_chroot() {
    if [ $# -gt 0 ]; then
        sfchroot_chroot /usr/share/sfchroot/chroot.sh $@
    else
        sfchroot_chroot /usr/share/sfchroot/chroot.sh su $USER_NAME -l
    fi    
}

CMD_FILE="/dev/shm/sfchroot-$DISTRO_PREFIX-user-cmd"
/bin/rm -f $CMD_FILE
if [[ "$1" == "--open-dir="* ]]; then
    DIR="$(echo $1 | cut -d= -f2)"
    shift
    if [[ $DIR == "$HOST_HOME_DIR"* ]]; then
        DIR=$(echo $DIR | sed "s|$HOST_HOME_DIR|/home/host-user|")
    fi
    echo "cd $DIR" > $CMD_FILE
    chmod a+rwx $CMD_FILE
    chown 100000:100000 $CMD_FILE
fi

if [ -z "$(sfchroot_ssh_pid)" ]; then # first start
    if [ $(whoami) != "root" ]; then
        print_info "chroot not ready, run me as root"
        exit 10
    else # root
        MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
        if [ $MOUNTS -gt 5 ]; then
            print_info "$CHROOT_DIR already mounted"
            _sfchroot_chroot $@
            sfchroot_cleanup
        elif [ $MOUNTS -gt 0 ]; then
            print_info "$CHROOT_DIR partially mounted"
            ./close.sh
        else
            sfchroot_mount_img
            sfchroot_mount
            _sfchroot_chroot $@
            sfchroot_cleanup          
        fi
    fi
else # chroot ready, ssh to it
    sfchroot_ssh $@
fi

