#!/bin/sh
#https://jaist.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz

CONFIGURE_FLAGS="--disable-shared --disable-frontend"

#需要编译的平台
BUILD_ARCH=$1
#最低触发的版本
DEPLOYMENT_TARGET=$2

# directories
SOURCE="lame-3.100"
FAT="lame-iOS"

CURRENTPATH=`pwd`
SCRATCH="${CURRENTPATH}/scratch-lame"
THIN="${CURRENTPATH}/thin-lame"

COMPILE="y"
LIPO="y"

if [ ! "$BUILD_ARCH" ]
then
ARCHS="arm64 x86_64"
else
ARCHS=$BUILD_ARCH
fi
if [ ! "$DEPLOYMENT_TARGET" ]
then
DEPLOYMENT_TARGET="9.0"
fi

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

if [ ! -r $SOURCE ]
then
    SRC_TAR_NAME=${SOURCE}.tar.gz
    if [ ! -f "$CURRENTPATH/$SRC_TAR_NAME" ]
    then
        echo "$SRC_TAR_NAME source not found, Trying to download..."
        curl -O  https://jaist.dl.sourceforge.net/project/lame/lame/3.100//$SRC_TAR_NAME || exit 1
    fi
    mkdir $SOURCE
    tar zxvf $CURRENTPATH/$SRC_TAR_NAME --strip-components 1 -C $CURRENTPATH/$SOURCE || exit 1
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	SIMULATOR="-mios-simulator-version-min=${DEPLOYMENT_TARGET}"
                        HOST=x86_64-apple-darwin
		    else
		    	SIMULATOR="-mios-simulator-version-min=${DEPLOYMENT_TARGET}"
                        HOST=i386-apple-darwin
		    fi
		else
		    PLATFORM="iPhoneOS"
		    SIMULATOR=
                    HOST=arm-apple-darwin
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH"
		#AS="$CWD/$SOURCE/extras/gas-preprocessor.pl $CC"
		CFLAGS="-arch $ARCH $SIMULATOR"
		if ! xcodebuild -version | grep "Xcode [1-6]\."
		then
			CFLAGS="$CFLAGS -fembed-bitcode"
		fi
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		CC=$CC $CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
                    --host=$HOST \
		    --prefix="$THIN/$ARCH" \
                    CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"

		make -j3 install
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
fi

rm -rf $SCRATCH
rm -rf $THIN
