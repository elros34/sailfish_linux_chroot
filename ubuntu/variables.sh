#!/bin/bash
[ -n "$VARIABLES_SH" ] && return
export "VARIABLES_SH=1"

export IMG_SIZE=3900M
export TARGET_URL=http://bridgman.canonical.com/releases/ubuntu-base/releases/disco/release/ubuntu-base-19.04-base-armhf.tar.gz
export TARGET_URL2=https://github.com/elros34/sailfish_linux_chroot/releases/download/v0.2/ubuntu-base-19.04-base-kernel-3.0.0-armhf.tar.gz
export CHROOT_IMG=ubuntu-19.04-armhf.ext4
export DISTRO=ubuntu
export DISTRO_PREFIX=ubu
export USER_NAME=user
export SSH_PORT=2228
# Change to "set -x" for debugging
export TRACE_CMD="set +x"
export CHROOT_DIR="/.$DISTRO"
export ENABLE_AUDIO=0 # don't use
export SYNC_XKEYBOARD=1 # .xkeyboard_synced

print_info() {
    echo -e "\n\e[93m=== $1 ===\n\e[0m"
}
export -f print_info

print_msg() {
    echo -e "\n\e[93m$1\n\e[0m"
}
export -f print_msg
