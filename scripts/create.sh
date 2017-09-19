#!/bin/bash
set -e
#set -x
export PS1="[\u@ubu-chroot: \w]# "

useradd nemo -u 100000 -U -m
groupmod -g 100000 nemo

# Make network connections works if CONFIG_ANDROID_PARANOID_NETWORK is enabled
groupadd -g 3003 inet
usermod -aG inet nemo 
usermod -g inet _apt

su - nemo -c "mkdir -p /home/nemo/.config/ ; #mkdir /home/nemo/.config/pulse"

cat <<'EOF' >> /home/nemo/.bashrc
export $(dbus-launch)
mkdir -p /tmp/runtime-nemo
export TERM=xterm-256color
export XDG_RUNTIME_DIR=/tmp/runtime-nemo
export WAYLAND_DISPLAY=../../run/display/wayland-0
export EGL_PLATFORM=wayland
export QT_WAYLAND_FORCE_DPI=96
export DISPLAY=:0
DISPLAY_RES=$(cat /sys/class/graphics/fb0/modes | grep -Eo '[0-9]+x[0-9]+')
export DISPLAY_WIDTH=$(echo $DISPLAY_RES | cut -d x -f 1)
export DISPLAY_HEIGHT=$(echo $DISPLAY_RES | cut -d x -f 2)
EOF

echo 'export PS1="[\u@ubu-chroot: \w]# "' >> /root/.bashrc 
echo 'export PS1="[\u@ubu-chroot: \w]# "' >> /home/nemo/.bashrc 

apt update
apt upgrade -y
apt install -y vim dialog locales command-not-found kbd bash-completion sed
apt clean

dpkg-reconfigure locales

# libhybris
apt install -y libhybris unionfs-fuse
update-alternatives --set arm-linux-gnueabihf_egl_conf /usr/lib/arm-linux-gnueabihf/libhybris-egl/ld.so.conf 
ldconfig

exit

