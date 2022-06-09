#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Bilibili
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below
# https://github.com/kolyvan/kxmovie
# https://github.com/yixia/FFmpeg-Android
# http://git.videolan.org/?p=vlc-ports/android.git;a=summary
# https://github.com/kewlbear/FFmpeg-iOS-build-script/

#--------------------
echo "===================="
echo "[*] check host"
echo "===================="
set -e

#--------------------
# include


#--------------------
# common defines
TARGET_ARCH=$1
TARGET_BUILD_OPT=$2
echo "TARGET_ARCH=$TARGET_ARCH"
echo "TARGET_BUILD_OPT=$TARGET_BUILD_OPT"
if [ -z "$TARGET_ARCH" ]; then
    echo "You must specific an architecture 'armv7, armv7s, arm64, i386, x86_64, ...'.\n"
    exit 1
fi


TARGET_BUILD_ROOT=`pwd`
TARGET_TAGET_OS="darwin"


# ffmpeg build params
export COMMON_TARGET_CFG_FLAGS=
source $TARGET_BUILD_ROOT/../config/module.sh

FFMPEG_CFG_FLAGS=
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $COMMON_TARGET_CFG_FLAGS"

# Optimization options (experts only):

# Advanced options (experts only):
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --enable-cross-compile"
# --disable-symver may indicate a bug
# FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --disable-symver"

# Developer options (useful when working on FFmpeg itself):
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --disable-stripping"

##
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --arch=$TARGET_ARCH"
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --target-os=$TARGET_TAGET_OS"
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --enable-static"
FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --disable-shared"
FFMPEG_EXTRA_CFLAGS=

# i386, x86_64
FFMPEG_CFG_FLAGS_SIMULATOR=
FFMPEG_CFG_FLAGS_SIMULATOR="$FFMPEG_CFG_FLAGS_SIMULATOR --disable-asm"
FFMPEG_CFG_FLAGS_SIMULATOR="$FFMPEG_CFG_FLAGS_SIMULATOR --disable-mmx"
FFMPEG_CFG_FLAGS_SIMULATOR="$FFMPEG_CFG_FLAGS_SIMULATOR --assert-level=2"

# armv7, armv7s, arm64
FFMPEG_CFG_FLAGS_ARM=
FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --enable-pic"
FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --enable-neon"
case "$TARGET_BUILD_OPT" in
    debug)
        FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --disable-optimizations"
        FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --enable-debug"
        FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --disable-small"
    ;;
    *)
        FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --enable-optimizations"
        FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --enable-debug"
        FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --enable-small"
    ;;
esac

echo "build_root: $TARGET_BUILD_ROOT"

#--------------------
echo "===================="
echo "[*] check gas-preprocessor"
echo "===================="
TARGET_TOOLS_ROOT="$TARGET_BUILD_ROOT/../extra"
export PATH="$TARGET_TOOLS_ROOT/gas-preprocessor:$PATH"

echo "gasp: $TARGET_TOOLS_ROOT/gas-preprocessor/gas-preprocessor.pl"

#--------------------
echo "===================="
echo "[*] config arch $TARGET_ARCH"
echo "===================="

TARGET_BUILD_NAME="unknown"
TARGET_XCRUN_PLATFORM="iPhoneOS"
TARGET_XCRUN_OSVERSION=
TARGET_GASPP_EXPORT=
TARGET_DEP_OPENSSL_INC=
TARGET_DEP_OPENSSL_LIB=
TARGET_XCODE_BITCODE=

if [ "$TARGET_ARCH" = "i386" ]; then
    TARGET_BUILD_NAME="ffmpeg-i386"
    TARGET_BUILD_NAME_OPENSSL=openssl-i386
    TARGET_XCRUN_PLATFORM="iPhoneSimulator"
    TARGET_XCRUN_OSVERSION="-mios-simulator-version-min=6.0"
    FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $FFMPEG_CFG_FLAGS_SIMULATOR"
elif [ "$TARGET_ARCH" = "x86_64" ]; then
    TARGET_BUILD_NAME="ffmpeg-x86_64"
    TARGET_BUILD_NAME_OPENSSL=openssl-x86_64
    TARGET_XCRUN_PLATFORM="iPhoneSimulator"
    TARGET_XCRUN_OSVERSION="-mios-simulator-version-min=7.0"
    FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $FFMPEG_CFG_FLAGS_SIMULATOR"
elif [ "$TARGET_ARCH" = "armv7" ]; then
    TARGET_BUILD_NAME="ffmpeg-armv7"
    TARGET_BUILD_NAME_OPENSSL=openssl-armv7
    TARGET_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    TARGET_XCODE_BITCODE="-fembed-bitcode"
    FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --disable-asm"
    FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $FFMPEG_CFG_FLAGS_ARM"
