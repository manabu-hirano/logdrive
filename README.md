# LogDrive

LogDrive is surveillance and forensic analysis tools for Xen-based IaaS cloud environments.

## Getting Started

### Prerequisites: operating system 

Download CentOS-6.9-x86_64-bin-DVD1.iso from https://www.centos.org and boot your computer using the burnt disc. Install CentOS 6.9 on your computer with the following options.

- Basic Storage Devices
- Minimal Desktop
- select "Customize now" -> select "Development" -> check "Development Tools"

After the installation, disable firewall, selinux, and Network Manager services.

    service iptables stop
    service ip6tables stop
    chkconfig iptables off
    chkconfig ip6tables off
    vi /etc/selinux/config
      SELINUX=disabled
    service NetworkManager stop
    chkconfig NetworkManager off

### Prerequisites: downloading related software


Clone Git repository.

    unset SSH_ASKPASS
    git clone https://github.com/manabu-hirano/logdrive.git

Execute ./download/download.sh script to obtain the following software.

    cd logdrive/download
    bash download.sh

- hadoop-2.9.0.tar.gz
- bridge-utils-1.5-3.fc17.src.rpm
- xen-4.1.2.tar.gz
- CentOS-5.11-i386-bin-DVD-1of2.iso (Guest OS)

Confirm the above software are in ./download directory.

### Prerequisites: installing LogDrive and related software

Execute setup scripts as follows:

    cd ../setup
    bash 0-setup-bridge-utils.sh
    bash 1-setup-xen-logdrive.sh
    bash 2-setup-kernel.sh

After the kernel installation, you need to config your grub
and reboot your computer. Please see the details in the end
of the output of the 2-setup-kernel.sh.

After rebooting your machine, execute the following scripts.

    bash 3-setup-network.sh
    bash 4-setup-benchmark.sh
    bash 5-setup-hadoop.sh

## Installing guest OS for tests

First, you need to specify IP address of your computer as follows:

    cd tests
    vi ipaddr_definition.sh
    HOST_IP=192.168.1.130  # YOUR COMPUTER'S IP ADDRESS
    GUEST_IP_SUFFIX_BASE=150  # SUFFIX OF GUEST OS'S IP ADDRESS

In our script, host's IP address is ${HOST_IP}, and guest OS's IP addresses are 192.168.1.{151, 152, 153, ...}/24 when you use the above setting.

    cd tests
    bash make-VMs.sh
    ## This scripts makes VMs by answering questions
    ##
    Please specify the disk type you want to use:
    1) BLKTAP2 aio
    2) BLKTAP2 preservation
    3) NON-BLKTAP2, file
    1-3) [ ENTER 2 ]
    Disk type is set to preservation
    Please specify the number of VMs you want to create:
    1-36) [ ENTER 1 (YOU CAN SPECIFY UP TO 36 VMs) ]   
    The number of VMs is set to 1
    Please specify the installation directory of VMs:
    /benchmark) [ ENTER ]
    The installation directory of VMs is set to /benchmark
    Are you sure to proceed to install VMs?
    y or n) [ ENTER y ]

while the script is installing OS on VM, you can check the progress as follows:

    # To list virtual machines
    xl list
    # To switch console of a virtual machine
    xl console tap:preservation-vm-1
    # To show the output of make-VMs.sh (change the last number to specify a VM)
    tail -f /tmp/preservation-vm-1.log

The LogDrive database of the installed virtual machine is /benchmark/preservation-vm-1.img.

## Installing benchmark software on VMs

If you need to execute benchmark software on VMs, use the following instructions.

    rpm -ivh https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    yum -y install sshpass
    
    bash auto-setup-VMs.sh 2 1
     ## 2 for preservation, 1 for the number of VMs to be setup

## Running the benchmark software on VMs

First, you need to add a user "download" with password "test" as follows to gather the results of benchmark software on multiple VMs.

    useradd download
    passwd download 
     Changing password for user download.
     New password: [ ENTER "test" ]
     BAD PASSWORD: it is too short
     BAD PASSWORD: is too simple
     Retype new password: [ ENTER "test" ]

    # Copy original logdrive file
    cp /benchmark/preservation-vm-1.img /benchmark/preservation-vm-1.img.orig
    bash auto-runtest-VMs.sh

You can check the results of benchmark software on VMs as CSV files in /benchmark/results/. If you need to execute further benchmark, see the detail of the auto-runtest-VMs.sh.

### Preservation mode on virtual machines

Typical steps to start and to shutdown virtual machines with LogDrive support as follows.

First, you need to obtain the current UNIX time to restore the LogDrive after this test.

    [root@localhost tests]# date +%s
    1521800128

The above UNIX time will be needed to restore the previous state of the LogDrive database.

    xl create -c /benchmark/preservation-vm-1.postinstall.xl.cfg
    ...
    preservation-vm-1 login: [ ENTER "root" ]
    Password: [ ENTER "test" ]
    [root@preservation-vm-1 ~]# echo "THIS IS TEST" > /root/test.txt 

