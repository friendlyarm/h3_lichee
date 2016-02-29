#!/bin/bash
DIR=/home/build/dailybuild
PLATFORM=linux
CHIPS=sun4i_crane
BOARD=evb-v12r
BOARD_NUM=8
VERSION=3.0
DATE0=$(date +%w)
DATE1=$(date +%F)
PACKAGE_LOG_DIR="$DIR"/"$DATE1"-$DATE0
BUILD="$DIR"/work
LICHEEDIR="$BUILD"/lichee
ANDROIDDIR="$BUILD"/android4.0.1 
IMGDIR="$LICHEEDIR"/tools/pack

if [ -d $BUILD ];then
rm -rf $BUILD
fi
mkdir -pv $BUILD
if [ -d $LICHEEDIR ];then
rm -rf $LICHEEDIR
fi
mkdir -pv $LICHEEDIR

if [ -d $PACKAGE_LOG_DIR ];then
rm -rf $PACKAGE_LOG_DIR
fi
mkdir -pv $PACKAGE_LOG_DIR

cd $LICHEEDIR
echo download lichee
repo init -u git://172.16.1.11/manifest.git -b lichee -m dev_v3.0.xml << EOF
EOF
cd 	$LICHEEDIR
repo sync
cd 	$LICHEEDIR

./build.sh -p $CHIPS -k $VERSION > $PACKAGE_LOG_DIR/lichee_build.log 2> $PACKAGE_LOG_DIR/lichee_build_err_warn.log

if [ -d $ANDROIDDIR ];then
rm -rf $ANDROIDDIR
fi
mkdir -pv $ANDROIDDIR
cd $ANDROIDDIR
echo download android
repo init -u git://172.16.1.11/manifest.git -b ics-exdroid << EOF
EOF
cd $ANDROIDDIR
repo sync 
repo start ics-exdroid --all 
 
cd $ANDROIDDIR
export PATH=$PATH:/usr/lib/sunJVM/JDK/jdk1.6.0_29/bin/
source build/envsetup.sh
for ((i=6;i<="$BOARD_NUM";i++))
do 
	cd $ANDROIDDIR
	
	lunch $i
	extract-bsp

	
	echo $PATH
	make -j8  > $PACKAGE_LOG_DIR/lunch_"$i"_build.log  2> $PACKAGE_LOG_DIR/lunch_"$i"_build_err_warn.log
	cd $ANDROIDDIR
	#. build/envsetup.sh
	#Slunch $i
	pack
done
cp "$IMGDIR"/*.img  $PACKAGE_LOG_DIR

echo "###################################################################" > $PACKAGE_LOG_DIR/text.txt
echo repo init -u git://172.16.1.11/manifest.git -b lichee -m dev_v3.0.xml >> $PACKAGE_LOG_DIR/text.txt
echo "repo init -u git://172.16.1.11/manifest.git -b ics-exdroid" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "build linux instruction" >> $PACKAGE_LOG_DIR/text.txt
echo "./build.sh -p $CHIPS -k $VERSION" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "-------------------------extra-message-----------------------------" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "the log information and packgae in {$PACKAGE_LOG_DIR} dir " >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt

echo "" >> $PACKAGE_LOG_DIR/text.txts
echo "-------------------------build-result------------------------------" >> $PACKAGE_LOG_DIR/text.txt
for ((i=6;i<="$BOARD_NUM";i++))
do 
echo "this is lunch $i last 10 line of compile information" >> $PACKAGE_LOG_DIR/text.txt
tail $PACKAGE_LOG_DIR/lunch_"$i"_build.log >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###################################################################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
done
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###################################################################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###############thanks for consult this mail########################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###################################################################" >> $PACKAGE_LOG_DIR/text.txt
cd $PACKAGE_LOG_DIR
cat text.txt | mutt -s "android_text_version[Daily build] $DATE1"  panlong@allwinnertech.com tanliang@allwinnertech.com benn@allwinnertech.com weng@allwinnertech.com zhangxu@allwinnertech.com  
