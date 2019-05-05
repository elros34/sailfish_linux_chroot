#!/bin/bash
set -e
source ubu-common.sh
eval $TRACE_CMD

if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

# Never mount /dev twice
if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 5 ]; then
    print_info "$CHROOT_DIR already mounted"
    ./ubu-close.sh
    exit 1
fi

FREE_SPACE="$(df -h $(dirname $CHROOT_IMG) | tail -n1 | awk '{print $4}')"
print_info "$FREE_SPACE space available ($IMG_SIZE needed), continue (Y/n)?"
read yn
if [ x$yn == "xn" ]; then
    ./ubu-close.sh
    exit 1
fi

if [ -f $CHROOT_IMG ]; then
    print_info "$CHROOT_IMG exists, do you want to overwrite it (y/N)?"
    read yn
    if [ x$yn == "xy" ]; then
        ubu_cleanup
        /bin/rm -f $CHROOT_IMG
    else
        ./ubu-close.sh
        exit 1
    fi
fi

print_info "Creating image..."
dd if=/dev/zero bs=1 count=0 seek=$IMG_SIZE of=$CHROOT_IMG
mkfs.ext4 -O ^has_journal $CHROOT_IMG
mkdir -p $CHROOT_DIR
ubu_mount_img

if [[ "$(uname -r)" == "3.0"* ]]; then
    TARGET_URL=$TARGET_URL2
else
    print_info "Use kernel 3.0 compatible tarball (y/N)?"
    read yn
    if [ x$yn == "xy" ]; then
        TARGET_URL=$TARGET_URL2
    fi 
fi

TARBALL=$(basename $TARGET_URL)
if [ ! -e $TARBALL ] || [ $(du -m $TARBALL | cut -f1) -lt 20 ]; then
    rm -f $TARBALL
    curl -O -J -L $TARGET_URL
    chown $HOST_USER:$HOST_USER $TARBALL
fi

print_info "Extracting..."
tar --numeric-owner -pxzf $TARBALL -C $CHROOT_DIR/

ARCH=$(uname -m)
if [[ $ARCH == "x86"* ]]; then
    pkcon install -y qemu-user-static || true
    cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin/
fi

mkdir -p $CHROOT_DIR/usr/share/ubu_chroot/
mkdir -p $CHROOT_DIR/home/host-user
chown $HOST_USER:$HOST_USER $CHROOT_DIR/home/host-user
mkdir -p $CHROOT_DIR/home/$USER_NAME
mkdir -p $CHROOT_DIR/run/display
mkdir -p $CHROOT_DIR/media/sdcard
mkdir -p $CHROOT_DIR/run/dbus # /var/run -> /run
mkdir -p $CHROOT_DIR/var/lib/dbus
mkdir -p $CHROOT_DIR/system
mkdir -p $CHROOT_DIR/parentroot
ln -sf /system/vendor $CHROOT_DIR/vendor

mkdir -p $CHROOT_DIR/home/$USER_NAME/.ssh/
touch $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys
chmod 0600 $CHROOT_DIR/home/$USER_NAME/.ssh/authorized_keys

ubu_mount
ubu_chroot /usr/share/ubu_chroot/create.sh
# test connection and update known_hosts
ubu_chroot /usr/share/ubu_chroot/chroot.sh true
ubu_host_user_exe "ssh -p 2228 -o StrictHostKeyChecking=no $USER_NAME@localhost true" || true
ubu_cleanup

if [ x$ON_DEVICE == x"1" ]; then
    sed -i "s!UBU_CHROOT_PATH!$(pwd)!g" desktop/ubu-shell.desktop
    sed -i "s!UBU_CHROOT_PATH!$(pwd)!g" desktop/ubu-close.desktop
    /bin/cp -f desktop/ubu-shell.desktop /usr/share/applications/
    /bin/cp -f desktop/ubu-close.desktop /usr/share/applications/
    update-desktop-database
fi

print_info "Image created. Now you can run ubu-install.sh"

