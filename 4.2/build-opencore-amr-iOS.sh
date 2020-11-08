#!/bin/sh
#https://downloads.sourceforge.net/project/opencore-amr/opencore-amr

set -xe

VERSION="0.1.5"
LIBSRCNAME="opencore-amr"
CURRENTPATH=`pwd`
SRC_PATH=$CURRENTPATH/$LIBSRCNAME-$VERSION

DEST="${CURRENTPATH}/${LIBSRCNAME}-iOS"
mkdir -p $DEST

#需要编译的平台
BUILD_ARCH=$1
#最低触发的版本
DEPLOYMENT_TARGET=$2

DEVELOPER=`xcode-select -print-path`
LIBS="libopencore-amrnb.a libopencore-amrwb.a"

if [ ! "$BUILD_ARCH" ]
then
ARCHS="arm64 armv7 armv7s x86_64 i386"
else
ARCHS=$BUILD_ARCH
fi
if [ ! "$DEPLOYMENT_TARGET" ]
then
DEPLOYMENT_TARGET="9.0"
fi

if [ ! -r $SRC_PATH ]
then
    SRC_TAR_NAME=${LIBSRCNAME}-${VERSION}.tar.gz
    if [ ! -f "$CURRENTPATH/$SRC_TAR_NAME" ]
    then
        echo "$SRC_TAR_NAME source not found, Trying to download..."
        curl -O  https://downloads.sourceforge.net/project/opencore-amr/opencore-amr/$SRC_TAR_NAME || exit 1
    fi
    mkdir $SRC_PATH
    tar zxvf $CURRENTPATH/$SRC_TAR_NAME --strip-components 1 -C $SRC_PATH || exit 1
fi

tar zxvf ${LIBSRCNAME}-${VERSION}.tar.gz -C "${CURRENTPATH}"
cd "${CURRENTPATH}/${LIBSRCNAME}-${VERSION}"

./configure

for arch in $ARCHS; do
    make clean
    IOSMV=" -miphoneos-version-min=$DEPLOYMENT_TARGET"
    case $arch in
    arm*)
        if [ $arch == "arm64" ]
        then
            IOSMV=" -miphoneos-version-min=8.0"
        fi
        echo "Building opencore-amr for iPhoneOS $arch ****************"
        PATH=`xcodebuild -version -sdk iphoneos PlatformPath`"/Developer/usr/bin:$PATH" \
        SDK=`xcodebuild -version -sdk iphoneos Path` \
        CXX="xcrun --sdk iphoneos clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include  -fembed-bitcode" \
        LDFLAGS="-Wl" \
        ./configure \
        --host=arm-apple-darwin \
        --prefix=$DEST \
        --disable-shared
        ;;
    *)
        echo "Building opencore-amr for iPhoneSimulator $arch *****************"
        PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
        CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV -fembed-bitcode" \
        ./configure \
        --host=$arch \
        --prefix=$DEST \
        --disable-shared
        ;;
    esac
    make -j3
    make install
    for i in $LIBS; do
        mv $DEST/lib/$i $DEST/lib/$i.$arch
    done
done

echo "Merge into universal binary."

for i in $LIBS; do
    input=""
    for arch in $ARCHS; do
        input="$input $DEST/lib/$i.$arch"
    done
    xcrun lipo -create -output $DEST/lib/$i $input
done

rm $DEST/lib/libopencore-amrnb.a.*
rm $DEST/lib/libopencore-amrnb.la
rm $DEST/lib/libopencore-amrwb.a.*
rm $DEST/lib/libopencore-amrwb.la
rm -rf $DEST/lib/pkgconfig
