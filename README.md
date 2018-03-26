# LogDrive

LogDrive is proactive data collection, surveillance, and analysis software for cloud forensics in Xen-based Infrastructure-as-a-Service (IaaS) cloud environments.

## Getting Started

### Requirement

You need a temporary PC to test this software and tutorial. The LogDrive framework uses custom Linux kernel so that we cannot use Docker unfortunately. We tested this tutorial on a PC with 8 GB RAM and 128 GB SSD. Please note that we did not test this tutorial on a virtual machine such as an EC2 instance yet (i.e., a virtual machine runs on a virtual machine). You also need Internet connection via DHCP.

### Prerequisites: host operating system 

Download CentOS-6.9-x86_64-bin-DVD1.iso from https://www.centos.org and boot your computer using the burnt disc. Install CentOS 6.9 on your temporary computer with the following options. 

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
    yum -y remove NetworkManager

Before the next step, reboot your computer.

### Prerequisites: downloading related software

Clone Git repository. If you cannot connect your local network, try "ifup eth0" (change the argument if your NIC is not eth0).

    [root@localhost ~]# unset SSH_ASKPASS
    [root@localhost ~]# git clone https://github.com/manabu-hirano/logdrive.git

Run ./download/download.sh script to obtain the following software.

    [root@localhost ~]# cd logdrive/download
    [root@localhost download]# bash download.sh

- hadoop-2.9.0.tar.gz
- bridge-utils-1.5-3.fc17.src.rpm
- xen-4.1.2.tar.gz
- CentOS-5.11-i386-bin-DVD-1of2.iso (Guest OS)

Confirm the above software were downloaded in ./download directory.

### Prerequisites: installing LogDrive and related software

Run setup scripts.

    [root@localhost logdrive]# cd ../setup
    [root@localhost setup]# bash 0-setup-bridge-utils.sh
    ...
     
    [root@localhost setup]# bash 1-setup-xen-logdrive.sh
    ##
    ## This script 
    ##  - installs Xen
    ##  - installs LogDrive preservation and restoration functions
    ##
    Are you sure you want to install Xen with prsv-sys (blktap2 driver)? 
    ...
    y or n) [ ENTER "y" ] 
    ... 
    [root@localhost setup]# bash 2-setup-kernel.sh
    ...
      [ THIS SCRIPT WILL TAKE LONGER THAN THE PREVIOUS SCRIPT ]

After the kernel installation, edit /etc/grub.conf and /etc/fstab, and reboot your computer. Please see the details in the end of the output of the 2-setup-kernel.sh.

    [root@localhost setup]# vi /etc/grub.conf
       [ INSERT THE FOLLOWING NEW ENTRY ]
    #hiddenmenu
    title Xen (4.1.2) with CentOS (2.6.32.57)
    root (hd0,0)
    kernel /xen-4.1.2.gz
    module /vmlinuz-2.6.32.57 ro root=/dev/mapper/VolGroup-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD rd_LVM_LV=VolGroup/lv_swap SYSFONT=latarcyrheb-sun16 rhgb crashkernel=auto  KEYBOARDTYPE=pc KEYTABLE=jp106 rd_LVM_LV=VolGroup/lv_root quiet rd_NO_DM
    module /initramfs-2.6.32.57.img
    
    [root@localhost setup]# vi /etc/fstab
       [ ADD THE FOLLOWING LINE BELOW THE LAST LINE ]
    xenfs                   /proc/xen               xenfs   defaults        0 0
    
    [root@localhost setup]# reboot

During rebooting process, select "Xen (4.1.2) with Cent OS (2.6.32.57)" at grub menu. After rebooting your machine, run the following scripts.

    [root@localhost setup]# bash 3-setup-network.sh
    ....
    --- Is your network interface eth0?
    y or n) [ ENTER "y" if your NIC is eth0 ]
    ....
    --- Are you sure to copy /tmp/ifcfg-eth0 
    ....
    y or n) [ ENTER "y" ]
    ....
    --- Are you sure to copy ./network-settings/ifcfg-xenbr0 
    ....
    y or n) [ ENTER "y" ]
    ....
    [root@localhost setup]# ip a
        [ CHECK xenbr0 has IP address and eth0 has no IP address (bridged to xenbr0) ]


    [root@localhost setup]# bash 4-setup-benchmark.sh
    ....
    --- Finished 4-setup-benchmark.sh
    
    [root@localhost setup]# bash 5-setup-hadoop.sh 
    Are you sure you want to install java?
    ....
    y or n) [ ENTER "y" ]
    ....
    Are you sure you want to install hadoop-2.9.0.tar.gz?
    y or n) [ ENTER "y" ]
    ....
    Are you sure you want to update your ~/.bash_profile?
    y or n) [ ENTER "y" ]
    ....
    
    [root@localhost setup]# source ~/.bash_profile


