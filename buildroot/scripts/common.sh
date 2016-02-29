#!/bin/bash
set -e

PLATFORM=""
MODULE=""
CUR_DIR=$PWD
OUT_DIR=$CUR_DIR/out
KERN_VER=3.3
KERN_DIR=$CUR_DIR/linux-${KERN_VER}
KERN_OUT_DIR=$KERN_DIR/output
BR_DIR=$CUR_DIR/buildroot
BR_OUT_DIR=$BR_DIR/output
U_BOOT_DIR=$CUR_DIR/u-boot
KERN_VER_RELEASE=3.3.0

update_kdir()
{
	KERN_VER=$1
	KERN_DIR=${CUR_DIR}/linux-${KERN_VER}
	KERN_OUT_DIR=$KERN_DIR/output
}

show_help()
{
printf "
NAME
	build - The top level build script for Lichee Linux BSP

SYNOPSIS
	build [-h] | [-p platform] [-k kern_version] [-m module] | pack

OPTIONS
	-h             Display help message
	-p [platform]  platform, e.g. sun6i, sun6i_dragonboard, sun6i_fiber
                   sun6i: full linux bsp
                   sun6i_dragonboard: board test packages
                   sun6i_fiber: android kernel

	-k [kern_ver]  3.3(default)                          [OPTIONAL]

	-m [module]    Use this option when you dont want to build all. [OPTIONAL]
                   e.g. kernel, buildroot, uboot, all(default)...
	pack           To start pack program

Examples:
	./build.sh -p sun6i
	./build.sh -p sun6i_dragonboard
	./build.sh -p sun6i_fiber
	./build.sh -p sun6i_fiber_a31s
	./build.sh pack

"

}

update_kern_ver()
{
	if [ -r ${KERN_DIR}/include/generated/utsrelease.h ]; then
		KERN_VER_RELEASE=`cat include/generated/utsrelease.h |awk -F\" '{print $2}'`
	fi
}


