#!/bin/bash
# Do not edit, copied from sailfish_ubu_chroot
set -e
#set -x
source /usr/share/ubu_chroot/ubu-variables.sh

if [ $# -eq 0 ]; then
    echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1
fi

if [ x$1 == "xkwin" ]; then
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.kde4/
    sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-1|WAYLAND_DISPLAY=../../run/display/wayland-0|" /home/$USER_NAME/.bashrc
    
	# xhost, kwin
	# plasma-active-default-settings: provide kdeglobals needed by kwin_wayland. Without kdeglobals file kwin is unusable slow
	apt install x11-xserver-utils kwin-wayland xwayland kwin-wayland-backend-wayland kwin-wayland-backend-x11 plasma-active-default-settings -y --no-install-recommends 
	
    ln -fs /usr/share/kservicetypes5/kwineffect.desktop /usr/share/kservicetypes5/kwin-effect.desktop 
    ln -fs /usr/share/kservicetypes5/kwinscript.desktop /usr/share/kservicetypes5/kwin-script.desktop

	
elif [ x$1 == "xlxde" ]; then
	# lxde, xprop
    apt install -y lxde x11-utils lxterminal 
    # Disable screensaver
    rm /etc/xdg/autostart/light-locker.desktop || true
    rm /etc/xdg/autostart/gnome-screensaver.desktop || true
elif [ x$1 == "xxfce4" ]; then
    apt install -y xfce4 
elif [ x$1 == "xweston" ]; then
	apt install -y weston
	sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-1|WAYLAND_DISPLAY=../../run/display/wayland-0|" /home/$USER_NAME/.bashrc
	export WAYLAND_DISPLAY=../../run/display/wayland-0
elif [ x$1 == "xqxcompositor" ]; then
    # For dependecies
    apt install -y xwayland
    mkdir -p /usr/local/share/X11/xkb/rules
    ln -fs /usr/share/X11/xkb/rules/evdev /usr/local/share/X11/xkb/rules/
    ln -fs /usr/bin/xkbcomp /usr/local/bin/
	sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-0|WAYLAND_DISPLAY=../../run/display/wayland-1|" /home/$USER_NAME/.bashrc
	export WAYLAND_DISPLAY=../../run/display/wayland-1

elif [ x$1 == "xglibc" ]; then
	echo "libc6 hold" | dpkg --set-selections
	cd /glibc
	dpkg -i libc6_2.24*.deb libc6-armel_2.24*.deb libc-bin_2.24*.deb locales_2.24*.deb multiarch-support_2.24*.deb
	#cd /libhybris
	#dpkg -i libhybris-common1_*.deb libhybris_0*.deb

else
	echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1
fi

apt clean

