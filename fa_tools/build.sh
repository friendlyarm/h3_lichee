#!/bin/bash -u

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

function run_cmd() 
{
    eval $@ || exit $?
}

function usage()
{
    echo -e "usage: $0 -b board -p platform -t target"
    echo -e "\t -b ${FA_BOARD}"
    echo -e "\t -p ${FA_PLATFORM}"
    echo -e "\t -t ${FA_TARGET}"
    exit 1
}

function parse_arg()
{
    if [ $# -lt 4 ]; then
        usage
    fi

    local found=0
    OLD_IFS=${IFS}
    IFS="|"
    while getopts "b:p:t:" opt
    do
        case $opt in
            b )
                SELECTED_BOARD=$OPTARG
                for tmp in ${FA_BOARD}
                do
                    if [ ${SELECTED_BOARD} = ${tmp} ];then
                        found=1
                        break
                    else
                        found=0
                    fi
                done
                if [ ${found} -eq 0 ]; then
                    pt_error "unsupported board"
                    usage
                fi
                ;;
            p )
                SELECTED_PLATFORM=$OPTARG
                for tmp in ${FA_PLATFORM}
                do
                    if [ ${SELECTED_PLATFORM} = ${tmp} ];then
                        found=1
                        break
                    else
                        found=0
                    fi
                done
                if [ ${found} -eq 0 ]; then
                    pt_error "unsupported platform"
                    usage
                fi
                ;;
            t )
                SELECTED_TARGET=$OPTARG
                for tmp in ${FA_TARGET}
                do
                    if [ ${SELECTED_TARGET} = ${tmp} ];then
                        found=1
                        break
                    else
                        found=0
                    fi
                done
                if [ ${found} -eq 0 ]; then
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

function pack_lichee_4_linux()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh pack" 

    (cd ./${AW_KER}/output/lib/modules/ && tar czf ${FA_OUT}/3.4.39.tar.gz 3.4.39-h3)
    run_cmd "cp ./tools/pack/out/boot0_sdcard.fex ${FA_OUT}/"
    run_cmd "cp ./tools/pack/out/u-boot.fex ${FA_OUT}/"
    run_cmd "cp ./tools/pack/out/boot.fex ${FA_OUT}/boot.img"

    tree ${FA_OUT}
}

function build_uboot_4_linux()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1 -b nanopi-h3 -m uboot"
    pack_lichee_4_linux
    pt_info "Build and pack u-boot for ${LINUX_PLAT_MSG} success"    
}

function  build_kernel_4_linux()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1 -b nanopi-h3 -m kernel"
    pack_lichee_4_linux

    pt_info "Build and pack kernel for ${LINUX_PLAT_MSG} success"
}

function  build_lichee_4_linux()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1 -b nanopi-h3"
    pack_lichee_4_linux

    pt_info "Build and pack lichee for ${LINUX_PLAT_MSG} success"
}

function build_clean_4_linux()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1_linux -b nanopi-h3 -m clean"
    run_cmd "rm ./fa_out -rf"
    pt_info "Clean lichee for ${LINUX_PLAT_MSG} success"
}

function pack_lichee_4_android()
{
    cd ${PRJ_ROOT_DIR}
    if [ -d ../android ]; then
        (cd ../android && source ./build/envsetup.sh && lunch nanopi_h3-eng && pack)
    else
        pt_error "Android directory not found"
    fi
}

function build_uboot_4_android()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1_android -b nanopi-h3 -m uboot"
    pack_lichee_4_android
    pt_info "Build and pack u-boot for ${ANDROID_PLAT_MSG} success"    
}

function  build_kernel_4_android()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1_android -b nanopi-h3 -m kernel"
    pack_lichee_4_android
    pt_info "Build and pack kernel for ${ANDROID_PLAT_MSG} success"
}

function build_lichee_4_android()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "echo -e \"2\n\" | ./build.sh lunch ${SELECTED_BOARD}"
    pt_info "build lichee for ${ANDROID_PLAT_MSG} success. Please build and pack in Android directory"
}

