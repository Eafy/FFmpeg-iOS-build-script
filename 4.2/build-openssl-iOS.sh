#!/bin/sh
#https://www.openssl.org/source/openssl-1.1.0k.tar.gz

SHELL_PATH=`pwd`
#需要编译的版本号
SRC_VERSION="1.1.1f"
SRC_NAME="openssl-$SRC_VERSION"
SRC_PATH="$SHELL_PATH/$SRC_NAME"
#编译的平台
ARCHS="arm64 armv7 x86_64 i386"
#最低触发的版本
DEPLOYMENT_TARGET="8.0"
#输出路径
PREFIX="$SHELL_PATH/openssl-iOS"

#需要编译的平台
BUILD_ARCH=$1
#最低触发的版本
DEPLOYMENT_TARGET=$2

ARCHS="arm64 armv7 armv7s x86_64 i386"

if [ ! "$BUILD_ARCH" ]
then
BUILD_ARCH="all"
fi
if [ ! "$DEPLOYMENT_TARGET" ]
then
DEPLOYMENT_TARGET="8.0"
fi

rm -rf "$SRC_PATH" "$PREFIX"
#下载资源包
if [ ! -r $SRC_NAME ]
then
    SRC_TAR_NAME="$SRC_NAME.tar.gz"
    if [ ! -f "$SHELL_PATH/$SRC_TAR_NAME" ]
    then
        echo "$SRC_TAR_NAME source not found, Trying to download..."
        curl -O https://www.openssl.org/source/$SRC_TAR_NAME
    fi
    mkdir $SRC_PATH
    tar zxvf $SHELL_PATH/$SRC_TAR_NAME --strip-components 1 -C $SRC_PATH || exit 1
fi

CC=$(xcrun --find clang)
IOS_SDK_PATH=$(xcrun -sdk iphoneos --show-sdk-path)
IOS_CROSS_TOP=${IOS_SDK_PATH//\/SDKs*/}
IOS_CROSS_SDK=${IOS_SDK_PATH##*/}
IOS_SIMULATOR_SDK_PATH=$(xcrun -sdk iphonesimulator --show-sdk-path)
IOS_SIMULATOR_CROSS_TOP=${IOS_SIMULATOR_SDK_PATH//\/SDKs*/}
IOS_SIMULATOR_CROSS_SDK=${IOS_SIMULATOR_SDK_PATH##*/}

for ARCH in $ARCHS
do
    if [ "$BUILD_ARCH" = "all" -o "$BUILD_ARCH" = "$ARCH" ]
    then
        cd $SRC_PATH
        echo "building $ARCH..."

        CONFIGURE_FLAGS="no-shared"
        CFLAGS="-mios-version-min=$DEPLOYMENT_TARGET"
        if [ "$ARCH" = "x86_64" -o "$ARCH" = "i386" ]
        then
            CROSS_TOP=$IOS_SIMULATOR_CROSS_TOP
            CROSS_SDK=$IOS_SIMULATOR_CROSS_SDK
            if [ "$ARCH" = "i386" ]
            then
                CONFIGURE_FLAGS="$CONFIGURE_FLAGS no-asm"
            fi
        else
            if [ "$ARCH" == "arm64" -o "$ARCH" == "armv7" ]
            then
                CROSS_TOP=$IOS_CROSS_TOP
                CROSS_SDK=$IOS_CROSS_SDK
                CFLAGS="$CFLAGS -fembed-bitcode"
            fi
        fi

        export CROSS_TOP
        export CROSS_SDK
        export CC="$CC -arch $ARCH $CFLAGS"

        echo CROSS_TOP=$CROSS_TOP
        echo CROSS_SDK=$CROSS_SDK
        echo CC=$CC
        echo prefix=$PREFIX/$ARCH

        $SRC_PATH/Configure \
            iphoneos-cross \
            --prefix=$PREFIX/$ARCH \
            $CONFIGURE_FLAGS
        make -j3
        make install -j3

        mkdir $PREFIX/$ARCH/lib
        cp *.a $PREFIX/$ARCH/lib
        cp -rf include $PREFIX
        make clean

        unset CC
        unset CROSS_SDK
        unset CROSS_TOP
    fi
done

echo "building lipo lib binaries..."
mkdir -p $PREFIX/lib
set - $ARCHS
cd $PREFIX/$1/lib
for LIB in *.a
do
    cd $SHELL_PATH
    lipo -create `find $PREFIX -name $LIB` -output $PREFIX/lib/$LIB
done

cd $SHELL_PATH
cp -rf $PREFIX/$1/include $PREFIX
echo "building lipo openssl lib binaries successed"