### Installing guest OS for tests

First, specify IP addresses of your computer and virtual machines as follows. In the following example, we assume that you have free IP address of 192.168.1.{151,152,...} for virtual machines in addition to your computer's IP address (i.e., 192.168.1.130). Please note that netmask has been fixed at 24 and network address has been fixed at 192.168.1 in the test scripts. If you need to change netmask and network address, edit the test scripts and configuration files.

    [root@localhost setup]# cd ../tests
    [root@localhost tests]# vi ipaddr_definition.sh
     HOST_IP=192.168.1.130  # YOUR COMPUTER'S IP ADDRESS
     GUEST_IP_SUFFIX_BASE=150  # SUFFIX OF GUEST OS'S IP ADDRESS

Run make-VMs.sh to install CentOS5 on new virtual machine.

    [root@localhost tests]# bash make-VMs.sh
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
    .... [ INSTALLATION OF GUEST OS ON VM TAKES A FEW MINUTES ] ...

While the script is installing OSes on virtual machines, you can check the progress as follows:

    # To list virtual machines
    [root@localhost tests]# xl list
    # To switch console of a virtual machine
    [root@localhost tests]# xl console tap:preservation-vm-1
    # To show the output of make-VMs.sh (change the last number to specify a VM)
    [root@localhost tests]# tail -f /tmp/preservation-vm-1.log

The LogDrive database of the installed virtual machine is /benchmark/preservation-vm-1.img.

### (Optional) Benchmarking VM's throughput

You can skip this section.

If you have to run benchmark software on VMs, see the following instructions.

    [root@localhost tests]# rpm -ivh https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    [root@localhost tests]# yum -y install sshpass
    
    [root@localhost tests]# bash auto-setup-VMs.sh 2 1
      ## 2 for preservation, 1 for the number of VMs to be setup

Before running benchmark software on virtual machines, add new user named "download" with password "test" to collect the results from multiple VMs automatically.

    [root@localhost tests]# useradd download
    [root@localhost tests]# passwd download 
     Changing password for user download.
     New password: [ ENTER "test" ]
     BAD PASSWORD: it is too short
     BAD PASSWORD: is too simple
     Retype new password: [ ENTER "test" ]

Then, run benchmark script as follows.

    # Copy original logdrive file
    [root@localhost tests]# cp /benchmark/preservation-vm-1.img /benchmark/preservation-vm-1.img.orig
    [root@localhost tests]# bash auto-runtest-VMs.sh
      [ THIS TAKES OVER TEN MINUTES ]

Check the result in /benchmark/results/1/1/{*.csv, *.html}. If you need further complex benchmark, edit auto-runtest-VMs.sh.

### Preservation mode on virtual machines

Typical steps to start and to shutdown virtual machines with LogDrive support as follows.

First, check the current UNIX time to restore the LogDrive after this test.

    [root@localhost tests]# date +%s
    1521826741

The above UNIX time is necessary to restore the previous state of the LogDrive database.

    [root@localhost tests]# xl create -c /benchmark/preservation-vm-1.postinstall.xl.cfg
    ...
    preservation-vm-1 login: [ ENTER "root" ]
    Password: [ ENTER "test" ]
    [root@preservation-vm-1 ~]# echo "THIS IS TEST" > /root/test.txt 

The write operations that are executed on the virtual machine are recorded in a LogDrive database (i.e., /benchmark/preservation-vm-1.img). Finally, shutdown the virtual machine.


    [root@preservation-vm-1 ~]# shutdown -h now
    ....
    System halted.

After shutting down the virtual machine, remove the blktap instance. This important process flushes the index of the LogDrive database.

    [root@localhost logdrive]# tap-ctl list
    25076  0    0 preservation /benchmark/preservation-vm-1.img
    [root@localhost tests]# bash ./umount.sh /benchmark/preservation-vm-1.img 
    Destroying tap device process 25075, minor 0 ...
    [root@localhost tests]# tap-ctl list
    [root@localhost tests]# [ CHECK THERE IS NO BLKTAP INSTANCE HERE ]


To compare between the restored state and the latest state of the LogDrive database, get the current UNIX time again.

    [root@localhost tests]# date +%s
    1521826952
 
At this point, you can use the LogDrive database (i.e., /benchmark/preservation-vm-1.img) in restoration mode.

### Restoration mode using LogDrive database

First, create mount points to restore the LogDrive database. If you have problems, change the mount points.

    [root@localhost tests]# mkdir /mnt/timetravel-1
    [root@localhost tests]# mkdir /mnt/timetravel-2

