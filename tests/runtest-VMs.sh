cat << EOF
## This script runs benchmark on each VM by answering questions
## you do not need to supply parameters like the following,
##  but you can utilize these parameters from automatic test scripts
## runtest-VMs.sh [type] [num of vms]
##
##
EOF

if [ $# == 2 ]; then
	type=$1;
	number=$2;
else
	type=""
	number=""
fi

source ./ipaddr_definition.sh

CSV_DIR=/benchmark/csv_dir
## 
USER_TO_DOWNLOAD_CSV=download
PW_TO_DOWNLOAD_CSV=test
IP_TO_DOWNLOAD_CSV=${HOST_IP}

WAIT_MIN=120

echo "Please specify the disk type you want to use:"
echo " 1) BLKTAP2 aio"
echo " 2) BLKTAP2 preservation"
echo " 3) NON-BLKTAP2, file"

if [ $type ]; then
	echo type is $type;
else
	read -p "1-3) " type;
fi

case $type in
    [1]* ) DISK_TYPE=aio; TAP_TYPE="tap:"; break;;
    [2]* ) DISK_TYPE=preservation; TAP_TYPE="tap:"; break;;
    [3]* ) DISK_TYPE=file; TAP_TYPE=""; break;;
    * ) echo "Please answer between 1-3"; exit;;
esac 
echo Disk type is set to ${DISK_TYPE}

echo "Please specify the number of VMs on which you want to test:"

if [ $number ]; then
        echo number is $number;
else
	read -p "1-36) " number
fi

if [ $number -ge 1 -a $number -le 36 ]; then
    NUMBER_OF_VMS=$number
else
    echo "Please answer between 1-36"
    exit 1
fi
echo The number of VMs is set to ${NUMBER_OF_VMS}

echo Delete page caches on domain 0
echo 3 > /proc/sys/vm/drop_caches

for i in `seq 1 ${NUMBER_OF_VMS}`
do
  echo Creating ${DISK_TYPE}-vm-${i}
  xl destroy ${TAP_TYPE}${DISK_TYPE}-vm-${i}
  xl create /benchmark/${DISK_TYPE}-vm-${i}.postinstall.xl.cfg
done

echo Wait for ${WAIT_MIN} seconds for booting OSes
for i in `seq 1 ${WAIT_MIN}`
do
 sleep 1
 echo -n ${i} " "
done

echo ""
echo Removing CSV directory for storing results
rm -rf ${CSV_DIR}
mkdir ${CSV_DIR}
chown ${USER_TO_DOWNLOAD_CSV} ${CSV_DIR}

echo Removing ssh know_hosts file for automatic login...
rm -f /root/.ssh/known_hosts

for i in `seq 1 ${NUMBER_OF_VMS}`
do
   VM_IPADDR=`echo 150+${i} | bc`
   sshpass -p 'test' ssh -o StrictHostKeyChecking=no root@192.168.1.${VM_IPADDR}  "echo 3 > /proc/sys/vm/drop_caches; mkdir /tmp/test; rm /tmp/${DISK_TYPE}-vm-${VM_IPADDR}.csv; rm -f /root/.ssh/known_hosts"
   sshpass -p 'test' ssh -o StrictHostKeyChecking=no root@192.168.1.${VM_IPADDR}  "bonnie++ -d /tmp/test -u root -q > /tmp/${DISK_TYPE}-vm-${VM_IPADDR}.csv; sshpass -p ${PW_TO_DOWNLOAD_CSV} scp -o StrictHostKeyChecking=no /tmp/${DISK_TYPE}-vm-${VM_IPADDR}.csv ${USER_TO_DOWNLOAD_CSV}@${IP_TO_DOWNLOAD_CSV}:${CSV_DIR}; shutdown -h now" &
done

echo "Running benchmark on guest VMs..."
REMAIN_VMS=${NUMBER_OF_VMS}

for j in `seq 1 ${NUMBER_OF_VMS}`
do
  completed[${j}]="0"
done

echo "Waiting for completion of benchmarks..."
while [ ${REMAIN_VMS} != "0" ]
do
   echo -n "."
   sleep 10

   for j in `seq 1 ${NUMBER_OF_VMS}`
   do
        if [ "${completed[${j}]}" == "0" ]; then
           TEST_IF_COMPLETED=`xl list | grep ${TAP_TYPE}${DISK_TYPE}-vm-${j}`
           if [ "${TEST_IF_COMPLETED}" == "" ]; then
                echo Completed benchmark on ${TAP_TYPE}${DISK_TYPE}-vm-${j}
		completed[${j}]="1"
                REMAIN_VMS=`echo ${REMAIN_VMS}-1 | bc`
		sh ../tapdisk-tools/umount.sh /benchmark/${DISK_TYPE}-vm-${j}.img
           fi
        fi
   done
done

echo "Finishing setup ${DISK_TYPE}-vm-[1-${NUMBER_OF_VMS}]"

