#!/bin/sh

#···············支持的平台·初版版本·第三方库·是否重新编译第三方库
#./build-ffmpeg-iOS.sh all 9.0 all yes

SHELL_PATH=`pwd`
#需要编译FFpmeg版本号
SRC_VERSION="4.2"
#FFpmeg文件/文件夹名称
SRC_NAME="ffmpeg-$SRC_VERSION"
SRC_PATH="$SHELL_PATH/$SRC_NAME"
#编译的平台
ARCHS="arm64 armv7 armv7s x86_64 i386"
#输出路径
PREFIX="$SHELL_PATH/FFmpeg-iOS"
SRC_BUILD="$SHELL_PATH/FFmpeg-build"

#需要编译的平台
BUILD_ARCH=$1
#最低触发的版本
DEPLOYMENT_TARGET=$2
#需要编译的第三方库
BUILD_THIRD_LIB=$3
#是否重新编译第三方库
BUILD_THIRD_LIB_COMPILE=$4

CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs --disable-ffplay --disable-doc --enable-pic --enable-static --disable-shared --disable-asm"

CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-encoders --disable-decoders \
--disable-muxers --disable-parsers --disable-filters --disable-demuxers \
--enable-demuxer=h264,aac,hevc,pcm*,flv,hls,mp3,avi \
--enable-encoder=h264,aac,libx264,pcm_*,libopencore_amrnb \
--enable-decoder=h264,aac,pcm*,amrnb,amrwb,hevc \
--enable-muxer=h264,aac,pcm*,flv,mp4,avi \
--enable-parser=h264,aac,hevc \
--enable-avfilter --enable-filter=anull"
  
if [ ! "$BUILD_ARCH" ]
then
BUILD_ARCH="all"
fi
if [ ! "$DEPLOYMENT_TARGET" ]
then
DEPLOYMENT_TARGET="9.0"
fi
if [ ! "$BUILD_THIRD_LIB" ]
then
BUILD_THIRD_LIB="all"
fi
if [ ! "$BUILD_THIRD_LIB_COMPILE" ]
then
BUILD_THIRD_LIB_COMPILE="yes"
fi

#是否编译X264
if [ "$BUILD_THIRD_LIB" = "x264" ] || [ "$BUILD_THIRD_LIB" = "all" ]
then
    if [ "$BUILD_THIRD_LIB_COMPILE" = "yes" ]    #是否重新编译x264的库
    then
        sh $SHELL_PATH/build-x264-iOS.sh $BUILD_ARCH $DEPLOYMENT_TARGET
    fi
    X264=$SHELL_PATH/x264-iOS
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi
#是否编译opencore-amr
if [ "$BUILD_THIRD_LIB" = "opencoreamr" ] || [ "$BUILD_THIRD_LIB" = "all" ]
then
    if [ "$BUILD_THIRD_LIB_COMPILE" = "yes" ]
    then
        sh $SHELL_PATH/build-opencore-amr-iOS.sh $BUILD_ARCH $DEPLOYMENT_TARGET
    fi
    OPENCORE_AMR=$SHELL_PATH/opencore-amr-iOS
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-version3 --enable-libopencore-amrnb --enable-libopencore-amrwb"
fi
#是否编译openssl
if [ "$BUILD_THIRD_LIB" = "openssl" ] || [ "$BUILD_THIRD_LIB" = "all" ]
then
    if [ "$BUILD_THIRD_LIB_COMPILE" = "yes" ]
    then
        sh $SHELL_PATH/build-openssl-iOS.sh $BUILD_ARCH $DEPLOYMENT_TARGET
    fi
    OPENSSL=$SHELL_PATH/openssl-iOS
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-nonfree --enable-openssl"
fi

#检测并安装yasm
if [ ! `which yasm` ]
then
    echo 'Yasm not found'
    if [ ! `which brew` ]
    then
        echo 'Homebrew not found. Trying to install...'
                    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
            || exit 1
    fi
    echo 'Trying to install Yasm...'
    brew install yasm || exit 1
