#!/bin/bash

set -e
cd $(dirname $(readlink -f $0))
source ./variables.sh
eval $TRACE_CMD
source ../common/create.sh

sfchroot_createsh
sfchroot_createsh_install_helper
sfchroot_createsh_install_qdevel-su

print_info "Image created"

