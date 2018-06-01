#!/bin/bash
# Do not edit, copied from sailfish_ubu_chroot
set -e
#set -x

source ~/.uburc

if [ $(whoami) == "root" ]; then
    echo "Don't run me as root!"
    exit 1
fi

echo "arguments: $@"

if [ $# -eq 0 ];then
    echo "supported compositors: kwin, weston, qxcompositor, xfce4, chromium"
	exit 1
fi

if [ x$1 == "xkwin" ]; then
	kwin_wayland --width $DISPLAY_WIDTH --height $DISPLAY_HEIGHT --xwayland &
elif [ x$1 == "xweston" ]; then
	weston
elif [ x$1 == "xxfce4" ]; then
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland +extension GLX +iglx -nolisten tcp &
	while [ ! -f /tmp/.X0-lock ]; do
		sleep 1
	done
	startxfce4
elif [ x$1 == "xqxcompositor" ]; then
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland +extension GLX +iglx -nolisten tcp &
	while [ ! -f /tmp/.X0-lock ]; do
		sleep 1
	done
elif [ x$1 == "xchromium" ]; then #only for hw keyboard devices
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland +extension GLX +iglx -nolisten tcp &
	while [ ! -f /tmp/.X0-lock ]; do
		sleep 1
	done
	chromium-browser --window-size=$DISPLAY_HEIGHT,$DISPLAY_WIDTH --window-position=0,0
else
	echo "supported compositors: kwin, weston, qxcompositor"
	$@
fi