The operations that are executed on the virtual machines are recorded in LogDrive database (i.e., /benchmark/preservation-vm-1.img). Finally, you need to shutdown the virtual machine.

    [root@preservation-vm-1 ~]# shutdown -h now
    ....
    System halted.

After shuting down the virtual machine, remove the blktap instance. This step flushes the indexes of the LogDrive database.

    [root@localhost logdrive]# tap-ctl list
    25076  0    0 preservation /benchmark/preservation-vm-1.img
    [root@localhost tests]# bash ./umount.sh /benchmark/preservation-vm-1.img 
    Destroying tap device process 25075, minor 0 ...
    [root@localhost tests]# tap-ctl list
    [root@localhost tests]# [ CHECK THERE IS NO BLKTAP INSTANCE HERE ]


To compare between the restored state and the latest state of the LogDrive database, get the current UNIX time again.

    [root@localhost tests]# date +%s
    1521800391
 
At this point, you can use the LogDrive database (i.e., /benchmark/preservation-vm-1.img) in restoration mode.

### Restoration mode using LogDrive database

First, you need mount points to restore the LogDrive database. In this turorial, we use the following mount points (If you have problems, chenge the mount points).

    [root@localhost tests]# mkdir /mnt/timetravel-1
    [root@localhost tests]# mkdir /mnt/timetravel-2

In this tutorial, we restore two previous virtual disks to compare the difference between them. The last argument after colon is the UNIX time at which the disk is restored.

    [root@localhost tests]# tap-ctl create -a timetravel:/benchmark/preservation-vm-1.img:1521800128
    /dev/xen/blktap-2/tapdev1  <= CHECK THIS NAME
    [root@localhost tests]# tap-ctl create -a timetravel:/benchmark/preservation-vm-1.img:1521800391
    /dev/xen/blktap-2/tapdev2  <= CHECK THIS NAME

Now, we have two virtual block devices named tapdev1 and tapdev2. These two devices are created by LogDrive framework. Let's check the internal state of the virtual device.

    [root@localhost tests]# fdisk -l -u /dev/xen/blktap-2/tapdev1
    
    Disk /dev/xen/blktap-2/tapdev1: 10.7 GB, 10737418240 bytes
    255 heads, 63 sectors/track, 1305 cylinders, total 20971520 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x0004d192

                     Device Boot      Start         End      Blocks   Id  System
    /dev/xen/blktap-2/tapdev1p1   *          63    18908504     9454221   83  Linux
    /dev/xen/blktap-2/tapdev1p2        18908505    20948759     1020127+  82  Linux swap / Solaris

The two devices have the identical partition table, so we can mount these two devices in the same way except for a mount point. Mount root partition of the different UNIXT time in read only mode as follows:

    [root@localhost ]# mount -t ext3 -o ro,offset=`expr 63 \* 512` /dev/xen/blktap-2/tapdev1 /mnt/timetravel-1 
    [root@localhost ]# mount -t ext3 -o ro,offset=`expr 63 \* 512` /dev/xen/blktap-2/tapdev2 /mnt/timetravel-2

Let's check the difference between the two restored disks.

    [root@localhost ]# diff -r /mnt/timetravel-1/root/ /mnt/timetravel-2/root/
    diff -r /mnt/timetravel-1/root/.bash_history /mnt/timetravel-2/root/.bash_history
    19a20,23
    > ls
    > echo "THIS IS THE TEST" > /root/test.txt
    > less /root/test.txt 
    > shutdown -h now
    Only in /mnt/timetravel-2/root/: test.txt
    [root@localhost ]# cat /mnt/timetravel-2/root/test.txt 
    THIS IS THE TEST
    [root@localhost ]# 

You will found the difference in .bash_history and the newly created file "test.txt".

Finally, we have to unmount the restored devices and to remove the LogDrive instance as follows.

    [root@localhost tests]# tap-ctl list
    1928  1    0 timetravel /benchmark/preservation-vm-1.img:1521800128
    1935  2    0 timetravel /benchmark/preservation-vm-1.img:1521800391
    [root@localhost tests]# df
    Filesystem           1K-blocks     Used Available Use% Mounted on
    ....
    /dev/xen/blktap-2/tapdev1
                       9158060  2691200   5994152  31% /mnt/timetravel-1
    /dev/xen/blktap-2/tapdev2
                       9158060  2691240   5994112  31% /mnt/timetravel-2
    
    [root@localhost tests]# bash ./umount.sh /benchmark/preservation-vm-1.img:1521800128 /mnt/timetravel-1
    Destroying tap device process 1928, minor 1 ...
    [root@localhost tests]# bash ./umount.sh /benchmark/preservation-vm-1.img:1521800391 /mnt/timetravel-2
    Destroying tap device process 1935, minor 2 ...
    [root@localhost tests]# tap-ctl list
    [root@localhost tests]# [ CONFIRM NO BLKTAP HERE ]
    [root@localhost tests]# df
       [ CONFIRM THERE IS NO MOUNT POINTS RELATED TO LOGDRIVE HERE ]

