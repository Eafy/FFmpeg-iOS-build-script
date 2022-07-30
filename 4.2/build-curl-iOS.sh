#!/bin/bash
#https://curl.haxx.se/download.html/curl-7.66.0
#https://curl.se/download/curl-7.84.0.tar.gz

SHELL_PATH=`pwd`
CURL_PATH=$SHELL_PATH/curl-7.84.0
SSL_PATH=`pwd`/openssl-arm

readonly XCODE_DEV="$(xcode-select -p)"
export DEVROOT="${XCODE_DEV}/Toolchains/XcodeDefault.xctoolchain"
DFT_DIST_DIR=$CURL_PATH
DIST_DIR=$SHELL_PATH/curl-iOS

if ["$SSL_PATH"]
then
    SSL_FLAG="--with-ssl=$SHELL_PATH/openssl-iOS"
    echo "SSL_FLAG:$SSL_FLAG"
fi

function build_for_arch() {
  ARCH=$1
  HOST=$2
  SYSROOT=$3
  PREFIX=$4
  IPHONEOS_DEPLOYMENT_TARGET="9.0"
  export PATH="${DEVROOT}/usr/bin/:${PATH}"
  export CFLAGS="-DCURL_BUILD_IOS -arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${SYSROOT} -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode"
  export LDFLAGS="-arch ${ARCH} -isysroot ${SYSROOT}"
  ./configure --disable-shared --without-zlib --enable-static --enable-ipv6 ${SSL_FLAG} --host="${HOST}" --prefix=${PREFIX} && make -j8 && make install
}

cd $CURL_PATH
TMP_DIR=$CURL_PATH/tmp/build_libcurl_$$

build_for_arch i386 i386-apple-darwin ${XCODE_DEV}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk ${TMP_DIR}/i386 || exit 1
build_for_arch x86_64 x86_64-apple-darwin ${XCODE_DEV}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk ${TMP_DIR}/x86_64 || exit 2
build_for_arch arm64 arm-apple-darwin ${XCODE_DEV}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${TMP_DIR}/arm64 || exit 3
build_for_arch armv7s armv7s-apple-darwin ${XCODE_DEV}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${TMP_DIR}/armv7s || exit 4
build_for_arch armv7 armv7-apple-darwin ${XCODE_DEV}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${TMP_DIR}/armv7 || exit 5

mkdir -p ${TMP_DIR}/lib/
${DEVROOT}/usr/bin/lipo \
  -arch x86_64 ${TMP_DIR}/x86_64/lib/libcurl.a \
  -arch armv7 ${TMP_DIR}/armv7/lib/libcurl.a \
  -arch armv7s ${TMP_DIR}/armv7s/lib/libcurl.a \
  -arch arm64 ${TMP_DIR}/arm64/lib/libcurl.a \
  -output ${TMP_DIR}/lib/libcurl.a -create

cp -r ${TMP_DIR}/arm64/include ${TMP_DIR}/

mkdir -p ${DIST_DIR}
cp -r ${TMP_DIR}/include ${TMP_DIR}/lib ${DIST_DIR}

