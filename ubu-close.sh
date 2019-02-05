#!/bin/bash
source ubu-common.sh
eval $TRACE_CMD

CHROOT_DIR=${1:-"/.ubuntu"}

ubu_cleanup force



