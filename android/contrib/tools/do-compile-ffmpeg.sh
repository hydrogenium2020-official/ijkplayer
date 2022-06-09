#! /usr/bin/env bash
#
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
# https://github.com/yixia/FFmpeg-Android
# http://git.videolan.org/?p=vlc-ports/android.git;a=summary

#--------------------
echo "===================="
echo "[*] check env $1"
echo "===================="
set -e


#--------------------
# common defines
TARGET_ARCH=$1
TARGET_BUILD_OPT=$2
echo "TARGET_ARCH=$TARGET_ARCH"
echo "TARGET_BUILD_OPT=$TARGET_BUILD_OPT"
if [ -z "$TARGET_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'."
    echo ""
    exit 1
fi


TARGET_BUILD_ROOT=`pwd`
TARGET_ANDROID_API=19


TARGET_BUILD_NAME=
TARGET_SOURCE=
TARGET_CROSS_PREFIX=
TARGET_DEP_OPENSSL_INC=
TARGET_DEP_OPENSSL_LIB=

TARGET_DEP_LIBSOXR_INC=
TARGET_DEP_LIBSOXR_LIB=

TARGET_CFG_FLAGS=

TARGET_EXTRA_CFLAGS=
TARGET_EXTRA_LDFLAGS=
TARGET_DEP_LIBS=
TARGET_CLANG_PREFIX=

TARGET_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
TARGET_ASSEMBLER_SUB_DIRS=


#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh
TARGET_MAKE_TOOLCHAIN_FLAGS=$IJK_MAKE_TOOLCHAIN_FLAGS
TARGET_MAKE_FLAGS=$IJK_MAKE_FLAG
TARGET_GCC_VER=$IJK_GCC_VER
TARGET_GCC_64_VER=$IJK_GCC_64_VER


#----- armv7a begin -----
if [ "$TARGET_ARCH" = "armv7a" ]; then
    TARGET_BUILD_NAME=ffmpeg-armv7a
    TARGET_BUILD_NAME_OPENSSL=openssl-armv7a
    TARGET_BUILD_NAME_LIBSOXR=libsoxr-armv7a
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CLANG_PREFIX=armv7a-linux-androideabi$TARGET_ANDROID_API
    TARGET_CROSS_PREFIX=arm-linux-androideabi
    TARGET_TOOLCHAIN_NAME=${TARGET_CROSS_PREFIX}-${TARGET_GCC_VER}

    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --arch=arm --cpu=cortex-a8"
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-neon"
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-thumb"

    TARGET_EXTRA_CFLAGS="$TARGET_EXTRA_CFLAGS -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb"
    TARGET_EXTRA_LDFLAGS="$TARGET_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"

    TARGET_ASSEMBLER_SUB_DIRS="arm"

elif [ "$TARGET_ARCH" = "x86" ]; then
    

    TARGET_BUILD_NAME=ffmpeg-x86
    TARGET_BUILD_NAME_OPENSSL=openssl-x86
    TARGET_BUILD_NAME_LIBSOXR=libsoxr-x86
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CLANG_PREFIX=i686-linux-android$TARGET_ANDROID_API
    TARGET_CROSS_PREFIX=i686-linux-android
    TARGET_TOOLCHAIN_NAME=x86-${TARGET_GCC_VER}

    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --arch=x86 --cpu=i686 --enable-x86asm"

    TARGET_EXTRA_CFLAGS="$TARGET_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    TARGET_EXTRA_LDFLAGS="$TARGET_EXTRA_LDFLAGS"

    TARGET_ASSEMBLER_SUB_DIRS="x86"

elif [ "$TARGET_ARCH" = "x86_64" ]; then
    TARGET_ANDROID_API=21

    TARGET_BUILD_NAME=ffmpeg-x86_64
    TARGET_BUILD_NAME_OPENSSL=openssl-x86_64
    TARGET_BUILD_NAME_LIBSOXR=libsoxr-x86_64
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CLANG_PREFIX=x86_64-linux-android$TARGET_ANDROID_API
    TARGET_CROSS_PREFIX=x86_64-linux-android
    TARGET_TOOLCHAIN_NAME=${TARGET_CROSS_PREFIX}-${TARGET_GCC_64_VER}

    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --arch=x86_64 --enable-x86asm"
    TARGET_CFLAGS="$TARGET_CFLAGS -march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
    TARGET_EXTRA_CFLAGS="$TARGET_EXTRA_CFLAGS -fPIC"
    TARGET_EXTRA_LDFLAGS="$TARGET_EXTRA_LDFLAGS -Wl"

    TARGET_ASSEMBLER_SUB_DIRS="x86"

elif [ "$TARGET_ARCH" = "arm64" ]; then
    TARGET_ANDROID_API=21

    TARGET_BUILD_NAME=ffmpeg-arm64
    TARGET_BUILD_NAME_OPENSSL=openssl-arm64
    TARGET_BUILD_NAME_LIBSOXR=libsoxr-arm64
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CLANG_PREFIX=aarch64-linux-android$TARGET_ANDROID_API
    TARGET_CROSS_PREFIX=aarch64-linux-android
    TARGET_TOOLCHAIN_NAME=${TARGET_CROSS_PREFIX}-${TARGET_GCC_64_VER}

    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --arch=arm64 --enable-yasm"

    TARGET_EXTRA_CFLAGS="$TARGET_EXTRA_CFLAGS"
    TARGET_EXTRA_LDFLAGS="$TARGET_EXTRA_LDFLAGS"

    TARGET_ASSEMBLER_SUB_DIRS="aarch64 neon"

else
    echo "unknown architecture $TARGET_ARCH";
    exit 1
fi

if [ ! -d $TARGET_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $TARGET_BUILD_NAME"
    echo "!! Run 'sh init-android.sh' first"
    echo ""
    exit 1
fi

TARGET_TOOLCHAIN_PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64

TARGET_SYSROOT=$TARGET_TOOLCHAIN_PATH/sysroot
TARGET_PREFIX=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME/output
TARGET_DEP_OPENSSL_INC=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME_OPENSSL/output/include
TARGET_DEP_OPENSSL_LIB=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME_OPENSSL/output/lib
TARGET_DEP_LIBSOXR_INC=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME_LIBSOXR/output/include
TARGET_DEP_LIBSOXR_LIB=$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME_LIBSOXR/output/lib

case "$UNAME_S" in
    CYGWIN_NT-*)
        TARGET_SYSROOT="$(cygpath -am $TARGET_SYSROOT)"
        TARGET_PREFIX="$(cygpath -am $TARGET_PREFIX)"
    ;;
esac


mkdir -p $TARGET_PREFIX
# mkdir -p $TARGET_SYSROOT


#--------------------
echo ""
echo "--------------------"
echo "[*] check ffmpeg env"
echo "--------------------"
export PATH=$TARGET_TOOLCHAIN_PATH/bin:$PATH
export CC=$TARGET_TOOLCHAIN_PATH/bin/$TARGET_CLANG_PREFIX-clang
export SYSROOT=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
export CXX=$TARGET_TOOLCHAIN_PATH/bin/$TARGET_CLANG_PREFIX-clang++
export LD=${TARGET_CROSS_PREFIX}-ld
export AR=${TARGET_CROSS_PREFIX}-ar
export STRIP=${TARGET_CROSS_PREFIX}-strip

TARGET_CFLAGS="-Os -Wall -pipe \
    -std=c17 \
    -ffast-math \
    -fstrict-aliasing -Werror=strict-aliasing \
    -Wa,--noexecstack \
    -DANDROID -DNDEBUG -fPIC"

# cause av_strlcpy crash with gcc4.7, gcc4.8
# -fmodulo-sched -fmodulo-sched-allow-regmoves

# --enable-thumb is OK
#TARGET_CFLAGS="$TARGET_CFLAGS -mthumb"

# not necessary
#TARGET_CFLAGS="$TARGET_CFLAGS -finline-limit=300"

export COMMON_TARGET_CFG_FLAGS=
. $TARGET_BUILD_ROOT/../../config/module.sh


#--------------------
# with openssl
if [ -f "${TARGET_DEP_OPENSSL_LIB}/libssl.a" ]; then
    echo "OpenSSL detected"
# TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-nonfree"
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-openssl"

    TARGET_CFLAGS="$TARGET_CFLAGS -I${TARGET_DEP_OPENSSL_INC}"
    TARGET_DEP_LIBS="$TARGET_DEP_LIBS -L${TARGET_DEP_OPENSSL_LIB} -lssl -lcrypto"
fi

if [ -f "${TARGET_DEP_LIBSOXR_LIB}/libsoxr.a" ]; then
    echo "libsoxr detected"
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-libsoxr"

    TARGET_CFLAGS="$TARGET_CFLAGS -I${TARGET_DEP_LIBSOXR_INC}"
    TARGET_DEP_LIBS="$TARGET_DEP_LIBS -L${TARGET_DEP_LIBSOXR_LIB} -lsoxr"
fi

TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS $COMMON_TARGET_CFG_FLAGS"

#--------------------
# Standard options:
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --prefix=$TARGET_PREFIX"

# Advanced options (experts only):
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --cross-prefix=${TARGET_CROSS_PREFIX}-"
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-cross-compile"
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --target-os=android"
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-pic"
# TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --disable-symver"

if [ "$TARGET_ARCH" = "x86" ]; then
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --disable-asm"
elif [ "$TARGET_ARCH" = "x86_64" ];then
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --disable-asm"
else
    # Optimization options (experts only):
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-asm"
    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-inline-asm"
fi

case "$TARGET_BUILD_OPT" in
    debug)
        TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --disable-optimizations"
        TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-debug"
        TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --disable-small"
    ;;
    *)
        TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-optimizations"
        TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-debug"
        TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --enable-small"
    ;;
