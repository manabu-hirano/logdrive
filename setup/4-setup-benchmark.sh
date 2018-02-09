cat << EOF
##
## This script sets up
##  - Bonnie++ 
EOF

BONNIE_TGZ=../downloads/bonnie++-1.97.tgz

if [ ! -e ${BONIE_TGZ} ]; then
  echo "You need to download ${BONNIE_TGZ} first."
  exit 1
fi

echo "Copying original Bonnie++ benchmark software to /tmp"
tar xvzf ${BONNIE_TGZ} -C /tmp
echo "Overwriting MIN_TIME of bonnie.h with "0.01"
cp ./bonnie/bonnie.h /tmp/bonnie++-1.97.1/
## Save current directory to OLDPWD
pwd
pushd /tmp
echo "Archiving bonnie++ sorce code to tar for VMs"
tar cvf /tmp/bonnie.tar bonnie++-1.97.1
cd bonnie++-1.97.1
echo "Making bonnie++ on this host"
make install
popd

cat << EOF
bonnie.tar was created in /tmp/
EOF

echo "--- Finished $0"

