# scripts/mkcmd.sh
#
# (c) Copyright 2013
# Allwinner Technology Co., Ltd. <www.allwinnertech.com>
# James Deng <csjamesdeng@allwinnertech.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Notice:
#   1. This script muse source at the top directory of lichee.

cpu_cores=`cat /proc/cpuinfo | grep "processor" | wc -l`
if [ ${cpu_cores} -le 8 ] ; then
    LICHEE_JLEVEL=${cpu_cores}
else
    LICHEE_JLEVEL=`expr ${cpu_cores} / 2`
fi

export LICHEE_JLEVEL

function mk_error()
{
    echo -e "\033[47;31mERROR: $*\033[0m"
}

function mk_warn()
{
    echo -e "\033[47;34mWARN: $*\033[0m"
}

function mk_info()
{
    echo -e "\033[47;30mINFO: $*\033[0m"
}

# define importance variable
LICHEE_TOP_DIR=`pwd`
LICHEE_BR_DIR=${LICHEE_TOP_DIR}/buildroot
LICHEE_KERN_DIR=${LICHEE_TOP_DIR}/${LICHEE_KERN_VER}
LICHEE_TOOLS_DIR=${LICHEE_TOP_DIR}/tools
LICHEE_OUT_DIR=${LICHEE_TOP_DIR}/out
LICHEE_UBOOT_DIR=${LICHEE_TOP_DIR}/brandy

# make surce at the top directory of lichee
if [ ! -d ${LICHEE_BR_DIR} -o \
     ! -d ${LICHEE_KERN_DIR} -o \
     ! -d ${LICHEE_TOOLS_DIR} ] ; then
    mk_error "You are not at the top directory of lichee."
    mk_error "Please changes to that directory."
    exit 1
fi

# export importance variable
export LICHEE_TOP_DIR
export LICHEE_BR_DIR
export LICHEE_KERN_DIR
export LICHEE_TOOLS_DIR
export LICHEE_OUT_DIR

platforms=(
"android"
"dragonboard"
"linux"
)

function check_env()
{
	if [ "x${LICHEE_PLATFORM}" = "xandroid" ] ; then
		if [ -z "${LICHEE_CHIP}" -o \
			 -z "${LICHEE_PLATFORM}" -o \
			 -z "${LICHEE_KERN_VER}" ] ; then
			mk_error "run './build.sh config' setup env"
			exit 1
		fi
	else
		if [ -z "${LICHEE_CHIP}" -o \
			 -z "${LICHEE_PLATFORM}" -o \
			 -z "${LICHEE_KERN_VER}" -o \
			 -z "${LICHEE_BOARD}" ] ; then
			mk_error "run './build.sh config' setup env"
			exit 1
		fi
	fi
}

function check_uboot_defconf()
{
	local defconf
	local ret=1

	defconf="${LICHEE_CHIP}/${LICHEE_PLATFORM}/${LICHEE_BOARD}"
	if [ ! -f ${LICHEE_UBOOT_DIR}/include/config/${defconf} ] ; then
		ret=0;
		defconf="${LICHEE_CHIP}"
	fi

	export LICHEE_UBOOT_DEFCONF=${defconf}

	return ${ret}
}

function init_defconf()
{
	local pattern
	local defconf
	local out_dir="common"

	check_env

	pattern="${LICHEE_CHIP}_${LICHEE_PLATFORM}_${LICHEE_BOARD}"
	defconf=`awk '$1=="'$pattern'" {print $2,$3}' buildroot/scripts/mkrule`
	if [ -n "${defconf}" ] ; then
		export LICHEE_BR_DEFCONF=`echo ${defconf} | awk '{print $1}'`
		export LICHEE_KERN_DEFCONF=`echo ${defconf} | awk '{print $2}'`
		 out_dir="${LICHEE_BOARD}"
	else
		pattern="${LICHEE_CHIP}_${LICHEE_PLATFORM}_${LICHEE_BUSINESS}"
		defconf=`awk '$1=="'$pattern'" {print $2,$3}' buildroot/scripts/mkrule`
		if [ -n "${defconf}" ] ; then
			export LICHEE_BR_DEFCONF=`echo ${defconf} | awk '{print $1}'`
			export LICHEE_KERN_DEFCONF=`echo ${defconf} | awk '{print $2}'`
			out_dir="common"
		else
			pattern="${LICHEE_CHIP}_${LICHEE_PLATFORM}"
			defconf=`awk '$1=="'$pattern'" {print $2,$3}' buildroot/scripts/mkrule`
			if [ -n "${defconf}" ] ; then
				export LICHEE_BR_DEFCONF=`echo ${defconf} | awk '{print $1}'`
				export LICHEE_KERN_DEFCONF=`echo ${defconf} | awk '{print $2}'`
				out_dir="common"
			fi
		fi
	fi

    export LICHEE_PLAT_OUT="${LICHEE_OUT_DIR}/${LICHEE_CHIP}/${LICHEE_PLATFORM}/${out_dir}"
    export LICHEE_BR_OUT="${LICHEE_PLAT_OUT}/buildroot"
    mkdir -p ${LICHEE_BR_OUT}

	set_build_info
}

