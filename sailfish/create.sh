#!/bin/bash

set -e
cd $(dirname $(readlink -f $0))
source ./variables.sh
eval $TRACE_CMD
source ../common/create.sh

sfchroot_createsh

sed "s|SFCHROOT_PATH|$PWD|g" sfoschroot.sh > /usr/local/bin/sfoschroot.sh
chmod a+x /usr/local/bin/sfoschroot.sh

print_info "Image created"

