#!/bin/bash
set -e
#set -x

if [ $1 == "kwin" ]
then

    chown -R nemo:nemo /home/nemo/.kde4/
    sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-1|WAYLAND_DISPLAY=../../run/display/wayland-0|" /home/nemo/.bashrc
    
	apt update
	# xhost, kwin
	# plasma-active-default-settings: provide kdeglobals needed by kwin_wayland. Without kdeglobals file kwin is unusable slow
	apt install x11-xserver-utils kwin-wayland xwayland kwin-wayland-backend-wayland kwin-wayland-backend-x11 plasma-active-default-settings -y --no-install-recommends 
	
    ln -fs /usr/share/kservicetypes5/kwineffect.desktop /usr/share/kservicetypes5/kwin-effect.desktop 
    ln -fs /usr/share/kservicetypes5/kwinscript.desktop /usr/share/kservicetypes5/kwin-script.desktop

	
elif [ $1 == "lxde" ] 
then
	# lxde, xprop
    apt install lxde-core x11-utils lxterminal -y --no-install-recommends

elif [ $1 == "weston" ]
then
	apt install -y weston
	sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-1|WAYLAND_DISPLAY=../../run/display/wayland-0|" /home/nemo/.bashrc
	export WAYLAND_DISPLAY=../../run/display/wayland-0
elif [ $1 == "qxcompositor" ]
then
    # For dependecies
    apt install xwayland
    mkdir -p /usr/local/share/X11/xkb/rules
    ln -fs /usr/share/X11/xkb/rules/evdev /usr/local/share/X11/xkb/rules/
    ln -fs /usr/bin/xkbcomp /usr/local/bin/
	sed -i "s|WAYLAND_DISPLAY=../../run/display/wayland-0|WAYLAND_DISPLAY=../../run/display/wayland-1|" /home/nemo/.bashrc
	export WAYLAND_DISPLAY=../../run/display/wayland-1

elif [ $1 == "glibc" ]
then
	echo "libc6 hold" | dpkg --set-selections

else
	echo "supported arguments: kwin, lxde, weston, qxcompositor, glibc"
	exit 1

fi



