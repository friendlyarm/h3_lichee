#!/bin/sh
DIR=/home/panlong/daily_build
PLATFORM=linux
CHIPS=sun5i
BOARD=a12-evb
VERSION=3.0
LICHEEDIR=lichee_"$CHIPS"_$VERSION
HOME=/home/panlong/auto/$LICHEEDIR
DATE=$(date)
DATE1=$(date +%F)
PACKAGE_LOG_DIR="$DATE1"
COMPILE_LOG=/home/panlong/auto/$LICHEEDIR.log

#prepare dir
if [ -d $HOME ];then
rm -rf $HOME
fi
mkdir -pv $HOME

#donwload source code
cd $HOME
repo init -u git://172.16.1.11/manifest.git -b lichee -m dev_v3.0.xml << EOF
EOF
cd $HOME
repo sync

#compile code
./build.sh -p $CHIPS -k $VERSION > $HOME/build.log 2> $HOME/build_err_warn.log

#pack package
cd $HOME/tools/pack
./pack -c $CHIPS -p $PLATFORM -b $BOARD > $HOME/pack.log 2> $HOME/pack_err_warn.log
cd $HOME/tools/pack
./pack -c $CHIPS -p $PLATFORM -b a13-evb
#write text

echo "###################################################################" > $HOME/text.txt
echo repo init -u git://172.16.1.11/manifest.git -b lichee -m dev_v3.0.xml >> $HOME/text.txt
echo "" >> $HOME/text.txt
echo "./build.sh -p $CHIPS -k $VERSION" >> $HOME/text.txt
echo "-----------------------------git-log-------------------------------" >> $HOME/text.txt
echo "##########################buildroot-log############################" >> $HOME/text.txt
cd $HOME/buildroot
git log -n 1 >> $HOME/text.txt
echo "##########################linux-3.0-log############################" >> $HOME/text.txt
cd $HOME/linux-3.0
git log -n 1 >> $HOME/text.txt
echo "###########################u-boot-log##############################" >> $HOME/text.txt
cd $HOME/u-boot
git log -n 1 >> $HOME/text.txt
echo "###########################tools-log###############################" >> $HOME/text.txt
cd $HOME/tools
git log -n 1 >> $HOME/text.txt
echo "-------------------------build-result------------------------------" >> $HOME/text.txt
echo "this is the last 10 line of compile information" >> $HOME/text.txt
tail $HOME/build.log >> $HOME/text.txt
echo "###################################################################" >> $HOME/text.txt
WARNING_NUM=$( grep -Hr "warning:" $HOME/build_err_warn.log | wc -l )
echo "there is $WARNING_NUM warning of compile" >> $HOME/text.txt
echo "this is detailed information of warning " >> $HOME/text.txt
echo "###################################################################" >> $HOME/text.txt
cat $HOME/build_err_warn.log >> $HOME/text.txt
echo "-------------------------extra-message-----------------------------" >> $HOME/text.txt
echo "the log information and packgae in $PACKAGE_LOG_DIR dir " >> $HOME/text.txt
echo "###################################################################" >> $HOME/text.txt
echo "###############thanks for consult this mail########################" >> $HOME/text.txt
echo "###################################################################" >> $HOME/text.txt
cd $HOME
mv  build.log COMPILE_LOG
cat text.txt | mutt -s "[Daily build] $DATE"  panlong@allwinnertech.com tanliang@allwinnertech.com benn@allwinnertech.com -a  build_err_warn.log pack.log pack_err_warn.log