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

pt_info "This script is only for ANDROID."
#./build.sh -p sun8iw7p1_android -b nanopi-h3 -m uboot
#./build.sh -p sun8iw7p1_android -b nanopi-h3 -m kernel
#WIRELESS_DIR=../../wireless/
#[ -d ${WIRELESS_DIR} ] && (cd ${WIRELESS_DIR} && ./build.sh android)
echo -e "2\n" | ./build.sh lunch

cd ../android
export PATH=/usr/lib/jvm/jdk1.6.0_45/bin:$PATH
source ./build/envsetup.sh
lunch nanopi_h3-eng
extract-bsp
if [ "x${1}" = "xboot.img"]; then
    make bootimage
else 
    make -j8
fi
pack
