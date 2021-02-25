#!/bin/bash
cd ..

git clone https://github.com/attack11/AnyKernel3 -b Extended-Kernel_dtb-only --depth=1 anykernel

if [[ "$@" =~ "clang" ]]; then
	git clone https://github.com/kdrag0n/proton-clang.git --depth=1 clang
elif [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/arter97/arm64-gcc.git -b master --depth=1 gcc
	git clone https://github.com/arter97/arm32-gcc.git -b master --depth=1 gcc32
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Release type
if [[ $BRANCH == "extended" ]]; then
	export VERSION="Kernel-Hmp-OC-addon"
elif [[ $BRANCH == "extended-eas" ]]; then
	export VERSION="Kernel-Eas-OC-addon"
fi

# Export Version
export DEFCONFIG=whyred_defconfig
export ZIPNAME="Extended-${VERSION}.zip"

# Set COMPILER
export ARCH=arm64 && export SUBARCH=arm64
export KBUILD_JOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

# Compilation
START=$(date +"%s")
make O=out clean && make O=out mrproper
make O=out ARCH=arm64 whyred_defconfig
if [[ "$@" =~ "clang" ]]; then
	export PATH="$(pwd)/clang/bin:$PATH"
	make dtbs -j${KBUILD_JOBS} O=out ARCH=arm64 CC="clang" CROSS_COMPILE="aarch64-linux-gnu-" CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
elif [[ "$@" =~ "gcc" ]]; then
    export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-elf-"
	export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-eabi-"
	make dtbs -j${KBUILD_JOBS} O=out ARCH=arm64
fi
END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/dts/qcom/sdm660-mtp.dtb ]
	then
	cat $(pwd)/out/arch/arm64/boot/dts/qcom/sdm660-mtp.dtb $(pwd)/out/arch/arm64/boot/dts/qcom/sdm636-mtp_e7s.dtb > $(pwd)/out/arch/arm64/boot/dts/qcom/dtb
	cp $(pwd)/out/arch/arm64/boot/dts/qcom/dtb $(pwd)/anykernel
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="Repository: <code>$(basename `git rev-parse --show-toplevel`)</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
Compilation Time: <code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</code>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
	cd anykernel
	zip -r9 ${ZIPNAME} *
	curl -F chat_id="${KERNEL_CHAT_ID_PRIVATE}" \
                    -F caption="$(sha1sum ${ZIPNAME} | awk '{ print $1 }')" \
                    -F document=@"$(pwd)/${ZIPNAME}" \
                    https://api.telegram.org/bot${BOT_API_TOKEN}/sendDocument
    rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb
	else
    exit 1
fi
