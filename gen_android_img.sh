#!/bin/bash

echo "*******************************************************"
echo " WARNING:This script is only for ANDROID."
echo "*******************************************************"

./build.sh -p sun8iw7p1_android -b nanopi-h3 -m kernel

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
