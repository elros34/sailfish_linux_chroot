#!/bin/bash
set -e
source ubu-common.sh
eval $TRACE_CMD

if [ $# -eq 0 ]; then
    echo "supported arguments: xfce4, qxcompositor, chromium"
    exit 1
fi

run_qxcompositor() {
    if [ "$1" == "qxcompositor" ] || [ "$1" == "xfce4" ] || [ "$1" == "chromium" ] || [ "$1" == "chromium-browser" ]; then
        if [ "$ON_DEVICE" == "1" ]; then
            # TODO: multi instances
            if [ -n "$(ubu_qxcompositor_pid)" ]; then
                print_info "qxcompositor already running"
                return 0
            fi

            ubu_host_user_exe "invoker --type=silica-qt5 qxcompositor --wayland-socket-name ../../display/wayland-ubu-1 -u user -p 2228" &

            while [ ! -f /run/display/wayland-ubu-1.lock ]; do
                sleep 1
            done
        fi
    else
        exit 1
    fi
}

if [ -z "$(ubu_ssh_pid)" ]; then # first start
    if [ $(whoami) != "root" ]; then
        print_info "chroot not ready, run me as root"
        exit 10
    else
        run_qxcompositor $1
        if [ "$1" == "qxcompositor" ]; then # just open shell
            ./ubu-chroot.sh
        else
            bash ./ubu-chroot.sh sudo --login --user=$USER_NAME /usr/share/ubu_chroot/start.sh $@
        fi
    fi
else # chroot ready, ssh to it
    run_qxcompositor $1
    if [ "$1" == "qxcompositor" ]; then
        ./ubu-chroot.sh
    else
        ubu_ssh "/usr/share/ubu_chroot/start.sh $@"
    fi   
fi

