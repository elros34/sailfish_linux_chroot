#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))
source ./common.sh
eval $TRACE_CMD

if [ $# -eq 0 ]; then
    print_msg "Usage: $0 (xfce4 | chromium | qxcompositor | xwayland [application])"
    exit 1
fi

run_qxcompositor() {
    if [ "$1" == "qxcompositor" ] || [ "$1" == "xfce4" ] || [ "$1" == "chromium" ] || [ "$1" == "chromium-browser" ] || [ "$1" == "xwayland" ]; then
        if [ "$ON_DEVICE" == "1" ]; then
            # TODO: multi instances
            if [ -n "$(sfchroot_qxcompositor_pid)" ]; then
                print_info "qxcompositor already running"
                sfchroot_host_user_exe "invoker -s --type=silica-qt5 qxcompositor"
                return 0
            fi

            sfchroot_host_user_exe "invoker -s --type=silica-qt5 qxcompositor --wayland-socket-name ../../display/wayland-$DISTRO_PREFIX-1 -u $USER_NAME -p $SSH_PORT" &

            while [ ! -f /run/display/wayland-$DISTRO_PREFIX-1.lock ]; do
                sleep 1
            done
        fi
    else
        exit 1
    fi
}

if [ -z "$(sfchroot_ssh_pid)" ]; then # first start
    if [ $(whoami) != "root" ]; then
        print_info "chroot not ready, run me as root"
        exit 10
    else
        run_qxcompositor $1
        if [ "$1" == "qxcompositor" ]; then # just open shell
            ./chroot.sh
        else
            ./chroot.sh sudo --login --user=$USER_NAME "/usr/share/sfchroot/start.sh $@"
        fi
    fi
else # chroot ready, ssh to it
    run_qxcompositor $1
    if [ "$1" == "qxcompositor" ]; then
        ./chroot.sh
    elif [ "$1" == "xwayland" ]; then
        sfchroot_ssh_tty "/usr/share/sfchroot/start.sh $@"
    else
        sfchroot_ssh "/usr/share/sfchroot/start.sh $@"
    fi   
fi

