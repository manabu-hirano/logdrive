cat << EOF
##
## This script sets up
##  - xencommons service
##  - ifcfg-eth0 and ifcfg-xenbr0
##
EOF

## EDIT HERE IF YOUR NIC IS NOT eth0
NET_IF=eth0

echo "--- This script update network config for ${NET_IF}"
echo "--- Is your network interface ${NET_IF}?"
read -p "y or n) " yn
case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Please edit the head of this file first"; exit;;
    * ) echo "Please answer y(es) or n(o)."; exit;;
esac

ETH0_CFG_SRC=./network-settings/ifcfg-${NET_IF}
XENBR0_CFG_SRC=./network-settings/ifcfg-xenbr0
NETWORK_CFG_DST=/etc/sysconfig/network-scripts

echo "--- Start xencoomns as an automatic daemon"
service xencommons start
chkconfig xencommons on

echo "--- Are you sure to copy ${ETH0_CFG_SRC} "
echo "---  in ${NETWORK_CFG_DST}?"
cat ${ETH0_CFG_SRC}

read -p "y or n) " yn
case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Please edit ${ETH0_CFG_SRC} first"; exit;;
    * ) echo "Please answer y(es) or n(o)."; exit;;
esac 

echo "--- Are you sure to copy ${XENBR0_CFG_SRC} "
echo "---  in ${NETWORK_CFG_DST}?"
cat ${XENBR0_CFG_SRC}

read -p "y or n) " yn
case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Please edit ${XENBR0_CFG_SRC} first"; exit;;
    * ) echo "Please answer y(es) or n(o)."; exit;;
esac

echo "--- Copying ${ETH0_CFG_SRC} and ${XENBR0_CFG_SRC}"
echo "---  in ${NETWORK_CFG_DST}"
cp -n ${NETWORK_CFG_DST}/ifcfg-${NET_IF} ${NETWORK_CFG_DST}/ifcfg-${NET_IF}.bak
cp -n ${NETWORK_CFG_DST}/ifcfg-xenbr0 ${NETWORK_CFG_DST}/ifcfg-xenbr0.bak

cp -f ${ETH0_CFG_SRC} ${NETWORK_CFG_DST}/
cp -f ${XENBR0_CFG_SRC} ${NETWORK_CFG_DST}/

echo "--- Restarting network services"
service network restart

echo "--- Finished $0"

