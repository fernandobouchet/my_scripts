#!/bin/bash
cd ..

git clone https://github.com/attack11/AnyKernel3 -b Extended-Kernel --depth=1 anykernel

if [[ "$@" =~ "clang" ]]; then
	git clone https://github.com/kdrag0n/proton-clang.git --depth=1 clang
elif [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/arter97/arm64-gcc.git -b master --depth=3 gcc
	git clone https://github.com/arter97/arm32-gcc.git -b master --depth=3 gcc32
	cd gcc
	git checkout cd9eb72bace3b4d682d5251a9eb4829bdd0ec2ca
	cd ../gcc32
	git checkout b788b457799d68553f51a00a5dd4a1d0ea6b0558
	cd ..
fi
