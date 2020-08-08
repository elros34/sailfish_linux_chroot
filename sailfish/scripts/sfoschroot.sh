#!/bin/bash
set -e
source /usr/share/sfchroot/variables.sh
eval $TRACE_CMD

while [ $# -gt 0 ]; do 
    case $1 in
    "--build-dep")
        shift
        [[ $1 == *".spec" ]] && spec_file=$1 && shift || spec_file="$(find . -name *.spec | head -n1)"
        pkgs=$(pcregrep -o1 "^BuildRequires:[\s\t]*(.*)" "$spec_file")
        for pkg in $pkgs; do
            # filter out >= 0.0.1
            pcregrep -q -e "([\d]\.)+\d" -e "[<>=]+" <<< $pkg && continue
            zypper --non-interactive in $pkg
        done
    ;;
    "--build")
        shift
        [[ $1 == *".spec" ]] && spec_file=$1 && shift  || spec_file="$(find . -name *.spec | head -n1)"
        mkdir -p $PWD/RPMS/
        rpmbuild -bb $spec_file --build-in-place --define="%_rpmdir $PWD/RPMS/"
        mv RPMS/*/*.rpm RPMS/
        rmdir RPMS/* 2>/dev/null || true
    ;;
    *)
        print_info "Unsupported argument: $1"
        break
    ;;
    esac
done


