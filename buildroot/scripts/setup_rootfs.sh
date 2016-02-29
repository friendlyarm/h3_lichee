#!/bin/sh

TGT_DIR=$1
TGT_FILE=$TGT_DIR/etc/init.d/S30platform

echo "###################################################################"

MAC_ADDR=`cat configs/user.cfg |grep -v "\#" |grep MAC_ADDR| awk -F= '{print $2}'`
CLIENT_IP_ADDR=`cat configs/user.cfg |grep -v "\#" |grep CLIENT_IP_ADDR| awk -F= '{print $2}'`
echo $MAC_ADDR
echo $CLIENT_IP_ADDR

touch $TGT_FILE
chmod +x $TGT_FILE
echo "#!/bin/sh" > $TGT_FILE
echo "ifconfig eth0 hw ether ${MAC_ADDR}" >> $TGT_FILE
echo "ifconfig eth0 $CLIENT_IP_ADDR" >> $TGT_FILE
echo "ifconfig lo 127.0.0.1" >> $TGT_FILE

echo "###################################################################"
