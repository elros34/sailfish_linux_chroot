#!/bin/bash
#set -x

CHROOT_DIR=$1
if [ -z $CHROOT_DIR ]
then
	CHROOT_DIR=/.ubuntu
else
	if [[ $CHROOT_DIR != /* ]]
	then
		echo $CHROOT_DIR is not absolute path
		exit 1
	fi
fi 

echo "chroot dir: $CHROOT_DIR"

fuser -k $CHROOT_DIR
umount -R $CHROOT_DIR

if [ $? -eq 0 ]
then
	echo "umounting $CHROOT_DIR successful"
else	
	for dir in $(mount | grep $CHROOT_DIR | cut -f 3 -d" " | sort -r)
	do
		echo "umounting $dir"
		umount -fl $dir
	done	
fi


