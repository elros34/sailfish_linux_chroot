#!/bin/bash
set -e
cd $(dirname $(readlink -f $0))

../common/close.sh $@

