cat << EOF
## This script shutdown all VMs and clear all tap devices.
## runtest-VMs.sh [type] [num of vms]
## type 1=aio,2=prsv,3=file
##
EOF

if [ $# == 2 ]; then
	type=$1;
	number=$2;
else
	echo "Please specify type and number of VMs"
	exit
fi

case $type in
    [1]* ) DISK_TYPE=aio; TAP_TYPE="tap:"; break;;
    [2]* ) DISK_TYPE=preservation; TAP_TYPE="tap:"; break;;
    [3]* ) DISK_TYPE=file; TAP_TYPE=""; break;;
    * ) echo "Please answer between 1-3"; exit;;
esac 
echo Disk type is set to ${DISK_TYPE}

if [ $number -ge 1 -a $number -le 36 ]; then
    NUMBER_OF_VMS=$number
else
    echo "Please answer between 1-36"
    exit 1
fi
echo The number of VMs is set to ${NUMBER_OF_VMS}

for i in `seq 1 ${NUMBER_OF_VMS}`
do
  echo Shutdowning ${DISK_TYPE}-vm-${i}
  xl destroy ${TAP_TYPE}${DISK_TYPE}-vm-${i}
done

echo "Waiting for completion of shutdown processes..."
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
		sh ./umount.sh /benchmark/${DISK_TYPE}-vm-${j}.img
           fi
        fi
   done
done

echo "Finishing setup ${DISK_TYPE}-vm-[1-${NUMBER_OF_VMS}]"

