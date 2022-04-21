#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# ----------------------------------------------------------------------
# build.sh - build kernel zImage from source tree
#
# This will only work when the kernel was compiled with clang
# and script is in main dir
#
# usage: Run './build.sh' from top level of kernel tree.
#                make chmod 0775 build.sh
#
# Copyright (C) 2022 Marcin Kubiak mARk <r3066.funtab@gmail.com>
# Licensed under the terms of the GNU GPL License
# ----------------------------------------------------------------------
#
# specify colors utilized in the terminal
    red=$(tput setaf 1)             #  red
    grn=$(tput setaf 2)             #  green
    ylw=$(tput setaf 3)             #  yellow
    blu=$(tput setaf 4)             #  blue
    ppl=$(tput setaf 5)             #  purple
    cya=$(tput setaf 6)             #  cyan
    txtbld=$(tput bold)             #  Bold
    bldred=${txtbld}$(tput setaf 1) #  red
    bldgrn=${txtbld}$(tput setaf 2) #  green
    bldylw=${txtbld}$(tput setaf 3) #  yellow
    bldblu=${txtbld}$(tput setaf 4) #  blue
    bldppl=${txtbld}$(tput setaf 5) #  purple
    bldcya=${txtbld}$(tput setaf 6) #  cyan
    txtrst=$(tput sgr0)             #  Reset
    rev=$(tput rev)                 #  Reverse color
    pplrev=${rev}$(tput setaf 5)
    cyarev=${rev}$(tput setaf 6)
    ylwrev=${rev}$(tput setaf 3)
    blurev=${rev}$(tput setaf 4)
    blink=$(tput blink)
    dim=$(tput dim)
    clear=$(tput clear)

# extra var
TOOLCHAINDIR=clang15_20220402f
PRODUCT=sweet
ANDROID=MiuiR

HEADER="K E R N E L • S W E E T • S W E E T I N"

echo build_vers >> build_vers
TIME=$(date +%Y%m%d-%H%M)
KERNELVERSION=$(grep VERSION Makefile | head -n1 | awk '{print $3}').$(grep PATCHLEVEL Makefile | head -n1 | awk '{print $3}').$(grep SUBLEVEL Makefile | head -n1 | awk '{print $3}');
COMMIT=$(git log --oneline -1 | awk '{print $1}' | cut -c 1-8)
COUNTER=$( cat -n build_vers | tail -1 | awk '{print $1}')
CONFIG=vendor/sweet_defconfig
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
STRIP="aarch64-linux-gnu-strip"

export KBUILD_BUILD_USER="mARk"
export KBUILD_BUILD_HOST="linux"

export KBUILD_BUILD_TIMESTAMP=$TIME
export PATH="$HOME/toolchain/$TOOLCHAINDIR/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/toolchain/$TOOLCHAINDIR/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$($HOME/toolchain/$TOOLCHAINDIR/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export CC_STRING="$($KBUILD_COMPILER_STRING --version | head -n 1  | perl -pe 's/\((?:http|git).*?\)//gs')"
export out=out

# make simply gitlog incl package
    git log --pretty=format:"  %s" |  awk 'NR == 1, NR == 400 { print $0 }' | cut -c 1-60 > AnyKernel3/changelog.tmp
    sed  -i '1i\=============================================='                             AnyKernel3/changelog.tmp
    sed  -i "1i\Date: ${TIME}                 #${COUNTER}"                                  AnyKernel3/changelog.tmp
    sed  -i "1i\mARkOS android ${ANDROID} kernel-${KERNELVERSION} "                         AnyKernel3/changelog.tmp
    sed  -i '1i\============================================='                              AnyKernel3/changelog.tmp
    sed -n -e '/^======/,/Linux 4.14./p' AnyKernel3/changelog.tmp | more | head -n -1  > AnyKernel3/changelog
    rm AnyKernel3/changelog.tmp

