#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
source ./common.sh
eval $TRACE_CMD

if [ $(whoami) != "root" ]; then
    print_info "run me as root!"
    exit 1
fi

if [ $# -eq 0 ]; then
    print_msg "Usage: $0 (kwin | lxde | xfce4 | weston | qxcompositor | glibc (for 3.0.0 kernel) | libhybris | chromium-browser | qtwayland)"
    exit 1
fi


copy_configs() {
    for opt in $@; do
        case $opt in
        "kwin")
            cp -f configs/kwinrc $CHROOT_DIR/home/$USER_NAME/.config/
            sfchrootrc_sed "s|display/wayland-$DISTRO_PREFIX-1|display/wayland-0|"
            ;;
        "xfce4")
            sfchroot_install_desktop "$DISTRO_PREFIX-xfce.desktop"
            ;;
        "weston")
            cp -f configs/weston.ini $CHROOT_DIR/home/$USER_NAME/.config/
            sfchrootrc_sed "s|display/wayland-$DISTRO_PREFIX-1|display/wayland-0|"
            ;;
        "qxcompositor")
            if [ $ON_DEVICE -eq 1 ]; then
                if [ -z "$(which qxcompositor)" ] ; then
                    sfchroot_pkcon install -y qxcompositor
                    if [ -z "$(which qxcompositor)" ] ; then
                        sfchroot_add_repo_and_install qxcompositor "http://repo.merproject.org/obs/home:/elros34:/sailfishapps"
                    fi
                fi
            fi
            mkdir -p $CHROOT_DIR/usr/local/bin/
            install -m 755 -o root xwayland/Xwayland $CHROOT_DIR/usr/local/bin/
            sfchrootrc_sed "s|display/wayland-0|display/wayland-$DISTRO_PREFIX-1|"
            mkdir -p $CHROOT_DIR/home/$USER_NAME/.config/autostart/
            /bin/cp -f configs/xhost.desktop $CHROOT_DIR/home/$USER_NAME/.config/autostart/
            ;;
        "chromium-browser")
            sfchroot_install_desktop "$DISTRO_PREFIX-chromium-browser.desktop"
            ;;
        "glibc"|"libhybris"|"qtwayland"|"lxde")
            echo $opt
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
    sfchroot_chroot /usr/share/sfchroot/install.sh $@
    sfchroot_cleanup
    exit
elif [ $MOUNTS -gt 0 ]; then
    echo "$CHROOT_DIR partially mounted"
    ./close.sh
    exit 1
fi

sfchroot_mount_img
sfchroot_mount
copy_configs $@
sfchroot_prepare_and_chroot /usr/share/sfchroot/install.sh $@
sfchroot_cleanup


