#!/bin/sh

SRCROOT=`pwd`
PATCH_FILE_PATH=${SRCROOT}/artc
FFMPEG_DIR=${SRCROOT}/ffmpeg-4.2
echo "FFMPEG_DIR:$FFMPEG_DIR"

cd $SRCROOT

cp $PATCH_FILE_PATH/rtsdec.c $FFMPEG_DIR/libavformat

set -x

patch -p0 -N --dry-run --silent -f $FFMPEG_DIR/libavformat/Makefile < $PATCH_FILE_PATH/libavformat_make_artc.patch 1>/dev/null
if [ $? -eq 0 ]; then
patch -p0 -f $FFMPEG_DIR/libavformat/Makefile < $PATCH_FILE_PATH/libavformat_make_artc.patch
fi

patch -p0 -N --dry-run --silent -f $FFMPEG_DIR/libavformat/allformats.c < $PATCH_FILE_PATH/libavformat_reg_artc.patch 1>/dev/null
if [ $? -eq 0 ]; then
patch -p0 -f $FFMPEG_DIR/libavformat/allformats.c < $PATCH_FILE_PATH/libavformat_reg_artc.patch
fi

set +x
