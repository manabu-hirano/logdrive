cat << EOF
##
## This script
##  - installs required packages 
##  - installs bridge-utils that supports blktap2
##  * we do not recoomend to run "yum update" here because of dependency problems
EOF

TMP_ROOT=/tmp
BRIDGE_UTILS=bridge-utils-1.5-3.fc17
BRIDGE_UTILS_RPM=../download/${BRIDGE_UTILS}.src.rpm

echo "--- Installing required packages"
yum install -y yum-utils libsysfs-devel libidn-devel zlib-devel libcurl-devel libX11-devel gtk2-devel python-devel ncurses-devel libaio-devel pciutils-devel libuuid-devel udev dev86 gettext gnutls-devel openssl-devel flex bison wget git iproute python zlib openssl SDL-devel transfig texi2html ghostscript tetex-latex perl iasl glibc-devel.i686 glibc-devel.x86_64 mercurial ruby httpd rpm-build gcc texinfo gcc-c++

if [ ! -e ${BRIDGE_UTILS_RPM} ]; then
  echo "Error: ${BRIDGE_UTILS_RPM} does not exist"
  echo "       Please runs ../download/download.sh first"
  exit 1
fi

echo "--- Installing ${BRIDGE_UTILS_RPM}"
rpm -ivh ${BRIDGE_UTILS_RPM}

echo "--- Building ${BRIDGE_UTILS} from src.rpm"
pushd ~/rpmbuild/SPECS
rpmbuild -bp --define 'dist .xen' bridge-utils.spec
cd ~/rpmbuild/BUILD/bridge-utils-1.5/libbridge

echo "--- Patching some header files for supporting <linux/in6.h>"
patch < ~/prsv-sys/setup/bridge-utils/libbridge.h.patch 
patch < ~/prsv-sys/setup/bridge-utils/libbridge_private.h.patch 

echo "--- Executing configure scripts etc."
umask 022
cd /root/rpmbuild/BUILD
cd bridge-utils-1.5
LANG=C
export LANG
unset DISPLAY
autoconf
CFLAGS='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
export CFLAGS
CXXFLAGS='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
export CXXFLAGS
FFLAGS='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -I/usr/lib64/gfortran/modules'
export FFLAGS
./configure --build=x86_64-redhat-linux-gnu --host=x86_64-redhat-linux-gnu --target=x86_64-redhat-linux-gnu --program-prefix= --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --includedir=/usr/include --libdir=/usr/lib64 --libexecdir=/usr/libexec --localstatedir=/var --sharedstatedir=/var/lib --mandir=/usr/share/man --infodir=/usr/share/info

echo "--- Making ${BRIDGE_UTILS}"
cd ~/rpmbuild/BUILD/bridge-utils-1.5/
make

echo "-- Installing ${BRIDGE_UTILS}"
make install

popd

echo "--- Finishing installing required packages and ${BRIDGE_UTILS} that supports blktap2."