### Setup Hadoop and MapReduce programs

In the indexing and searching phase, we use Hadoop framework. We format HDFS first.

    [root@localhost setup]# hdfs namenode -format
    ....
    /************************************************************
    SHUTDOWN_MSG: Shutting down NameNode at localhost/127.0.0.1
    ************************************************************/

After formating the HDFS, start dfs and yarn services.

    [root@localhost setup]# /usr/local/hadoop-2.9.0/sbin/start-all.sh 
    This script is Deprecated. Instead use start-dfs.sh and start-yarn.sh
    18/03/23 21:56:39 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    Starting namenodes on [localhost]
    root@localhost's password: 
    localhost: starting namenode, logging to /usr/local/hadoop-2.9.0/logs/hadoop-root-namenode-localhost.localdomain.out
    root@localhost's password: 
    localhost: starting datanode, logging to /usr/local/hadoop-2.9.0/logs/hadoop-root-datanode-localhost.localdomain.out
    Starting secondary namenodes [0.0.0.0]
    root@0.0.0.0's password: 
    0.0.0.0: starting secondarynamenode, logging to /usr/local/hadoop-2.9.0/logs/hadoop-root-secondarynamenode-localhost.localdomain.out
    18/03/23 21:57:06 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    starting yarn daemons
    starting resourcemanager, logging to /usr/local/hadoop-2.9.0/logs/yarn-root-resourcemanager-localhost.localdomain.out
    root@localhost's password: 
    localhost: starting nodemanager, logging to /usr/local/hadoop-2.9.0/logs/yarn-root-nodemanager-localhost.localdomain.out

Check the status of your HDFS via http://localhost:50070/. If you cannot see the management screen, check /usr/local/hadoop-2.9.0/logs/*.log.

Then, compile the Hadoop MapReduce programs.

    [root@localhost tests]# bash compile.sh 
    Are you sure you want to delete AnalysisSystem.jar and ./jp directory?
    y or n) [ ENTER "y" ]
    ....
    Please note that these classes need the following external jar files to execute:
    /usr/local/hadoop-2.9.0/share/hadoop/common/hadoop-common-2.9.0.jar:/usr/local/hadoop-2.9.0/share/hadoop/mapreduce/hadoop-mapreduce-client-core-2.9.0.jar:./
    [root@localhost tests]# 

When the compilation was success, you can foud AnalysisSystem.jar in ./tests directory.

### Indexing

First, convert LogDrive database file in local file system into SequenceFile in HDFS.

    [root@localhost tests]# hadoop fs -rm /preservation-vm-1.seq
    [root@localhost tests]# hadoop jar AnalysisSystem.jar jp.ac.toyota_ct.analysis_sys.convertToSequenceFileFromLdLocal /benchmark/preservation-vm-1.img /preservation-vm-1.seq /tmp/info.txt
    18/03/23 23:19:32 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    18/03/23 23:19:33 INFO compress.CodecPool: Got brand-new compressor [.deflate]
       [ WAIT A FEW MINUTES... ]
    [root@localhost tests]# 

You can check the output file via http://localhost:50070/explorer.html#/.
Next, create HashDB from the created SequenceFile in the above step.

    [root@localhost tests]# hadoop fs -rmr /preservation-vm-1.md5
    [root@localhost tests]# hadoop jar AnalysisSystem.jar jp.ac.toyota_ct.analysis_sys.hashIndex /preservation-vm-1.seq /preservation-vm-1.md5
    ....
      [ WAIT A FEW MINUTES ... ]
    ....
    		WRONG_REDUCE=0
	File Input Format Counters 
		Bytes Read=2417399078
	File Output Format Counters 
		Bytes Written=112712198
    78193:ms

You can check the output HashDB directory of preservation-vm-1.md5 via http://localhost:50070/explorer.html#/.

If you check the contents of the HashDB, use hadoop command with fs option. You will be able to see MD5, UNIX timestamps, LBA, and size of LBA.
 
    [root@localhost tests]# hadoop fs -text /preservation-vm-1.md5/part-r-00000
    ....
    01aa484db799e7d2febbea1d486cc824	1521814332,774557330,1889029,4096
    01aa484db799e7d2febbea1d486cc824	1521814332,774548310,1889029,1344
       [ ENTER CTRL-C TO STOP ]

### Search (1): sector-hash based file detection

### Search (2): simple string search


## Authors

- Manabu Hirano - project manager
- Contributors: Hiromu Ogawa, Koki Yoshida, Natsuki Tsuzuki, Seishiro Ikeda

## License

This project is licensed under the BSD License

    Copyright (c) 2018, Manabu Hirano
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

