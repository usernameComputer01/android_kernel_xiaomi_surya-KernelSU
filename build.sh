#!/bin/bash
#
# Compile script for Arise kernel
# Copyright (C) 2020-2021 Adithya R.

TC_DIR="$(pwd)/tc/clang-neutron"
DEFCONFIG="surya_defconfig"

export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
	echo "Neutron Clang not found! Downloading to $TC_DIR..."
	mkdir -p "$TC_DIR" && cd "$TC_DIR"
	curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
	bash ./antman -S
	bash ./antman --patch=glibc
	cd ../..
	if ! [ -d "$TC_DIR" ]; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

cd "$TC_DIR" && bash ./antman -U && cd ../..


if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

if [[ $1 = "-rf" || $1 = "--regen-full" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG
	cp out/.config arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated full defconfig at $DEFCONFIG"
	exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi


mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

if [ ! -z "$USE_CCACHE"  ] && [ ! -z "$CCACHE_EXEC"  ] && [ -x "$CCACHE_EXEC" ]; then
	CC_EXEC="$CCACHE_EXEC clang"
else
	CC_EXEC=clang
fi

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC="$CC_EXEC" LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE="aarch64-linux-gnu-" CROSS_COMPILE_COMPAT="arm-linux-gnueabi-" LLVM=1 LLVM_IAS=1 DTC_EXT=dtc Image.gz 2> >(tee log.txt >&2) || exit $?
