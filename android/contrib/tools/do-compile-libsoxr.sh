#! /usr/bin/env bash
#
# Copyright (C) 2014 Miguel Botón <waninkoko@gmail.com>
# Copyright (C) 2014 Zhang Rui <bbcallen@gmail.com>
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

#--------------------
set -e

if [ -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    echo "They must point to your NDK directories.\n"
    exit 1
fi

#--------------------
# common defines
TARGET_ARCH=$1
if [ -z "$TARGET_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'.\n"
    exit 1
fi


TARGET_BUILD_ROOT=`pwd`

TARGET_BUILD_NAME=
TARGET_SOURCE=
TARGET_CROSS_PREFIX=

TARGET_CFG_FLAGS=
TARGET_PLATFORM_CFG_FLAGS=

TARGET_EXTRA_CFLAGS=
TARGET_EXTRA_LDFLAGS=

TARGET_CMAKE_ABI=
TARGET_CMAKE_EXTRA_FLAGS=

#----- armv7a begin -----
if [ "$TARGET_ARCH" = "armv7a" ]; then
    TARGET_BUILD_NAME=libsoxr-armv7a
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CMAKE_ABI="armeabi-v7a with NEON"
    TARGET_CMAKE_EXTRA_FLAGS="-DHAVE_WORDS_BIGENDIAN_EXITCODE=1 -DWITH_SIMD=0"

elif [ "$TARGET_ARCH" = "x86" ]; then
    TARGET_BUILD_NAME=libsoxr-x86
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CMAKE_ABI="x86"
    TARGET_CMAKE_EXTRA_FLAGS="-DHAVE_WORDS_BIGENDIAN_EXITCODE=1"

elif [ "$TARGET_ARCH" = "x86_64" ]; then
    TARGET_ANDROID_PLATFORM=android-21

    TARGET_BUILD_NAME=libsoxr-x86_64
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CMAKE_ABI="x86_64"

elif [ "$TARGET_ARCH" = "arm64" ]; then
    TARGET_ANDROID_PLATFORM=android-21

    TARGET_BUILD_NAME=libsoxr-arm64
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CMAKE_ABI="arm64-v8a"

else
    echo "unknown architecture $TARGET_ARCH";
    exit 1
fi

TARGET_PREFIX=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME/output
TARGET_CMAKE_BUILD_DIR=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME/build

mkdir -p $TARGET_PREFIX
mkdir -p $TARGET_CMAKE_BUILD_DIR

#--------------------
echo ""
echo "--------------------"
echo "[*] configurate libsoxr"
echo "--------------------"
cd $TARGET_CMAKE_BUILD_DIR
TARGET_CMAKE_CFG_FLAGS="-DCMAKE_TOOLCHAIN_FILE=${TARGET_SOURCE}/android.toolchain.cmake -DANDROID_NDK=$ANDROID_NDK -DBUILD_EXAMPLES=0 -DBUILD_LSR_TESTS=0 -DBUILD_SHARED_LIBS=0 -DBUILD_TESTS=0 -DCMAKE_BUILD_TYPE=Release -DWITH_LSR_BINDINGS=0 -DWITH_OPENMP=0 -DWITH_PFFFT=0"
echo "cmake $TARGET_CMAKE_CFG_FLAGS -DANDROID_ABI=$TARGET_CMAKE_ABI -DCMAKE_INSTALL_PREFIX=$TARGET_PREFIX"
cmake $TARGET_CMAKE_CFG_FLAGS $TARGET_CMAKE_EXTRA_FLAGS -DANDROID_ABI=$TARGET_CMAKE_ABI -DCMAKE_INSTALL_PREFIX=$TARGET_PREFIX $TARGET_SOURCE


#--------------------
echo ""
echo "--------------------"
echo "[*] compile libsoxr"
echo "--------------------"
make -j4
make install
