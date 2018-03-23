#!/bin/sh

JAVA_CLASSPATH=/usr/local/hadoop-2.9.0/share/hadoop/common/hadoop-common-2.9.0.jar:/usr/local/hadoop-2.9.0/share/hadoop/mapreduce/hadoop-mapreduce-client-core-2.9.0.jar:./

JAVAC_OPT=" -encoding UTF-8 "
PACKAGE_NAME=jp/ac/toyota_ct/analysis_sys
JAR_NAME=AnalysisSystem.jar

echo "Are you sure you want to delete ${JAR_NAME} and ./jp directory?"
read -p "y or n) " yn
case $yn in
  [Yy]*)
    if [ -e ./${JAR_NAME} ] || [ -e ./jp ]; then
      rm -rf jp
      rm ${JAR_NAME}
      rm *.class
    fi
  ;;
  *)
    echo "Compile aborted"
    exit
  ;;
esac

echo "Compiling Java files..."

javac ${JAVAC_OPT} ByteControl.java
javac ${JAVAC_OPT} HashAlgorithm.java
javac ${JAVAC_OPT} preservationRecord.java preservationDatabase.java preservationRecordInfo.java

echo "Moving some the following class files to ${PACKAGE_NAME} because they are needed by following compiles"
mkdir -p ${PACKAGE_NAME}
ls *.class
mv *.class ${PACKAGE_NAME}

javac -classpath ${JAVA_CLASSPATH} ${JAVAC_OPT} hashIndex.java
javac -classpath ${JAVA_CLASSPATH} ${JAVAC_OPT} samplingIndex.java
javac -classpath ${JAVA_CLASSPATH} ${JAVAC_OPT} hashSearch.java
javac -classpath ${JAVA_CLASSPATH} ${JAVAC_OPT} keywordSearch.java
javac -classpath ${JAVA_CLASSPATH} ${JAVAC_OPT} convertToSequenceFileFromLdLocal.java

echo "Moving the following compiled class files to ${PACKAGE_NAME}..."
ls *.class
mv *.class ${PACKAGE_NAME}

echo "Creating jar file: ${JAR_NAME} "
jar cvf ${JAR_NAME} jp

echo "Complete creating ${JAR_NAME} consists of the following class files!"
jar tf ${JAR_NAME}

echo "Please note that these classes need the following external jar files to execute:"
echo ${JAVA_CLASSPATH}
