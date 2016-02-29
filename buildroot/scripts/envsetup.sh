#!/bin/bash

LICHEE_ROOT=$PWD
LICHEE_LINUX_VER=""
CRANE_ROOT=""

count=0

select_linux_ver()
{
    for lver in $(find -mindepth 1 -maxdepth 1 -name "linux-*" -type d |sort); do
        lvers[$count]=`basename $lver`
        let count=$count+1
    done

    if [ $count -eq 1 ]; then
        LICHEE_LINUX_VER=${lvers[0]}
    else
        count=0
        for ver in ${lvers[@]}
        do
           echo $count. $ver
           let count=$count+1
        done


        read -p "Please select a linux version:"
        LICHEE_LINUX_VER=${lvers[$REPLY]}
    fi
}

lroot()
{
    cd $LICHEE_ROOT
}

lout()
{
    cd $LICHEE_ROOT/out
}

llinux()
{
    cd $LICHEE_ROOT/$LICHEE_LINUX_VER
}

lpack()
{
    cd $LICHEE_ROOT/tools/pack
}

lbr()
{
    cd $LICHEE_ROOT/buildroot
}

olinux()
{
    cd $LICHEE_ROOT/$LICHEE_LINUX_VER/output
}

opack()
{
    cd $LICHEE_ROOT/tools/pack/out
}

obr()
{
    cd $LICHEE_ROOT/buildroot/output
}

ask_crane_root()
{
    while true; do
        read -p "Please input your crane root full path:"
        if [ -d "$REPLY/device/softwinner" ]; then
            CRANE_ROOT=`cd $REPLY; pwd`
            break
        fi
    done
}

update_path()
{
    PCTOOLS_ROOT=$LICHEE_ROOT/tools/pack/pctools/linux
    if echo $PATH |grep -v $PCTOOLS_ROOT 2>&1 1>/dev/null
    then
        export PATH=$PATH:$PCTOOLS_ROOT/android:$PCTOOLS_ROOT/mod_update:$PCTOOLS_ROOT/eDragonEx:$PCTOOLS_ROOT/fsbuild200
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PCTOOLS_ROOT}/libs
    fi
}

select_linux_ver
update_path

