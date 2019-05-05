#!/bin/bash
set -e
source ubu-common.sh
eval $TRACE_CMD

if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "supported arguments: kwin, lxde, xfce4, weston, qxcompositor, glibc (for 3.0.0 kernel), libhybris, chromium-browser"
    exit 1
fi

copy_configs() {
    if [ x$1 == "xkwin" ]; then
        cp -f configs/kwinrc $CHROOT_DIR/home/$USER_NAME/.config/
        uburc_sed "s|display/wayland-ubu-1|display/wayland-0|"
    elif [ x$1 == "xlxde" ]; then
        echo $1
    elif [ x$1 == "xxfce4" ]; then
        echo $1
        sed -i "s!UBU_CHROOT_PATH!$(pwd)!" desktop/ubu-xfce.desktop
        /bin/cp -f desktop/ubu-xfce.desktop /usr/share/applications/
        update-desktop-database
    elif [ x$1 == "xweston" ]; then
        cp -f configs/weston.ini $CHROOT_DIR/home/$USER_NAME/.config/
        uburc_sed "s|display/wayland-ubu-1|display/wayland-0|"
    elif [ x$1 == "xqxcompositor" ]; then
        if [ $ON_DEVICE -eq 1 ]; then
            pkcon install -y qxcompositor || true
            print_info "https://build.merproject.org/package/show/home:elros34:sailfishapps/qxcompositor"
        fi
        mkdir -p $CHROOT_DIR/usr/local/bin/
        cp xwayland/Xwayland $CHROOT_DIR/usr/local/bin/
           mkdir -p $CHROOT_DIR/debs/xwayland
        cp xwayland/x11-xkb-utils_*_armhf.deb $CHROOT_DIR/debs/xwayland
        uburc_sed "s|display/wayland-0|display/wayland-ubu-1|"
        mkdir -p $CHROOT_DIR/home/$USER_NAME/.config/autostart/
        /bin/cp -f configs/xhost.desktop $CHROOT_DIR/home/$USER_NAME/.config/autostart/
        
    elif [ x$1 == "xglibc" ]; then
           mkdir -p $CHROOT_DIR/debs/glibc
        /bin/cp -r -f glibc/*.deb $CHROOT_DIR/debs/glibc/
    elif [ x$1 == "xlibhybris" ]; then
           mkdir -p $CHROOT_DIR/debs/libhybris
        /bin/cp -r -f libhybris/*.deb $CHROOT_DIR/debs/libhybris/
    elif [ x$1 == "xchromium-browser" ]; then
           echo $1
        sed -i "s!UBU_CHROOT_PATH!$(pwd)!" desktop/ubu-chromium-browser.desktop
        /bin/cp -f desktop/ubu-chromium-browser.desktop /usr/share/applications/
        update-desktop-database
    fi
}

MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -gt 5 ]; then
    copy_configs $1
    echo "$CHROOT_DIR already mounted"
    echo "chrooting"
    ubu_chroot /usr/share/ubu_chroot/install.sh $@
    ubu_cleanup
    exit
elif [ $MOUNTS -gt 0 ]; then
    echo "$CHROOT_DIR partially mounted"
    ./ubu-close.sh
    exit 1
fi

ubu_mount_img
ubu_mount
copy_configs $1
ubu_chroot /usr/share/ubu_chroot/install.sh $@
ubu_cleanup


