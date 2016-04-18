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
    pt_error "Please run as root."
    exit
fi

if [ $# -ne 1 ]; then
    pt_error "Usage:./fuse_uboot.sh device"
    exit 1
fi

apt-get -y --force-yes install pv > /dev/null
DEV_NAME=`basename $1`
BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size`
if [ $? -ne 0 ]; then
    pt_error "Error: Can't find device ${DEV_NAME}"
    exit 1
fi

if [ ${BLOCK_CNT} -le 0 ]; then
    pt_error "Error: NO media found in card reader."
    exit 1
fi

if [ ${BLOCK_CNT} -gt 64000000 ]; then
    pt_error "Error: Block device size (${BLOCK_CNT}) is too large"
    exit 1
fi

umount ${SDCARD}* 2>/dev/null
pt_info "formatting sd card, please wait..."
dd if=/dev/zero of=${SDCARD} bs=16M count=4
sync

fdisk $SDCARD <<EOF
o
n
p



w
EOF
mkfs.vfat ${SDCARD}1 -n SD
sync
pt_info "format success."