esac

#--------------------
echo ""
echo "--------------------"
echo "[*] configurate ffmpeg"
echo "--------------------"
cd $TARGET_SOURCE
if [ -f "./config.h" ]; then
    echo 'reuse configure'
else
    which $CC
    ./configure $TARGET_CFG_FLAGS \
        --cc=$CC \
        --cxx=$CXX \
        --extra-cflags="$TARGET_CFLAGS $TARGET_EXTRA_CFLAGS" \
        --extra-ldflags="$TARGET_DEP_LIBS $TARGET_EXTRA_LDFLAGS"
    make clean
fi

#--------------------
echo ""
echo "--------------------"
echo "[*] compile ffmpeg"
echo "--------------------"
cp config.* $TARGET_PREFIX
make $TARGET_MAKE_FLAGS > /dev/null
make install
mkdir -p $TARGET_PREFIX/include/libffmpeg
cp -f config.h $TARGET_PREFIX/include/libffmpeg/config.h

#--------------------
echo ""
echo "--------------------"
echo "[*] link ffmpeg"
echo "--------------------"
echo $TARGET_EXTRA_LDFLAGS

TARGET_C_OBJ_FILES=
TARGET_ASM_OBJ_FILES=
for MODULE_DIR in $TARGET_MODULE_DIRS
do
    C_OBJ_FILES="$MODULE_DIR/*.o"
    if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
        echo "link $MODULE_DIR/*.o"
        TARGET_C_OBJ_FILES="$TARGET_C_OBJ_FILES $C_OBJ_FILES"
    fi

    for ASM_SUB_DIR in $TARGET_ASSEMBLER_SUB_DIRS
    do
        ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
        if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
            echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
            TARGET_ASM_OBJ_FILES="$TARGET_ASM_OBJ_FILES $ASM_OBJ_FILES"
        fi
    done
