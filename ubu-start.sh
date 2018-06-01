#!/bin/bash
set -e
#set -x
source ubu-variables.sh
source ubu-common.sh

if [ $# -eq 0 ]; then
    echo "supported arguments: xfce4, qxcompositor, chromium"
	exit 1
fi

if [ x$1 == "xqxcompositor" ] || [ x$1 == "xxfce4" ] || [ x$1 == "xchromium" ]; then
	if [ x$ON_DEVICE == "x1" ]; then	
		if [ -n "$(pgrep qxcompositor)" ]; then
			echo "qxcompositor already running"
			exit 1
		fi
		
		su $HOST_USER -l -c "qxcompositor --wayland-socket-name ../../display/wayland-1 &" 
		while [ ! -f /run/display/wayland-1.lock ]; do
			sleep 1
		done
	fi
fi

bash ./ubu-chroot.sh sudo -iu $USER_NAME /usr/share/ubu_chroot/start.sh $@

