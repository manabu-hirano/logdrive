cat << EOF
## This script runs setup-VMs.sh automatically.
## TAP_TYPE 1=aio,2=prsv,3=file

EOF

TAP_TYPE=2

NUMBER_OF_VMS=1

echo "Copying benchmark software to /var/www/html"
yes | cp ./programs/bonnie.tar /var/www/html
yes | cp ./programs/install-bench.sh /var/www/html
yes | cp ./programs/CentOS-Base.repo /var/www/html
service httpd start

echo "Starting setup software on VMs..."
date

mkdir /benchmark

sh ./setup-VMs.sh ${TAP_TYPE} ${NUMBER_OF_VMS}
sh shutdown-all-VMs.sh ${TAP_TYPE} ${NUMBER_OF_VMS}

echo "Finishing setup software on VMs..."
date
 
