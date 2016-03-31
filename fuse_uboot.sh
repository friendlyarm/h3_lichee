#!/bin/sh

SDCARD=$1
boot0_fex=boot0_sdcard.fex
uboot_fex=u-boot.fex

if [ $UID -ne 0 ]
    then
    echo "Please run as root."
    exit
fi

if [ $# -ne 1 ]; then
    echo "Usage:./fuse_uboot.sh device"
    exit 1
fi

DEV_NAME=`basename $1`
BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size`
if [ $? -ne 0 ]; then
    echo "Error: Can't find device ${DEV_NAME}"
    exit 1
fi

if [ ${BLOCK_CNT} -le 0 ]; then
    echo "Error: NO media found in card reader."
    exit 1
fi

if [ ${BLOCK_CNT} -gt 64000000 ]; then
    echo "Error: Block device size (${BLOCK_CNT}) is too large"
    exit 1
fi

cd tools/pack/out/ > /dev/null
[ -e ${boot0_fex} ] && dd if=${boot0_fex} of=${SDCARD} bs=1k seek=8
[ -e ${uboot_fex} ] && dd if=${uboot_fex} of=${SDCARD} bs=1k seek=16400
sync
cd -  > /dev/null

echo FINISH