In this tutorial, we restore two previous virtual disks to compare the difference between them. The last argument after colon is the UNIX time at which the disk is restored.

    [root@localhost tests]#  tap-ctl create -a timetravel:/benchmark/preservation-vm-1.img:1521826741
    /dev/xen/blktap-2/tapdev0  <= CHECK THIS NAME
    [root@localhost tests]#  tap-ctl create -a timetravel:/benchmark/preservation-vm-1.img:1521826952
    /dev/xen/blktap-2/tapdev1 <= CHECK THIS NAME

Now, we have two virtual block devices named tapdev0 and tapdev1. These two devices are created by LogDrive framework. Let's check the internal state of the virtual device.

    [root@localhost tests]# fdisk -l -u /dev/xen/blktap-2/tapdev0
    
    Disk /dev/xen/blktap-2/tapdev0: 10.7 GB, 10737418240 bytes
    255 heads, 63 sectors/track, 1305 cylinders, total 20971520 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x000d2fab
    
                     Device Boot      Start         End      Blocks   Id  System
    /dev/xen/blktap-2/tapdev0p1   *          63    18908504     9454221   83  Linux
    /dev/xen/blktap-2/tapdev0p2        18908505    20948759     1020127+  82  Linux swap / Solaris

The two restored virtual block devices have the identical partition table, so we can mount them in the same way except for a device name and a mount point. Mount root partition of the different UNIX time in read only mode as follows:

    [root@localhost ]# mount -t ext3 -o ro,offset=`expr 63 \* 512` /dev/xen/blktap-2/tapdev0 /mnt/timetravel-1 
    [root@localhost ]# mount -t ext3 -o ro,offset=`expr 63 \* 512` /dev/xen/blktap-2/tapdev1 /mnt/timetravel-2

Let's check the difference between the two restored disks.

    [root@localhost tests]# diff -r /mnt/timetravel-1/root/ /mnt/timetravel-2/root/
    Only in /mnt/timetravel-2/root/: .bash_history
    Only in /mnt/timetravel-2/root/: test.txt
       [ THE ABOVE RESULT MAY DIFFER BECAUSE OF YOUR ACTIONS ON THE VIRTUAL MACHINE ]
    
    [root@localhost ]# cat /mnt/timetravel-2/root/test.txt 
    THIS IS THE TEST
    [root@localhost ]# 

You will find the differences in .bash_history and in the newly created file "test.txt" at least.

If you need to use conventional forensic tools to analyze them in file-system level, you can make disk image files by dd command.

    [root@localhost ]# dd if=/dev/xen/blktap-2/tapdev0 of=1521826741.img conv=noerror,sync
    [root@localhost ]# dd if=/dev/xen/blktap-2/tapdev1 of=1521826952.img conv=noerror,sync

Finally, unmount the restored devices and to remove the LogDrive instance as follows. This step cannot be skipped.

    [root@localhost tests]# tap-ctl list
    6368  0    0 timetravel /benchmark/preservation-vm-1.img:1521826741
    6382  1    0 timetravel /benchmark/preservation-vm-1.img:1521826952
    [root@localhost tests]# df
    Filesystem           1K-blocks     Used Available Use% Mounted on
    ....
    /dev/xen/blktap-2/tapdev1
                       9158060  2691200   5994152  31% /mnt/timetravel-1
    /dev/xen/blktap-2/tapdev2
                       9158060  2691240   5994112  31% /mnt/timetravel-2
   
    ## executes "bash ./umount.sh tap_name mout_point" as follows:
    [root@localhost tests]# bash ./umount.sh /benchmark/preservation-vm-1.img  /mnt/timetravel-1
    Destroying tap device process 6368, minor 0 ...
    [root@localhost tests]# bash ./umount.sh /benchmark/preservation-vm-1.img  /mnt/timetravel-2
    Destroying tap device process 6382, minor 1 ...
    
    [root@localhost tests]# tap-ctl list
    [root@localhost tests]# [ CONFIRM NO BLKTAP HERE ]
    
    [root@localhost tests]# df
       [ CONFIRM THERE IS NO MOUNT POINTS RELATED TO LOGDRIVE HERE ]

### Prerequisites: formatting HDFS and compiling MapReduce programs

In the indexing and searching phases, we use Hadoop framework. This tutorial uses your computer as single Hadoop master/slave server in stand-alone mode. First you have to format Hadoop distributed file system (HDFS).

    [root@localhost setup]# source ~/.bash_profile
    [root@localhost setup]# hdfs namenode -format
    ....
    /************************************************************
    SHUTDOWN_MSG: Shutting down NameNode at localhost/127.0.0.1
    ************************************************************/

