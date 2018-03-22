##
echo Deleting previous files
yes | rm bonnie.tar
yes | rm -rf bonnie++-1.97.1
yes | rm CentOS-Base.repo
##
echo Downloading new repository setting
wget http://192.168.1.210/CentOS-Base.repo
yes | cp CentOS-Base.repo /etc/yum.repos.d/
##
echo Installing gcc
yum -y install gcc
yum -y install gcc-c++
##
echo Downloading bonnie
wget http://192.168.1.210/bonnie.tar
tar xvf bonnie.tar 
cd bonnie++-1.97.1/
make clean
make; make install
##
echo Installing epel-release and sshpass
yum -y install epel-release
yum -y install sshpass
##
shutdown -h now

