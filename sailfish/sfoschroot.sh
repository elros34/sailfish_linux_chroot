#!/bin/bash
set -e

export _PWD=$PWD
cd SFCHROOT_PATH

if [ $# -eq 0 ]; then
    ./chroot.sh --open-dir $_PWD
else
    while [ $# -gt 0 ]; do 
        case $1 in
        "--build-dep")
            ./chroot.sh --open-dir $_PWD --as-root /usr/share/sfchroot/sfoschroot.sh "$@"
            [[ $2 == *".spec" ]] && shift 2 || shift
            ;;
        "--build")
            ./chroot.sh --open-dir $_PWD /usr/share/sfchroot/sfoschroot.sh "$@"
            [[ $2 == *".spec" ]] && shift 2 || shift
            break
            ;;
        "--close")
            shift
            ./close.sh
            break
            ;;
        "-h"|"--help")
            echo "Usage: sfoschroot.sh (--help | --build [rpm spec] | --build-dep [rpm spec] | --close) [args]"
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

