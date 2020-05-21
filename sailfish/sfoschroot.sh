#!/bin/bash
set -e

export _PWD=$PWD
cd SFCHROOT_PATH
./chroot.sh --open-dir=$_PWD

