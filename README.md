# 项目介绍
https://github.com/bilibili/ijkplayer 的fork,有所改动
- 升级openssl 至`1.1.1o`,提升安全性，原有的有安全漏洞风险,切换到官方上游
- 默认开启x264,x265，启用dash(还是用不了?),opus支持,启用libxml2
- `x86_64`（目标平台）因为编译错误原因默认关闭`汇编加速`
- 支持Android NDK `r21`(其他版本需要有llvm和gcc 4.9共存的版本)
- 暂不支持ios(因为我没设备测试)

## 构建
拉取ffmpeg,libyuv,soundtouch

    sh init-android.sh
拉取openssl

    sh init-android-openssl.sh

指定Android NDK变量
    
    export ANDROID_NDK=NDK所在文件夹

切到构建目录

    cd android/contrib

清理可能干扰的文件

    sh compile-openssl.sh clean
    sh compile-ffmpeg.sh clean

编译FFmpeg前，要把当前目录下的每个`ffmpeg-平台架构`的文件夹里面的configure改下，不然100%报错(原因是openssl更新了测试用的函数，然后ffmpeg没有跟进(是b站的fork没跟进，还在4.0))

关于libxml2

删除以下代码(前提是你系统有libxml2库,debian/ubuntu可能叫做`libxml2-dev`,archlinux默认带，叫做`libxml2`)

    require_pkg_config libxml2 libxml-2.0 libxml2/libxml/xmlversion.h xmlCheckVersion


关于OpenSSL的修改

    check_pkg_config openssl openssl openssl/ssl.h OPENSSL_init_ssl ||

改成

    check_pkg_config openssl openssl openssl/ssl.h OPENSSL_init_ssl ||
    check_lib openssl openssl/ssl.h OPENSSL_init_ssl -lssl -lcrypto ||


开始编译OpenSSL,FFmpeg(注意有没有报错比如说`Error:`这样的)

    sh compile-openssl.sh all
    sh compile-ffmpeg.sh clean

开始编译ijkplayer

    cd ..
    sh compile-ijk.sh all

然后去当前目录的`ijkplayer\ijkplayer-平台架构\src\main\libs`里面的文件夹里面找so,拿到项目里面替换就好