#!/bin/bash
#
# Compile script for kernel
#

SECONDS=0
DATE=$(date '+%Y%m%d-%H%M')

DEVICE="${1:-pissarro}"
DEFCONFIG="${DEVICE}_defconfig"
ZIPNAME="BrickedKernel-${DEVICE}-${DATE}.zip"

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

echo -e "\nCleaning up...\n"
if [ -d "out" ]; then
    echo "Found old 'out' folder, deleting..."
    rm -rf out
fi

if [ -f "AnyKernel3/Image.gz" ]; then
    echo "Found old image in AnyKernel3, deleting..."
    rm -f AnyKernel3/Image.gz
fi

if [ -f "KernelSU-Next" ]; then
    echo "Found old KernelSU-Next, deleting..."
    rm -f KernelSU-Next
fi

curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s legacy

echo -e "\nDefconfig compilation\n"
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
    Image.gz

if [ -f "out/arch/arm64/boot/Image.gz" ]; then
    echo -e "\nKernel compiled successfully! Image at out/arch/arm64/boot/Image.gz\n"
    
    cp out/arch/arm64/boot/Image.gz AnyKernel3
    cd AnyKernel3 && zip -r9 "../$ZIPNAME" . && cd ..
    echo "Zip package created: $ZIPNAME"
else
    echo -e "\nCompilation failed!\n"
    exit 1
fi

echo "Elapsed time: $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)."
