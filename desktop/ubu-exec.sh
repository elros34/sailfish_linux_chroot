#!/bin/bash

if [ $1 == "ubu-shell" ]; then # executed always in fingerterm
    shift
    ./ubu-chroot.sh $1
    if [ $? -eq 10 ]; then
        devel-su ./ubu-chroot.sh $1
    fi

    exec bash 
else 
    ./ubu-start.sh $@
    if [ $? -ne 10 ]; then
       exit
    fi

    invoker --type=generic fingerterm -e "echo -e '\n=== ubu $1 ===\n'; devel-su ./ubu-start.sh $@; exec bash" 
fi


