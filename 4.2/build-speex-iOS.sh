#!/bin/sh
 
ZJ_OGG_VERSION=1.3.4
ZJ_SPEEX_VERSION=1.2.0
ZJ_SPEEXDSP_VERSION=1.2.0
 
ZJ_IOS_MIN_VERSION=9.0
ZJ_SAVE_DIR=`pwd`/SpeexCompile
ZJ_IOS_SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
ZJ_XCODE_ROOT=`xcode-select -print-path`
 
ARCH_ARRAY=(
i386
x86_64
arm64
armv7
armv7s
)
 
echo "iOS sdk version:$ZJ_IOS_SDK_VERSION"
 
##############OGG#####################
if [ ! $ZJ_OGG_VERSION ];then
     echo "You have not input ogg version:$ZJ_OGG_VERSION!"
else
  echo "Ogg version:$ZJ_OGG_VERSION"
fi
 
ZJ_OGG_DIR=$ZJ_SAVE_DIR/libogg
ZJ_OGG_SRC_DIR=$ZJ_OGG_DIR/libogg-$ZJ_OGG_VERSION
if [ -d "$ZJ_OGG_SRC_DIR" ];
    then
         echo "Ogg src file is exist:$ZJ_OGG_SRC_DIR"
    else
        mkdir -p $ZJ_OGG_DIR
        pushd $ZJ_OGG_DIR
        curl -o libogg-$ZJ_OGG_VERSION.zip https://svn.xiph.org/releases/ogg/libogg-$ZJ_OGG_VERSION.zip
        unzip -o libogg-$ZJ_OGG_VERSION.zip -d .
        rm libogg-$ZJ_OGG_VERSION.zip
fi
pushd $ZJ_OGG_SRC_DIR
 
OGG_LIPO_PATH=""
for i in "${!ARCH_ARRAY[@]}"; do
    ZJ_ARCH=${ARCH_ARRAY[$i]}
    echo "arch:$ZJ_ARCH"
    
    if [ "$ZJ_ARCH" = "i386" ] || [ "$ZJ_ARCH" = "x86_64" ];
    then
        ZJ_PLATFORM=iPhoneSimulator
        ZJ_HOST=$ZJ_ARCH-apple-darwin
        ZJ_SDK_PLATFORM=iphonesimulator
        ZJ_IOS_VERSION=ios-simulator-version-min=$ZJ_IOS_MIN_VERSION
    else
        ZJ_PLATFORM=iPhoneOS
        ZJ_HOST=arm-apple-darwin
        ZJ_SDK_PLATFORM=iphoneos
        ZJ_IOS_VERSION=iphoneos-version-min=$ZJ_IOS_MIN_VERSION
    fi
    
ZJ_PLATFORM_PATH=$ZJ_XCODE_ROOT/Platforms/$ZJ_PLATFORM.platform/Developer
ZJ_SDK_PATH=$ZJ_PLATFORM_PATH/SDKs/$ZJ_PLATFORM$ZJ_IOS_SDK_VERSION.sdk
ZJ_FLAGS="-arch $ZJ_ARCH -isysroot $ZJ_SDK_PATH -m$ZJ_IOS_VERSION -fembed-bitcode"
 
CC=`xcrun -sdk $ZJ_SDK_PLATFORM$ZJ_IOS_SDK_VERSION -find clang`
CXX=`xcrun -sdk $ZJ_SDK_PLATFORM$ZJ_IOS_SDK_VERSION -find clang++`
 
CFLAGS=$ZJ_FLAGS
CXXFLAGS=$ZJ_FLAGS
LDFLAGS=$ZJ_FLAGS
export CC CXX CFLAGS CXXFLAGS LDFLAGS
 
ZJ_PREFIX=$ZJ_OGG_DIR/Ogg-$ZJ_ARCH
OGG_LIPO_PATH="$OGG_LIPO_PATH $ZJ_PREFIX/lib/libogg.a "
ZJ_CONFIGURE_FLAGS="-prefix=$ZJ_PREFIX -host=$ZJ_HOST -disable-shared $ZJ_EXTRA_CONFIGURE_FLAGS"
 
echo "ZJ_CONFIGURE_FLAGS=$ZJ_CONFIGURE_FLAGS"
echo "ZJ_FLAGS=$ZJ_FLAGS"
 
$ZJ_OGG_SRC_DIR/configure $ZJ_CONFIGURE_FLAGS
make
make install
make clean
    
done
 
