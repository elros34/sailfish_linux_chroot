#!/bin/bash

if [ $1 == "shell" ]; then # executed always in fingerterm
    shift
    ./chroot.sh $1
    [ $? -eq 10 ] && devel-su ./chroot.sh $1

    exec bash 
fi

