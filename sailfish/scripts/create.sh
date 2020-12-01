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

# Make network connection works if CONFIG_ANDROID_PARANOID_NETWORK is enabled
groupadd -g 3003 inet
usermod -aG inet $USER_NAME

su $USER_NAME -c "mkdir -p /home/$USER_NAME/.config/pulse"
install -o $USER_NAME -g $USER_NAME /etc/skel/.bashrc /home/$USER_NAME/
install -o $USER_NAME -g $USER_NAME /etc/skel/.bash_profile /home/$USER_NAME/
echo 'source ~/.'"$DISTRO_PREFIX"'rc' >> /home/$USER_NAME/.bashrc
echo '[ -n "$DBUS_SESSION_BUS_PID" ] && kill "$DBUS_SESSION_BUS_PID" || true' >> /home/$USER_NAME/.bash_logout
echo 'export PS1="[\u@sfos-chroot: \w]# "' >> /root/.bashrc
echo 'CD_FILE=/dev/shm/sfchroot-sfos-cd' >> /root/.bashrc 
echo '[ -x $CD_FILE ] && source $CD_FILE && rm -f $CD_FILE || true' >> /root/.bashrc
mkdir -p /run/user/100000
chmod 700 /run/user/100000
chown $USER_NAME:$USER_NAME /run/user/100000

zypper ref -f
zypper dup -y
zypper --non-interactive in spectacle git vim make gcc gcc-c++ nano sed sudo openssh-server bc strace rsync ncurses
# Add repo with wget and other tools
ssu ar obs-nielnielsen http://repo.merproject.org/obs/home:/nielnielsen/sailfish_latest_armv7hl/
zypper --non-interactive in wget
# Looks like broken currently so disable it
ssu dr obs-nielnielsen
zypper clean
usermod -aG wheel $USER_NAME
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/sfchroot-wheel
chmod 0440 /etc/sudoers.d/sfchroot-wheel

# ssh
mkdir /run/sshd
chmod 0755 /run/sshd
cat >> /etc/ssh/sshd_config <<EOF 
Match User $USER_NAME
    ChrootDirectory /
    AllowTCPForwarding no
Match all

# chacha20-poly1305 doesn't work in sailfish: message authentication code incorrect
Ciphers -chacha20-poly1305@openssh.com
EOF

# sshd_config: AllowGroups sailfish-system root
usermod -aG sailfish-system $USER_NAME

#ssh-keygen -A
/usr/sbin/sshd-hostkeys
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh/

touch /usr/share/sfchroot/.create_finished


