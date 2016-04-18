#!/bin/bash
set -e

PLATFORM="sun8iw7p1"
MODE=""

show_help()
{
	printf "\nbuild.sh - Top level build scritps\n"
	echo "Valid Options:"
	echo "  -h  Show help message"
	echo "  -p <platform> platform, e.g. sun5i, sun6i, sun8iw1p1, sun8iw3p1, sun9iw1p1"
	echo "  -m <mode> mode, e.g. ota_test"
	printf "\n\n"
}

build_uboot()
{
	cd u-boot-2011.09/
	if [ "x${LICHEE_BOARD}" = "xnanopi-h3"  -a "x${LICHEE_PLATFORM}" = "xlinux" ] ; then
		printf "\033[0;32;1mskip uboot clean for nanopi-h3 Linux system\033[0m\n"
	elif [ "x${LICHEE_BOARD}" = "x"  -a "x${LICHEE_PLATFORM}" = "xandroid" ] ; then
		printf "\033[0;32;1mskip uboot clean for nanopi-h3 Android system\033[0m\n"
	else
		make distclean
	fi
	if [ "x$MODE" = "xota_test" ] ; then
		export "SUNXI_MODE=ota_test"
	fi
	make ${PLATFORM}_config
	make -j16

    if [ ${PLATFORM} = "sun8iw6p1" ] || [ ${PLATFORM} = "sun8iw7p1" ] || [ ${PLATFORM} = "sun8iw8p1" ] || [ ${PLATFORM} = "sun9iw1p1" ] || [ ${PLATFORM} = "sun8iw5p1" ] ; then
        make spl
    fi

	cd - 1>/dev/null
}

while getopts p:m: OPTION
do
	case $OPTION in
	p)
		PLATFORM=$OPTARG
		;;
	m)
		MODE=$OPTARG
		;;
	*) show_help
		exit
		;;
esac
done

case "$1" in
clean)
	cd u-boot-2011.09/
	if [ "x$LICHEE_BOARD" = "xnanopi-h3" ] ; then                
		make distclean
	fi
	cd - 1>/dev/null
	;;
*)
	build_uboot
	;;
esac