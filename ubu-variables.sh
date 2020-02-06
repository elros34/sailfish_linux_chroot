IMG_SIZE=3900M
TARGET_URL=http://cdimage.ubuntu.com/ubuntu-base/releases/19.04/release/ubuntu-base-19.04-base-armhf.tar.gz
TARGET_URL2=https://github.com/elros34/sailfish_ubu_chroot/releases/download/v0.2/ubuntu-base-19.04-base-kernel-3.0.0-armhf.tar.gz
CHROOT_IMG=ubuntu-19.04-armhf.ext4
# Change to "set -x" for debugging
export TRACE_CMD="set +x"
export USER_NAME=user
export CHROOT_DIR=/.ubuntu
export ENABLE_AUDIO=0 # don't use
export SYNC_XKEYBOARD=1 # .xkeyboard_synced

print_info() {
    echo -e "\n\e[93m=== $1 ===\n\e[0m"
}

print_msg() {
    echo -e "\n\e[93m$1\n\e[0m"
}
