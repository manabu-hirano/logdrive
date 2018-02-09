#!/bin/sh

echo downloading hadoop
wget http://ftp.jaist.ac.jp/pub/apache/hadoop/common/hadoop-2.9.0/hadoop-2.9.0.tar.gz

exit

echo downloading bridge-utils-1.5-3.fc17.src.rpm
wget http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/17/Fedora/source/SRPMS/b/bridge-utils-1.5-3.fc17.src.rpm

echo downloading xen-4.1.2.tar.gz
wget http://www.xenproject.org/downloads/xen-archives/supported-xen-41-series/xen-412/21-xen-412/file.html
mv file.html xen-4.1.2.tar.gz

echo downloading CentOS5.11 ISO image
wget http://ftp.iij.ad.jp/pub/linux/centos-vault/5.11/isos/i386/CentOS-5.11-i386-bin-DVD-1of2.iso


