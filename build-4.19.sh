#!/bin/bash
cd ..

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Release type
if [[ $BRANCH == "extended" ]]; then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended 4-19 ${STABLE_RELEASE_VERSION} build's started on CI...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
	export VERSION="Kernel-4.19-${STABLE_RELEASE_VERSION}"
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended Beta ${BRANCH} build's started on CI...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
	export VERSION="Kernel-4.19-Beta-${BRANCH}-${SEMAPHORE_WORKFLOW_NUMBER}"
fi

# Export User, Host and Local Version
export LOCALVERSION=`echo -${VERSION}`
export KBUILD_BUILD_USER=attack11
export KBUILD_BUILD_HOST=xda
export ZIPNAME="Extended-${VERSION}.zip"
export DEFCONFIG=vendor/whyred_defconfig

# Set COMPILER
export ARCH=arm64
export KBUILD_JOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
if [[ "$@" =~ "clang" ]]; then
	export PATH="$(pwd)/clang/bin:$PATH"
elif [[ "$@" =~ "gcc" ]]; then
    export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-elf-"
	export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-eabi-"
fi

# Compilation
START=$(date +"%s")
make O=out $DEFCONFIG
if [[ "$@" =~ "clang" ]]; then
	make -j${KBUILD_JOBS} O=out ARCH=arm64 CC="clang" CROSS_COMPILE="aarch64-linux-gnu-" CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
elif [[ "$@" =~ "gcc" ]]; then
	make -j${KBUILD_JOBS} O=out
fi
END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]
	then
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
if [ $BRANCH == "extended" ]; then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
fi
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<b>Repository:</b> <i><code>$(basename `git rev-parse --show-toplevel`)</code></i>
<b>Branch:</b> <i><code>$(git rev-parse --abbrev-ref HEAD)</code></i>
<b>Latest Commit:</b> <i><code>$(git log --pretty=format:'%h : %s' -1)</code></i>
<b>Compilation Time:</b> <i><code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</code></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
	cd anykernel
	zip -r9 ${ZIPNAME} *
	curl -F chat_id="${KERNEL_CHAT_ID_PRIVATE}" \
                    -F caption="$(sha1sum ${ZIPNAME} | awk '{ print $1 }')" \
                    -F document=@"$(pwd)/${ZIPNAME}" \
                    https://api.telegram.org/bot${BOT_API_TOKEN}/sendDocument
    rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb
else
        if [[ $BRANCH == "extended" ]]; then
        curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build finished with errors...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
        curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build finished with errors...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
        else
        curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build finished with errors...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
        fi
    exit 1
fi