# host info view in header
    echo -e ' \n ';
    echo -e ${red}"   ${HEADER}   "${txtrst};  
    echo -e ${bldcya}'  =================================================='${txtrst};
    echo  ${txtbld}${ylw}"   Target:       "${txtrst}$PRODUCT-$ANDROID-v$KERNELVERSION-$COMMIT;
    echo  ${txtbld}${ppl}"   Builds:       "${txtrst}#$COUNTER;
    echo -e ' ';
    echo  ${txtbld}${grn}"   Platform:     "${txtrst}$(lsb_release -d | cut -c 14-70 ) $(uname -srm);
    echo  ${txtbld}${grn}"   Toolchain:    "${txtrst}$(clang --version | head -n 1)
    echo  ${txtbld}${grn}"   Linker:       "${txtrst}$(gcc --version | head -n 1)
    echo  ${txtbld}${grn}"                 "${txtrst}$(ld.lld --version | head -n 1)
    echo  ${txtbld}${grn}"                 "${txtrst}$(ld --version | head -n 1)
    echo -e ${bldcya}'  =================================================='${txtrst};
    echo -e ${dim}"\n"

# functions
start_build () {
    make -j$(nproc --all) O=$out \
                          ARCH=arm64 \
                          CC="ccache clang" \
                          AR="llvm-ar" \
                          NM="llvm-nm" \
			  LD="ld.lld" \
			  AS="llvm-as" \
			  OBJCOPY="llvm-objcopy" \
			  OBJDUMP="llvm-objdump" \
			  STRIP="llvm-strip" \
                          CLANG_TRIPLE=aarch64-linux-gnu- \
                          CROSS_COMPILE=aarch64-linux-gnu- \
                          CROSS_COMPILE_ARM32=arm-linux-gnueabi- \

}

# build kernel Image.gz dtbo.img
    make O=$out ARCH=arm64 $CONFIG > /dev/null
    start_build

    if [ -f "$out/arch/arm64/boot/Image.gz" ] && [ -f "$out/arch/arm64/boot/dtbo.img" ] && [ -f "$out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb" ]; then

	    echo -e ${bldcya}"\nKernel compiled succesfully! \n    Zipping and packing modules... \n"${txtrst};

	    ZIPNAME="boot•mARkOS•$KERNELVERSION•$ANDROID•$PRODUCT-$TIME.zip"

    if [ ! -d AnyKernel3 ]; then
	    git clone -q https://github.com/mark-android/AnyKernel3.git
    fi;

    cp -f $out/arch/arm64/boot/Image.gz AnyKernel3/zImage
    cp -f $out/arch/arm64/boot/dtbo.img AnyKernel3
    cp -f $out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb AnyKernel3/dtb

    python3 avbtool.py add_hash_footer --image AnyKernel3/dtbo.img --partition_size=33554432 --partition_name dtbo

    cd AnyKernel3
	if [ ! -d $KERNEL_DIR/_BUILD_KERNEL ]; then
            mkdir $KERNEL_DIR/_BUILD_KERNEL
	fi;

    zip -r9 "$KERNEL_DIR/_BUILD_KERNEL/$ZIPNAME" *
    cd ..

        rm AnyKernel3/zImage
        rm AnyKernel3/dtbo.img

    echo -e ${bldgrn}"\nZipping succesfully! \n"${txtrst};
    echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo -e ${bldylw}"Zip: $ZIPNAME" ${txtrst};
    echo -e "";
    echo -e "";

# delete output dir
    rm -rf $out

# footer
	echo -e "";
	echo -e "";
	echo -e ${blu}"                 _    _  _  _     _ _   _ _    "${txtrst};
	echo -e ${blu}"    _ _ _ _     / \  |  _ \| | _ / _ \/ _ _|   "${txtrst};
	echo -e ${grn}"   |  _   _ \  / _ \ | |_) | |/ / | | \_ _ \   "${txtrst};
	echo -e ${ylw}"   | | | | | |/ _,_ \|  _ <|   <| |_| |_ _) |  "${txtrst};
	echo -e ${red}"   |_| |_| |_/_/   \_\_| \_\_|\_|\_ _/ \_ _/   "${txtrst};
	echo -e ${red}"         • K E R N E L • S W E E T •           "${txtrst};  
	echo -e ${blu}"                                               "${txtrst};
	echo -e ${blu}"                                               "${txtrst};
	echo -e ${ppl}"            Xiaomi Redmi Note 10 Pro           "${txtrst};
	echo -e ${ppl}"            by mARk-android@github             "${txtrst};
	echo -e ${blu}"                                               "${txtrst};
	echo -e ${blu}"   ******************************************* "${txtrst};
	echo -e "";
	echo -e "";
	echo -e "";
	echo -e "";

else
    echo -e ${bldred}"\nCompilation failed!\n"${txtrst};
fi;
