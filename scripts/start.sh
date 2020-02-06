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
    #matchbox-window-manager -use_titlebar no &
    H="$(bc <<< $DISPLAY_HEIGHT/$CHROMIUM_SCALE)"
    W="$(bc <<< $DISPLAY_WIDTH/$CHROMIUM_SCALE)"
    # FIXME
    nohup sh -c "sleep 6; $(pcregrep -o1 'Exec=(.*)' ~/.config/autostart/setxkbmap.desktop)" > /dev/null &
    chromium-browser --force-device-scale-factor=$CHROMIUM_SCALE --window-size=$H,$W --window-position=0,0 $@
    #TODO: onboard --layout=Phone, autoshow/hide for hw keyboard less devices
else
    print_msg "Usage: $0 (kwin | weston | xfce4 | xwayland [application])"
    $@
fi



