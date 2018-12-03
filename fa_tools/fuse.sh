#!/bin/bash

function pt_error()
{
    echo -e "\033[1;31mERROR: $*\033[0m"
    exit 1
}

function pt_warn()
{
    echo -e "\033[1;31mWARN: $*\033[0m"
}

function pt_info()
{
    echo -e "\033[1;32mINFO: $*\033[0m"
}

function execute_cmd() 
{
    eval $@ || exit $?
}

function usage()
{
    echo "Usage:"
    echo -e "\t`basename $0` -d device[${FA_DEV}] -p platform[linux] -t target[${FA_LINUX_TARGET}]"
    echo -e "\t`basename $0` -d device[${FA_DEV}] -p platform[android] -t target[${FA_ANDROID_TARGET}]"
    exit 1
}

function parse_arg()
{
    if [ $# -lt 4 ]; then
        usage
    fi
    OLD_IFS=${IFS}
    IFS="|"
    local tmp
    while getopts "d:p:t:" opt
    do
        case $opt in
            d )
                SELECTED_DEV=$OPTARG
                for tmp in ${SELECTED_DEV}
                do
                    if [[ ${SELECTED_DEV} =~ ${tmp} ]];then
                        FOUND=1
                        break
                    else
                        FOUND=0
                    fi
                done
                if [ ${FOUND} -eq 0 ]; then
                    pt_error "unsupported fuse device"
                    usage
                fi
                check_fuse_device
                ;;
            p )
                SELECTED_PLATFORM=$OPTARG
                for tmp in ${FA_PLATFORM}
                do
                    if [ ${SELECTED_PLATFORM} = ${tmp} ];then
                        FOUND=1
                        break
                    else
                        FOUND=0
                    fi
                done
                if [ ${FOUND} -eq 0 ]; then
                    pt_error "unsupported platform"
                    usage
                fi
                ;;
            t )
                local plat_target
                SELECTED_TARGET=$OPTARG
                if [ "x${SELECTED_PLATFORM}" = "xlinux" ]; then
                    plat_target=${FA_LINUX_TARGET}
                elif [ "x${SELECTED_PLATFORM}" = "xandroid" ]; then
                    plat_target=${FA_ANDROID_TARGET}
                else
                    usage
                fi
                for tmp in ${plat_target}
                do
                    if [ ${SELECTED_TARGET} = ${tmp} ];then
                        FOUND=1
                        break
                    else
                        FOUND=0
                    fi
                done
                if [ ${FOUND} -eq 0 ]; then
                    pt_error "unsupported target"
                    usage
                fi
                ;;
            ? )
                usage;;
            esac
    done
    IFS=${OLD_IFS}
}

function check_fuse_device() 
{
    if [[ "x${SELECTED_DEV}" =~ "x/dev/sd" ]]; then
        DEV_NAME=`basename ${SELECTED_DEV}`
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
    elif [ "x${SELECTED_DEV}" = "xfastboot" ]; then
        fastboot devices | grep -q fastboot
        if [ $? -ne 0 ]; then
            pt_error "fastboot not ready"
            exit 1
        fi 
    fi
}

function fuse_uboot()
{
    BOOT0_FEX=${PRJ_ROOT_DIR}/tools/pack/out/boot0_sdcard.fex
    UBOOT_FEX=${PRJ_ROOT_DIR}/tools/pack/out/u-boot.fex
    if [[ "x${SELECTED_DEV}" =~ "x/dev/sd" ]]; then
        pt_info "fusing ${BOOT0_FEX}..."
        execute_cmd "dd if=${BOOT0_FEX} of=${SELECTED_DEV} bs=1k seek=8"
        pt_info "fusing ${UBOOT_FEX}..."
        execute_cmd "dd if=${UBOOT_FEX} of=${SELECTED_DEV} bs=1k seek=16400"
    elif [ "x${SELECTED_DEV}" = "xfastboot" ]; then
        pt_info "fusing ${BOOT0_FEX}..."
        execute_cmd "fastboot flash boot0 ${BOOT0_FEX}"
        pt_info "fusing ${UBOOT_FEX}..."
        execute_cmd "fastboot flash u-boot ${UBOOT_FEX}"
    fi
}

function fuse_env_fex_4_android()
{
    ENV_FEX=${PRJ_ROOT_DIR}/tools/pack/out/env.fex
    if [[ "x${SELECTED_DEV}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${ENV_FEX} of=${SELECTED_DEV} bs=1M seek=52"
    elif [ "x${SELECTED_DEV}" = "xfastboot" ]; then
        execute_cmd "fastboot flash env ${ENV_FEX}"
    fi    
}

function fuse_boot_fex_4_android()
{
    BOOT_FEX=${PRJ_ROOT_DIR}/tools/pack/out/boot.fex
    if [[ "x${SELECTED_DEV}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${BOOT_FEX} of=${SELECTED_DEV} bs=1M seek=68"
    elif [ "x${SELECTED_DEV}" = "xfastboot" ]; then
        execute_cmd "fastboot flash boot ${BOOT_FEX}"
    fi
}

function fuse_system_fex_4_android()
{
    SYSTEM_FEX=${PRJ_ROOT_DIR}/tools/pack/out/system.fex
    if [[ "x${SELECTED_DEV}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${SYSTEM_FEX} of=${SELECTED_DEV} bs=1M seek=84"
    elif [ "x${SELECTED_DEV}" = "xfastboot" ]; then
        execute_cmd "fastboot flash system ${SYSTEM_FEX}"
    fi    
}

cd ..
PRJ_ROOT_DIR=`pwd`

LINUX_PLAT_MSG="Linux platform"
ANDROID_PLAT_MSG="Android platform"

# friendlyelec attribute
FA_DEV="/dev/sd|fastboot"
FA_PLATFORM="linux|android"
FA_ANDROID_TARGET="u-boot|env.fex|boot.fex|system.fex"
FA_LINUX_TARGET="u-boot"

# user attribute
SELECTED_PLATFORM=linux
SELECTED_TARGET=u-boot
SELECTED_DEV=/dev/null

parse_arg $@

if [ "x${SELECTED_PLATFORM}" = "xlinux" ]; then
    if [ "x${SELECTED_TARGET}" = "xu-boot" ]; then
        fuse_uboot
        pt_info "fuse u-boot for ${LINUX_PLAT_MSG} success"
    else
        pt_error "unsupported target"
        usage
        exit 0
    fi
elif [ "x${SELECTED_PLATFORM}" = "xandroid" ]; then
    if [ "x${SELECTED_TARGET}" = "xu-boot" ]; then
        fuse_uboot
        pt_info "fuse u-boot for ${ANDROID_PLAT_MSG} success"
    elif [ "x${SELECTED_TARGET}" = "xenv.fex" ]; then
        fuse_env_fex_4_android
        pt_info "fuse env.fex for ${ANDROID_PLAT_MSG} success"
    elif [ "x${SELECTED_TARGET}" = "xboot.fex" ]; then
        fuse_boot_fex_4_android
        pt_info "fuse boot.fex for ${ANDROID_PLAT_MSG} success"
    elif [ "x${SELECTED_TARGET}" = "xsystem.fex" ]; then
        fuse_system_fex_4_android
        pt_info "fuse system.fex for ${ANDROID_PLAT_MSG} success"
        exit 0
    else
        pt_error "unsupported target"
        usage
    fi
fi

