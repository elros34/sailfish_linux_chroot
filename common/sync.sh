#!/bin/bash
set -e
source ./variables.sh
source ./common.sh
# only for install helper function
source ../common/create.sh
eval $TRACE_CMD


if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

if [ $# -gt 0 ]; then
    if [ "$1" == "--all" ] || [ "$1" == "-a" ]; then
        /bin/rm -f .xkeyboard_synced
        /bin/rm -f .screen_dimensions_set
        sfchroot_host_user_exe "ssh-keygen -R [localhost]:$SSH_PORT" || true
        sfchroot_createsh_install_helper
    else
        print_msg "Usage: $0 [OPTION]"
        print_msg "Options: \n  --all, -a   sync also xkeyboard, screen dimensions, known_hosts and helper script"
        exit 1
    fi
fi


MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -gt 5 ]; then
    sfchroot_prepare_and_chroot /usr/share/sfchroot/chroot.sh true
else
    if [ $MOUNTS -gt 0 ]; then
        print_info "$CHROOT_DIR partially mounted"
        ./close.sh
    fi
    sfchroot_mount_img
    sfchroot_mount
    sfchroot_prepare_and_chroot /usr/share/sfchroot/chroot.sh true
fi

print_info "Synchronization completed"

