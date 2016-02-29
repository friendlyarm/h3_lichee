#!/bin/bash

LICHEE_ROOT=$PWD
PACK_ROOT=tools/pack
TARGET_CHIP="sun6i"
TARGET_PLATFORM="android"
TARGET_BOARD="evb"
TARGET_FUNC="prvt"
count=0


select_chip()
{
    count=0
    chip=$1

    printf "All valid chips:\n"

    for chip in $(cd $PACK_ROOT/chips/; find -mindepth 1 -maxdepth 1 -type d |sort); do
        chips[$count]=`basename $PACK_ROOT/$chip`
        printf "$count. ${chips[$count]}\n"
        let count=$count+1
    done

    while true; do
        read -p "Please select a platform:"
        RES=`expr match "$REPLY" '[0-9][0-9]*$'`
        if [ -z "$REPLY" ]; then
			echo "Must choice a chip"
			continue
		fi
		if [ "$RES" -le 0 ]; then
            echo "please use index number"
            continue
        fi
        if [ "$REPLY" -ge $count ]; then
            echo "too big"
            continue
        fi
        if [ "$REPLY" -lt "0" ]; then
            echo "too small"
            continue
        fi
        break
    done

    TARGET_CHIP=${chips[$REPLY]}
}


select_platform()
{
    count=0
    chip=$1

    printf "All valid platforms:\n"

    for platform in $(cd $PACK_ROOT/chips/$TARGET_CHIP/configs/; find -mindepth 1 -maxdepth 1 -type d |sort); do
        platforms[$count]=`basename $PACK_ROOT/chips/$TARGET_CHIP/configs/$platform`
        printf "$count. ${platforms[$count]}\n"
        let count=$count+1
    done

    while true; do
        read -p "Please select a platform:"
        RES=`expr match "$REPLY" '[0-9][0-9]*$'`
        if [ -z "$REPLY" ]; then
			echo "Must choice a platform"
			continue
		fi
		if [ "$RES" -le 0 ]; then
            echo "please use index number"
            continue
        fi
        if [ "$REPLY" -ge $count ]; then
            echo "too big"
            continue
        fi
        if [ "$REPLY" -lt "0" ]; then
            echo "too small"
            continue
        fi
        break
    done

    TARGET_PLATFORM=${platforms[$REPLY]}
}


select_boards()
{
    count=0
    chip=$1
    platform=$2

    printf "All valid boards:\n"

    for board in $(cd $PACK_ROOT/chips/$TARGET_CHIP/configs/$platform/; find -mindepth 1 -maxdepth 1 -type d |grep -v default|sort); do
        boards[$count]=`basename $PACK_ROOT/chips/$TARGET_CHIP/configs/$platform/$board`
        printf "$count. ${boards[$count]}\n"
        let count=$count+1
    done

    while true; do
        read -p "Please select a board:"
        RES=`expr match "$REPLY" '[0-9][0-9]*$'`
        if [ -z "$REPLY" ]; then
			echo "Must choice a board"
			continue
		fi
		if [ "$RES" -le 0 ]; then
            echo "please use index number"
            continue
        fi
        if [ "$REPLY" -ge $count ]; then
            echo "too big"
            continue
        fi
        if [ "$REPLY" -lt "0" ]; then
            echo "too small"
            continue
        fi
        break
    done

    TARGET_BOARD=${boards[$REPLY]}
}


printf "Start packing for Private system\n\n"

select_chip

select_platform $TARGET_CHIP

select_boards $TARGET_CHIP $TARGET_PLATFORM

echo "$TARGET_CHIP $TARGET_PLATFORM $TARGET_BOARD"

cd $PACK_ROOT
./pack -c $TARGET_CHIP -p $TARGET_PLATFORM -b $TARGET_BOARD -f $TARGET_FUNC
cd -


