#!/bin/bash
set -e
#set -x

if [ $(whoami) == "root" ]
then
    echo "Don't run me as root!"
    exit 1
fi

if [ $# -eq 0 ]
then
    echo "supported compositors: kwin, weston, qxcompositor"
	exit 1
fi

echo "arguments: $@" 

if [ $1 == "kwin" ]
then
	kwin_wayland --width $DISPLAY_WIDTH --height $DISPLAY_HEIGHT --xwayland &
elif [ $1 == "weston" ]
then
	weston
elif [ $1 == "qxcompositor" ]
then
	export WAYLAND_DISPLAY=../../run/display/wayland-1
	Xwayland +extension GLX +iglx -nolisten tcp &
else
	echo "supported compositors: kwin, weston, qxcompositor"
	exit 1

fi

shift
$@

