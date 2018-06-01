#!/bin/bash
set -e
#set -x
source /usr/share/ubu_chroot/ubu-variables.sh

touch /.nomedia
export PS1="[\u@ubu-chroot: \w]# "

useradd $USER_NAME -u 100000 -U -m
chown $USER_NAME:$USER_NAME /home/$USER_NAME
groupmod -g 100000 $USER_NAME

# Make network connection works if CONFIG_ANDROID_PARANOID_NETWORK is enabled
groupadd -g 3003 inet
usermod -aG inet $USER_NAME
usermod -g inet _apt

su $USER_NAME -c "mkdir -p /home/$USER_NAME/.config/ ; #mkdir /home/$USER_NAME/.config/pulse"

# pgrep --uid 100000 dbus-daemon
echo 'source .uburc' >> /home/$USER_NAME/.bashrc
echo 'kill $DBUS_SESSION_BUS_PID || true' >> /home/$USER_NAME/.bash_logout
echo 'export PS1="[\u@ubu-chroot: \w]# "' >> /root/.bashrc 

# 17.04 is doomed, 17.10 is broken (locale-gen) and 18.04 doesn't have libhybris (need more work)
sed -i 's!http://ports.ubuntu.com/ubuntu-ports/!http://old-releases.ubuntu.com/ubuntu/!g' /etc/apt/sources.list

apt update
apt upgrade -y
apt install -y vim dialog locales command-not-found kbd bash-completion sed dbus-x11 apt-file psmisc sudo
usermod -aG sudo $USER_NAME

#FIXME
echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

dpkg-reconfigure locales

# libhybris
apt install -y libhybris unionfs-fuse
update-alternatives --set arm-linux-gnueabihf_egl_conf /usr/lib/arm-linux-gnueabihf/libhybris-egl/ld.so.conf 
ldconfig
apt clean

echo "Image created. Now you can run ubu-install.sh"

