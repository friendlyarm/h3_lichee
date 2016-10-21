#!/bin/bash

# usage:
# ./gen_script.sh nanopi_neo
# ./gen_script.sh nanopi_m1

SYS_CONFIG_DIR=./tools/pack/chips/sun8iw7p1/configs/nanopi-h3

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

function gen_script() 
{
    SRC_SYS_CONFIG=boards/sys_config_nanopi_${1}.fex
    DEST_SYS_CONFIG=sys_config.fex
    (cd ${SYS_CONFIG_DIR} && cp -v ${SRC_SYS_CONFIG} ${DEST_SYS_CONFIG})
    ./build.sh pack
    [ -d ./script ] || mkdir script
    cp -fv ./tools/pack/out/sys_config.bin ./script/script-${1}.bin
    cp -fv ./tools/pack/out/sys_config.bin ./tools/pack/out/script.bin
    rm -rf ${SYS_CONFIG_DIR}/${DEST_SYS_CONFIG}
}

function parse_arg()
{
    if [ $# -ne 2 ]; then
        pt_warn "Usage:`basename $0` -b board"
        exit 1
    fi
    while getopts "b:" opt
    do
        case $opt in
            b )
                BOARD=$OPTARG;;
            ? )
                pt_warn "Usage:`basename $0` -b board"
                exit 1;;
            esac
    done
}

parse_arg $@
pt_info "board=${BOARD}"
if [[ "x${BOARD}" = "xnanopi-m1" ]]; then
    gen_script "m1"
elif [ "x${BOARD}" = "xnanopi-neo" ]; then
    gen_script "neo"
elif [ "x${BOARD}" = "xnanopi-air" ]; then
    gen_script "air"
elif [ "x${BOARD}" = "xnanopi-m1-plus" ]; then
    gen_script "m1_plus"
else
    pt_error "Unsupported board"
    exit 1
fi
