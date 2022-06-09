#! /usr/bin/env bash
#
# Copyright (C) 2014 Miguel Botón <waninkoko@gmail.com>
# Copyright (C) 2014 Zhang Rui <bbcallen@gmail.com>
# Copyright (C) 2022 Hydrogenium2020
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
    echo "运行前一定要定义ANDROID_NDK变量，以便让我找到Android NDK位置"
    echo "这个变量一定要定义了你的Android NDK文件夹位置\n"
    exit 1
fi

#--------------------
# 变量定义
#构建平台架构
TARGET_ARCH=$1
if [ -z "$TARGET_ARCH" ]; then
    echo "没有指定架构,只能编译以下架构 'armv7a, arm64, x86, ...'.\n"
    exit 1
fi
#构建的那个地方的根目录
TARGET_BUILD_ROOT=`pwd`

#Android SDK API版本
TARGET_ANDROID_API=19

#构建名称
TARGET_BUILD_NAME=

#源码位置
TARGET_SOURCE=

#构建工具链前缀
TARGET_CROSS_PREFIX=

#构建CFLAGS
TARGET_CFG_FLAGS=

#构建Android ABI（就是平台架构）
TARGET_ANDROID_ABI=

#额外的构建CFLAGS/LDFLAGS
TARGET_EXTRA_CFLAGS=
TARGET_EXTRA_LDFLAGS=



#--------------------
echo ""
echo "--------------------"
echo "[*] 设置环境变量"
echo "--------------------"
. ./tools/do-detect-env.sh
TARGET_MAKE_TOOLCHAIN_FLAGS=$IJK_MAKE_TOOLCHAIN_FLAGS
TARGET_MAKE_FLAGS="$IJK_MAKE_FLAG"
TARGET_GCC_VER=$IJK_GCC_VER
TARGET_GCC_64_VER=$IJK_GCC_64_VER


#如果未指定，从Armv7a开始编译
if [ "$TARGET_ARCH" = "armv7a" ]; then
    TARGET_ANDROID_ARCH=arm
    TARGET_ANDROID_ABI="android-arm"
    
    TARGET_BUILD_NAME=openssl-armv7a
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME
	
    TARGET_CROSS_PREFIX=arm-linux-androideabi
	TARGET_TOOLCHAIN_NAME=${TARGET_CROSS_PREFIX}-${TARGET_GCC_VER}



elif [ "$TARGET_ARCH" = "x86" ]; then
    TARGET_ANDROID_ARCH=x86
    TARGET_ANDROID_ABI="android-x86"

    TARGET_BUILD_NAME=openssl-x86
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME
	
    TARGET_CROSS_PREFIX=i686-linux-android
	TARGET_TOOLCHAIN_NAME=x86-${TARGET_GCC_VER}

    TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS no-asm"

elif [ "$TARGET_ARCH" = "x86_64" ]; then
    TARGET_ANDROID_ARCH=x86_64
    #Android 5.0.0开始支持64位架构，所以指定Api为21
    TARGET_ANDROID_API=21
    TARGET_ANDROID_ABI="android-x86_64"

    TARGET_BUILD_NAME=openssl-x86_64
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CROSS_PREFIX=x86_64-linux-android
    TARGET_TOOLCHAIN_NAME=${TARGET_CROSS_PREFIX}-${TARGET_GCC_64_VER}

elif [ "$TARGET_ARCH" = "arm64" ]; then
    TARGET_ANDROID_ARCH=arm64
    #Android 5.0.0开始支持64位架构，所以指定Api为21
    TARGET_ANDROID_API=21
    TARGET_ANDROID_ABI="android-arm64"

    TARGET_BUILD_NAME=openssl-arm64
    TARGET_SOURCE=$TARGET_BUILD_ROOT/$TARGET_BUILD_NAME

    TARGET_CROSS_PREFIX=aarch64-linux-android
    TARGET_TOOLCHAIN_NAME=${TARGET_CROSS_PREFIX}-${TARGET_GCC_64_VER}

else
    echo "不支持的架构 $TARGET_ARCH !";
    exit 1
fi

#工具链位置
TARGET_TOOLCHAIN_PATH=$ANDROID_NDK/toolchain/$TARGET_TOOLCHAIN_NAME/prebuilt/linux-x86_64
echo "-> 使用位于 $TARGET_TOOLCHAIN_PATH  的工具链"
#构建输出文件夹(就是生成库的位置)
TARGET_PREFIX="$TARGET_BUILD_ROOT/build/$TARGET_BUILD_NAME/output"
echo "-> 生成的文件在 $TARGET_PREFIX"
#创建构建输出文件夹
mkdir -p $TARGET_PREFIX


#--------------------
echo ""
echo "--------------------"
echo "[*] 配置openssl"
echo "--------------------"
export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export PATH=$TARGET_TOOLCHAIN_PATH/bin:$PATH
echo $PATH
export COMMON_TARGET_CFG_FLAGS=

TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS $COMMON_TARGET_CFG_FLAGS"

#--------------------
# 构建选项:
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS zlib-dynamic"
#指定API
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS -D__ANDROID_API__=$TARGET_ANDROID_API"
#不构建共享库
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS no-shared"
#构建文件夹
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS --prefix=$TARGET_PREFIX"
#指定ABI
TARGET_CFG_FLAGS="$TARGET_CFG_FLAGS $TARGET_ANDROID_ABI"
#--------------------
cd $TARGET_SOURCE
#if [ -f "./Makefile" ]; then
#    echo 'reuse configure'
#else

    echo "./Configure $TARGET_CFG_FLAGS"
    ./Configure $TARGET_CFG_FLAGS 
#        --extra-cflags="$TARGET_CFLAGS $TARGET_EXTRA_CFLAGS" \
#        --extra-ldflags="$TARGET_EXTRA_LDFLAGS"
#fi

#--------------------
echo ""
echo "--------------------"
echo "[*] 编译 openssl"
echo "--------------------"
make depend
make $TARGET_MAKE_FLAGS
make install


