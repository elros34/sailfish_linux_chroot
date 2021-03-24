#!/bin/bash
set -e

export _PWD=$PWD
cd SFCHROOT_PATH
ret=0

chroot_sh() {    
    ./chroot.sh --open-dir $_PWD $@ || ret=$?
    [ $ret -eq 10 ] && [ "$(whoami)" != "root" ] && qdevel-su --title="Root required to start chroot" ./chroot.sh --open-dir $_PWD $@
}

if [ $# -eq 0 ]; then
    chroot_sh $@
else
    while [ $# -gt 0 ]; do 
        case $1 in
        "-d" | "--build-dep")
            chroot_sh --as-root /usr/share/sfchroot/sfoschroot.sh "$@"
            [[ $2 == *".spec" ]] && shift 2 || shift
            ;;
        "-b" | "--build")
            chroot_sh /usr/share/sfchroot/sfoschroot.sh "$@"
            [[ $2 == *".spec" ]] && shift 2 || shift
            break
            ;;
        "-c" | "--close")
            shift
            ./close.sh || ret=$?
            [ $ret -eq 10 ] && [ "$(whoami)" != "root" ] && qdevel-su --title="Root required to close chroot" ./close.sh
            break
            ;;
        "-h" | "--help")
            echo -e "Usage: sfoschroot.sh [options] [args]\n" \
                    "Options:\n" \
                    "  --help, -h                   Print help.\n" \
                    "  --build, -b [rpm spec]       Build rpm package.\n" \
                    "  --build-dep, -d [rpm spec]   Install build dependencies.\n" \
                    "  --close, -c                  Close chroot."
            break
            ;;
        "--")
            shift
            chroot_sh $@
            break
            ;;
        *)
            chroot_sh $@
            break
            ;;
        esac
    done
fi