regen_rootfs()
{
	if [ -d ${BR_OUT_DIR}/target ]; then
		echo "Copy modules to target..."
		mkdir -p ${BR_OUT_DIR}/target/lib/modules

		rm -rf ${BR_OUT_DIR}/target/lib/modules/*
		cp -rf ${KERN_OUT_DIR}/lib/modules/* ${BR_OUT_DIR}/target/lib/modules/

		if [ "$PLATFORM" = "sun4i-debug" ]; then
			cp -rf ${KERN_DIR}/vmlinux ${BR_OUT_DIR}/target
		fi
	fi


	if [ "$PLATFORM" != "sun6i_fiber" ]; then
		echo "Regenerating Rootfs..."
		(cd ${BR_DIR}; make target-generic-getty-busybox; make target-finalize)
        	(cd ${BR_DIR};  make LICHEE_GEN_ROOTFS=y rootfs-ext4)
	else
		echo "Skip Regenerating Rootfs..."
	fi
}

regen_dragonboard_rootfs()
{
    (cd ${BR_DIR}/target/dragonboard; if [ ! -d "./rootfs" ]; then echo "extract rootfs.tar.gz"; tar -zxf rootfs.tar.gz; fi)
    mkdir -p ${BR_DIR}/target/dragonboard/rootfs/lib/modules
    rm -rf ${BR_DIR}/target/dragonboard/rootfs/lib/modules/${KERN_VER}*
    cp -rf ${KERN_OUT_DIR}/lib/modules/* ${BR_DIR}/target/dragonboard/rootfs/lib/modules/
    (cd ${BR_DIR}/target/dragonboard; ./build.sh)
    return 0
}

gen_output_sun3i()
{
	echo "output sun3i"
}

gen_output_generic()
{
	cp -v ${BR_OUT_DIR}/images/* ${OUT_DIR}/
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	fi
}

gen_output_sun4i()
{
	gen_output_generic
}

gen_output_sun4i-lite()
{
	gen_output_generic
}

gen_output_sun4i-debug()
{
	gen_output_generic
}

gen_output_a13-test()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	#cp -v ${BR_OUT_DIR}/images/* ${OUT_DIR}/
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/

	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	fi

	(cd $BR_DIR/target/test; fakeroot ./create_module_image.sh)
}

gen_output_sun5i()
{
	gen_output_generic
}

gen_output_a12()
{
	gen_output_generic
}

gen_output_a13()
{
	gen_output_generic
}

gen_output_sun4i_crane()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi

	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android/
	mkdir -p ${OUT_DIR}/android/toolchain/
	cp ${BR_DIR}/dl/arm-2010.09-50-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2 ${OUT_DIR}/android/toolchain/

	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_a13_nuclear()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi

	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android/
		mkdir -p ${OUT_DIR}/android/toolchain/
	cp ${BR_DIR}/dl/arm-2010.09-50-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2 ${OUT_DIR}/android/toolchain/

	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_a12_nuclear()
{
	gen_output_a13_nuclear
}

gen_output_sun6i()
{
	gen_output_generic
}

gen_output_sun6i_fiber()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi


	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_sun6i_fiber_a31s()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi


	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android
	if [ -e ${U_BOOT_DIR}/u-boot.bin ]; then
		cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/android
	fi
}

gen_output_sun6i_dragonboard()
{
    if [ ! -d "${OUT_DIR}/dragonboard" ]; then
        mkdir -p ${OUT_DIR}/dragonboard
    fi

    cp -v ${KERN_OUT_DIR}/boot.img ${OUT_DIR}/dragonboard/
    cp -v ${BR_DIR}/target/dragonboard/rootfs.ext4 ${OUT_DIR}/dragonboard/
    cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/dragonboard/
}

clean_output()
{
	rm -rf ${OUT_DIR}/*
	rm -rf ${BR_OUT_DIR}/images/*
	rm -rf ${KERN_OUT_DIR}/*
}

if [ "$1" = "pack" ]; then
   	echo "generate rootfs now, it will takes several minutes and log in out/"
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi
	regen_rootfs > out/gen_rootfs_log.txt 2>&1
	gen_output_sun6i >> out/gen_rootfs_log.txt 2>&1
	echo "generate rootfs has finished!"
    ${BR_DIR}/scripts/build_pack.sh
	exit 0
elif [ "$1" = "pack_dragonboard" ]; then
        regen_dragonboard_rootfs
        gen_output_sun6i_dragonboard
        ${BR_DIR}/scripts/build_pack.sh
	    exit 0
elif [ "$1" = "pack_prvt" ]; then
        ${BR_DIR}/scripts/build_prvt.sh
	    exit 0
fi

while getopts hp:m:k: OPTION
do
	case $OPTION in
	h) show_help
	exit 0
	;;
	p) PLATFORM=$OPTARG
	;;
	m) MODULE=$OPTARG
	;;
	k) KERN_VER=$OPTARG
	update_kdir $KERN_VER
	;;
	*) show_help
	exit 1
	;;
esac
done

if [ -z "$PLATFORM" ]; then
	show_help
	exit 1
fi


if [ -z "$PLATFORM" ]; then
	show_help
	exit 1
fi



clean_output

if [ "$MODULE" = buildroot ]; then
	cd ${BR_DIR} && ./build.sh -p ${PLATFORM}
elif [ "$MODULE" = kernel ]; then
	export PATH=${BR_OUT_DIR}/external-toolchain/bin:$PATH
	cd ${KERN_DIR} && ./build.sh -p ${PLATFORM}
elif [ "$MODULE" = "uboot" ]; then
	case ${PLATFORM} in
	a12_nuclear*)
			echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
		;;
	a12*)
		echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
		;;
	a13_nuclear*)
			echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
		;;
	a13*)
		echo "build uboot for sun5i_a13"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
		;;
	*)
		echo "build uboot for ${PLATFORM}"
		cd ${U_BOOT_DIR} && ./build.sh -p ${PLATFORM}
		;;
	esac
else
	cd ${BR_DIR} && ./build.sh -p ${PLATFORM}
	export PATH=${BR_OUT_DIR}/external-toolchain/bin:$PATH
	cd ${KERN_DIR} && ./build.sh -p ${PLATFORM}

	#regen_rootfs

	gen_output_${PLATFORM}

	echo -e "\033[0;31;1m###############################\033[0m"
	echo -e "\033[0;31;1m#         compile success     #\033[0m"
	echo -e "\033[0;31;1m###############################\033[0m"
	fi


