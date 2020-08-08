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
elif [ "$1" == "chromium" ] || [ "$1" == "chromium-browser" ]; then #only for hw keyboard devices
    shift
    start_xwayland
    if [ "$QXCOMPOSITOR_PORTRAIT" == "1" ]; then
        # chromium ignores small width value?
        matchbox-window-manager -use_titlebar no &
        W="$(bc <<< $DISPLAY_WIDTH/$CHROMIUM_SCALE)"
        H="$(bc <<< $DISPLAY_HEIGHT/$CHROMIUM_SCALE)"
        [ "$CHROMIUM_MATCHBOX_KEYBOARD" == "1" ] && matchbox-keyboard &
    else
        W="$(bc <<< $DISPLAY_HEIGHT/$CHROMIUM_SCALE)"
        H="$(bc <<< $DISPLAY_WIDTH/$CHROMIUM_SCALE)"
    fi
    # FIXME
    nohup sh -c "sleep 6; $(pcregrep -o1 'Exec=(.*)' ~/.config/autostart/setxkbmap.desktop)" > /dev/null &
    chromium-browser --force-device-scale-factor=$CHROMIUM_SCALE --window-size=$W,$H --window-position=0,0 $@ || true
    #TODO: onboard --layout=Phone, autoshow/hide for hw keyboard less devices
else
    print_msg "Usage: $0 (kwin | weston | xfce4 | xwayland [application])"
    $@
fi



