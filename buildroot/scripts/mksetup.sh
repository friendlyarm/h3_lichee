# scripts/mksetup.sh
#
# (c) Copyright 2013
# Allwinner Technology Co., Ltd. <www.allwinnertech.com>
# James Deng <csjamesdeng@allwinnertech.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

. buildroot/scripts/mkcmd.sh

function mksetup()
{
    rm -f .buildconfig
    printf "\n"
    printf "Welcome to mkscript setup progress\n"

    select_board
    printf "==================================\n"

    init_defconf
}

# Setup all variables in setup.
mksetup