function build_clean_4_android()
{
    cd ${PRJ_ROOT_DIR}
    run_cmd "./build.sh -p sun8iw7p1_android -b nanopi-h3 -m clean"
    pt_info "clean lichee for ${ANDROID_PLAT_MSG} success"
}

function update_config()
{
    rm -rf ./.config
    echo "BOARD_NAME=${SELECTED_BOARD}" >>.config
    echo "PLATFORM=${SELECTED_PLATFORM}" >>.config
    echo "TARGET=${SELECTED_TARGET}" >>.config
}

function prepare_toolchain()
{
    local src_dir=${PRJ_ROOT_DIR}/fa_tools/toolchain_h3_linux-3.4
    local target_dir=${PRJ_ROOT_DIR}/brandy/toolchain

    if [ ! -e ${target_dir}/gcc-linaro-arm.tar.xz ]; then
        [ -d ${src_dir} ] || git clone https://github.com/friendlyarm/toolchain_h3_linux-3.4 ${src_dir} --depth 1 -b master
        run_cmd "cat ${src_dir}/gcc-linaro-arm.tar.xz* >${target_dir}/gcc-linaro-arm.tar.xz"
    fi
}

DEBUG="no"
cd ..
PRJ_ROOT_DIR=`pwd`
AW_KER=linux-3.4

LINUX_PLAT_MSG="Linux platform"
ANDROID_PLAT_MSG="Android platform"

# friendlyelec attribute
FA_BOARD="nanopi-air|nanopi-neo|nanopi-m1|nanopi-m1-plus"
FA_PLATFORM="linux|android"
FA_TARGET="all|u-boot|kernel|pack|clean"
FA_OUT=${PRJ_ROOT_DIR}/fa_out

# user attribute
SELECTED_BOARD="unset"
SELECTED_PLATFORM="unset"
SELECTED_TARGET="unset"
SYS_CONFIG_DIR=${PRJ_ROOT_DIR}/tools/pack/chips/sun8iw7p1/configs/nanopi-h3

parse_arg $@
update_config

cd ${PRJ_ROOT_DIR}
mkdir -p ${FA_OUT}

pt_info "preparing sys_config.fex"
cp -rvf ${SYS_CONFIG_DIR}/board/sys_config_${SELECTED_BOARD}.fex ${SYS_CONFIG_DIR}/sys_config.fex
touch ./linux-3.4/.scmversion

prepare_toolchain
if [ "x${SELECTED_PLATFORM}" = "xlinux" ]; then
    if [ "x${SELECTED_TARGET}" = "xpack" ]; then
        pack_lichee_4_linux
        pt_info "Pack lichee for ${LINUX_PLAT_MSG} success"   
    elif [ "x${SELECTED_TARGET}" = "xu-boot" ]; then
        build_uboot_4_linux
    elif [ "x${SELECTED_TARGET}" = "xkernel" ]; then
        build_kernel_4_linux
    elif [ "x${SELECTED_TARGET}" = "xall" ]; then
        build_lichee_4_linux
    elif [ "x${SELECTED_TARGET}" = "xclean" ]; then
        build_clean_4_linux
    else
        pt_error "unsupported target: ${SELECTED_TARGET}"
        usage
    fi
elif [ "x${SELECTED_PLATFORM}" = "xandroid" ]; then
    if [ "x${SELECTED_TARGET}" = "xpack" ]; then
        pack_lichee_4_android
        pt_info "Pack lichee for ${ANDROID_PLAT_MSG} success" 
    elif [ "x${SELECTED_TARGET}" = "xu-boot" ]; then
        build_uboot_4_android
    elif [ "x${SELECTED_TARGET}" = "xkernel" ]; then
        build_kernel_4_android
    elif [ "x${SELECTED_TARGET}" = "xall" ]; then
        build_lichee_4_android
    elif [ "x${SELECTED_TARGET}" = "xclean" ]; then
        build_clean_4_android
    else
        pt_error "unsupported target: ${SELECTED_TARGET}"
        usage
    fi
else
    pt_error "unsupported platform: ${SELECTED_PLATFORM}"
fi