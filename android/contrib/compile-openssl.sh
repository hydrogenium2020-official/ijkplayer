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

#----------
UNI_BUILD_ROOT=`pwd`
TARGET_TARGET=$1
set -e
set +x

TARGET_ACT_ARCHS_32="armv7a x86"
TARGET_ACT_ARCHS_64="armv7a arm64 x86 x86_64"
TARGET_ACT_ARCHS_ALL=$TARGET_ACT_ARCHS_64

echo_archs() {
    echo "===================="
    echo "[*] check archs"
    echo "===================="
    echo "TARGET_ALL_ARCHS = $TARGET_ACT_ARCHS_ALL"
    echo "TARGET_ACT_ARCHS = $*"
    echo ""
}

echo_usage() {
    echo "Usage:"
    echo "  compile-openssl.sh armv7a|arm64|x86|x86_64"
    echo "  compile-openssl.sh all|all32"
    echo "  compile-openssl.sh all64"
    echo "  compile-openssl.sh clean"
    echo "  compile-openssl.sh check"
    exit 1
}

echo_nextstep_help() {
    #----------
    echo ""
    echo "--------------------"
    echo "[*] Finished"
    echo "--------------------"
    echo "# to continue to build ffmpeg, run script below,"
    echo "sh compile-ffmpeg.sh "
    echo "# to continue to build ijkplayer, run script below,"
    echo "sh compile-ijk.sh "
}

#----------
case "$TARGET_TARGET" in
    "")
        echo_archs armv7a
        sh tools/do-compile-openssl.sh armv7a
    ;;
    armv7a|arm64|x86|x86_64)
        echo_archs $TARGET_TARGET
        sh tools/do-compile-openssl.sh $TARGET_TARGET
        echo_nextstep_help
    ;;
    all32)
        echo_archs $TARGET_ACT_ARCHS_32
        for ARCH in $TARGET_ACT_ARCHS_32
        do
            sh tools/do-compile-openssl.sh $ARCH
        done
        echo_nextstep_help
    ;;
    all|all64)
        echo_archs $TARGET_ACT_ARCHS_64
        for ARCH in $TARGET_ACT_ARCHS_64
        do
            sh tools/do-compile-openssl.sh $ARCH
        done
        echo_nextstep_help
    ;;
    clean)
        echo_archs TARGET_ACT_ARCHS_64
        for ARCH in $TARGET_ACT_ARCHS_ALL
        do
            if [ -d openssl-$ARCH ]; then
                cd openssl-$ARCH && git clean -xdf && cd -
            fi
        done
        rm -rf ./build/openssl-*
    ;;
    check)
        echo_archs TARGET_ACT_ARCHS_ALL
    ;;
    *)
        echo_usage
        exit 1
    ;;
esac
