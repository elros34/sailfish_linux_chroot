#!/bin/bash
set -e
source ubu-variables.sh
source ubu-common.sh
eval $TRACE_CMD


if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

if [ $# -gt 0 ]; then
    if [ "$1" == "--all" ] || [ "$1" == "-a" ]; then
        /bin/rm -f .xkeyboard_synced
        /bin/rm -f .screen_dimensions_set
        ubu_host_user_exe "ssh-keygen -R [localhost]:2228" || true
    else
        print_info "supported arguments: --all, -a"
        exit 1
    fi
fi


MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -gt 5 ]; then
    ubu_chroot /usr/share/ubu_chroot/chroot.sh true
else
    if [ $MOUNTS -gt 0 ]; then
        print_info "$CHROOT_DIR partially mounted"
        ./ubu-close.sh
    fi
    ubu_mount_img
    ubu_mount
    ubu_chroot /usr/share/ubu_chroot/chroot.sh true
fi

print_info "Synchronization completed"

