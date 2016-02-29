#!/bin/bash

BR_SCRIPTS_DIR=`dirname $0`
LICHEE_ROOT=$PWD
PACK_ROOT=tools/pack

. ${BR_SCRIPTS_DIR}/mkconfig.sh
setup_packconfig $1
TARGET_CHIP=$chip
TARGET_PLATFORM=$platform
TARGET_BOARD=$board
echo "$TARGET_CHIP $TARGET_PLATFORM $TARGET_BOARD"

if [ "$TARGET_PLATFORM" = "crane" ]; then
    if [ -z "$CRANE_IMAGE_OUT" ]; then
        echo "You need to export CRANE_IMAGE_OUT var to env"
        exit 1
    fi

    if [ ! -f "$CRANE_IMAGE_OUT/system.img" ]; then
        echo "You have wrong CRANE_IMAGE_OUT env"
        exit 1
    fi
fi

cd $PACK_ROOT
./pack -c $TARGET_CHIP -p $TARGET_PLATFORM -b $TARGET_BOARD
cd -
