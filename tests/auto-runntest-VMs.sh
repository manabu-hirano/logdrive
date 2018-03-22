cat << EOF
## This script runs runtest-VMs.sh automatically.
##
EOF

PRSV_TYPE=2
CSV_DIR=/benchmark/csv_dir
RESULT_DIR=/benchmark/results

if [ ! -e ${CSV_DIR} ]; then
	mkdir ${CSV_DIR}
        chown download ${CSV_DIR}
fi

if [ ! -e ${RESULT_DIR} ]; then
	mkdir ${RESULT_DIR}
fi

#REPEAT=3
REPEAT=1

for k in `seq 1 ${REPEAT}`
do
  echo "Starting benchmark tests... ${k}/${REPEAT}"

  PRSV_DIR=${RESULT_DIR}/${k}/

  if [ -e ${PRSV_DIR} ]; then
 	echo "Please delete directory ${PRSV_DIR} first"
        exit
  fi 

  echo "Creating output directories"
  mkdir -p ${PRSV_DIR}

#  for i in 1 2 4 8 16
  for i in 1
  do
	mkdir ${PRSV_DIR}/${i}
  done

  ## TEST FOR PRESERVATION
#  for i in 1 2 # 4 8 16
  for i in 1
  do
    # The following overwrite step is needed because prsv records all past logs
    # It will reach the limit of the disk soon 
    for j in `seq 1 ${i}`
    do
    	yes | cp /benchmark/preservation-vm-${j}.img.orig /benchmark/preservation-vm-${j}.img
    done
    sh ./runtest-VMs.sh ${PRSV_TYPE} ${i}
    yes | cp ${CSV_DIR}/*.csv ${PRSV_DIR}/${i}/
    for file in `\find ${PRSV_DIR}/${i} -name \*.csv -type f`;
    do
      bon_csv2html $file > $file.html
    done
    cat ${PRSV_DIR}/${i}/preservation*.csv > ${PRSV_DIR}/${i}/all.csv
    sh shutdown-all-VMs.sh 2 ${i}
  done

done

echo "Finishing benchmark tests..."

