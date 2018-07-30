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
    echo -e "\033[1;32mUsage: `basename $0` -d device[${H5_FUSE_DEVICE}] -p platform[linux] -t target[${H5_LINUX_TARGET}]\033[0m"
    echo -e "\033[1;32mUsage: `basename $0` -d device[${H5_FUSE_DEVICE}] -p platform[android] -t target[${H5_ANDROID_TARGET}]\033[0m"
    exit 1
}

function parse_arg()
{
    if [ $# -lt 4 ]; then
        usage
    fi
    OLD_IFS=${IFS}
    IFS="|"
    while getopts "d:p:t:" opt
    do
        case $opt in
            d )
                FUSE_DEVICE=$OPTARG
                for TMP in ${H5_FUSE_DEVICE}
                do
                    if [[ ${FUSE_DEVICE} = ${TMP} ]];then
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
                PLATFORM=$OPTARG
                for TMP in ${H5_PLATFORM}
                do
                    if [ ${PLATFORM} = ${TMP} ];then
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
                TARGET=$OPTARG
                if [ "x${PLATFORM}" = "xlinux" ]; then
                    H5_TARGET=${H5_LINUX_TARGET}
                elif [ "x${PLATFORM}" = "xandroid" ]; then
                    H5_TARGET=${H5_ANDROID_TARGET}
                else
                    usage
                fi
                for TMP in ${H5_TARGET}
                do
                    if [ ${TARGET} = ${TMP} ];then
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
    if [[ "x${FUSE_DEVICE}" =~ "x/dev/sd" ]]; then
        DEV_NAME=`basename ${FUSE_DEVICE}`
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
    elif [ "x${FUSE_DEVICE}" = "xfastboot" ]; then
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
    if [[ "x${FUSE_DEVICE}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${BOOT0_FEX} of=${FUSE_DEVICE} bs=1k seek=8"
        execute_cmd "dd if=${UBOOT_FEX} of=${FUSE_DEVICE} bs=1k seek=16400"
    elif [ "x${FUSE_DEVICE}" = "xfastboot" ]; then
        execute_cmd "fastboot flash boot0 ${BOOT0_FEX}"
        execute_cmd "fastboot flash boot_package ${UBOOT_FEX}"
    fi
}

function fuse_env_fex_4_android()
{
    ENV_FEX=${PRJ_ROOT_DIR}/tools/pack/out/env.fex
    if [[ "x${FUSE_DEVICE}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${ENV_FEX} of=${FUSE_DEVICE} bs=1M seek=52"
    elif [ "x${FUSE_DEVICE}" = "xfastboot" ]; then
        execute_cmd "fastboot flash env ${ENV_FEX}"
    fi    
}

function fuse_boot_fex_4_android()
{
    BOOT_FEX=${PRJ_ROOT_DIR}/tools/pack/out/boot.fex
    if [[ "x${FUSE_DEVICE}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${BOOT_FEX} of=${FUSE_DEVICE} bs=1M seek=68"
    elif [ "x${FUSE_DEVICE}" = "xfastboot" ]; then
        execute_cmd "fastboot flash boot ${BOOT_FEX}"
    fi
}

function fuse_system_fex_4_android()
{
    SYSTEM_FEX=${PRJ_ROOT_DIR}/tools/pack/out/system.fex
    if [[ "x${FUSE_DEVICE}" =~ "x/dev/sd" ]]; then
        execute_cmd "dd if=${SYSTEM_FEX} of=${FUSE_DEVICE} bs=1M seek=84"
    elif [ "x${FUSE_DEVICE}" = "xfastboot" ]; then
        execute_cmd "fastboot flash system ${SYSTEM_FEX}"
    fi    
}

cd ..
PRJ_ROOT_DIR=`pwd`
H5_FUSE_DEVICE="/dev/sd|fastboot"
H5_PLATFORM="linux|android"
H5_ANDROID_TARGET="u-boot|env.fex|boot.fex|system.fex"
H5_LINUX_TARGET="u-boot"
PLATFORM=linux
TARGET=u-boot
FUSE_DEVICE=/dev/null

parse_arg $@

if [ "x${PLATFORM}" = "xlinux" ]; then
    if [ "x${TARGET}" = "xu-boot" ]; then
        fuse_uboot
        pt_info "fuse u-boot for Linux platform success"
    else
        pt_error "unsupported target"
        usage
        exit 0
    fi
elif [ "x${PLATFORM}" = "xandroid" ]; then
    if [ "x${TARGET}" = "xu-boot" ]; then
        fuse_uboot
        pt_info "fuse u-boot for Android platform success"
    elif [ "x${TARGET}" = "xenv.fex" ]; then
        fuse_env_fex_4_android
        pt_info "fuse env.fex for Android platform success"
    elif [ "x${TARGET}" = "xboot.fex" ]; then
        fuse_boot_fex_4_android
        pt_info "fuse boot.fex for Android platform success"
    elif [ "x${TARGET}" = "xsystem.fex" ]; then
        fuse_system_fex_4_android
        pt_info "fuse system.fex for Android platform success"
        exit 0
    else
        pt_error "unsupported target"
        usage
    fi
fi

