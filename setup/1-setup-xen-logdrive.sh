cat << EOF
##
## This script 
##  - installs Xen
##  - installs LogDrive preservation and restoration functions
##
EOF

XEN_ROOT=/usr/src
XEN_VERSION=4.1.2

if [ -e ${XEN_ROOT}/xen-${XEN_VERSION}  ]; then
	echo "Current setting of O_DIRECT in ${XEN_ROOT}:"
	grep "#define O_DIRECT_FOR_AIO" ${XEN_ROOT}/xen-4.1.2/tools/blktap2/drivers/block-aio.c
	grep "#define O_DIRECT_FOR_PRSV" ${XEN_ROOT}/xen-4.1.2/tools/blktap2/drivers/preservation.c
fi
echo "Please change O_DIRECT_FOR_ flags in the following src if you want to switch O_DIRECT options"
echo xen-with-blktap/src/tools/blktap2/drivers/preservation.c 
echo xen-with-blktap/src/tools/blktap2/drivers/block-aio.c
echo "---"
grep "define O_DIRECT_FOR" xen-with-blktap/src/tools/blktap2/drivers/preservation.c 
grep "define O_DIRECT_FOR" xen-with-blktap/src/tools/blktap2/drivers/block-aio.c 
echo "---"

if [ -e ${XEN_ROOT}/xen-${XEN_VERSION}  ]; then
        echo "---"
        echo "Current setting of DEFAULT_BLOCK_SIZE in ${XEN_ROOT}"
        grep "#define DEFAULT_BLOCK_SIZE" ${XEN_ROOT}/xen-4.1.2/tools/blktap2/drivers/utils.h
fi

echo "Please change DEFAULT_BLOCK_SIZE in the following src"
echo xen-with-blktap/src/tools/blktap2/drivers/util.h

if [ -e ${XEN_ROOT}/xen-${XEN_VERSION}  ]; then
        echo "---"
        echo "Current setting of DEFAULT_BLOCK_SIZE in ${XEN_ROOT}"
        grep "#define DEFAULT_BLOCK_SIZE" ${XEN_ROOT}/xen-4.1.2/tools/blktap2/drivers/utils.h
fi


echo "---"
if [ ! -e ../download/xen-4.1.2.tar.gz ]; then
  echo "Error: could not find ../download/xen-4.1.2.tar.gz"
  echo "Error: please executes ../download/downlods.sh first"
  exit 1
fi

if [ -e ${XEN_ROOT}/xen-4.1.2 ]; then
  echo "Error: ${XEN_ROOT}/xen-4.1.2/ already exist"
  echo "Error: please delete ${XEN_ROOT}/xen-4.1.2/ first"
  exit 1
fi

echo "Are you sure you want to install Xen with prsv-sys (blktap2 driver)? "
echo " In most cases, you do not need to use O_DIRECT."
echo "Current setting in prsv-sys is"
grep "#define O_DIRECT_FOR_AIO" ./xen-with-blktap/src/tools/blktap2/drivers/block-aio.c
grep "#define O_DIRECT_FOR_PRSV" ./xen-with-blktap/src/tools/blktap2/drivers/preservation.c
grep "#define DEFAULT_BLOCK_SIZE" ./xen-with-blktap/src/tools/blktap2/drivers/utils.h
read -p "y or n) " yn
case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Canceled."; exit;;
    * ) echo "Please answer y(es) or n(o)."; exit;;
esac

echo "--- Extracting xen-4.1.2.tar.gz onto ${XEN_ROOT}/"
tar xvzf ../download/xen-4.1.2.tar.gz -C ${XEN_ROOT}

echo "--- Copying modified and newly appended files for prsv-sys on original Xen 4.1.2"
cd xen-with-blktap
sh copy-diff-and-new-files.sh 1
cd ..

echo "--- Making Xen ---"
cd ${XEN_ROOT}/xen-4.1.2/tools/check
./chk build
./chk install
cd ${XEN_ROOT}/xen-4.1.2
make -j3 xen tools
echo "--- Installing Xen ---"
make install-xen install-tools

echo "--- Finished $0"

