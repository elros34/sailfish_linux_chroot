#!/bin/bash
set -e
#set -x
source /usr/share/ubu_chroot/ubu_variables.sh

if [ $# -eq 0 ]
then
    echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1
fi

if [ $1 == "kwin" ]
then

    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.kde4/
    sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-1|WAYLAND_DISPLAY=../../run/display/wayland-0|" /home/$USER_NAME/.bashrc
    
	# xhost, kwin
	# plasma-active-default-settings: provide kdeglobals needed by kwin_wayland. Without kdeglobals file kwin is unusable slow
	apt install x11-xserver-utils kwin-wayland xwayland kwin-wayland-backend-wayland kwin-wayland-backend-x11 plasma-active-default-settings -y --no-install-recommends 
	apt clean
	
    ln -fs /usr/share/kservicetypes5/kwineffect.desktop /usr/share/kservicetypes5/kwin-effect.desktop 
    ln -fs /usr/share/kservicetypes5/kwinscript.desktop /usr/share/kservicetypes5/kwin-script.desktop

	
elif [ $1 == "lxde" ] 
then
	# lxde, xprop
    apt install -y lxde x11-utils lxterminal 
    apt clean
    # Disable screensaver
    rm /etc/xdg/autostart/light-locker.desktop
    rm /etc/xdg/autostart/gnome-screensaver.desktop

elif [ $1 == "weston" ]
then
	apt install -y weston
	apt clean
	sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-1|WAYLAND_DISPLAY=../../run/display/wayland-0|" /home/$USER_NAME/.bashrc
	export WAYLAND_DISPLAY=../../run/display/wayland-0
elif [ $1 == "qxcompositor" ]
then
    # For dependecies
    apt install -y xwayland
    apt clean
    mkdir -p /usr/local/share/X11/xkb/rules
    ln -fs /usr/share/X11/xkb/rules/evdev /usr/local/share/X11/xkb/rules/
    ln -fs /usr/bin/xkbcomp /usr/local/bin/
	sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-0|WAYLAND_DISPLAY=../../run/display/wayland-1|" /home/$USER_NAME/.bashrc
	export WAYLAND_DISPLAY=../../run/display/wayland-1

elif [ $1 == "glibc" ]
then
	echo "libc6 hold" | dpkg --set-selections
	cd /glibc
	dpkg -i libc6_2.23*.deb libc6-armel_2.23*.deb libc-bin_2.23*.deb locales_2.23*.deb multiarch-support_2.23*.deb
	cd -

else
	echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1

fi