echo "OGG_LIPO_PATH=$OGG_LIPO_PATH"
mkdir -p $ZJ_SAVE_DIR/Speex/lib
mkdir -p $ZJ_SAVE_DIR/Speex/include
lipo -create $OGG_LIPO_PATH -output $ZJ_SAVE_DIR/Speex/lib/libogg.a
cp -r $ZJ_OGG_DIR/Ogg-arm64/include $ZJ_SAVE_DIR/Speex
popd
 
 
##############SPEEX#####################
if [ ! $ZJ_SPEEX_VERSION ];then
     echo "You have not input speex version:$ZJ_SPEEX_VERSION!"
else
  echo "Speex version:$ZJ_SPEEX_VERSION"
fi
 
ZJ_SPEEX_DIR=$ZJ_SAVE_DIR/libspeex
ZJ_SPEEX_SRC_DIR=$ZJ_SPEEX_DIR/speex-$ZJ_SPEEX_VERSION
if [ -d "$ZJ_SPEEX_SRC_DIR" ];
    then
         echo "Speex src file is exist:$ZJ_SPEEX_SRC_DIR"
    else
        mkdir -p $ZJ_SPEEX_DIR
        pushd $ZJ_SPEEX_DIR
        curl -o speex-$ZJ_SPEEX_VERSION.tar.gz https://svn.xiph.org/releases/speex/speex-$ZJ_SPEEX_VERSION.tar.gz
        tar xvfz speex-$ZJ_SPEEX_VERSION.tar.gz
        rm speex-$ZJ_SPEEX_VERSION.tar.gz
fi
pushd $ZJ_SPEEX_SRC_DIR
 
SPEEX_LIPO_PATH=""
for i in "${!ARCH_ARRAY[@]}"; do
    ZJ_ARCH=${ARCH_ARRAY[$i]}
    echo "arch:$ZJ_ARCH"
    
    if [ "$ZJ_ARCH" = "i386" ] || [ "$ZJ_ARCH" = "x86_64" ];
    then
        ZJ_PLATFORM=iPhoneSimulator
        ZJ_HOST=$ZJ_ARCH-apple-darwin
        ZJ_SDK_PLATFORM=iphonesimulator
        ZJ_IOS_VERSION=ios-simulator-version-min=$ZJ_IOS_MIN_VERSION
    else
        ZJ_PLATFORM=iPhoneOS
        ZJ_HOST=arm-apple-darwin
        ZJ_SDK_PLATFORM=iphoneos
        ZJ_IOS_VERSION=iphoneos-version-min=$ZJ_IOS_MIN_VERSION
    fi
    
ZJ_PLATFORM_PATH=$ZJ_XCODE_ROOT/Platforms/$ZJ_PLATFORM.platform/Developer
ZJ_SDK_PATH=$ZJ_PLATFORM_PATH/SDKs/$ZJ_PLATFORM$ZJ_IOS_SDK_VERSION.sdk
ZJ_FLAGS="-arch $ZJ_ARCH -isysroot $ZJ_SDK_PATH -m$ZJ_IOS_VERSION -fembed-bitcode"
 
CC=`xcrun -sdk $ZJ_SDK_PLATFORM$ZJ_IOS_SDK_VERSION -find clang`
CXX=`xcrun -sdk $ZJ_SDK_PLATFORM$ZJ_IOS_SDK_VERSION -find clang++`
 
CFLAGS=$ZJ_FLAGS
CXXFLAGS=$ZJ_FLAGS
LDFLAGS=$ZJ_FLAGS
export CC CXX CFLAGS CXXFLAGS LDFLAGS
 
ZJ_PREFIX=$ZJ_SPEEX_DIR/Speex-$ZJ_ARCH
SPEEX_LIPO_PATH="$SPEEX_LIPO_PATH $ZJ_PREFIX/lib/libspeex.a "
ZJ_CONFIGURE_FLAGS="-prefix=$ZJ_PREFIX -host=$ZJ_HOST -disable-shared -enable-static -disable-oggtest -disable-fixed-point -enable-float-api -with-ogg=$ZJ_OGG_DIR/Ogg-$ZJ_ARCH $ZJ_EXTRA_CONFIGURE_FLAGS"
 
echo "ZJ_CONFIGURE_FLAGS=$ZJ_CONFIGURE_FLAGS"
echo "ZJ_FLAGS=$ZJ_FLAGS"
 
./configure $ZJ_CONFIGURE_FLAGS
make
make install
make clean
    
done
 
echo "SPEEX_LIPO_PATH=$SPEEX_LIPO_PATH"
lipo -create $SPEEX_LIPO_PATH -output $ZJ_SAVE_DIR/Speex/lib/libspeex.a
cp -r $ZJ_SPEEX_DIR/Speex-arm64/include $ZJ_SAVE_DIR/Speex
cp -rf $ZJ_SAVE_DIR/Speex $(dirname $ZJ_SAVE_DIR)/speex-iOS
exit

