#!/bin/bash
#
# scripts/mkcommon.sh
# (c) Copyright 2013
# Allwinner Technology Co., Ltd. <www.allwinnertech.com>
# James Deng <csjamesdeng@allwinnertech.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

BR_SCRIPTS_DIR=`dirname $0`

# source shflags
. ${BR_SCRIPTS_DIR}/shflags/shflags
[ -f .buildconfig ] && . .buildconfig
. ${BR_SCRIPTS_DIR}/mkcmd.sh

[ -f .buildconfig ] && . .buildconfig

if [ "x$1" = "xconfig" ] ; then
	. ${BR_SCRIPTS_DIR}/mksetup.sh
	init_buildcmd $*
	mklichee
	exit $?
elif [ "x$1" = "xpack" ] ; then
	init_defconf
	init_buildcmd $*
	mkpack
	exit $?
elif [ "x$1" = "xpack_debug" ] ; then
	select_board_ex
	init_defconf
	init_buildcmd  $*
	mkpack -d card0
	exit $?
elif [ "x$1" = "xpack_secure" ] ; then
	init_defconf
	init_buildcmd  $*
	mkpack -s secure
	exit $?
elif [ "x$1" = "xpack_prev_refurbish" ] ; then
    init_defconf
    mkpack -s secure -f prev_refurbish
    exit $?
elif [ "x$1" = "xpack_dump" ] ; then
	select_board_ex
	init_defconf
	init_buildcmd  $*
	mkpack -m dump
	exit $?
elif [ "x$1" = "xpack_prvt" ] ; then
	select_board_ex
	init_defconf
	init_buildcmd $*
	mkpack -f prvt
	exit $?
elif [ $# -eq 0 ] ; then
	init_defconf
	init_buildcmd $*
	mklichee
	exit $?
elif [ "x$1" = "xlunch" ] ; then
	select_lunch
	init_defconf
	init_buildcmd $*
	mklichee
	exit $?
fi

# define option, format:
#   'long option' 'default value' 'help message' 'short option'
DEFINE_string 'platform' '' 'platform to build, e.g. sun9iw1p1' 'p'
DEFINE_string 'kernel' 'linux-3.4' 'kernel to build, e.g. 3.3' 'k'
DEFINE_string 'board' '' 'board to build, e.g. evb' 'b'
DEFINE_string 'module' '' 'module to build, e.g. buildroot, kernel, uboot, clean' 'm'
DEFINE_string 'business' '' 'business to kernel config, e.g. stardard, security' 'c'
FLAGS_HELP="Top level build script for lichee

Examples:
1. Set the config option and build
    $ ./build.sh config
2. Build lichee using preset config value
    $ ./build.sh
3. Pack a linux, dragonboard image
    $ ./build.sh pack
4. Build lichee using command argument
    $ ./build.sh -p <platform>
"

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

chip=${FLAGS_platform%%_*}
platform=${FLAGS_platform##*_}
business=${FLAGS_business}
kernel=${FLAGS_kernel}
board=${FLAGS_board}
module=${FLAGS_module}


if [ "${platform}" = "${chip}" ] ; then
    platform="linux"
fi

if [ -z "${module}" ] ; then
    module="all"
fi

if ! init_chips ${chip} || \
   ! init_platforms ${platform} ; then
    mk_error "invalid platform '${FLAGS_platform}'  need to set board like -p [platform]"
    exit 1
fi

if ! init_business ${chip} ${business} ; then
	mk_error "invalid business '${FLAGS_business}'  need to set business like -c [business]"
	exit 1
fi

if 	! init_kern_ver ${kernel} ; then
	mk_error "invalid kernel '${FLAGS_kernel}'  need to set board like -k [kernel]"
	exit 1
fi

if ! init_boards ${chip} ${board} ; then
    mk_error "invalid board '${FLAGS_board}' need to set board like -b [board]"
    exit 1
fi

# init default config
init_defconf

if [ ${module} = "all" ]; then
	init_buildcmd ${module}
    mklichee
elif [ ${module} = "uboot" ] ; then
    mkuboot
elif [ ${module} = "buildroot" ] ; then
    mkbr
elif [ ${module} = "kernel" ] ; then
    mkkernel
elif [ ${module} = "clean" ] ; then
    mkclean
elif [ ${module} = "distclean" ] ; then
    mkdistclean
else
    mk_error "invalid module '${module}'"
    exit 1
fi

exit $?

