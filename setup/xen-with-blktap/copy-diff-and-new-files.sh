 
SRC_ROOT=/usr/src/xen-4.1.2
DST_ROOT=./src

if [ $# -ne 1 ]; then
  echo "Usage: sh copy-diff-and-new-files.sh [copy_direction]"
  echo "copy_direction=0: Copy xen-blktap code from ${SRC_ROOT} to ${DST_ROOT}"
  echo "copy_direction=1: Copy xen-blktap code from ${DST_ROOT} to ${SRC_ROOT}"
  exit 1
fi

if [ $1 -eq 0 ]; then
  echo "copy_direction=0: Copy xen-blktap code from ${SRC_ROOT} to ${DST_ROOT}"
elif [ $1 -eq 1 ]; then
  TMP_ROOT=${SRC_ROOT}
  SRC_ROOT=${DST_ROOT}
  DST_ROOT=${TMP_ROOT}
  echo "copy_direction=1: Copy xen-blktap code from ${SRC_ROOT} to ${DST_ROOT}"
else
  echo "bad options"
  exit 1
fi

echo --- Copying modifled files in Xen to this repository

cp -v ${SRC_ROOT}/tools/blktap2/drivers/block-aio.c  ${DST_ROOT}/tools/blktap2/drivers/
cp -v ${SRC_ROOT}/tools/blktap2/drivers/block-log.c  ${DST_ROOT}/tools/blktap2/drivers/
cp -v ${SRC_ROOT}/tools/blktap2/drivers/Makefile     ${DST_ROOT}/tools/blktap2/drivers/
cp -v ${SRC_ROOT}/tools/blktap2/drivers/tapdisk-disktype.c   ${DST_ROOT}/tools/blktap2/drivers/
cp -v ${SRC_ROOT}/tools/blktap2/drivers/tapdisk-disktype.h   ${DST_ROOT}/tools/blktap2/drivers/

cp -v ${SRC_ROOT}/tools/libxl/libxl.c          ${DST_ROOT}/tools/libxl/
cp -v ${SRC_ROOT}/tools/libxl/libxl_device.c   ${DST_ROOT}/tools/libxl/
cp -v ${SRC_ROOT}/tools/libxl/libxl.h          ${DST_ROOT}/tools/libxl/
cp -v ${SRC_ROOT}/tools/libxl/libxlu_cfg_l.c   ${DST_ROOT}/tools/libxl/
cp -v ${SRC_ROOT}/tools/libxl/libxlu_cfg_l.h   ${DST_ROOT}/tools/libxl/
cp -v ${SRC_ROOT}/tools/libxl/xl_cmdimpl.c     ${DST_ROOT}/tools/libxl/

echo --- Copying newly appended files in Xen to this repository

cp -v ${SRC_ROOT}/tools/blktap2/drivers/block-preservation.c   ${DST_ROOT}/tools/blktap2/drivers/ 
cp -v ${SRC_ROOT}/tools/blktap2/drivers/block-timetravel.c     ${DST_ROOT}/tools/blktap2/drivers/ 
cp -v ${SRC_ROOT}/tools/blktap2/drivers/preservation.c         ${DST_ROOT}/tools/blktap2/drivers/ 
cp -v ${SRC_ROOT}/tools/blktap2/drivers/preservation.h         ${DST_ROOT}/tools/blktap2/drivers/
cp -v ${SRC_ROOT}/tools/blktap2/drivers/utils.c                ${DST_ROOT}/tools/blktap2/drivers/ 
cp -v ${SRC_ROOT}/tools/blktap2/drivers/utils.h                ${DST_ROOT}/tools/blktap2/drivers/ 



