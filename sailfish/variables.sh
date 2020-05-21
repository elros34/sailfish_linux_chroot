#!/bin/bash
[ -n "$VARIABLES_SH" ] && return
export "VARIABLES_SH=1"

export IMG_SIZE=2G
export TARGET_URL=http://releases.sailfishos.org/sdk/targets/Sailfish_OS-3.3.0.16-Sailfish_SDK_Target-armv7hl.tar.7z
export TARGET_URL2=https://github.com/elros34/sailfish_linux_chroot/releases/download/v0.3/Sailfish_OS-3.3.0.16-kernel-3.0.0-Sailfish_SDK_Target-armv7hl.tar.7z
export CHROOT_IMG=sailfish-3.3.0.16-armhf.ext4
export DISTRO=sailfish
export DISTRO_PREFIX=sfos
export USER_NAME=nemo
export SSH_PORT=2229
# Change to "set -x" for debugging
export TRACE_CMD="set +x"
export CHROOT_DIR="/.$DISTRO"
export ENABLE_AUDIO=0 # don't use
export SYNC_XKEYBOARD=0 # .xkeyboard_synced

print_info() {
    echo -e "\n\e[93m=== $1 ===\n\e[0m"
}
export -f print_info

print_msg() {
    echo -e "\n\e[93m$1\n\e[0m"
}
export -f print_msg
