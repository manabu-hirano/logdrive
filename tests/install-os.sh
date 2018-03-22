#!/bin/sh
cat << EOF
##
## This script installs
##  - OS on virtual disk of TYPE (TYPE is one of aio, preservation, or file)
##
## install-os.sh [TYPE] [VM_NUMBER]
##   you can specify a unique vm number for distinguish multiple guest OSes
##   you can also specify TYPE (one of aio, preservation, or file)
##
EOF

source ./ipaddr_definition.sh

BLOCK_SIZE=4096
IMG_SIZE_IN_GB=10
##IMG_SIZE_IN_GB=1000 # 1TB

if [ $# -ne 3 ]; then
   echo "Usage: ./install-os.sh [TYPE] [VM_NUMBER] [INSTALL_DIR]"
   exit 1
else
   if [ ! \( $2 -ge 0 -a $2 -le 36 \) ]; then
	echo You can specify any number between 0 and 36
	exit 1
   fi
   VM_NUMBER=$2
   INSTALL_DIR=$3
fi

echo VM_NUMBER set to ${VM_NUMBER}
echo INSTALL_DIR set to ${INSTALL_DIR}

case "$1" in
  "aio" ) BLKTAP2_TYPE="aio"; TAP_TYPE="tap:";;
  "preservation" ) BLKTAP2_TYPE="preservation"; TAP_TYPE="tap:";;
  "file" ) BLKTAP2_TYPE="file"; TAP_TYPE="";;
  * ) echo "Please specify aio, preservation, or file"; exit 1;;
esac
echo "BLKTAP2_TYPE set to ${TAP_TYPE}${BLKTAP2_TYPE}"

INSTALL_IMG=${INSTALL_DIR}/${BLKTAP2_TYPE}-vm-${VM_NUMBER}.img
INSTALL_ISO_HTTP_DIR=/var/www/html/centos

## You can change the following parameters for switchnig OS and versions
INSTALL_ISO=../download/CentOS-5.11-i386-bin-DVD-1of2.iso
TMP_KS_URL=http://${HOST_IP}/${BLKTAP2_TYPE}-vm-${VM_NUMBER}.ks.cfg
INSTALL_URL=http://${HOST_IP}/centos
VM_IPADDR=`echo ${GUEST_IP_SUFFIX_BASE}+${VM_NUMBER} | bc`

TMP_KS_CFG=/var/www/html/${BLKTAP2_TYPE}-vm-${VM_NUMBER}.ks.cfg
TMP_XL_CFG=/tmp/${BLKTAP2_TYPE}-vm-${VM_NUMBER}.xl.cfg
POSTINSTALL_XL_CFG=${INSTALL_DIR}/${BLKTAP2_TYPE}-vm-${VM_NUMBER}.postinstall.xl.cfg

INSTALL_XL_CFG_ORIG=./config/centos5/centos5-install.xl.cfg.orig
POSTINSTALL_XL_CFG_ORIG=./config/centos5/centos5-postinstall.xl.cfg.orig
INSTALL_KS_CFG_ORIG=./config/centos5/centos5-install.ks.cfg.orig

echo Creating temporary XL configuration as ${TMP_XL_CFG} ...
cat ${INSTALL_XL_CFG_ORIG} | sed -e "s/VM_NUMBER/${VM_NUMBER}/g" | \
	sed -e "s/BLKTAP2_TYPE/${TAP_TYPE}${BLKTAP2_TYPE}/g" | \
	sed -e "s#INSTALL_IMG#${INSTALL_IMG}#g" | \
	sed -e "s#KS_URL#${TMP_KS_URL}#g" > ${TMP_XL_CFG}
echo ------------------------------------------------
cat ${TMP_XL_CFG}
echo ------------------------------------------------

echo Creating temporary Kickstart \(ks\) configuration as ${TMP_KS_CFG} ...
cat ${INSTALL_KS_CFG_ORIG} | sed -e "s/VM_NUMBER/${VM_NUMBER}/g" | \
	sed -e "s#INSTALL_URL#${INSTALL_URL}#g" | \
	sed -e "s/BLKTAP2_TYPE/${BLKTAP2_TYPE}/g" | \
	sed -e "s/VM_IPADDR/${VM_IPADDR}/g" > ${TMP_KS_CFG}
