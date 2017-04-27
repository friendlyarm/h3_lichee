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

function install_package()
{
    PACKAGE=${1}
    if dpkg -s ${PACKAGE} 2>&1 | grep "not installed" > /dev/null; then    
        apt-get install ${PACKAGE} --force-yes -y
    fi
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

case $1 in
/dev/sd[a-z] | /dev/loop[0-9] | /dev/mmcblk1)
    if [ ! -e $1 ]; then
        pt_error "$1 does not exist."
        exit 1
    fi
    DEV_NAME=`basename $1`
    BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size` ;;&
/dev/sd[a-z])
    DEV_PART_NAME=${DEV_NAME}1
    REMOVABLE=`cat /sys/block/${DEV_NAME}/removable` ;;
/dev/mmcblk1 | /dev/loop[0-9])
    DEV_PART_NAME=${DEV_NAME}p1
    REMOVABLE=1 ;;
*)
    pt_error "Unsupported SD reader"
    exit 0
esac

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

install_package dosfstools
umount /dev/${DEV_NAME}* >/dev/null 2>&1
pt_info "formatting ${DEV_NAME}, please wait..."
dd if=/dev/zero of=/dev/${DEV_NAME} bs=16M count=6
sync

fdisk /dev/$DEV_NAME <<EOF
o
n
p



w
EOF
mkfs.vfat /dev/${DEV_PART_NAME} -n SD
sync
pt_info "format success."
