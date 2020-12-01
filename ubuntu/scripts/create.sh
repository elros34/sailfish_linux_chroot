#!/bin/bash
set -e
source /usr/share/sfchroot/variables.sh
eval $TRACE_CMD

export PS1="[\u@$DISTRO_PREFIX-chroot: \w]# "

useradd $USER_NAME --uid 100000 -U -m --shell /bin/bash
groupmod -g 100000 $USER_NAME
chown $USER_NAME:$USER_NAME /home/$USER_NAME
echo "Password in chroot"
passwd $USER_NAME
dpkg-reconfigure bash

# Make network connection works if CONFIG_ANDROID_PARANOID_NETWORK is enabled
groupadd -g 3003 inet
usermod -aG inet $USER_NAME
usermod -g inet _apt

su $USER_NAME -c "mkdir -p /home/$USER_NAME/.config/pulse"
# pgrep --uid 100000 dbus-daemon
install -o $USER_NAME -g $USER_NAME /etc/skel/.bashrc /home/$USER_NAME/
install -o $USER_NAME -g $USER_NAME /etc/skel/.profile /home/$USER_NAME/
echo 'source ~/.'"$DISTRO_PREFIX"'rc' >> /home/$USER_NAME/.bashrc
echo '[ -n "$DBUS_SESSION_BUS_PID" ] && kill "$DBUS_SESSION_BUS_PID" || true' >> /home/$USER_NAME/.bash_logout
echo 'export PS1="[\u@ubu-chroot: \w]# "' >> /root/.bashrc 
echo 'CD_FILE=/dev/shm/sfchroot-ubu-cd' >> /root/.bashrc 
echo '[ -x $CD_FILE ] && source $CD_FILE && rm -f $CD_FILE || true' >> /root/.bashrc 
mkdir -p /run/user/100000
chmod 700 /run/user/100000
chown $USER_NAME:$USER_NAME /run/user/100000

# 19.04 is EOL
grep -q disco-updates /etc/apt/sources.list && sed -i 's|ports.ubuntu.com/ubuntu-ports|old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list
apt update
apt upgrade -y
apt install -y vim dialog locales command-not-found kbd bash-completion sed dbus-x11 apt-file psmisc sudo openssh-server apt-utils unionfs-fuse bc rsync pcregrep
apt-file update
usermod -aG sudo $USER_NAME
dpkg-reconfigure locales

# ssh
mkdir /run/sshd
chmod 0755 /run/sshd
cat >> /etc/ssh/sshd_config <<EOF 
Match User $USER_NAME
    ChrootDirectory /
    AllowTCPForwarding no
EOF

chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh/

# Remove useless prompts
/bin/rm -f /etc/update-motd.d/{60-unminimize,10-help-text}

apt clean

touch /usr/share/sfchroot/.create_finished