echo ------------------------------------------------
cat ${TMP_KS_CFG}
echo ------------------------------------------------

echo Creating post install XL configuration as ${POSTINSTALL_XL_CFG} ...
cat ${POSTINSTALL_XL_CFG_ORIG} | sed -e "s/VM_NUMBER/${VM_NUMBER}/g" | \
        sed -e "s/BLKTAP2_TYPE/${TAP_TYPE}${BLKTAP2_TYPE}/g" | \
        sed -e "s#INSTALL_IMG#${INSTALL_IMG}#g" > ${POSTINSTALL_XL_CFG}
echo ------------------------------------------------
cat ${POSTINSTALL_XL_CFG}
echo ------------------------------------------------

echo Destroying a vm of same name if it exists...
xl destroy ${TAP_TYPE}${BLKTAP2_TYPE}-vm-${VM_NUMBER}

echo Destoying a same tap-device if it exists...
sh ./umount.sh ${INSTALL_IMG}

echo Deleting the previous test image at ${INSTALL_IMG}...
if [ -e ${INSTALL_IMG} ]; then
  rm ${INSTALL_IMG}
fi

echo Making ${IMG_SIZE_IN_GB} GB installation disk image at ${INSTALL_IMG} ...
case ${BLKTAP2_TYPE} in
 "aio"|"file" )
   dd if=/dev/zero of=${INSTALL_IMG} bs=`echo 2^30 | bc` count=${IMG_SIZE_IN_GB}
   ;;
 "preservation" )
   ./mkimage.rb ${INSTALL_IMG} `echo 2^30*${IMG_SIZE_IN_GB} | bc` ${BLOCK_SIZE};;
esac

if [ ! -e ${INSTALL_IMG} ]; then
	echo Could not create image file
	exit 1
fi

if [ ! \( -e ${INSTALL_ISO} -a -e ${INSTALL_ISO_HTTP_DIR} \) ]; then
	echo ${INSTALL_ISO} or ${INSTALL_ISO_HTTP_DIR} does not exist
	exit 1
fi

echo Mounting ${INSTALL_ISO} on ${INSTALL_ISO_HTTP_DIR} ...
mount -t iso9660 -o loop ${INSTALL_ISO} ${INSTALL_ISO_HTTP_DIR}

echo Restarting httpd for http installation ...
service httpd restart

echo Copying linux kernels and initrd files to /benchmark/ because pygrub cannot read image files like preservation
if [ ! -e /benchmark/vmlinuz-2.6.18-398.el5xen ]; then
  cp ./config/centos5/vmlinuz-2.6.18-398.el5xen /benchmark
fi
if [ ! -e /benchmark/initrd-2.6.18-398.el5xen.img ]; then
  cp ./config/centos5/initrd-2.6.18-398.el5xen.img /benchmark
fi

echo Creating temporary XL configuration ...

echo Booting Xen guest OS for installng ${INSTALL_ISO} by XL config ${TMP_XL_CFG} ...
xl create ${TMP_XL_CFG}

echo "Installing OS on guest vm ..."
TEST_IF_VM_EXISTS=`xl list | grep ${BLKTAP2_TYPE}-vm-${VM_NUMBER}`
while [ "${TEST_IF_VM_EXISTS}" ]
do
	TEST_IF_VM_EXISTS=`xl list | grep ${BLKTAP2_TYPE}-vm-${VM_NUMBER}`
	echo ${TEST_IF_VM_EXISTS}
	sleep 10
done

echo "Destroying tap device of ${INSTALL_IMG}"
sh ./umount.sh ${INSTALL_IMG}

echo Removing ${TMP_KS_CFG} and ${TMP_XL_CFG}...
rm ${TMP_KS_CFG}
rm ${TMP_XL_CFG}

#echo Unmounting ${INSTALL_ISO_HTTP_DIR} ...
#umount ${INSTALL_ISO_HTTP_DIR}

echo Completed installing ${BLKTAP2_TYPE}-vm-${VM_NUMBER}
cat << EOF
## For booting this guest OS
## execute "xl create -c ${POSTINSTALL_XL_CFG}"
EOF


