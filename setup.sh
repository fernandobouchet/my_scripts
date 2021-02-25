#!/bin/bash
cd ..

git clone https://github.com/attack11/AnyKernel3 -b Extended-Kernel --depth=1 anykernel

if [[ "$@" =~ "clang" ]]; then
	git clone https://github.com/kdrag0n/proton-clang.git --depth=1 clang
elif [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/arter97/arm64-gcc.git -b master --depth=1 gcc
	git clone https://github.com/arter97/arm32-gcc.git -b master --depth=1 gcc32
fi
