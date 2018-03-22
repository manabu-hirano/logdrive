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

In our script, host's IP address is ${HOST_IP}, and guest OS's IP addresses are 192.168.1.{151, 152, 153, ...} if you use the above setting.

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
   1-36) [ ENTER 1 FOR    
   The number of VMs is set to 1
   Please specify the installation directory of VMs:
   /benchmark) [ ENTER ]
   The installation directory of VMs is set to /benchmark
   Are you sure to proceed to install VMs?
   y or n) [ ENTER y ]

while the script is installing OSes on VMs, you can check the progress as follows:

  # To list virtual machines
  xl list
  # To switch console of a virtual machine
  xl console tap:preservation-vm-1
  # To show the output of make-VMs.sh (change the last number to specify a VM)
  tail -f /tmp/preservation-vm-1.log

## Running the tests

### Preservation

### Restoration

### Indexing

### Search



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

