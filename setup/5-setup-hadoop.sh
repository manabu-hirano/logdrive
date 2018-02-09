cat <<EOF 
##
## This script sets up
##  - hadoop and Java
##
EOF

HADOOP_TGZ=hadoop-2.9.0.tar.gz
HADOOP_INSTALL=/usr/local/hadoop-2.9.0
BASH_PROFILE_ORIG=./hadoop-config/bash_profile.template

echo Are you sure you want to install java?
read -p "y or n) " yn
case $yn in
    [Yy]* )
	yum install java-1.8.0-openjdk
    	yum install java-1.8.0-openjdk-devel 
esac

echo Are you sure you want to install ${HADOOP_TGZ}?
read -p "y or n) " yn
case $yn in
    [Yy]* ) 
	tar xvzf ../downloads/${HADOOP_TGZ} -C /usr/local/
esac 

echo "Automatically update ${HADOOP_INSTALL}/etc/hadoop/hadoop-env.sh"
sed -i.bak -e 's|${JAVA_HOME}|/usr/lib/jvm/java|g' ${HADOOP_INSTALL}/etc/hadoop/hadoop-env.sh
echo "Other parameters in hadoop-env.sh such as heap should be configured for your computer."

echo "Are you sure you want to update your ~/.bash_profile?"
read -p "y or n) " yn
case $yn in
    [Yy]* )

    cp ~/.bash_profile ~/.bash_profile.bak
cat ${BASH_PROFILE_ORIG} | sed -e "s#<HADOOP_INSTALL>#${HADOOP_INSTALL}#g" > ~/.bash_profile

    echo "Your updated .bash_profile is:"
    cat ~/.bash_profile

esac


