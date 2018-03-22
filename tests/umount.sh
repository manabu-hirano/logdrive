#!/bin/sh
#cat << EOF
## Executing umount.sh...
##  umount.sh image_file_path [mount_path_to_be_unmount]
##    destroy the tap device that are specified by a parameter.
##    the parameter must be specified by an absolute path.
#EOF

function destroyTapDevice() {
        ## Check pid and minor of the tap device
        PID=`echo $1 | sed 's/^pid=\([[:digit:]]*\) minor=\([[:digit:]]*\).*/\1/'`
        MINOR=`echo $1 | sed 's/^pid=\([[:digit:]]*\) minor=\([[:digit:]]*\).*/\2/'`
        echo Destroying tap device process ${PID}, minor ${MINOR} ...
        ## Destroy the tap
        tap-ctl close -m ${MINOR} -p ${PID}
        tap-ctl detach -m ${MINOR} -p ${PID}
        tap-ctl free -m ${MINOR}
}

if [ "$1" = "" ]; then
  echo "Error: image_file_path is not specified"
  exit 1
fi

if [ "$2" != "" ]; then
  #echo "Unmounting $2 ..."
  umount $2 > /dev/null 2>&1
fi

IFS=$'\n' ## This need to process the following for loop
for LINE in `tap-ctl list`
do
	PIDCHECK=`echo ${LINE} | grep "pid="`
	if [ "${PIDCHECK}" = "" ]; then
		#echo Failed to read line --- ${LINE}
		continue
	fi
	TARGETCHECK=`echo ${PIDCHECK} | grep $1`
        if [ "${TARGETCHECK}" = "" ]; then
                #echo Line is not the target --- ${LINE}
                continue
        fi
	##echo "Destroying ... ${LINE}"
	destroyTapDevice ${LINE}
done

