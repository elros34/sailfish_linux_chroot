#!/bin/bash
#set -x
source ubu-variables.sh
source ubu-common.sh

CHROOT_DIR=${1:-"/.ubuntu"}

echo "chroot dir: $CHROOT_DIR"

ubu_cleanup force