#    FFMPEG_CFG_CPU="--cpu=cortex-a8"
elif [ "$TARGET_ARCH" = "armv7s" ]; then
    TARGET_BUILD_NAME="ffmpeg-armv7s"
    TARGET_BUILD_NAME_OPENSSL=openssl-armv7s
    FFMPEG_CFG_CPU="--cpu=swift"
    TARGET_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    TARGET_XCODE_BITCODE="-fembed-bitcode"
    FFMPEG_CFG_FLAGS_ARM="$FFMPEG_CFG_FLAGS_ARM --disable-asm"
    FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $FFMPEG_CFG_FLAGS_ARM"
elif [ "$TARGET_ARCH" = "arm64" ]; then
    TARGET_BUILD_NAME="ffmpeg-arm64"
    TARGET_BUILD_NAME_OPENSSL=openssl-arm64
    TARGET_XCRUN_OSVERSION="-miphoneos-version-min=7.0"
    TARGET_XCODE_BITCODE="-fembed-bitcode"
    FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $FFMPEG_CFG_FLAGS_ARM"
    TARGET_GASPP_EXPORT="GASPP_FIX_XCODE5=1"
else
    echo "unknown architecture $TARGET_ARCH";
    exit 1
fi

echo "build_name: $TARGET_BUILD_NAME"
echo "platform:   $TARGET_XCRUN_PLATFORM"
echo "osversion:  $TARGET_XCRUN_OSVERSION"

#--------------------
echo "===================="
echo "[*] make ios toolchain $TARGET_BUILD_NAME"
echo "===================="

TARGET_BUILD_SOURCE="$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME"
TARGET_BUILD_PREFIX="$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME/output"

FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --prefix=$TARGET_BUILD_PREFIX"

mkdir -p $TARGET_BUILD_PREFIX

echo "build_source: $TARGET_BUILD_SOURCE"
echo "build_prefix: $TARGET_BUILD_PREFIX"

#--------------------
echo "\n--------------------"
echo "[*] configurate ffmpeg"
echo "--------------------"
TARGET_XCRUN_SDK=`echo $TARGET_XCRUN_PLATFORM | tr '[:upper:]' '[:lower:]'`
TARGET_XCRUN_CC="xcrun -sdk $TARGET_XCRUN_SDK clang"

FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS $FFMPEG_CFG_CPU"

FFMPEG_CFLAGS=
FFMPEG_CFLAGS="$FFMPEG_CFLAGS -arch $TARGET_ARCH"
FFMPEG_CFLAGS="$FFMPEG_CFLAGS $TARGET_XCRUN_OSVERSION"
FFMPEG_CFLAGS="$FFMPEG_CFLAGS $FFMPEG_EXTRA_CFLAGS"
FFMPEG_CFLAGS="$FFMPEG_CFLAGS $TARGET_XCODE_BITCODE"
FFMPEG_LDFLAGS="$FFMPEG_CFLAGS"
FFMPEG_DEP_LIBS=

#--------------------
echo "\n--------------------"
echo "[*] check OpenSSL"
echo "----------------------"
FFMPEG_DEP_OPENSSL_INC=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME_OPENSSL/output/include
FFMPEG_DEP_OPENSSL_LIB=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME_OPENSSL/output/lib
#--------------------
# with openssl
if [ -f "${FFMPEG_DEP_OPENSSL_LIB}/libssl.a" ]; then
    FFMPEG_CFG_FLAGS="$FFMPEG_CFG_FLAGS --enable-openssl"

    FFMPEG_CFLAGS="$FFMPEG_CFLAGS -I${FFMPEG_DEP_OPENSSL_INC}"
    FFMPEG_DEP_LIBS="$FFMPEG_CFLAGS -L${FFMPEG_DEP_OPENSSL_LIB} -lssl -lcrypto"
fi

#--------------------
echo "\n--------------------"
echo "[*] configure"
echo "----------------------"

if [ ! -d $TARGET_BUILD_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $TARGET_BUILD_NAME"
    echo "!! Run 'sh init-ios.sh' first"
    echo ""
    exit 1
fi

# xcode configuration
export DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

cd $TARGET_BUILD_SOURCE
if [ -f "./config.h" ]; then
    echo 'reuse configure'
else
    echo "config: $FFMPEG_CFG_FLAGS $TARGET_XCRUN_CC"
    ./configure \
        $FFMPEG_CFG_FLAGS \
        --cc="$TARGET_XCRUN_CC" \
        $FFMPEG_CFG_CPU \
        --extra-cflags="$FFMPEG_CFLAGS" \
        --extra-cxxflags="$FFMPEG_CFLAGS" \
        --extra-ldflags="$FFMPEG_LDFLAGS $FFMPEG_DEP_LIBS"
    make clean
fi

#--------------------
echo "\n--------------------"
echo "[*] compile ffmpeg"
echo "--------------------"
cp config.* $TARGET_BUILD_PREFIX
make -j3 $TARGET_GASPP_EXPORT
make install
mkdir -p $TARGET_BUILD_PREFIX/include/libffmpeg
cp -f config.h $TARGET_BUILD_PREFIX/include/libffmpeg/config.h
