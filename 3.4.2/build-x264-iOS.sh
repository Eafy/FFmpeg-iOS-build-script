#!/bin/sh
#http://download.videolan.org/pub/videolan/x264/snapshots/
#version:x264-snapshot-20180426-2245.tar.bz2

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli"

ARCHS="arm64 armv7 armv7s x86_64 i386"

# directories
SOURCE="x264"
FAT="x264-iOS"

SCRATCH="scratch-x264"
# must be an absolute path
THIN=`pwd`/"thin-x264"

COMPILE="y"
LIPO="y"

rm -rf "$SCRATCH"
rm -rf "$THIN"
rm -rf "$FAT"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"
		CFLAGS="-arch $ARCH"
        ASFLAGS=""

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CPU=
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=8.0"
		    	HOST=
		    else
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=8.0"
			HOST="--host=i386-apple-darwin"
		    fi
		else
		    PLATFORM="iPhoneOS"
		    if [ $ARCH = "arm64" ]
		    then
		        HOST="--host=aarch64-apple-darwin"
                XARCH="-arch aarch64"
		    else
		        HOST="--host=arm-apple-darwin"
                XARCH="-arch arm"
		    fi
            CFLAGS="$CFLAGS -mios-version-min=8.0 -fembed-bitcode"
            ASFLAGS="$CFLAGS"
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"
		if [ $PLATFORM = "iPhoneOS" ]
		then
		    export AS="$CWD/$SOURCE/tools/gas-preprocessor.pl $XARCH -- $CC"
		else
		    export -n AS
		fi
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		CC=$CC $CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
		    $HOST \
		    --extra-cflags="$CFLAGS" \
		    --extra-asflags="$ASFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" || exit 1

		make -j3 install || exit 1
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
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
    rm -rf $SCRATCH
    rm -rf $THIN
    echo "building fat binaries successed"
fi
