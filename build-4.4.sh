#!/bin/bash
cd ..

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Release type
if [[ $BRANCH == "extended" ]]; then
    if [[ "$@" =~ "oldcam" ]]; then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended Hmp 4.4 ${STABLE_RELEASE_VERSION} build's started on CI...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
	export VERSION="Kernel-4.4-Hmp-Oldcam-${STABLE_RELEASE_VERSION}"
	elif [[ "$@" =~ "newcam" ]]; then
	export VERSION="Kernel-4.4-Hmp-Newcam-${STABLE_RELEASE_VERSION}"
	fi
elif [[ $BRANCH == "extended-eas" ]]; then
    if [[ "$@" =~ "oldcam" ]]; then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended Eas 4.4 ${STABLE_RELEASE_VERSION} build's started on CI...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
	export VERSION="Kernel-4.4-Eas-Oldcam-${STABLE_RELEASE_VERSION}"
	elif [[ "$@" =~ "newcam" ]]; then
	export VERSION="Kernel-4.4-Eas-Newcam-${STABLE_RELEASE_VERSION}"
	fi
else
    if [[ "$@" =~ "oldcam" ]]; then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended Beta ${BRANCH} build's started on CI...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
	export VERSION="Kernel-4.4-Beta-Eas-Oldcam-${BRANCH}-${SEMAPHORE_WORKFLOW_NUMBER}"
	elif [[ "$@" =~ "newcam" ]]; then
	export VERSION="Kernel-4.4-Beta-Eas-Newcam-${BRANCH}-${SEMAPHORE_WORKFLOW_NUMBER}"
	fi
fi

# Export User, Host and Local Version
export LOCALVERSION=`echo -${VERSION}`
export KBUILD_BUILD_USER=attack11
export KBUILD_BUILD_HOST=xda
export ZIPNAME="Extended-${VERSION}.zip"

# Compilation
if [[ "$@" =~ "oldcam" ]]; then
	export DEFCONFIG=whyred_defconfig
elif [[ "$@" =~ "newcam" ]]; then
	export DEFCONFIG=whyred-newcam_defconfig
fi
START=$(date +"%s")
make O=out clean && make O=out mrproper
if [[ "$@" =~ "clang" ]]; then
	export PATH="$(pwd)/clang/bin:$PATH"
	make O=out ARCH=arm64 $DEFCONFIG
	make -j$(nproc --all) O=out ARCH=arm64 CC="clang" CROSS_COMPILE="aarch64-linux-gnu-" CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
elif [[ "$@" =~ "gcc" ]]; then
  	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-elf-"
	export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-eabi-"
	make O=out ARCH=arm64 $DEFCONFIG
	make -j$(nproc --all) O=out ARCH=arm64
fi
END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]
	then
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
if [[ $BRANCH == "extended" || $BRANCH == "extended-eas" ]]; then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
fi
	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<b>Repository:</b> <i><code>$(basename `git rev-parse --show-toplevel`)</code></i>
<b>Branch:</b> <i><code>$(git rev-parse --abbrev-ref HEAD)</code></i>
<b>Latest Commit:</b> <i><code>$(git log --pretty=format:'%h : %s' -1)</code></i>
<b>Compilation Time:</b> <i><code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</code></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
	mkdir $(pwd)/releases
	cd anykernel
	zip -r9 ${ZIPNAME} *
	cd .. && mv $(pwd)/anykernel/${ZIPNAME} $(pwd)/releases
	curl -F chat_id="${KERNEL_CHAT_ID_PRIVATE}" \
                    -F caption="$(sha1sum $(pwd)/releases/${ZIPNAME} | awk '{ print $1 }')" \
                    -F document=@"$(pwd)/releases/${ZIPNAME}" \
                    https://api.telegram.org/bot${BOT_API_TOKEN}/sendDocument
else
        if [[ $BRANCH == "extended" || $BRANCH == "extended-eas" ]]; then
        curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build finished with errors...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PUBLIC} -d parse_mode=HTML
        curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build finished with errors...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
        else
        curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="<i><b>Extended-${VERSION} build finished with errors...</b></i>" -d chat_id=${KERNEL_CHAT_ID_PRIVATE} -d parse_mode=HTML
        fi
    exit 1
fi
