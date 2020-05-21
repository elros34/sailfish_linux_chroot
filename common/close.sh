#!/bin/bash
source ./common.sh
eval $TRACE_CMD

CHROOT_DIR=${1:-"$CHROOT_DIR"}
    
MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -eq 0 ]; then
    print_info "$CHROOT_DIR not mounted"
    exit 0
fi

if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

sfchroot_cleanup force