After formatting your HDFS, start dfs and yarn services. You will need to input your password four times in this step. You can skip these inputs when you use PKI authentication.

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

If the compilation was success, you can find AnalysisSystem.jar in ./tests directory.

### Indexing

First, convert a LogDrive database file into SequenceFile in HDFS.

    [root@localhost tests]# hadoop fs -rm /preservation-vm-1.seq
    [root@localhost tests]# hadoop jar AnalysisSystem.jar jp.ac.toyota_ct.analysis_sys.convertToSequenceFileFromLdLocal /benchmark/preservation-vm-1.img /preservation-vm-1.seq /tmp/info.txt
    18/03/23 23:19:32 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    18/03/23 23:19:33 INFO compress.CodecPool: Got brand-new compressor [.deflate]
       [ WAIT A FEW MINUTES... ]
    [root@localhost tests]# 

Check the output file (i.e., /preservation-vm-1.seq) via http://localhost:50070/explorer.html#/. Then, create HashDB from SequenceFile that is created in the above step.

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

Check the output HashDB directory (i.e., /preservation-vm-1.md5/) via http://localhost:50070/explorer.html#/.

Use hadoop command with fs option to see the output. Each line consits of MD5 hash, UNIX time in second, UNIX time in nanosecond, LBA, and size of data.
 
    [root@localhost tests]# hadoop fs -text /preservation-vm-1.md5/part-r-00000
    ....
    01aa484db799e7d2febbea1d486cc824	1521814332,774557330,1889029,4096
    01aa484db799e7d2febbea1d486cc824	1521814332,774548310,1889029,1344
       [ ENTER CTRL-C TO STOP ]

### Search without sampling 

A hashSearch class searches a file in a HashDB using sector-hash based file detection method.

First, delete /results directory in HDFS. Then, run sector-hash based file detection class. The following example searches "true" program stored as /bin/true in the guest operating system.

    [root@localhost tests]# hadoop fs -rmr /results
    [root@localhost tests]# hadoop jar AnalysisSystem.jar jp.ac.toyota_ct.analysis_sys.hashSearch ./sample_file/true /preservation-vm-1.md5 /results
    ....
      [ WAIT A FEW SECONDS ... ]

Check the result.

    [root@localhost tests]# hadoop fs -text /results/part-r-00000
    18/03/24 03:14:21 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    
    1521825179,345658709,518766,3584
    1521825179,345662182,518766,4096
    1521825179,345662182,518767,3584
    1521825179,345672244,518767,4096
    1521825179,348702080,518918,3584
    1521825179,348705598,518918,4096
    1521825179,348705598,518919,3584
    1521825179,348709139,518919,4096
    1521825179,348709139,518920,3584
    1521825179,348712537,518920,4096
    1521825179,348712537,518921,1952
    1521825179,348721085,518921,4096

Each line consists of UNIX time in second, UNIX time in nanosecond, LBA, size of sector. Your results, especially UNIX time and LBA, may be different to the above results. These write logs have identical sectors of file "true".

### Search with sampling 

This section describes how to reduce search time by using sampling technique. The following example creates a sampled HashDB with sampling rate of 0.5%.

    [root@localhost tests]# hadoop fs -rmr /preservation-vm-1.md5-0.05
    [root@localhost tests]# hadoop jar AnalysisSystem.jar jp.ac.toyota_ct.analysis_sys.samplingIndex /preservation-vm-1.md5 /preservation-vm-1.md5-0.05 0.05
    ....
      [ WAIT A FEW SECONDS ... ]
    ....
	File Input Format Counters 
		Bytes Read=112712198
	File Output Format Counters 
		Bytes Written=562199
    7846:ms

Seach a target file in the sampled HashDB.

    [root@localhost tests]# hadoop fs -rmr /results
    [root@localhost tests]# hadoop jar AnalysisSystem.jar jp.ac.toyota_ct.analysis_sys.hashSearch ./sample_file/true /preservation-vm-1.md5-0.05 /results
    ....
    	File Input Format Counters 
		Bytes Read=6580363
	File Output Format Counters 
		Bytes Written=34
    3880:ms

Check the result. If you are lucky, you can see a few detected sector like below.

    [root@localhost tests]# hadoop fs -text /results/part-r-00000
    18/03/24 03:21:57 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    
    1521825179,348705598,518918,4096

If you could not find any sectors, change the sampling rate (such as 0.1) and try the above steps again ;-)


## Authors

- Manabu Hirano (hirano_at_toyota-ct.ac.jp) - project manager
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

