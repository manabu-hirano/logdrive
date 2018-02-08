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

Execute ./download/download.sh script to obtain the following software.

- bridge-utils-1.5-3.fc17.src.rpm
- xen-4.1.2.tar.gz
- CentOS-5.11-i386-bin-DVD-1of2.iso (Guest OS)

Confirm the above software are in ./download directory.

### Requisites: setup environments


