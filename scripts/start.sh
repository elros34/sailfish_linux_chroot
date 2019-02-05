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

start_xwayland() {
    export WAYLAND_DISPLAY=../../display/wayland-ubu-1
    if [ -f /tmp/.X0-lock ]; then
        print_info "Xwayland already running"
    else
        Xwayland -nolisten tcp &
        i=10
        while [ $i -gt 0 ]; do
            if [ -f /tmp/.X0-lock ]; then
                break
            fi
            sleep 1
            ((i--))
        done
    fi
}

if [ x$1 == "xkwin" ]; then
	kwin_wayland --width $DISPLAY_WIDTH --height $DISPLAY_HEIGHT --xwayland &
elif [ x$1 == "xweston" ]; then
	weston
elif [ x$1 == "xxfce4" ] || [ x$1 == "xxfce" ]; then
    start_xwayland
	startxfce4
elif [ x$1 == "xqxcompositor" ]; then
    start_xwayland
elif [ x$1 == "xchromium" ] || [ x$1 == "xchromium-browser" ]; then #only for hw keyboard devices
    shift
    start_xwayland
    #matchbox-window-manager -use_titlebar no &
    H="$(bc <<< $DISPLAY_HEIGHT/$CHROMIUM_SCALE)"
    W="$(bc <<< $DISPLAY_WIDTH/$CHROMIUM_SCALE)"
	chromium-browser --force-device-scale-factor=$CHROMIUM_SCALE --window-size=$H,$W --window-position=0,0 $@
    #TODO: onboard --layout=Phone, autoshow/hide for hw keyboard less devices
else
	print_info "supported compositors: kwin, weston, qxcompositor"
	$@
fi



