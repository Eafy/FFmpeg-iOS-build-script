#!/bin/sh
#http://download.videolan.org/pub/videolan/x264/snapshots/
#version:x264-snapshot-20180426-2245.tar.bz2

SHELL_PATH=`pwd`
#需要编译的版本号
SRC_VERSION="20180426"
#资源文件/文件夹名称
SRC_NAME="x264-$SRC_VERSION"
SRC_PATH="$SHELL_PATH/$SRC_NAME"
#编译的平台
ARCHS="arm64 armv7 x86_64 i386"
#输出路径
PREFIX="$SHELL_PATH/x264-iOS"

#需要编译的平台
BUILD_ARCH=$1
#最低触发的版本
DEPLOYMENT_TARGET=$2

ARCHS="arm64 armv7 armv7s x86_64 i386"

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli"

if [ ! "$BUILD_ARCH" ]
then
BUILD_ARCH="all"
fi
if [ ! "$DEPLOYMENT_TARGET" ]
then
DEPLOYMENT_TARGET="8.0"
fi
fi

SRC_SCRATCH="$SHELL_PATH/scratch-x264"
SRC_THIN="$SHELL_PATH/thin-x264"
rm -rf "$SRC_SCRATCH" "$SRC_THIN" "$PREFIX"

if [ ! -r $SRC_NAME ]
then
    SRC_TAR_NAME="x264-snapshot-$SRC_VERSION-2245.tar.bz2"
    if [ ! -f "$SHELL_PATH/$SRC_TAR_NAME" ]
    then
        echo "$SRC_TAR_NAME source not found, Trying to download..."
        curl -O http://download.videolan.org/pub/videolan/x264/snapshots/$SRC_TAR_NAME || exit 1
    fi
    mkdir $SRC_PATH
    tar zxvf $SHELL_PATH/$SRC_TAR_NAME --strip-components 1 -C $SRC_PATH || exit 1
fi

for ARCH in $ARCHS
do
    if [ "$BUILD_ARCH" = "all" -o "$BUILD_ARCH" = "$ARCH" ]
    then
        echo "building $ARCH..."
        mkdir -p "$SRC_SCRATCH/$ARCH"
        cd "$SRC_SCRATCH/$ARCH"
        CFLAGS="-arch $ARCH -fno-stack-check"
        ASFLAGS=""

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            if [ "$ARCH" = "x86_64" ]
            then
                CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
                HOST=
            else
                CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=x86_64-apple-darwin"
            fi
        else
            PLATFORM="iPhoneOS"
            if [ "$ARCH" = "arm64" ]
            then
                HOST="--host=aarch64-apple-darwin"
                XARCH="-arch aarch64"
            else
                HOST="--host=arm-apple-darwin"
                XARCH="-arch arm"
            fi
            CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
            ASFLAGS="$CFLAGS"
        fi

        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"
        if [ PLATFORM = "iPhoneOS" ]
        then
            export AS="$SRC_PATH/tools/gas-preprocessor.pl $XARCH -- $CC"
        else
            export -n AS
        fi
        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"
        echo CC=$CC

        CC=$CC $SRC_PATH/configure \
            $CONFIGURE_FLAGS \
            $HOST \
            --extra-cflags="$CFLAGS" \
            --extra-asflags="$ASFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$SRC_THIN/$ARCH" || exit 1

        make -j3 install || exit 1
        cd $SHELL_PATH
    fi
done

echo "building lipo lib binaries..."
mkdir -p $PREFIX/lib
set - $ARCHS
cd $SRC_THIN/$1/lib
for LIB in *.a
do
    cd $SHELL_PATH
    lipo -create `find $SRC_THIN -name $LIB` -output $PREFIX/lib/$LIB
done

cd $SHELL_PATH
cp -rf $SRC_THIN/$1/include $PREFIX
rm -rf $SRC_SCRATCH
rm -rf $SRC_THIN
echo "building lipo x264 lib binaries successed"
