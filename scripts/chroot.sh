#!/bin/bash
#set -x

# libhybris
if [ $ON_DEVICE -eq 1 ] && [ -z "$(mount | grep 'unionfs on /system')" ]
then
    unionfs -o allow_other,nonempty /sfos/usr/libexec/droid-hybris/system/:/sfos/system/ /system
fi

$@

