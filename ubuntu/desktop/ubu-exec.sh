#!/bin/bash

if [ $1 == "shell" ]; then # executed always in fingerterm
    shift
    ./chroot.sh $1
    [ $? -eq 10 ] && devel-su ./chroot.sh $1

    exec bash 
else 
    ./start.sh $@
    [ $? -ne 10 ] && exit

    invoker --type=generic fingerterm -e "echo -e '\n=== ubu $1 ===\n'; devel-su ./start.sh $(printf '%q ' "$@"); exec bash" 
fi


