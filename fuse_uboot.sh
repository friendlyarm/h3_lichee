#!/bin/bash

SDCARD=$1
boot0_fex=boot0_sdcard.fex
uboot_fex=u-boot.fex

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

if [ $UID -ne 0 ]
    then
    echo "Please run as root."
    exit
fi

if [ $# -ne 1 ]; then
    pt_error "Usage:./fuse_uboot.sh device"
    exit 1
fi

DEV_NAME=`basename $1`
BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size`
if [ $? -ne 0 ]; then
    pt_error "Can't find device ${DEV_NAME}"
    exit 1
fi

if [ ${BLOCK_CNT} -le 0 ]; then
    pt_error "NO media found in card reader."
    exit 1
fi

if [ ${BLOCK_CNT} -gt 64000000 ]; then
    pt_error "Block device size (${BLOCK_CNT}) is too large"
    exit 1
fi

cd tools/pack/out/ > /dev/null
[ -e ${boot0_fex} ] && dd if=${boot0_fex} of=${SDCARD} bs=1k seek=8
[ -e ${uboot_fex} ] && dd if=${uboot_fex} of=${SDCARD} bs=1k seek=16400
sync
cd -  > /dev/null

pt_info "FINISH: U-boot fuse success"