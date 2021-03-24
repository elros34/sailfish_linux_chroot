#!/bin/bash
set -e

source ./variables.sh
source ./common.sh
eval $TRACE_CMD

[ -f .closing ] && print_info "still closing!" && exit 1

# dirty hack to change working directory in chroot
CD_FILE="/dev/shm/sfchroot-$DISTRO_PREFIX-cd"
/bin/rm -f $CD_FILE

AS_ROOT=0
ARGS=""
while [ $# -gt 0 ]; do
    case $1 in
        "--open-dir")
            DIR=$2
            shift 2
            if [[ $DIR == "$HOST_HOME_DIR"* ]]; then
                DIR=$(sed "s|$HOST_HOME_DIR|/home/host-user|" <<< $DIR)
            fi
            echo "cd $DIR" > $CD_FILE
            chmod a+rwx $CD_FILE
            chown 100000:100000 $CD_FILE
        ;;
        "--as-root")
            shift
            [ "$(whoami)" == "root" ] && AS_ROOT=1
        ;;
        *)
            break
        ;;
    esac
done

[ -z "$ARGS" ] && ARGS=$(sed "s|$HOST_HOME_DIR|/home/host-user|g" <<< "$@")

if [ -z "$(sfchroot_ssh_pid)" ] || [ "$AS_ROOT" -eq 1 ]; then # first start
    if [ $(whoami) != "root" ]; then
        print_info "chroot not ready, run me as root"
        exit 10
    else # root
        MOUNTS=$(mount | grep $CHROOT_DIR | wc -l)
        if [ "$AS_ROOT" -eq 1 ] && [ $MOUNTS -gt 5 ]; then 
            # already mounted, just chroot with arguments
            sfchroot_chroot /usr/share/sfchroot/chroot.sh $ARGS
        else
            if [ $MOUNTS -gt 0 ]; then
                print_info "$CHROOT_DIR partially mounted or ssh server is not started"
                ./close.sh
            else
                sfchroot_mount_img
                sfchroot_mount
                if [ "$AS_ROOT" -eq 1 ]; then
                    sfchroot_prepare_and_chroot /usr/share/sfchroot/chroot.sh $ARGS
                else
                    sfchroot_prepare_and_chroot /usr/share/sfchroot/chroot.sh true
                    sfchroot_ssh $ARGS
                fi
                sfchroot_cleanup          
            fi
        fi
    fi
else # chroot ready, ssh to it
    sfchroot_ssh $ARGS
fi

