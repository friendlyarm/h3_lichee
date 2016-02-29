#!/bin/sh

boot_part=$(mount | grep /media/*/BOOT | awk '{print $3}')
if [ -z $boot_part ] ; then
    boot_part=$(mount | grep /media/*/boot | awk '{print $3}')
fi
if [ -z $boot_part ] ; then
    echo "fail to find sdcard boot partition"
    exit 1
fi
device=`mount | grep ${boot_part}`
device=${device:5:3}

echo "boot partition:$boot_part"
echo "sdcard:$device"
cp -fv out/sun8iw7p1/linux/common/uImage $boot_part
cp -fv tools/pack/out/sys_config.bin $boot_part/script.bin
cd ./tools/pack > /dev/null
./fuse_uboot.sh /dev/${device}
cd - > /dev/null
eject /dev/sdg