function init_buildcmd()
{
	export LIHCEE_BUILD_CMD=$1
}

function set_build_info()
{
	if [ -d ${LICHEE_PLAT_OUT} ] ; then
		if [ -f ${LICHEE_PLAT_OUT}/.buildconfig ] ; then
			rm -f ${LICHEE_PLAT_OUT}/.buildconfig
		fi
		echo "export LICHEE_CHIP='${LICHEE_CHIP}'" >> ${LICHEE_OUT_DIR}/${LICHEE_CHIP}/.buildconfig
		echo "export LICHEE_PLATFORM='${LICHEE_PLATFORM}'" >> ${LICHEE_OUT_DIR}/${LICHEE_CHIP}/.buildconfig
		echo "export LICHEE_BUSINESS='${LICHEE_BUSINESS}'" >> ${LICHEE_OUT_DIR}/${LICHEE_CHIP}/.buildconfig
		echo "export LICHEE_KERN_VER='${LICHEE_KERN_VER}'" >> ${LICHEE_OUT_DIR}/${LICHEE_CHIP}/.buildconfig
		echo "export LICHEE_BOARD='${LICHEE_BOARD}'" >> ${LICHEE_OUT_DIR}/${LICHEE_CHIP}/.buildconfig
	fi
	
	if [ -f .buildconfig ] ; then
		rm .buildconfig
	fi
	echo "export LICHEE_CHIP=${LICHEE_CHIP}" >> .buildconfig
	echo "export LICHEE_PLATFORM=${LICHEE_PLATFORM}" >> .buildconfig
	echo "export LICHEE_BUSINESS=${LICHEE_BUSINESS}" >> .buildconfig
	echo "export LICHEE_KERN_VER=${LICHEE_KERN_VER}" >> .buildconfig
	echo "export LICHEE_BOARD=${LICHEE_BOARD}" >> .buildconfig
}

