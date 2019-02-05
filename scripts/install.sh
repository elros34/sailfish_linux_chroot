#!/bin/bash
# Do not edit, copied from sailfish_ubu_chroot
set -e
source /usr/share/ubu_chroot/ubu-variables.sh
eval $TRACE_CMD

if [ $# -eq 0 ]; then
    echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc, chromium-browser"
	exit 1
fi

if [ x$1 == "xkwin" ]; then
	# xhost, kwin
	# plasma-active-default-settings: provide kdeglobals needed by kwin_wayland. Without kdeglobals file kwin is unusable slow
	apt install -y --no-install-recommends x11-xserver-utils kwin-wayland xwayland kwin-wayland-backend-wayland kwin-wayland-backend-x11
    #ln -fs /usr/share/kservicetypes5/kwineffect.desktop /usr/share/kservicetypes5/kwin-effect.desktop 
    #ln -fs /usr/share/kservicetypes5/kwinscript.desktop /usr/share/kservicetypes5/kwin-script.desktop
	
elif [ x$1 == "xlxde" ]; then
	# lxde, xprop
    apt install -y lxde x11-utils lxterminal 
elif [ x$1 == "xxfce4" ]; then
    apt install -y xfce4 xfce4-goodies || true
    sed -i 's!set -e!#set -e!' /var/lib/dpkg/info/blueman.postinst || true
    apt -f install
    update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

    print_info "Tips for xfce:"
    echo "Increase dpi in 'Settings Manager/Appearance/Fonts/DPI'"
    echo "Select Default-hdpi theme in 'Settings Manager/Window Manager/Style/Theme'"
    echo -e "Disable compositing in 'Settings Manager/Window Manager Tweaks/Compositor'\n"
elif [ x$1 == "xweston" ]; then
    apt install -y weston
elif [ x$1 == "xqxcompositor" ]; then
    # For dependecies
    apt install -y xwayland
    dpkg -i /debs/xwayland/x11-xkb-utils_*_armhf.deb
    mkdir -p /usr/local/share/X11/xkb/rules
    ln -fs /usr/share/X11/xkb/rules/evdev /usr/local/share/X11/xkb/rules/
    ln -fs /usr/bin/xkbcomp /usr/local/bin/

elif [ x$1 == "xglibc" ]; then
	echo "libc6 hold" | dpkg --set-selections
    echo "libc-bin hold" | dpkg --set-selections
	cd /debs/glibc
	dpkg -i libc6_2.27*.deb libc6-armel_2.27*.deb libc-bin_2.27*.deb locales_2.27*.deb multiarch-support_2.27*.deb

elif [ x$1 == "xlibhybris" ]; then
    apt install -y libwayland-client0 libwayland-server0 libegl1 libgles2
	cd /debs/libhybris
	dpkg -i libhybris-common1_*.deb libhybris_0*.deb libhybris-test_*.deb libhybris-utils_*.deb libandroid-properties1_*.deb libhardware2_*.deb libmedia1_*.deb
    update-alternatives --set arm-linux-gnueabihf_egl_conf /usr/lib/arm-linux-gnueabihf/libhybris-egl/ld.so.conf 
    #FIXME
    sed -i 's!# Multiarch support!# Multiarch support\n/usr/lib/arm-linux-gnueabihf/libhybris-egl!' /etc/ld.so.conf.d/arm-linux-gnueabihf.conf
    ldconfig

elif [ x$1 == "xchromium-browser" ]; then
    apt install chromium-browser #matchbox-window-manager

else
	echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1
fi

# Disable screensaver
rm -f /etc/xdg/autostart/{light-locker.desktop,gnome-screensaver.desktop,xscreensaver.desktop,mate-screensaver.desktop} 2> /dev/null

apt clean

