# LogDrive

LogDrive is surveillance and forensic analysis tools for Xen-based IaaS cloud environments.

## Getting Started

### Prerequisites: operating system and kernels

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

### Rrequisites: related software

Clone Git repository.

    unset SSH_ASKPASS
    git clone https://github.com/manabu-hirano/logdrive.git

Execute ./download/download.sh script to obtain the following software.

    cd logdrive/download
    sh download.sh

- bridge-utils-1.5-3.fc17.src.rpm
- xen-4.1.2.tar.gz
- CentOS-5.11-i386-bin-DVD-1of2.iso (Guest OS)

Confirm the above software are in ./download directory.

### Requisites: setup environments

Execute setup scripts as follows:

    cd ../logdrive/setup
    sh 0-setup-bridge-utils.sh
    sh 1-setup-xen-logdrive.sh
    sh 2-setup-kernel.sh

After the kernel installation, you need to config your grub
and reboot your computer. Please see the details in the end
of the output of the 2-setup-kernel.sh.




