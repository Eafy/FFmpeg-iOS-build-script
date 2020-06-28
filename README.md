# FFmpeg-iOS-build-script
iOS平台编译FFmpeg的脚本，可能包含多个FFmpeg版本，不同版本可能支持不同的第三方库等。</br>
PS：需要在Xcode 10.1以上，MacOS 10.15以下版本编译；

## FFpmeg 3.4.2:
支持x264、fdk-aac、freetype字库、opencore-amr，封板代码进行了裁减。</br>
封版Release：[3.4.2.1.0.0](https://github.com/Eafy/FFmpeg-iOS-build-script/releases/tag/3.4.2.1.0.0)；

## FFpmeg 4.2:
支持x264、fdk-aac、opencore-amr、openssl，封板代码进行了裁减。</br>
### 编译前工作
  - 进入对应的版本文件夹，比如*FFmpeg-ios-build-script-master/4.2
  - 修改需要运行的脚本文件权限：chmod -R 777 *.sh
### 编译参数说明
    ./build-ffmpeg-iOS.sh `平台类型` `SDK最低版本` `第三方库是否编译进库` `是否重新编译第三方库` </br>
### 编译
  - FFmpeg一键编译</br>   
      `./build-ffmpeg-iOS.sh`
      >`#需注意Mac和Xcode版本`
   - FFmpeg单平台编译</br>
   编译arm64平台、SDK Min Version 8.0的所有第三方的ffmpeg库：</br>
   `./build-ffmpeg-iOS.sh arm64 8.0 all`</br>
   编译x86平台、SDK Min Version 8.0的带x264的ffmpeg库：</br>
   `./build-ffmpeg-iOS.sh x86 8.0 x264 yes`</br>
