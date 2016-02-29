#!/bin/bash

# $1: a directory, support the absolute directory and the kernel relative directory

if [ $# != 1 ]; then
	echo You should input as follow:
	echo $0 [a code directory]
	exit 0
fi

ORI_DIR=$1
DST_DIR=$1

IS_ABSOLUTE_DIR=`echo $ORI_DIR | grep "^/" -c`
if [ $IS_ABSOLUTE_DIR != 1 ]; then
	DST_DIR="../../../linux-3.4/"$ORI_DIR
fi

if [ ! -d $DST_DIR ]; then
	echo Invalid directory: $DST_DIR
	exit 100
fi

echo Check the directory: $DST_DIR ...
echo
java -jar CloneAnalyzer.jar -m 30 -d $DST_DIR
