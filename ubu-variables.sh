IMG_SIZE=3900M
TARGET_URL=http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.1-base-armhf.tar.gz
TARGET_URL2=https://github.com/elros34/sailfish_ubu_chroot/releases/download/v0.1/ubuntu-base-18.04.1-base-kernel-3.0.0-armhf.tar.gz
CHROOT_IMG=ubuntu-18.04-armhf.ext4
# Change to "set -x" for debugging
export TRACE_CMD="set +x"
export USER_NAME=user
export CHROOT_DIR=/.ubuntu
export HOST_USER=nemo
export HOST_HOME_DIR=/home/$HOST_USER
export ENABLE_AUDIO=0 # don't use
export SYNC_XKEYBOARD=1 # .xkeyboard_synced

print_info() {
    echo -e "\n\e[93m=== $1 ===\n\e[0m"
}

