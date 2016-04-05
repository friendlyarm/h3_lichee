#!/bin/sh

SDCARD=$1
boot_img=boot.fex

if [ $UID -ne 0 ]
    then
    echo "Please run as root."
    exit
fi

if [ $# -ne 1 ]; then
    echo "Usage:$0 device"
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
[ -e ${boot_img} ] && dd if=${boot_img} of=${SDCARD} bs=1M seek=68
sync
cd -  > /dev/null

echo FINISH