##############SPEEXDSP#####################
if [ ! $ZJ_SPEEXDSP_VERSION ];then
     echo "You have not input speexdsp version:$ZJ_SPEEXDSP_VERSION!"
else
  echo "Speexdsp version:$ZJ_SPEEXDSP_VERSION"
fi
 
ZJ_SPEEXDSP_DIR=$ZJ_SAVE_DIR/libspeexdsp
ZJ_SPEEXDSP_SRC_DIR=$ZJ_SPEEXDSP_DIR/speexdsp-$ZJ_SPEEXDSP_VERSION
if [ -d "$ZJ_SPEEXDSP_SRC_DIR" ];
    then
         echo "Speexdsp src file is exist:$ZJ_SPEEXDSP_SRC_DIR"
    else
        mkdir -p $ZJ_SPEEXDSP_DIR
        pushd $ZJ_SPEEXDSP_DIR
        curl -o speexdsp-$ZJ_SPEEXDSP_VERSION.tar.gz https://svn.xiph.org/releases/speex/speexdsp-$ZJ_SPEEXDSP_VERSION.tar.gz
        tar xvfz speexdsp-$ZJ_SPEEXDSP_VERSION.tar.gz
        rm speexdsp-$ZJ_SPEEXDSP_VERSION.tar.gz
fi
pushd $ZJ_SPEEXDSP_SRC_DIR
 
SPEEX_LIPO_DSP_PATH=""
for i in "${!ARCH_ARRAY[@]}"; do
    ZJ_ARCH=${ARCH_ARRAY[$i]}
    echo "arch:$ZJ_ARCH"
    
    if [ "$ZJ_ARCH" = "i386" ] || [ "$ZJ_ARCH" = "x86_64" ];
    then
        ZJ_PLATFORM=iPhoneSimulator
        ZJ_HOST=$ZJ_ARCH-apple-darwin
        ZJ_SDK_PLATFORM=iphonesimulator
        ZJ_IOS_VERSION=ios-simulator-version-min=$ZJ_IOS_MIN_VERSION
    else
        ZJ_PLATFORM=iPhoneOS
        ZJ_HOST=arm-apple-darwin
        ZJ_SDK_PLATFORM=iphoneos
        ZJ_IOS_VERSION=iphoneos-version-min=$ZJ_IOS_MIN_VERSION
    fi
    
ZJ_PLATFORM_PATH=$ZJ_XCODE_ROOT/Platforms/$ZJ_PLATFORM.platform/Developer
ZJ_SDK_PATH=$ZJ_PLATFORM_PATH/SDKs/$ZJ_PLATFORM$ZJ_IOS_SDK_VERSION.sdk
ZJ_FLAGS="-arch $ZJ_ARCH -isysroot $ZJ_SDK_PATH -m$ZJ_IOS_VERSION -fembed-bitcode"
 
CC=`xcrun -sdk $ZJ_SDK_PLATFORM$ZJ_IOS_SDK_VERSION -find clang`
CXX=`xcrun -sdk $ZJ_SDK_PLATFORM$ZJ_IOS_SDK_VERSION -find clang++`
 
CFLAGS=$ZJ_FLAGS
CXXFLAGS=$ZJ_FLAGS
LDFLAGS=$ZJ_FLAGS
export CC CXX CFLAGS CXXFLAGS LDFLAGS
 
ZJ_PREFIX=$ZJ_SPEEXDSP_DIR/Speexdsp-$ZJ_ARCH
SPEEX_LIPO_DSP_PATH="$SPEEX_LIPO_DSP_PATH $ZJ_PREFIX/lib/libspeexdsp.a "
ZJ_CONFIGURE_FLAGS="-prefix=$ZJ_PREFIX -host=$ZJ_HOST -disable-shared -enable-static -disable-oggtest -disable-fixed-point -enable-float-api -with-ogg=$ZJ_OGG_DIR/Ogg-$ZJ_ARCH $ZJ_EXTRA_CONFIGURE_FLAGS"
 
echo "ZJ_CONFIGURE_FLAGS=$ZJ_CONFIGURE_FLAGS"
echo "ZJ_FLAGS=$ZJ_FLAGS"
 
./configure $ZJ_CONFIGURE_FLAGS
make
make install
make clean
    
done
 
echo "SPEEX_LIPO_DSP_PATH=$SPEEX_LIPO_DSP_PATH"
lipo -create $SPEEX_LIPO_DSP_PATH -output $ZJ_SAVE_DIR/Speex/lib/libspeexdsp.a
cp -r $ZJ_SPEEXDSP_DIR/Speexdsp-arm64/include $ZJ_SAVE_DIR/Speex
cp -rf $ZJ_SAVE_DIR/Speex $(dirname $ZJ_SAVE_DIR)/speex-iOS
