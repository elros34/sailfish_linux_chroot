#!/bin/bash
set -e
source ubu-variables.sh
source ubu-common.sh
eval $TRACE_CMD

_ubu_chroot() {
    if [ $# -gt 0 ]; then
        ubu_chroot /usr/share/ubu_chroot/chroot.sh $@
    else
        ubu_chroot /usr/share/ubu_chroot/chroot.sh su $USER_NAME -l
    fi    
}

if [ -z "$(ubu_ssh_pid)" ]; then # first start
    if [ $(whoami) != "root" ]; then
        print_info "chroot not ready, run me as root"
        exit 10
    else # root
        MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
        if [ $MOUNTS -gt 5 ]; then
            print_info "$CHROOT_DIR already mounted"
            _ubu_chroot $@
            ubu_cleanup
        elif [ $MOUNTS -gt 0 ]; then
            print_info "$CHROOT_DIR partially mounted"
            ./ubu-close.sh
        else
            ubu_mount_img
            ubu_mount
            _ubu_chroot $@
            ubu_cleanup          
        fi
    fi
else # chroot ready, ssh to it
    ubu_ssh $@
fi



