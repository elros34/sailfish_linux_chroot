#!/bin/bash
set -e
source ubu-common.sh
eval $TRACE_CMD

if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

if [ $# -eq 0 ]; then
    print_msg "Usage: $0 (kwin | lxde | xfce4 | weston | qxcompositor | glibc (for 3.0.0 kernel) | libhybris | chromium-browser)"
    exit 1
fi


copy_configs() {
    for opt in $@; do
        case $opt in
        "kwin")
            cp -f configs/kwinrc $CHROOT_DIR/home/$USER_NAME/.config/
            uburc_sed "s|display/wayland-ubu-1|display/wayland-0|"
            ;;
        "lxde")
            echo $opt
            ;;
        "xfce4")
            ubu_install_desktop "ubu-xfce.desktop"
            ;;
        "weston")
            cp -f configs/weston.ini $CHROOT_DIR/home/$USER_NAME/.config/
            uburc_sed "s|display/wayland-ubu-1|display/wayland-0|"
            ;;
        "qxcompositor")
            if [ $ON_DEVICE -eq 1 ]; then
                pkcon install -y qxcompositor || true
                if [ ! -x /usr/bin/qxcompositor ]; then 
                    print_info "QXCompositor could not be installed: https://build.merproject.org/package/show/home:elros34:sailfishapps/qxcompositor"
                    exit 1
                fi
            fi
            mkdir -p $CHROOT_DIR/usr/local/bin/
            install -m 755 -o root xwayland/Xwayland $CHROOT_DIR/usr/local/bin/
            uburc_sed "s|display/wayland-0|display/wayland-ubu-1|"
            mkdir -p $CHROOT_DIR/home/$USER_NAME/.config/autostart/
            /bin/cp -f configs/xhost.desktop $CHROOT_DIR/home/$USER_NAME/.config/autostart/
            ;;
        "glibc")
            mkdir -p $CHROOT_DIR/debs/glibc
            /bin/rm -f $CHROOT_DIR/debs/glibc/*.deb
            /bin/cp -f glibc/*.deb $CHROOT_DIR/debs/glibc/
            ;;
        "libhybris")
            mkdir -p $CHROOT_DIR/debs/libhybris
            /bin/rm -f $CHROOT_DIR/debs/libhybris/*.tar.gz
            /bin/cp -f libhybris/*.tar.gz $CHROOT_DIR/debs/libhybris/
            ;;
        "chromium-browser")
            ubu_install_desktop "ubu-chromium-browser.desktop"
            if [ "$ON_DEVICE" == "1" ] && [ -f "$HOST_HOME_DIR/.local/share/applications/mimeinfo.cache" ]; then
                print_info "Dirty hack detected, x-scheme-handler/https will not work correctly!"
            fi
            ;;
        *)
            print_info "Wrong arg $opt"
            ;;
        esac
    done
}

MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
if [ $MOUNTS -gt 5 ]; then
    copy_configs $@
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
copy_configs $@
ubu_chroot /usr/share/ubu_chroot/install.sh $@
ubu_cleanup


