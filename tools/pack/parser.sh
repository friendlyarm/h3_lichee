#!/bin/bash

#set -e

ROOT_DIR=$PWD
TOOLS_DIR=${ROOT_DIR}/pctools/linux
FIRMWARE_NAME="1.img"
OUTPUT_NAME_BZ2="vmlinux.tar.bz2"
OUTPUT_NAME="vmlinux"
MAINTYPE_NAME="12345678"
SUBTYPE_NAME="123456789VMLINUX"

export PATH=${TOOLS_DIR}/mod_update:$PATH

show_help()
{
	printf "\nbuild.sh - parser firmware and fetch one file\n"
	echo " this script is used to fetch a file from a firmware"
	echo "  -h  Show help message"
	echo "  -f  firmware_name"
	echo "  -o  output_name"
	echo "  -m  main type in the image.cfg"
	echo "  -s  sub type in the image.cfg"
	echo "  then you can get the file indicated by the image.cfg in the firmware"
	printf "\n\n"
}

parser_file()
{
	OUTPUT_NAME_BZ2=${OUTPUT_NAME}".tar.bz2"
	parser_img $FIRMWARE_NAME $OUTPUT_NAME $MAINTYPE_NAME $SUBTYPE_NAME
	if [ $? -ne 0 ]
	then
		echo -e "\033[40;31;1m [parser file in the firmware fail]\033[0m"
	else
		echo -e "\033[40;32;1m [parser file in the firmware ok]\033[0m"
		tar -xjvf $OUTPUT_NAME_BZ2 $OUTPUT_NAME
		if [ $? -eq 0 ]
		then
			echo -e "\033[40;32;1m [unzip file successful]\033[0m"
		else
			echo -e "\033[40;31;1m [unzip file fail]\033[0m"
		fi
	fi
}

while getopts f:o:m:s: OPTION
do
	case $OPTION in
	f) FIRMWARE_NAME=$OPTARG
	;;
	o) OUTPUT_NAME=$OPTARG
	;;
	m) MAINTYPE_NAME=$OPTARG
	;;
	s) SUBTYPE_NAME=$OPTARG
	;;
	*) show_help
	exit 0
	;;
esac
done

parser_file