function init_chips()
{
    local chip=$1
    local cnt=0
    local ret=1

    for chipdir in ${LICHEE_TOOLS_DIR}/pack/chips/* ; do
        chips[$cnt]=`basename $chipdir`
        if [ "x${chips[$cnt]}" = "x${chip}" ] ; then
            ret=0
            export LICHEE_CHIP=${chip}
			#export PLATFORM=${chip}
        fi
        ((cnt+=1))
    done

    return ${ret}
}

function init_platforms()
{
    local cnt=0
    local ret=1
	local platform=$1

    for platformdir in ${platforms[@]} ; do
        if [ "x${platformdir}" = "x$platform" ] ; then
            ret=0
            export LICHEE_PLATFORM=${platform}
        fi
        ((cnt+=1))
    done

    return ${ret}
}

function init_kern_ver()
{
	local kern_ver=$1
    local cnt=0
    local ret=1

	if [ "x${LICHEE_CHIP}" = "xsun6i" -o "x${LICHEE_CHIP}" = "xsun8iw1p1" ] ; then
		kern_ver="linux-3.3"
	fi

	for kern_dir in ${LICHEE_TOP_DIR}/linux-* ; do
		kern_vers[$cnt]=`basename $kern_dir`
		if [ "x${kern_vers[$cnt]}" = "x${kern_ver}" ] ; then
			ret=0
			export LICHEE_KERN_VER=${kern_ver}
			export LICHEE_KERN_DIR=${LICHEE_TOP_DIR}/${LICHEE_KERN_VER}
		fi
		((cnt+=1))
	done

	return ${ret}
}

function init_business()
{
	local chip=$1
	local business=$2
    local ret=1

	pattern=${chip}
	defconf=`awk '$1=="'$pattern'" {for(i=2;i<=NF;i++) print($i)}' buildroot/scripts/mkbusiness`
	if [ -n "${defconf}" ] ; then
		printf "All available business:\n"
		for subbusness in $defconf ; do
			if [ "x${business}" = "x${subbusness}" ] ; then
				ret=0
				export LICHEE_BUSINESS=${subbusness}
			fi
		done
	else
		export LICHEE_BUSINESS=""
		ret=0
		printf "not set business, to use default!\n"
	fi

	return ${ret}
}

function init_boards()
{
    local chip=$1
    local board=$2
    local cnt=0
    local ret=1

	if [ "x${LICHEE_PLATFORM}" == "xandroid" ] ; then
		export LICHEE_BOARD=""
		ret=0;
		return ${ret}
	fi

    for boarddir in ${LICHEE_TOOLS_DIR}/pack/chips/${chip}/configs/* ; do
        boards[$cnt]=`basename $boarddir`
        if [ "x${boards[$cnt]}" = "x${board}" ] ; then
            ret=0
            export LICHEE_BOARD=${board}
        fi
        ((cnt+=1))
    done

    return ${ret}
}

function select_lunch()
{
	local chip_cnt=0
	local board_cnt=0
	local plat_cnt=0
	declare -a mulboards
	declare -a mulchips
	declare -a mulplatforms

    printf "All available lichee lunch:\n"
	for chipdir in ${LICHEE_TOOLS_DIR}/pack/chips/* ; do
		chips[$chip_cnt]=`basename $chipdir`
		#printf "%4d. %s\n" ${chip_cnt} ${chips[$chip_cnt]}
		for platform in ${platforms[@]} ; do
			if [ "x${platform}" = "xandroid" ] ; then
				pattern=${chips[$chip_cnt]}
				defconf=`awk '$1=="'$pattern'" {for(i=2;i<=NF;i++) print($i)}' buildroot/scripts/mkbusiness`
				if [ -n "${defconf}" ] ; then
					for subbusness in $defconf ; do
						mulchips[$board_cnt]=${chips[$chip_cnt]}
						mulplatforms[$board_cnt]=${platform}
						mulbusiness[$board_cnt]=${subbusness}
						mulboards[$board_cnt]=""
						printf "%4d. %s-%s-%s\n" $board_cnt ${chips[$chip_cnt]} ${platform} ${subbusness}
						((board_cnt+=1))
					done
				else
					mulchips[$board_cnt]=${chips[$chip_cnt]}
					mulplatforms[$board_cnt]=${platform}
					mulbusiness[$board_cnt]=""
					mulboards[$board_cnt]=""
					printf "%4d. %s-%s\n" $board_cnt ${chips[$chip_cnt]} ${platform} 
					((board_cnt+=1))
				fi
			fi
			((plat_cnt+=1))
		done
		((chip_cnt+=1))
	done

	while true ; do
        read -p "Choice: " choice
        if [ -z "${choice}" ] ; then
            continue
        fi

        if [ -z "${choice//[0-9]/}" ] ; then
            if [ $choice -ge 0 -a $choice -lt $board_cnt ] ; then
				#printf "%4d  %s %s %s\n" $choice  ${mulchips[$choice]} ${mulplatforms[$choice]} ${mulboards[$choice]}
				if [ -f .buildconfig ] ; then
					rm -f .buildconfig
				fi

				#export PLATFORM=${mulchips[$choice]}
				export LICHEE_CHIP="${mulchips[$choice]}"
                echo "export LICHEE_CHIP=${mulchips[$choice]}" >> .buildconfig

				export LICHEE_PLATFORM="${mulplatforms[$choice]}"
                echo "export LICHEE_PLATFORM=${mulplatforms[$choice]}" >> .buildconfig

				export LICHEE_BUSINESS="${mulbusiness[$choice]}"
                echo "export LICHEE_BUSINESS=${mulbusiness[$choice]}" >> .buildconfig

				export LICHEE_BOARD="${mulboards[$choice]}"
                echo "export LICHEE_BOARD=${mulboards[$choice]}" >> .buildconfig

				if [ "x${LICHEE_CHIP}" = "xsun8iw1p1" -o "x${LICHEE_CHIP}" = "xsun6i" ] ; then
					LICHEE_KERN_VER="linux-3.3"
				else
					LICHEE_KERN_VER="linux-3.4"
				fi
				printf "using kernel '${LICHEE_KERN_VER}':\n"
				export LICHEE_KERN_VER
				export LICHEE_KERN_DIR=${LICHEE_TOP_DIR}/${LICHEE_KERN_VER}
				echo "export LICHEE_KERN_VER=${LICHEE_KERN_VER}" >> .buildconfig

				echo "LICHEE_CHIP="$LICHEE_CHIP
				echo "LICHEE_PLATFORM="$LICHEE_PLATFORM
				echo "LICHEE_BUSINESS="$LICHEE_BUSINESS
				echo "LICHEE_BOARD="$LICHEE_BOARD
				echo "LICHEE_KERN_VER="$LICHEE_KERN_VER
				break
            fi
        fi
        printf "Invalid input ...\n"
    done
}

function select_business()
{
	local cnt=0
	local pattern
	local defconf
	
	select_platform

	pattern=${LICHEE_CHIP}
	defconf=`awk '$1=="'$pattern'" {for(i=2;i<=NF;i++) print($i)}' buildroot/scripts/mkbusiness`
	if [ -n "${defconf}" ] ; then
		printf "All available business:\n"
		for subbusness in $defconf ; do
			business[$cnt]=$subbusness
			printf "%4d. %s\n" $cnt ${business[$cnt]}
			((cnt+=1))
		done

		while true ; do
			read -p "Choice: " choice
			if [ -z "${choice}" ] ; then
				continue
			fi

			if [ -z "${choice//[0-9]/}" ] ; then
				if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
					export LICHEE_BUSINESS="${business[$choice]}"
					echo "export LICHEE_BUSINESS=${business[$choice]}" >> .buildconfig
					break;
				fi
			fi
			 printf "Invalid input ...\n"
		done
	else
		export LICHEE_BUSINESS=""
		echo "export LICHEE_BUSINESS=${LICHEE_BUSINESS}" >> .buildconfig
		printf "not set business, to use default!\n"
	fi
	
	echo "LICHEE_BUSINESS="$LICHEE_BUSINESS
}

function select_chip()
{
    local cnt=0
    local choice
	local call=$1

    printf "All available chips:\n"
    for chipdir in ${LICHEE_TOOLS_DIR}/pack/chips/* ; do
        chips[$cnt]=`basename $chipdir`
        printf "%4d. %s\n" $cnt ${chips[$cnt]}
        ((cnt+=1))
    done

    while true ; do
        read -p "Choice: " choice
        if [ -z "${choice}" ] ; then
            continue
        fi

        if [ -z "${choice//[0-9]/}" ] ; then
            if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
                export LICHEE_CHIP="${chips[$choice]}"
				#export PLATFORM=${LICHEE_CHIP}
                echo "export LICHEE_CHIP=${chips[$choice]}" >> .buildconfig
                break
            fi
        fi
        printf "Invalid input ...\n"
    done
}

function select_platform()
{
    local cnt=0
    local choice
	local call=$1

    select_chip

    printf "All available platforms:\n"
	for platform in ${platforms[@]} ; do
		printf "%4d. %s\n" $cnt $platform
		((cnt+=1))
	done

    while true ; do
        read -p "Choice: " choice
        if [ -z "${choice}" ] ; then
            continue
        fi

        if [ -z "${choice//[0-9]/}" ] ; then
            if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
                export LICHEE_PLATFORM="${platforms[$choice]}"
                echo "export LICHEE_PLATFORM=${platforms[$choice]}" >> .buildconfig
                break
            fi
        fi
        printf "Invalid input ...\n"
    done
}


function select_kern_ver()
{
    local cnt=0
    local choice

    select_business

	if [ "x${LICHEE_CHIP}" = "xsun8iw1p1" -o "x${LICHEE_CHIP}" = "xsun6i" ] ; then
		LICHEE_KERN_VER="linux-3.3"
	else
		LICHEE_KERN_VER="linux-3.4"
	fi
	printf "using kernel '${LICHEE_KERN_VER}':\n"
	export LICHEE_KERN_VER
	export LICHEE_KERN_DIR=${LICHEE_TOP_DIR}/${LICHEE_KERN_VER}
	echo "export LICHEE_KERN_VER=${LICHEE_KERN_VER}" >> .buildconfig

    # printf "All available kernel:\n"
	# for kern_dir in ${LICHEE_TOP_DIR}/linux-* ; do
		# kern_vers[$cnt]=`basename $kern_dir`
        # printf "%4d. %s\n" $cnt ${kern_vers[$cnt]}
		# ((cnt+=1))
	# done

    # while true ; do
        # read -p "Choice: " choice
        # if [ -z "${choice}" ] ; then
            # continue
        # fi

        # if [ -z "${choice//[0-9]/}" ] ; then
            # if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
                # export LICHEE_KERN_VER="${kern_vers[$choice]}"
				# export LICHEE_KERN_DIR=${LICHEE_TOP_DIR}/${LICHEE_KERN_VER}
                # echo "export LICHEE_KERN_VER=${kern_vers[$choice]}" >> .buildconfig
                # break
            # fi
        # fi
        # printf "Invalid input ...\n"
    # done
}

function select_board()
{
    local cnt=0
    local choice

	select_kern_ver

	if [ "x${LICHEE_PLATFORM}" = "xandroid" ] ; then
		export LICHEE_BOARD=""
        echo "export LICHEE_BOARD=" >> .buildconfig
		return 0
	fi

	printf "All available boards:\n"
    for boarddir in ${LICHEE_TOOLS_DIR}/pack/chips/${LICHEE_CHIP}/configs/* ; do
        boards[$cnt]=`basename $boarddir`
        if [ "x${boards[$cnt]}" = "xdefault" ] ; then
            continue
        fi
        printf "%4d. %s\n" $cnt ${boards[$cnt]}
        ((cnt+=1))
    done
    
    while true ; do
        read -p "Choice: " choice
        if [ -z "${choice}" ] ; then
            continue
        fi

        if [ -z "${choice//[0-9]/}" ] ; then
            if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
                export LICHEE_BOARD="${boards[$choice]}"
                echo "export LICHEE_BOARD=${boards[$choice]}" >> .buildconfig
                break
            fi
        fi
        printf "Invalid input ...\n"
    done
}

function select_board_ex()
{
	local cnt=0
    local choice

	printf "All available boards:\n"
    for boarddir in ${LICHEE_TOOLS_DIR}/pack/chips/${LICHEE_CHIP}/configs/* ; do
        boards[$cnt]=`basename $boarddir`
        if [ "x${boards[$cnt]}" = "xdefault" ] ; then
            continue
        fi
        printf "%4d. %s\n" $cnt ${boards[$cnt]}
        ((cnt+=1))
    done
    
    while true ; do
        read -p "Choice: " choice
        if [ -z "${choice}" ] ; then
            continue
        fi

        if [ -z "${choice//[0-9]/}" ] ; then
            if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
                export LICHEE_BOARD="${boards[$choice]}"
                echo "export LICHEE_BOARD=${boards[$choice]}" >> .buildconfig
                break
            fi
        fi
        printf "Invalid input ...\n"
    done
}

function mkbr()
{
    mk_info "build buildroot ..."

    local build_script="scripts/build.sh"

    (cd ${LICHEE_BR_DIR} && [ -x ${build_script} ] && ./${build_script})
    [ $? -ne 0 ] && mk_error "build buildroot Failed" && return 1

    mk_info "build buildroot OK."
}

function clbr()
{
    mk_info "build buildroot ..."

    local build_script="scripts/build.sh"
    (cd ${LICHEE_BR_DIR} && [ -x ${build_script} ] && ./${build_script} "clean")

    mk_info "clean buildroot OK."
}

function prepare_toolchain()
{
    mk_info "prepare toolchain ..."
    tooldir=${LICHEE_BR_OUT}/external-toolchain
    if [ ! -d ${tooldir} ] ; then
        mkbr
    fi

    if ! echo $PATH | grep -q "${tooldir}" ; then
        export PATH=${tooldir}/bin:$PATH
    fi
}

function mkkernel()
{
    mk_info "build kernel ..."

    local build_script="scripts/build.sh"

    prepare_toolchain

    # mark kernel .config belong to which config and build cmd used
	local config_mark="${LICHEE_KERN_DIR}/.config.mark"
	if [ -f ${config_mark} ] ; then
		if ! grep -q "${LICHEE_KERN_DEFCONF}" ${config_mark} ; then
			printf "\033[0;31;1mclean last time build for different config used\033[0m\n"
			(cd ${LICHEE_KERN_DIR} && [ -x ${build_script} ] && ./${build_script} "clean")
			echo "${LICHEE_KERN_DEFCONF}" > ${config_mark}
		elif [ "x$LIHCEE_BUILD_CMD" = "x" ] ; then
			printf "\033[0;31;1muse last time build config\033[0m\n"
		else
			printf "\033[0;31;1mclean last time build for config cmd used\033[0m\n"
			(cd ${LICHEE_KERN_DIR} && [ -x ${build_script} ] && ./${build_script} "clean")
		fi
	else
		echo "${LICHEE_KERN_DEFCONF}" > ${config_mark}
	fi

	(cd ${LICHEE_KERN_DIR} && [ -x ${build_script} ] && ./${build_script})
	[ $? -ne 0 ] && mk_error "build kernel Failed" && return 1

	mk_info "build kernel OK."
}

function clkernel()
{
    mk_info "clean kernel ..."

    local build_script="scripts/build.sh"

    prepare_toolchain

    (cd ${LICHEE_KERN_DIR} && [ -x ${build_script} ] && ./${build_script} "clean")

    mk_info "clean kernel OK."
}

function mkboot()
{
    mk_info "build boot ..."
    mk_info "build boot OK."
}

function mkuboot()
{
	mk_info "build uboot ..."
	local build_script
	if check_uboot_defconf ; then
		build_script="build.sh"
	else
		build_script="build_${LICHEE_CHIP}_${LICHEE_PLATFORM}_${LICHEE_BOARD}.sh"
	fi

	prepare_toolchain
	
	(cd ${LICHEE_UBOOT_DIR} && [ -x ${build_script} ] && ./${build_script})
	[ $? -ne 0 ] && mk_error "build uboot failed" && return 1

	mk_info "build uboot ok."
}

function cluboot()
{
	mk_info "clean uboot ..."
	local build_script
	if check_uboot_defconf ; then
		build_script="build.sh"
	else
		build_script="build_${LICHEE_CHIP}_${LICHEE_PLATFORM}_${LICHEE_BOARD}.sh"
	fi
	
	prepare_toolchain
	
	(cd ${LICHEE_UBOOT_DIR} && [-x ${build_script} ] && ./${build_script} "clean")
	[ $? -ne 0 ] && mk_error "clean uboot failed" && return 1

	mk_info "clean uboot ok."	
}

function packtinyandroid()
{
    rm -rf rootfs_tinyandroid
    mkdir -p rootfs_tinyandroid
    cp -a ${LICHEE_BR_OUT}/target/* rootfs_tinyandroid/
    if [ -f $LICHEE_KERN_DIR/tinyandroid.tar.gz ];then
        mk_info "copy tinyandroid"
        cd $LICHEE_KERN_DIR && tar zvxf tinyandroid.tar.gz && cd -
        rm -rf rootfs_tinyandroid/init
        rm -rf rootfs_tinyandroid/linuxrc
        cp -a  $LICHEE_KERN_DIR/tinyandroid/*  rootfs_tinyandroid/
        if [ "x$PACK_BSPTEST" = "xtrue" ];then
            if [ -d ${LICHEE_TOP_DIR}/SATA/linux/target ];then
                mk_info "copy SATA tinyandroid"
                cp -a ${LICHEE_TOP_DIR}/SATA/linux/target  rootfs_tinyandroid/
            fi
        fi
    fi
	mk_info "generating rootfs..."

	NR_SIZE=`du -sm rootfs_tinyandroid | awk '{print $1}'`
	NEW_NR_SIZE=$(((($NR_SIZE+32)/16)*16))
	#NEW_NR_SIZE=360
	TARGET_IMAGE=rootfs.ext4

	echo "blocks: $NR_SIZE"M" -> $NEW_NR_SIZE"M""
	$LICHEE_BR_DIR/target/tools/host/usr/bin/make_ext4fs -l $NEW_NR_SIZE"M" $TARGET_IMAGE rootfs_tinyandroid/
	fsck.ext4 -y $TARGET_IMAGE > /dev/null
	echo "success in generating rootfs"

	if [ -d $LICHEE_PLAT_OUT ]; then
		cp -v $TARGET_IMAGE $LICHEE_PLAT_OUT/
	fi

	echo "Build at: `date`"
}
function mkrootfs()
{
    mk_info "build rootfs ..."

    if [ ${LICHEE_PLATFORM} = "linux" ] ; then
        make O=${LICHEE_BR_OUT} -C ${LICHEE_BR_DIR} target-generic-getty-busybox
        [ $? -ne 0 ] && mk_error "build rootfs Failed" && return 1
        make O=${LICHEE_BR_OUT} -C ${LICHEE_BR_DIR} target-finalize
        [ $? -ne 0 ] && mk_error "build rootfs Failed" && return 1
        make O=${LICHEE_BR_OUT} -C ${LICHEE_BR_DIR} LICHEE_GEN_ROOTFS=y rootfs-ext4
        [ $? -ne 0 ] && mk_error "build rootfs Failed" && return 1
        cp ${LICHEE_BR_OUT}/images/rootfs.ext4 ${LICHEE_PLAT_OUT}
        if [ "x$PACK_TINY_ANDROID" = "xtrue" ];then
            packtinyandroid
        fi
    elif [ ${LICHEE_PLATFORM} = "dragonboard" ] ; then
		echo "Regenerating dragonboard Rootfs..."
        (
            cd ${LICHEE_BR_DIR}/target/dragonboard; \
        	if [ ! -d "./rootfs" ]; then \
        	echo "extract dragonboard rootfs.tar.gz"; \
        	tar zxf rootfs.tar.gz; \
        	fi
        )
		mkdir -p ${LICHEE_BR_DIR}/target/dragonboard/rootfs/lib/modules
        rm -rf ${LICHEE_BR_DIR}/target/dragonboard/rootfs/lib/modules/*
        cp -rf ${LICHEE_KERN_DIR}/output/lib/modules/* ${LICHEE_BR_DIR}/target/dragonboard/rootfs/lib/modules/
        (cd ${LICHEE_BR_DIR}/target/dragonboard; ./build.sh)
        cp ${LICHEE_BR_DIR}/target/dragonboard/rootfs.ext4 ${LICHEE_PLAT_OUT}
    else
        mk_info "skip make rootfs for ${LICHEE_PLATFORM}"
    fi

    mk_info "build rootfs OK."
}

function mklichee()
{

	mk_info "----------------------------------------"
    mk_info "build lichee ..."
	mk_info "chip: $LICHEE_CHIP"
	mk_info "platform: $LICHEE_PLATFORM"
	mk_info "business: $LICHEE_BUSINESS"
	mk_info "kernel: $LICHEE_KERN_VER"
	mk_info "board: $LICHEE_BOARD"
	mk_info "output: out/${LICHEE_CHIP}/${LICHEE_PLATFORM}/${LICHEE_BOARD}"
	mk_info "----------------------------------------"

	check_env
    mkbr && mkkernel && mkrootfs
    [ $? -ne 0 ] && return 1

	printf "\033[0;31;1m----------------------------------------\033[0m\n"
	printf "\033[0;31;1mbuild ${LICHEE_CHIP} ${LICHEE_PLATFORM} ${LICHEE_BUSINESS} lichee OK\033[0m\n"
	printf "\033[0;31;1m----------------------------------------\033[0m\n"
}

function mkclean()
{
    clkernel
    clbr

    mk_info "clean product output dir ..."
    rm -rf ${LICHEE_PLAT_OUT}
}

function mkdistclean()
{
    clkernel

    mk_info "clean entires output dir ..."
    rm -rf ${LICHEE_OUT_DIR}
}

function mkpack()
{
    mk_info "packing firmware ..."

	check_env

    (cd ${LICHEE_TOOLS_DIR}/pack && \
    	./pack -c ${LICHEE_CHIP} -p ${LICHEE_PLATFORM} -b ${LICHEE_BOARD} $@)
}

function mkhelp()
{
    printf "
                mkscript - lichee build script

<version>: 1.0.0
<author >: james

<command>:
    mkboot      build boot
	mkuboot		build uboot
    mkbr        build buildroot
    mkkernel    build kernel
    mkrootfs    build rootfs for linux, dragonboard
    mklichee    build total lichee
    
    mkclean     clean current board output
    mkdistclean clean entires output

    mkpack      pack firmware for lichee

    mkhelp      show this message

"
}

