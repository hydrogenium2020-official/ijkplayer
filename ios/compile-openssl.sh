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

#----------
# modify for your build tool

TARGET_ALL_ARCHS_IOS6_SDK="armv7 armv7s i386"
TARGET_ALL_ARCHS_IOS7_SDK="armv7 armv7s arm64 i386 x86_64"
TARGET_ALL_ARCHS_IOS8_SDK="armv7 arm64 i386 x86_64"

TARGET_ALL_ARCHS=$TARGET_ALL_ARCHS_IOS8_SDK

#----------
UNI_BUILD_ROOT=`pwd`
UNI_TMP="$UNI_BUILD_ROOT/tmp"
UNI_TMP_LLVM_VER_FILE="$UNI_TMP/llvm.ver.txt"
TARGET_TARGET=$1
set -e

#----------
TARGET_LIBS="libssl libcrypto"

#----------
echo_archs() {
    echo "===================="
    echo "[*] check xcode version"
    echo "===================="
    echo "TARGET_ALL_ARCHS = $TARGET_ALL_ARCHS"
}

do_lipo () {
    LIB_FILE=$1
    LIPO_FLAGS=
    for ARCH in $TARGET_ALL_ARCHS
    do
        LIPO_FLAGS="$LIPO_FLAGS $UNI_BUILD_ROOT/build/openssl-$ARCH/output/lib/$LIB_FILE"
    done

    xcrun lipo -create $LIPO_FLAGS -output $UNI_BUILD_ROOT/build/universal/lib/$LIB_FILE
    xcrun lipo -info $UNI_BUILD_ROOT/build/universal/lib/$LIB_FILE
}

do_lipo_all () {
    mkdir -p $UNI_BUILD_ROOT/build/universal/lib
    echo "lipo archs: $TARGET_ALL_ARCHS"
    for TARGET_LIB in $TARGET_LIBS
    do
        do_lipo "$TARGET_LIB.a";
    done

    cp -R $UNI_BUILD_ROOT/build/openssl-armv7/output/include $UNI_BUILD_ROOT/build/universal/
}

#----------
if [ "$TARGET_TARGET" = "armv7" -o "$TARGET_TARGET" = "armv7s" -o "$TARGET_TARGET" = "arm64" ]; then
    echo_archs
    sh tools/do-compile-openssl.sh $TARGET_TARGET
elif [ "$TARGET_TARGET" = "i386" -o "$TARGET_TARGET" = "x86_64" ]; then
    echo_archs
    sh tools/do-compile-openssl.sh $TARGET_TARGET
elif [ "$TARGET_TARGET" = "lipo" ]; then
    echo_archs
    do_lipo_all
elif [ "$TARGET_TARGET" = "all" ]; then
    echo_archs
    for ARCH in $TARGET_ALL_ARCHS
    do
        sh tools/do-compile-openssl.sh $ARCH
    done

    do_lipo_all
elif [ "$TARGET_TARGET" = "check" ]; then
    echo_archs
elif [ "$TARGET_TARGET" = "clean" ]; then
    echo_archs
    for ARCH in $TARGET_ALL_ARCHS
    do
        cd openssl-$ARCH && git clean -xdf && cd -
    done
else
    echo "Usage:"
    echo "  compile-openssl.sh armv7|arm64|i386|x86_64"
    echo "  compile-openssl.sh armv7s (obselete)"
    echo "  compile-openssl.sh lipo"
    echo "  compile-openssl.sh all"
    echo "  compile-openssl.sh clean"
    echo "  compile-openssl.sh check"
    exit 1
fi
