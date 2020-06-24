#!/bin/sh
#armv7 xcode9.1,
#sudo xcode-select -switch pathToXcode9.1/Contents/Developer
#xcode-select --print-path

#需要编译FFpmeg版本号
FF_VERSION="3.4.2"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi
SOURCE="ffmpeg-$FF_VERSION"
#输出路径
FAT="FFmpeg-iOS"

SCRATCH=`pwd`/"scratch-ffmpeg"
THIN=`pwd`/"thin-ffmpeg"
#编译之前需要删除临时缓存文件夹，防止和之前编译的或fdk-aac冲突
rm -rf "$SCRATCH"
rm -rf "$THIN"
rm -rf "$FAT"
rm -rf "ffbuild"

X264=`pwd`/x264-iOS         #H.264编码器
OPENCORE_AMR=`pwd`/opencore-amr-iOS
#FDK_AAC=`pwd`/fdk-aac-ios   #AAC第三方解码库
#FREETYPE=`pwd`/freetype-iOS  #字体引擎库

CONFIGURE_FLAGS="--enable-cross-compile --disable-stripping --disable-debug --disable-programs --disable-ffplay --disable-doc --enable-pic --enable-static --disable-shared --disable-asm"

CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-encoders --disable-decoders \
--enable-demuxers --disable-muxers --disable-parsers --disable-filters \
--enable-encoder=h264,aac,libx264,pcm_*,*jpeg*,libopencore_amrnb \
--enable-decoder=h264,aac,pcm_*,*jpeg*,amrnb,amrwb \
--enable-muxer=h264,aac,pcm_*,flv,mp4,avi \
--enable-parser=h264,aac,*jpeg*,mpeg* \
--enable-avfilter --enable-filter=anull"

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree"
fi

if [ "$FREETYPE" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfreetype"
fi

if [ "$OPENCORE_AMR" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-version3 --enable-libopencore-amrnb --enable-libopencore-amrwb"
fi

ARCHS="arm64 armv7 armv7s x86_64 i386"
#ARCHS="arm64"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="8.0"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
    then
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
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
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo "$SOURCE source not found. Trying to download..."
		curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

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

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
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
            CFLAGS="$CFLAGS -I$FREETYPE/include/freetype -I$CWD/libpng-iOS/include"
            LDFLAGS="$LDFLAGS -L$FREETYPE/lib -L$CWD/libpng-iOS/lib -lfreetype -lpng"
        fi
        if [ "$OPENCORE_AMR" ]
        then
            CFLAGS="$CFLAGS -I$OPENCORE_AMR/include"
            LDFLAGS="$LDFLAGS -L$OPENCORE_AMR/lib"
            echo "$LDFLAGS"
        fi

		TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    --as="$AS" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make -j3 install $EXPORT || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

rm -rf $SCRATCH
rm -rf $THIN
echo "iOS FFmpeg bulid success!"
