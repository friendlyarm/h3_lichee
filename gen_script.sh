#!/bin/bash

SYS_CONFIG=tools/pack/chips/sun8iw7p1/configs/nanopi-h3/sys_config.fex

DISP_TV_MOD_480I=0
DISP_TV_MOD_576I=1
DISP_TV_MOD_480P=2
DISP_TV_MOD_576P=3
DISP_TV_MOD_720P_50HZ=4
DISP_TV_MOD_720P_60HZ=5
DISP_TV_MOD_1080I_50HZ=6
DISP_TV_MOD_1080I_60HZ=7
DISP_TV_MOD_1080P_24HZ=8
DISP_TV_MOD_1080P_50HZ=9
DISP_TV_MOD_1080P_60HZ=10

gen_script() {
    echo "generating script-$2.bin"
    sed -i 's/\(^screen0_output_mode\) = \([0-9]\+\)/\1 = '$1'/g' ${SYS_CONFIG}
    ./build.sh pack
    [ -d ./script ] || mkdir script
    cp -fv ./tools/pack/out/sys_config.bin ./script/script-$2.bin
}

gen_script $DISP_TV_MOD_1080P_50HZ "1080p-50"
gen_script $DISP_TV_MOD_1080P_60HZ "1080p-60"
gen_script $DISP_TV_MOD_720P_50HZ "720p-50"
gen_script $DISP_TV_MOD_720P_60HZ "720p-60"

cp -fv ./tools/pack/out/sys_config.bin ./tools/pack/out/script.bin
