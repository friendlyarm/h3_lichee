#!/bin/sh

DIR=/home/panlong/daily_build
PLATFORM=linux
CHIPS=sun4i_crane
BOARD=evb-v12r
VERSION=3.0
DATE0=$(date +%w)
DATE1=$(date +%F)
PACKAGE_LOG_DIR="$DIR"/"$DATE0"-"$DATE1"/"$VERSION"_"$CHIPS"
BUILD="$DIR"/work
LICHEEDIR="$BUILD"/"$VERSION"_"$CHIPS"
ANDROIDDIR="$BUILD"/android4.0.1 

#prepare dir

if [ -d $LICHEEDIR ];then
rm -rf $LICHEEDIR
fi
mkdir -pv $LICHEEDIR

if [ -d $PACKAGE_LOG_DIR ];then
rm -rf $PACKAGE_LOG_DIR
fi
mkdir -pv $PACKAGE_LOG_DIR

#donwload source code
cd $LICHEEDIR
repo init -u git://172.16.1.11/manifest.git -b lichee -m dev_v3.0.xml << EOF
EOF
cd $LICHEEDIR
repo sync

#compile code
./build.sh -p $CHIPS -k $VERSION > $PACKAGE_LOG_DIR/build.log 2> $PACKAGE_LOG_DIR/build_err_warn.log

#write text

echo "###################################################################" > $PACKAGE_LOG_DIR/text.txt
echo repo init -u git://172.16.1.11/manifest.git -b lichee -m dev_v3.0.xml >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "./build.sh -p $CHIPS -k $VERSION" >> $PACKAGE_LOG_DIR/text.txt
echo "-----------------------------git-log-------------------------------" >> $PACKAGE_LOG_DIR/text.txt
echo "##########################buildroot-log############################" >> $PACKAGE_LOG_DIR/text.txt
cd $LICHEEDIR/buildroot
git log -n 1 --pretty=oneline --abbrev-commit >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "##########################linux-3.0-log############################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
cd $LICHEEDIR/linux-3.0
git log -n 1 --pretty=oneline --abbrev-commit >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###########################u-boot-log##############################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
cd $LICHEEDIR/u-boot
git log -n 1 --pretty=oneline --abbrev-commit >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###########################tools-log###############################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
cd $LICHEEDIR/tools
git log -n 1 --pretty=oneline --abbrev-commit >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "-------------------------build-result------------------------------" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "this is the last 10 line of compile information" >> $PACKAGE_LOG_DIR/text.txt
tail $PACKAGE_LOG_DIR/build.log >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###################################################################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
WARNING_NUM=$( grep -Hr "warning:" $PACKAGE_LOG_DIR/build_err_warn.log | wc -l )
echo "there is $WARNING_NUM warning of compile" >> $PACKAGE_LOG_DIR/text.txt
echo "this is detailed information of warning " >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
cat $PACKAGE_LOG_DIR/build_err_warn.log >> $PACKAGE_LOG_DIR/text.txt
echo "-------------------------extra-message-----------------------------" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "the log information and packgae in $PACKAGE_LOG_DIR dir " >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###################################################################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###############thanks for consult this mail########################" >> $PACKAGE_LOG_DIR/text.txt
echo "" >> $PACKAGE_LOG_DIR/text.txt
echo "###################################################################" >> $PACKAGE_LOG_DIR/text.txt
cd $PACKAGE_LOG_DIR
cat text.txt | mutt -s "[Daily build] $DATE1"  panlong@allwinnertech.com tangliang@allwinnertech.com benn@allwinnertech.com -a  build_err_warn.log 