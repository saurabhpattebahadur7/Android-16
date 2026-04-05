#!/bin/bash
#
# compile script for dtbo.img
#

SECONDS=0
DATE=$(date '+%Y%m%d-%H%M')

DEVICE="${1:-pissarro}"
DEFCONFIG="${DEVICE}_defconfig"
ZIPNAME="DTBO-${DEVICE}-${DATE}.zip"

echo -e "Building for: $DEVICE\n"

TC_DIR="$HOME/toolchains/proton-clang"
CURRENT_DIR=$(pwd)
if [ ! -d "$TC_DIR" ]; then
    mkdir -p "$HOME/toolchains"
    cd "$HOME/toolchains"
    git clone --depth=1 https://gitlab.com/LeCmnGend/proton-clang.git -b clang-15 proton-clang
    cd "$CURRENT_DIR"
fi
export PATH="$TC_DIR/bin:$PATH"

echo -e "\nDefconfig compilation\n"
rm -rf out
mkdir -p out
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 HOSTCC="clang" HOSTCXX="clang++" $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out \
    ARCH=arm64 \
    CC="clang" \
    HOSTCC="clang" \
    HOSTCXX="clang++" \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 \
    LLVM_IAS=1 \
    KCFLAGS="-w" \
    dtbo.img

if [ -f "out/arch/arm64/boot/dtbo.img" ]; then
    echo -e "\nDTBO compiled successfully! dtbo.img at out/arch/arm64/boot/dtbo.img\n"
    
    cp out/arch/arm64/boot/dtbo.img Flasher
    cd Flasher && zip -r9 "../$ZIPNAME" . && cd ..
    echo "Zip package created: $ZIPNAME"
else
    echo -e "\nCompilation failed!\n"
    exit 1
fi

echo "Elapsed time: $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)."
