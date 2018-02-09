cat << EOF
##
## This script sets up 
##  - xen with preservation and restoration functions
##  - kernel supporting blktap2 functions
##
EOF

KERNEL_ROOT=/usr/src

if [ -e ${KERNEL_ROOT}/linux-next ]; then
  echo "Error: ${KERNEL_ROOT}/linux-next/ already exist"
  echo "Error: please delete ${KERNEL_ROOT}/linux-next/ first"
  exit 1
fi

echo "--- Cloning linux kernel that supports blktap2"
pushd ${KERNEL_ROOT}/
git clone http://git.kernel.org/pub/scm/linux/kernel/git/jeremy/xen.git linux-next
cd ${KERNEL_ROOT}/linux-next
git checkout -b xen/next-2.6.32 origin/xen/next-2.6.32

echo "--- Copying .config file in ${KERNEL_ROOT}/linux-next/"
popd
cp kernel/config ${KERNEL_ROOT}/linux-next/.config

pushd ${KERNEL_ROOT}/linux-next
make oldconfig

echo "--- Making kernel and modules"
make -j3

echo "--- Installing modules and kernels"
make modules_install
make install

cat << EOF
Installed the kernel that supports blktap2.
Please edit the following files manually and reboot.

(1) edit /etc/grub.conf as follows:
-----------------------------------------
#hiddenmenu
title Xen (4.1.2) with CentOS (2.6.32.57)
        root (hd0,0)
        kernel /xen-4.1.2.gz
        module /vmlinuz-2.6.32.57 ro root=/dev/mapper/VolGroup-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD rd_LVM_LV=VolGroup/lv_swap SYSFONT=latarcyrheb-sun16 rhgb crashkernel=auto  KEYBOARDTYPE=pc KEYTABLE=jp106 rd_LVM_LV=VolGroup/lv_root quiet rd_NO_DM
        module /initramfs-2.6.32.57.img

* please note that you should specify one kernel and two module options here
* we recommend longer timeout value such as 30s.

(2) edit /etc/fstab
xenfs                   /proc/xen               xenfs   defaults        0 0

(3) reboot the system

EOF

echo "--- Finished $0"

