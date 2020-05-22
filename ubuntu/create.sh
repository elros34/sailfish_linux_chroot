#!/bin/bash

set -e
cd $(dirname $(readlink -f $0))
source ./variables.sh
eval $TRACE_CMD
source ../common/create.sh

sfchroot_createsh

print_info "Image created"