done

$CC -v -fPIC -lm -lz -shared --sysroot=$TARGET_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $TARGET_EXTRA_LDFLAGS \
    -Wl,-soname,libijkffmpeg.so \
    $TARGET_C_OBJ_FILES \
    $TARGET_ASM_OBJ_FILES \
    $TARGET_DEP_LIBS \
    -o $TARGET_PREFIX/libijkffmpeg.so

mysedi() {
    f=$1
    exp=$2
    n=`basename $f`
    cp $f /tmp/$n
    sed $exp /tmp/$n > $f
    rm /tmp/$n
}

echo ""
echo "--------------------"
echo "[*] create files for shared ffmpeg"
echo "--------------------"
rm -rf $TARGET_PREFIX/shared
mkdir -p $TARGET_PREFIX/shared/lib/pkgconfig
ln -s $TARGET_PREFIX/include $TARGET_PREFIX/shared/include
ln -s $TARGET_PREFIX/libijkffmpeg.so $TARGET_PREFIX/shared/lib/libijkffmpeg.so
cp $TARGET_PREFIX/lib/pkgconfig/*.pc $TARGET_PREFIX/shared/lib/pkgconfig
for f in $TARGET_PREFIX/lib/pkgconfig/*.pc; do
    # in case empty dir
    if [ ! -f $f ]; then
        continue
    fi
    cp $f $TARGET_PREFIX/shared/lib/pkgconfig
    f=$TARGET_PREFIX/shared/lib/pkgconfig/`basename $f`
    # OSX sed doesn't have in-place(-i)
    mysedi $f 's/\/output/\/output\/shared/g'
    mysedi $f 's/-lavcodec/-lijkffmpeg/g'
    mysedi $f 's/-lavfilter/-lijkffmpeg/g'
    mysedi $f 's/-lavformat/-lijkffmpeg/g'
    mysedi $f 's/-lavutil/-lijkffmpeg/g'
    mysedi $f 's/-lswresample/-lijkffmpeg/g'
    mysedi $f 's/-lswscale/-lijkffmpeg/g'
done
