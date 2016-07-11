#!/bin/bash

# usage:
# ./gen_script.sh nanopi_neo
# ./gen_script.sh nanopi_m1

SYS_CONFIG_DIR=./tools/pack/chips/sun8iw7p1/configs/nanopi-h3

DISP_TV_MOD_NONE=-1
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

gen_script_for_m1() 
{
    TARGET_SCRIPT=script-m1-$2.bin
    pt_info "generating ${TARGET_SCRIPT}"

    SYS_CONFIG=${SYS_CONFIG_DIR}/sys_config.fex
    if [ $1 -eq -1 ]; then
        sed -i 's/\(^hdmi_used\) = \([0-9]\+\)/\1 = 0/g' ${SYS_CONFIG}
    else
        sed -i 's/\(^hdmi_used\) = \([0-9]\+\)/\1 = 1/g' ${SYS_CONFIG}
        sed -i 's/\(^screen0_output_mode\) = \([0-9]\+\)/\1 = '$1'/g' ${SYS_CONFIG}
    fi
    ./build.sh pack
    [ -d ./script ] || mkdir script
    cp -fv ./tools/pack/out/sys_config.bin ./script/${TARGET_SCRIPT}
}

gen_script_for_neo() 
{
    NEO_SYS_CONFIG=${SYS_CONFIG_DIR}/boards/sys_config_nanopi_neo.fex
    SYS_CONFIG=${SYS_CONFIG_DIR}/sys_config.fex
    # backup current sys_config.fex
    mv ${SYS_CONFIG} ${SYS_CONFIG_DIR}/boards/sys_config_current.fex
    
    cp ${NEO_SYS_CONFIG} ${SYS_CONFIG}
    ./build.sh pack
    [ -d ./script ] || mkdir script
    cp -fv ./tools/pack/out/sys_config.bin ./script/script-neo.bin

    # restore current sys_config.fex
    mv ${SYS_CONFIG_DIR}/boards/sys_config_current.fex ${SYS_CONFIG}
}

gen_script_for_air() 
{
    NEO_SYS_CONFIG=${SYS_CONFIG_DIR}/boards/sys_config_nanopi_air.fex
    SYS_CONFIG=${SYS_CONFIG_DIR}/sys_config.fex
    # backup current sys_config.fex
    mv ${SYS_CONFIG} ${SYS_CONFIG_DIR}/boards/sys_config_current.fex
    
    cp ${NEO_SYS_CONFIG} ${SYS_CONFIG}
    ./build.sh pack
    [ -d ./script ] || mkdir script
    cp -fv ./tools/pack/out/sys_config.bin ./script/script-air.bin

    # restore current sys_config.fex
    mv ${SYS_CONFIG_DIR}/boards/sys_config_current.fex ${SYS_CONFIG}

}

if [ $# -ne 1 ]; then
    pt_warn "Usage: $0 board[nanopi_m1|nanopi_neo]"
    exit 1
else
    BOARD=${1}
    pt_info "board=${BOARD}"
fi

if [[ "x${BOARD}" = "xnanopi-m1" ]]; then
    gen_script_for_m1 $DISP_TV_MOD_NONE "no-hdmi"
    gen_script_for_m1 $DISP_TV_MOD_1080P_50HZ "1080p-50"
    gen_script_for_m1 $DISP_TV_MOD_1080P_60HZ "1080p-60"
    gen_script_for_m1 $DISP_TV_MOD_720P_50HZ "720p-50"
    gen_script_for_m1 $DISP_TV_MOD_720P_60HZ "720p-60"
elif [ "x${BOARD}" = "xnanopi-neo" ]; then
    gen_script_for_neo
elif [ "x${BOARD}" = "xnanopi-air" ]; then
    gen_script_for_air
else
    pt_error "Unsupported board"
    exit 1
fi

cp -fv ./tools/pack/out/sys_config.bin ./tools/pack/out/script.bin
