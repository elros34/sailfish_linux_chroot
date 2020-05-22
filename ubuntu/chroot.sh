#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))

../common/chroot.sh $@

