cat <<EOF 
##
## This script sets up
##  - hadoop and Java
##
EOF

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
sed -i.bak -e 's|#export HADOOP_HEAPSIZE=|export HADOOP_HEAPSIZE='${NODEMANAGER_RESOURCE_IN_MB}'|g' ${HADOOP_INSTALL}/etc/hadoop/hadoop-env.sh
sed -i.bak -e 's|$HADOOP_OPTS -Djava.net.preferIPv4Stack=true|$HADOOP_OPTS -Djava.net.preferIPv4Stack=true -XX:-UseGCOverheadLimit -Xmx'${NODEMANAGER_RESOURCE_IN_MB}'m|g' ${HADOOP_INSTALL}/etc/hadoop/hadoop-env.sh

echo "Are you sure you want to update your ~/.bash_profile?"
read -p "y or n) " yn
case $yn in
    [Yy]* )

    cp ~/.bash_profile ~/.bash_profile.bak
cat ${BASH_PROFILE_ORIG} | sed -e "s#<HADOOP_INSTALL>#${HADOOP_INSTALL}#g" | sed -e "s#<SPARK_INSTALL>#${SPARK_INSTALL}#g" > ~/.bash_profile

    echo "Your updated .bash_profile is:"
    cat ~/.bash_profile

esac