fi
#检测并安装gas-preprocessor.pl
if [ ! `which gas-preprocessor.pl` ]
then
    echo 'gas-preprocessor.pl not found. Trying to install...'
    (curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
        -o /usr/local/bin/gas-preprocessor.pl \
        && chmod +x /usr/local/bin/gas-preprocessor.pl) \
        || exit 1
fi

rm -rf "$PREFIX" "$SRC_BUILD"
#检测并下载资源包
if [ ! -r $SRC_NAME ]
then
    SRC_TAR_NAME="$SRC_NAME.tar.bz2"
    if [ ! -f "$SHELL_PATH/$SRC_TAR_NAME" ]
    then
        echo "$SRC_TAR_NAME source not found, Trying to download..."
        curl -O http://www.ffmpeg.org/releases/$SRC_TAR_NAME || exit 1
    fi
    mkdir $SRC_PATH
    tar zxvf $SHELL_PATH/$SRC_TAR_NAME --strip-components 1 -C $SRC_PATH || exit 1
fi

#部分第三方开需要打补丁修改配置文件
sh $SHELL_PATH/build-ffmpeg-patch.sh $SRC_PATH

#开始编译
for ARCH in $ARCHS
do
    if [ "$BUILD_ARCH" = "all" -o "$BUILD_ARCH" = "$ARCH" ]
    then
        echo "building $ARCH..."
        mkdir -p "$SRC_BUILD/$ARCH"
        cd "$SRC_BUILD/$ARCH"

        CFLAGS="-arch $ARCH"
        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
        else
            PLATFORM="iPhoneOS"
            CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
            if [ "$ARCH" = "arm64" ]
            then
                EXPORT="GASPP_FIX_XCODE5=1"
            fi
        fi

        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"

        if [ "$ARCH" = "arm64" ]
        then
            AS="gas-preprocessor.pl -arch aarch64 -- $CC"
        else
            AS="gas-preprocessor.pl -- $CC"
        fi

        LDFLAGS="$CFLAGS"
        CXXFLAGS="$CFLAGS"
        if [ "$X264" ]
        then
            CFLAGS="$CFLAGS -I$X264/include"
            LDFLAGS="$LDFLAGS -L$X264/lib"
        fi
        if [ "$FDK_AAC" ]
        then
            CFLAGS="$CFLAGS -I$FDK_AAC/include"
            LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
        fi
        if [ "$FREETYPE" ]
        then
            CFLAGS="$CFLAGS -I$FREETYPE/include/freetype -I$SHELL_PATH/libpng-iOS/include"
            LDFLAGS="$LDFLAGS -L$FREETYPE/lib -L$SHELL_PATH/libpng-iOS/lib -lfreetype -lpng"
        fi
        if [ "$OPENCORE_AMR" ]
        then
            CFLAGS="$CFLAGS -I$OPENCORE_AMR/include"
            LDFLAGS="$LDFLAGS -L$OPENCORE_AMR/lib"
            echo "$LDFLAGS"
        fi
        if [ "$OPENSSL" ]
        then
            CFLAGS="$CFLAGS -I$OPENSSL/include"
            LDFLAGS="$LDFLAGS -L$OPENSSL/lib"
        fi
        echo CC=$CC

        echo CFLAGS="$CFLAGS"
        echo LDFLAGS="$LDFLAGS"

        TMPDIR=${TMPDIR/%\/} $SRC_PATH/configure \
            --target-os=darwin \
            --arch=$ARCH \
            --cc="$CC" \
            --as="$AS" \
            $CONFIGURE_FLAGS \
            --extra-cflags="$CFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$SRC_BUILD/$ARCH" \
        || exit 1

        make -j3 install $EXPORT || exit 1
        make distclean
    fi
done

echo "building lipo ffmpeg lib binaries..."
mkdir -p $PREFIX/lib
set - $ARCHS
cd $SRC_BUILD/$1/lib
for LIB in *.a
do
    cd $SHELL_PATH
    lipo -create `find $SRC_BUILD -name $LIB` -output $PREFIX/lib/$LIB || exit 1
done

cd $SHELL_PATH
cp -rf $SRC_BUILD/$1/include $PREFIX
rm -rf $SRC_BUILD
echo "building lipo ffmpeg lib binaries successed"
