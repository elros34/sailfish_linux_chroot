#!/bin/bash
set -e
source ubu-variables.sh
source ubu-common.sh
eval $TRACE_CMD

if [ $# -eq 0 ]; then
    echo "supported arguments: xfce4, qxcompositor, chromium"
	exit 1
fi

run_qxcompositor() {
    if [ x$1 == "xqxcompositor" ] || [ x$1 == "xxfce4" ] || [ x$1 == "xchromium" ] || [ x$1 == "xchromium-browser" ]; then
	    if [ x$ON_DEVICE == "x1" ]; then	
		    if [ -n "$(pgrep qxcompositor)" ]; then
			    print_info "qxcompositor already running"
			    exit 1
		    fi

		    if [ $(whoami) == "root" ]; then
                su $HOST_USER -l -c "invoker --type=silica-qt5 qxcompositor --wayland-socket-name ../../display/wayland-1 &"
            else
                invoker --type=silica-qt5 qxcompositor --wayland-socket-name ../../display/wayland-1 &
            fi

		    while [ ! -f /run/display/wayland-1.lock ]; do
			    sleep 1
		    done
	    fi
    fi
}

if [ -z "$(ubu_ssh_pid)" ]; then # first start
    if [ $(whoami) != "root" ]; then
        print_info "chroot not ready, run me as root"
        exit 10
    else
        run_qxcompositor $1
        bash ./ubu-chroot.sh sudo --login --user=$USER_NAME /usr/share/ubu_chroot/start.sh $@
    fi
else # chroot ready, ssh to it
    run_qxcompositor $1
    if [ $(whoami) == "root" ]; then
        su $HOST_USER -l -c "ssh -p 2228 $USER_NAME@localhost /usr/share/ubu_chroot/start.sh $@"
    else
        ssh -p 2228 $USER_NAME@localhost /usr/share/ubu_chroot/start.sh $@
    fi   
fi

