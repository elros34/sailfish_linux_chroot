#!/bin/bash
set -e
#set -x
source /usr/share/ubu_chroot/ubu_variables.sh
export PS1="[\u@ubu-chroot: \w]# "

useradd $USER_NAME -u 100000 -U -m
groupmod -g 100000 $USER_NAME

# Make network connections works if CONFIG_ANDROID_PARANOID_NETWORK is enabled
groupadd -g 3003 inet
usermod -aG inet $USER_NAME
usermod -g inet _apt

su $USER_NAME -c "mkdir -p /home/$USER_NAME/.config/ ; #mkdir /home/$USER_NAME/.config/pulse"

cat <<'EOF' >> /home/$USER_NAME/.bashrc

# ubu_chroot variables
export $(dbus-launch)
mkdir -p /tmp/runtime-$USER_NAME
export TERM=xterm-256color
export XDG_RUNTIME_DIR=/tmp/runtime-$USER_NAME
export WAYLAND_DISPLAY=../../run/display/wayland-0
export EGL_PLATFORM=wayland
export QT_WAYLAND_FORCE_DPI=96
export DISPLAY=:0
DISPLAY_RES=$(cat /sys/class/graphics/fb0/modes | grep -Eo '[0-9]+x[0-9]+')
export DISPLAY_WIDTH=$(echo $DISPLAY_RES | cut -d x -f 1)
export DISPLAY_HEIGHT=$(echo $DISPLAY_RES | cut -d x -f 2)
EOF

echo 'export PS1="[\u@ubu-chroot: \w]# "' >> /root/.bashrc 
echo 'export PS1="[\u@ubu-chroot: \w]# "' >> /home/$USER_NAME/.bashrc 

apt update
apt upgrade -y
apt install -y vim dialog locales command-not-found kbd bash-completion sed
apt clean

dpkg-reconfigure locales

# libhybris
apt install -y libhybris unionfs-fuse
update-alternatives --set arm-linux-gnueabihf_egl_conf /usr/lib/arm-linux-gnueabihf/libhybris-egl/ld.so.conf 
ldconfig

echo "Image created. Now you can run ubu_install.sh"
exit

