cat << EOF
## auto-setup-VMs.sh ${TAP_TYPE} ${NUMBER_OF_VMS}
##  ${TAP_TYPE}: 1 for aio, 2 for prsv, 3 for file
## This script runs setup-VMs.sh automatically.
EOF

INSTALL_BENCHMARK_ORIG=./programs/install-bench.sh.orig
source ./ipaddr_definition.sh

if [ $# == 2 ]; then
        TAP_TYPE=$1;
        NUMBER_OF_VMS=$2;
else
        echo "Usage) bash auto-setup-VMs TAP_TYPE NUMBER_OF_VMS";
	echo " TAP_TYPE: 1 for aio, 2 for preservation, 3 for file";
	exit;
fi

cat ${INSTALL_BENCHMARK_ORIG} | sed -e "s/HOST_IP/${HOST_IP}/g" > /tmp/install-bench.sh 

echo "Copying benchmark software to /var/www/html"
yes | cp ./programs/bonnie.tar /var/www/html
yes | cp /tmp/install-bench.sh /var/www/html
yes | cp ./programs/CentOS-Base.repo /var/www/html
service httpd start

echo "Starting setup software on VMs..."

sh ./setup-VMs.sh ${TAP_TYPE} ${NUMBER_OF_VMS}
sh shutdown-all-VMs.sh ${TAP_TYPE} ${NUMBER_OF_VMS}

echo "Finishing setup software on VMs..."
 
