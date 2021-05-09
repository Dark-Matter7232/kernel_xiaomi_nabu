#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/lybdroid/kernel_xiaomi_inlh -b  eleven  kernel
cd kernel
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 -b gcc-master gcc64
git clone --depth=1 https://github.com/mvaisakh/gcc-arm -b gcc-master gcc32
git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
git clone --depth=1 https://github.com/lybdroid/AnyKernel3 -b vayu-miui AnyKernel
git clone --depth=1 https://android.googlesource.com/platform/system/libufdt libufdt
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
LOG=$(echo *.log)
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/vayu_user_defconfig
TC_DIR=${PWD}
GCC64_DIR="${PWD}/gcc64"
GCC32_DIR="${PWD}/gcc32"
CLANG_DIR="${PWD}/clang"
PATH="$TC_DIR/bin/:$CLANG_DIR/bin/:$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_HOST="Drone-CI"
export KBUILD_BUILD_USER="lybxlpsv"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$BOTTOKEN/sendSticker" \
        -d sticker="CAADBQADVAADaEQ4KS3kDsr-OWAUFgQ" \
        -d chat_id=$CHATID
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$BOTTOKEN/sendMessage" \
        -d chat_id="$CHATID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• vayu lybkernel •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Poco X3</b> (vayu)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>Proton clang 12</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b> #AOSP-Alpha"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$BOTTOKEN/sendDocument" \
        -F chat_id="$CHATID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Poco X3 (vayu)</b> | <b>Eva GCC</b>"
}
# Fin Error
function finerr() {
    curl -F document=@$LOG "https://api.telegram.org/bot$BOTTOKEN/sendDocument" \
        -F chat_id="$CHATID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build logs"
}
# Compile plox
function compile() {
   make O=out ARCH=arm64 vayu_user_defconfig
       make -j$(nproc --all) O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
#    python2 "libufdt/utils/src/mkdtboimg.py" \
# 					create "out/arch/arm64/boot/dtbo.img" --page_size=4096 out/arch/arm64/boot/dts/qcom/*.dtbo
   cp out/arch/arm64/boot/dtbo.img AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 vayu-lybkernel-${TANGGAL}.zip *
    cd ..
}
sticker
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
finerr
push
