#!/bin/bash
# Do not edit in chroot, copied from sailfish_linux_chroot
set -e
source /usr/share/sfchroot/variables.sh
eval $TRACE_CMD

source ~/.uburc

if [ $(whoami) == "root" ]; then
    print_info "Don't run me as root!"
    exit 1
fi

start_xwayland() {
    export WAYLAND_DISPLAY=../../display/wayland-$DISTRO_PREFIX-1
    if [ -f /tmp/.X0-lock ]; then
        print_info "Xwayland already running"
    else
        Xwayland -nolisten tcp &
        for i in {1..10}; do
            [ -f /tmp/.X0-lock ] && break
            sleep 1
        done
    fi
}

if [ "$1" == "kwin" ]; then
    kwin_wayland --width $DISPLAY_WIDTH --height $DISPLAY_HEIGHT --xwayland --wayland-display ../../display/wayland-0 --socket ../../display/wayland-kwin &
elif [ "$1" == "weston" ]; then
    weston
elif [ "$1" == "xfce4" ] || [ "$1" == "xfce" ]; then
    start_xwayland
    startxfce4
elif [ "$1" == "xwayland" ]; then
    shift
    start_xwayland
    $@ &
    exec bash
elif [ "$1" == "chromium" ] || [ "$1" == "chromium-browser" ]; then
    shift
    start_xwayland
    matchbox-window-manager -use_titlebar no &
    if [ "$CHROMIUM_ONBOARD_KEYBOARD" == "1" ]; then
        onboard --quirks=compiz --theme=Droid --layout=Phone --size=${DISPLAY_WIDTH}x300 &
    fi
    # FIXME
    nohup sh -c "sleep 6; $(pcregrep -o1 'Exec=(.*)' ~/.config/autostart/setxkbmap.desktop)" > /dev/null &
    chromium-browser --force-device-scale-factor=$CHROMIUM_SCALE --window-position=0,0 $@ || true
else
    print_msg "Usage: $0 (kwin | weston | xfce4 | xwayland [application])"
    $@
fi



