#!/bin/bash
set -e

export _PWD=$PWD
cd SFCHROOT_PATH

if [ $# -eq 0 ]; then
    ./chroot.sh --open-dir $_PWD
else
    while [ $# -gt 0 ]; do 
        case $1 in
        "--close")
            shift
            ./close.sh
            break
            ;;
        "-h"|"--help")
            echo "Usage: $(basename $0) (--help | --close) [args]"
            break
            ;;
        "--")
            shift
            ./chroot.sh --open-dir $_PWD $@
            break
            ;;
        *)
            ./chroot.sh --open-dir $_PWD $@
            break
            ;;
        esac
    done
fi

