#!/bin/bash
# Do not edit in chroot, copied from sailfish_linux_chroot
set -e
source /usr/share/sfchroot/variables.sh
eval $TRACE_CMD

if [ $# -eq 0 ]; then
    print_msg "Usage: $0 (kwin | lxde | weston | qxcompositor | glibc | chromium-browser)"
    exit 1
fi

for opt in $@; do
    case $opt in
    "kwin")
        # xhost, kwin
        apt install -y --no-install-recommends x11-xserver-utils kwin-wayland xwayland kwin-wayland-backend-wayland kwin-wayland-backend-x11
        ##ln -fs /usr/share/kservicetypes5/kwineffect.desktop /usr/share/kservicetypes5/kwin-effect.desktop 
        ##ln -fs /usr/share/kservicetypes5/kwinscript.desktop /usr/share/kservicetypes5/kwin-script.desktop
        ;;
    "lxde")
        # lxde, xprop
        apt install -y lxde x11-utils lxterminal 
        ;;
    "xfce4")
        apt install -y xfce4 xfce4-goodies
        update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

        print_info "Tips for xfce:"
        print_msg "Increase dpi in 'Settings Manager/Appearance/Fonts/DPI'"
        print_msg "Select Default-hdpi theme in 'Settings Manager/Window Manager/Style/Theme'"
        print_msg "Disable compositing in 'Settings Manager/Window Manager Tweaks/Compositor'\n"
        ;;
    "weston")
        apt install -y weston
        ;;
    "qxcompositor")
        # For dependecies
        apt install -y xwayland xsel libegl1
        mkdir -p /usr/local/share/X11/xkb/rules
        ln -fs /usr/share/X11/xkb/rules/evdev /usr/local/share/X11/xkb/rules/
        ln -fs /usr/bin/xkbcomp /usr/local/bin/
        ;;
    "glibc")
        echo "libc6 hold" | dpkg --set-selections
        echo "libc-bin hold" | dpkg --set-selections
        cd /debs/glibc
        dpkg -i libc6_2*.deb libc6-armel_2*.deb libc-bin_2*.deb locales_2*.deb multiarch-support_2*.deb
        ;;
    "libhybris")
        apt install -y libwayland-client0 libwayland-server0 libegl1 libgles2
        cd /debs/libhybris
        tar --numeric-owner -xzf libhybris*.tar.gz -C /
        update-alternatives --set arm-linux-gnueabihf_egl_conf /usr/lib/arm-linux-gnueabihf/libhybris-egl/ld.so.conf || true
        echo -e "# libhybris\n/usr/lib/arm-linux-gnueabihf/libhybris-egl" > /etc/ld.so.conf.d/01-libhybris.conf
        ldconfig
        ;;
    "chromium-browser")
        apt install -y chromium-browser
        update-alternatives --set x-www-browser /usr/bin/chromium-browser
        ;;
    *)
        print_info "Wrong arg $opt"
        ;;
    esac
done

# Disable screensaver
rm -f /etc/xdg/autostart/{light-locker.desktop,gnome-screensaver.desktop,xscreensaver.desktop,mate-screensaver.desktop} 2> /dev/null

apt clean

