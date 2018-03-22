cat << EOF
## This scripts makes VMs by answering questions
##
EOF

echo "Please specify the disk type you want to use:"
echo " 1) BLKTAP2 aio"
echo " 2) BLKTAP2 preservation"
echo " 3) NON-BLKTAP2, file"
read -p "1-3) " type
case $type in
    [1]* ) DISK_TYPE=aio; break;;
    [2]* ) DISK_TYPE=preservation; break;;
    [3]* ) DISK_TYPE=file; break;;
    * ) echo "Please answer between 1-3"; exit;;
esac 
echo Disk type is set to ${DISK_TYPE}

echo "Please specify the number of VMs you want to create:"
read -p "1-36) " number
if [ $number -ge 1 -a $number -le 36 ]; then
    NUMBER_OF_VMS=$number
else
    echo "Please answer between 1-36"
    exit 1
fi
echo The number of VMs is set to ${NUMBER_OF_VMS}

echo "Please specify the installation directory of VMs:"
read -p "/benchmark) " INSTALL_DIR
if [ -z ${INSTALL_DIR} ]; then 
	INSTALL_DIR=/benchmark
fi

mkdir ${INSTALL_DIR}
mkdir /var/www/html/centos

echo The installation directory of VMs is set to ${INSTALL_DIR}

echo "Are you sure to proceed to install VMs?"
read -p "y or n) " yn
case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Canceled."; exit;;
    * ) echo "Please answer y(es) or n(o)."; exit;;
esac

for i in `seq 1 ${NUMBER_OF_VMS}`
do
  rm /tmp/${DISK_TYPE}-vm-${i}.log
  echo Creating ${DISK_TYPE}-vm-${i}
  sh ./install-os.sh ${DISK_TYPE} ${i} ${INSTALL_DIR} &> /tmp/${DISK_TYPE}-vm-${i}.log &
done

for j in `seq 1 ${NUMBER_OF_VMS}`
do
  installed[${j}]="0"
done

echo "Installing OSes on guest VMs..."
REMAIN_VMS=${NUMBER_OF_VMS}
TEST_MESSAGE="Completed installing"

while [ ${REMAIN_VMS} != "0" ]
do
   echo -n "."
   sleep 10

   for j in `seq 1 ${NUMBER_OF_VMS}`
   do
	if [ "${installed[${j}]}" == "0" ]; then
           ##echo "Checking /tmp/${DISK_TYPE}-vm-${j}.log"
	   TEST_IF_COMPLETED=`grep "${TEST_MESSAGE}" /tmp/${DISK_TYPE}-vm-${j}.log`
	   if [ "${TEST_IF_COMPLETED}" ]; then
		echo ""
		echo "${TEST_IF_COMPLETED}"
		installed[${j}]="1"
		REMAIN_VMS=`echo ${REMAIN_VMS}-1 | bc`
           fi
        fi
   done
done

echo "Finishing installing ${DISK_TYPE}-vm-[1-${NUMBER_OF_VMS}]"

cat << EOF
================
Setup benchmark
================
At first, you need to:

cp test-suites/bonnie.tar /var/www/html/
cp test-suites/install-bench.sh /var/www/html/

For each VMs, you need to execute the following command.

xl create /benchmark/*-vm-*.postinstall.xl.cfg
login as root/test

yes | rm install-bench.sh; wget http://192.168.1.210/install-bench.sh; sh install-bench.sh

then the scripts installs bonnie++ and shutdown the vm automatically.

=====================
GUI login
=====================

Start virtual machine
xl create /benchmark/*-vm-*.postinstall.xl.cfg

Login as root with password "test"

Start vncserver and configure your password for vnc
vncserver

Once you start vncserver, .vnc/xstartup is created.
You need to replace "twm &" with "exec gnome-session &"

Then, restart your system and start vncserver again.

Outside the virtual machine, you can use vncviewer to access the vnc.
vncserver IPaddress:5901

EOF

