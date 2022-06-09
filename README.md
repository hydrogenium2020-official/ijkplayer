# 项目介绍
https://github.com/bilibili/ijkplayer 的fork,有所改动
- 升级openssl 至1.1.1o,提升安全性，原有的有安全漏洞风险,切换到官方上游
- 升级soundtouch至2.3.1
- 升级libyuv至https://github.com/noiseless/libyuv 所更新的最新commit
- 默认开启x264,x265,av1解码，启用dash,opus支持,启用libxml2
- x86_64因为编译错误原因默认关闭汇编加速
- 支持Android NDK r21(其他版本需要有llvm和gcc 4.9共存的版本)
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

开始编译OpenSSL,FFmpeg(注意有没有报错比如说`Error:`这样的)

    sh compile-openssl.sh all
    sh compile-ffmpeg.sh clean

开始编译ijkplayer

    cd ..
    sh compile-ijk.sh all

然后去当前目录的`ijkplayer\ijkplayer-平台架构`\src\main\libs里面的文件夹里面找so,拿到项目里面替换就好