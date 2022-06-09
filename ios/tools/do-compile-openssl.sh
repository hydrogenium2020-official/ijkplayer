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
# https://github.com/x2on/OpenSSL-for-iPhone

#--------------------
echo "===================="
echo "[*] check host"
echo "===================="
set -e


TARGET_XCRUN_DEVELOPER=`xcode-select -print-path`
if [ ! -d "$TARGET_XCRUN_DEVELOPER" ]; then
  echo "xcode path is not set correctly $TARGET_XCRUN_DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $TARGET_XCRUN_DEVELOPER in  
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac


#--------------------
# include


#--------------------
# common defines
TARGET_ARCH=$1
if [ -z "$TARGET_ARCH" ]; then
    echo "You must specific an architecture 'armv7, armv7s, arm64, i386, x86_64, ...'.\n"
    exit 1
fi


TARGET_BUILD_ROOT=`pwd`
TARGET_TAGET_OS="darwin"


# openssl build params
export COMMON_TARGET_CFG_FLAGS=

OPENSSL_CFG_FLAGS=
OPENSSL_EXTRA_CFLAGS=
OPENSSL_CFG_CPU=

# i386, x86_64
OPENSSL_CFG_FLAGS_SIMULATOR=

# armv7, armv7s, arm64
OPENSSL_CFG_FLAGS_ARM=
OPENSSL_CFG_FLAGS_ARM="iphoneos-cross"

echo "build_root: $TARGET_BUILD_ROOT"

#--------------------
echo "===================="
echo "[*] config arch $TARGET_ARCH"
echo "===================="

TARGET_BUILD_NAME="unknown"
TARGET_XCRUN_PLATFORM="iPhoneOS"
TARGET_XCRUN_OSVERSION=
TARGET_GASPP_EXPORT=
TARGET_XCODE_BITCODE=

if [ "$TARGET_ARCH" = "i386" ]; then
    TARGET_BUILD_NAME="openssl-i386"
    TARGET_XCRUN_PLATFORM="iPhoneSimulator"
    TARGET_XCRUN_OSVERSION="-mios-simulator-version-min=6.0"
    OPENSSL_CFG_FLAGS="darwin-i386-cc $OPENSSL_CFG_FLAGS"
elif [ "$TARGET_ARCH" = "x86_64" ]; then
    TARGET_BUILD_NAME="openssl-x86_64"
    TARGET_XCRUN_PLATFORM="iPhoneSimulator"
    TARGET_XCRUN_OSVERSION="-mios-simulator-version-min=7.0"
    OPENSSL_CFG_FLAGS="darwin64-x86_64-cc $OPENSSL_CFG_FLAGS"
elif [ "$TARGET_ARCH" = "armv7" ]; then
    TARGET_BUILD_NAME="openssl-armv7"
    TARGET_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    TARGET_XCODE_BITCODE="-fembed-bitcode"
    OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS_ARM $OPENSSL_CFG_FLAGS"
#    OPENSSL_CFG_CPU="--cpu=cortex-a8"
elif [ "$TARGET_ARCH" = "armv7s" ]; then
    TARGET_BUILD_NAME="openssl-armv7s"
    OPENSSL_CFG_CPU="--cpu=swift"
    TARGET_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    TARGET_XCODE_BITCODE="-fembed-bitcode"
    OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS_ARM $OPENSSL_CFG_FLAGS"
elif [ "$TARGET_ARCH" = "arm64" ]; then
    TARGET_BUILD_NAME="openssl-arm64"
    TARGET_XCRUN_OSVERSION="-miphoneos-version-min=7.0"
    TARGET_XCODE_BITCODE="-fembed-bitcode"
    OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS_ARM $OPENSSL_CFG_FLAGS"
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

mkdir -p $TARGET_BUILD_PREFIX


TARGET_XCRUN_SDK=`echo $TARGET_XCRUN_PLATFORM | tr '[:upper:]' '[:lower:]'`
TARGET_XCRUN_SDK_PLATFORM_PATH=`xcrun -sdk $TARGET_XCRUN_SDK --show-sdk-platform-path`
TARGET_XCRUN_SDK_PATH=`xcrun -sdk $TARGET_XCRUN_SDK --show-sdk-path`
TARGET_XCRUN_CC="xcrun -sdk $TARGET_XCRUN_SDK clang"

export CROSS_TOP="$TARGET_XCRUN_SDK_PLATFORM_PATH/Developer"
export CROSS_SDK=`echo ${TARGET_XCRUN_SDK_PATH/#$CROSS_TOP\/SDKs\//}`
export BUILD_TOOL="$TARGET_XCRUN_DEVELOPER"
export CC="$TARGET_XCRUN_CC -arch $TARGET_ARCH $TARGET_XCRUN_OSVERSION"

echo "build_source: $TARGET_BUILD_SOURCE"
echo "build_prefix: $TARGET_BUILD_PREFIX"
echo "CROSS_TOP: $CROSS_TOP"
echo "CROSS_SDK: $CROSS_SDK"
echo "BUILD_TOOL: $BUILD_TOOL"
echo "CC: $CC"

#--------------------
echo "\n--------------------"
echo "[*] configurate openssl"
echo "--------------------"

OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS $TARGET_XCODE_BITCODE"
OPENSSL_CFG_FLAGS="$OPENSSL_CFG_FLAGS --openssldir=$TARGET_BUILD_PREFIX"

# xcode configuration
export DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

cd $TARGET_BUILD_SOURCE
if [ -f "./Makefile" ]; then
    echo 'reuse configure'
else
    echo "config: $OPENSSL_CFG_FLAGS"
    ./Configure \
        $OPENSSL_CFG_FLAGS
    make clean
fi

#--------------------
echo "\n--------------------"
echo "[*] compile openssl"
echo "--------------------"
set +e
make
make install_sw
