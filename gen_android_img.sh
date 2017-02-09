#!/bin/bash

function pt_error()
{
    echo -e "\033[1;31mERROR: $*\033[0m"
}

function pt_warn()
{
    echo -e "\033[1;31mWARN: $*\033[0m"
}

function pt_info()
{
    echo -e "\033[1;32mINFO: $*\033[0m"
}

function parse_arg()
{
    if [ $# -lt 2 ]; then
        pt_warn "Usage:`basename $0` -b board -t target"
        exit 1
    fi
    while getopts "b:t:" opt
    do
        case $opt in
            b )
                BOARD=$OPTARG
                if [ "x${BOARD}" != "xnanopi-m1" \
                    -a "x${BOARD}" != "xnanopi-m1-plus" ]; then
                    pt_error "${BOARD} not support Android"
                    exit 1
                fi
            ;;
            t )
                TARGET=${OPTARG};;
            ? )
                pt_warn "Usage:`basename $0` -b board"
                exit 1;;
            esac
    done
}

parse_arg $@
pt_info "This script is only for ANDROID."
touch ./linux-3.4/.scmversion
echo -e "2\n" | ./build.sh lunch ${BOARD}

cd ../android
export PATH=/usr/lib/jvm/jdk1.6.0_45/bin:$PATH
source ./build/envsetup.sh
lunch nanopi_h3-eng
extract-bsp
if [ "x${TARGET}" = "xboot.img" ]; then
    make bootimage
else 
    make -j8
fi
pack
