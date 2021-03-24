#!/bin/bash
source ./common.sh
eval $TRACE_CMD


CHROOT_DIR=${1:-"$CHROOT_DIR"}

if ! mountpoint -q $CHROOT_DIR; then
    print_info "$CHROOT_DIR not mounted"
    rm -f .closing
    exit 0
fi

if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 10
fi

sfchroot_cleanup force

