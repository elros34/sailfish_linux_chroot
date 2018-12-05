#!/bin/bash
# Do not edit, copied from sailfish_ubu_chroot
set -e
source /usr/share/ubu_chroot/ubu-variables.sh
eval $TRACE_CMD

source ~/.uburc

if [ $(whoami) == "root" ]; then
    print_info "Don't run me as root!"
    exit 1
fi

echo "arguments: $@"

if [ $# -eq 0 ];then
    print_info "supported compositors: kwin, weston, qxcompositor, xfce4, chromium"
	exit 1
fi

if [ x$1 == "xkwin" ]; then
	kwin_wayland --width $DISPLAY_WIDTH --height $DISPLAY_HEIGHT --xwayland &
elif [ x$1 == "xweston" ]; then
	weston
elif [ x$1 == "xxfce4" ] || [ x$1 == "xxfce" ]; then
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland -nolisten tcp &
	while [ ! -f /tmp/.X0-lock ]; do
		sleep 1
	done
	startxfce4
elif [ x$1 == "xqxcompositor" ]; then
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland -nolisten tcp &
	while [ ! -f /tmp/.X0-lock ]; do
		sleep 1
	done
elif [ x$1 == "xchromium" ] || [ x$1 == "xchromium-browser" ]; then #only for hw keyboard devices
    shift
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland -nolisten tcp &
	while [ ! -f /tmp/.X0-lock ]; do
		sleep 1
	done
    #matchbox-window-manager -use_titlebar no &
	chromium-browser --window-size=$DISPLAY_HEIGHT,$DISPLAY_WIDTH --window-position=0,0 $@
    #TODO: onboard --layout=Phone, autoshow/hide for hw keyboard less devices
else
	print_info "supported compositors: kwin, weston, qxcompositor"
	$@
fi



