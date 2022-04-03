#! /bin/bash
# Copyright (C) 2020 KenHV
# Copyright (C) 2020 Starlight
# Copyright (C) 2021 CloudedQuartz
#
# Specify colors utilized in the terminal
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
    
    
    
# Config
DEVICE="sweet"
DEFCONFIG="vendor/${DEVICE}_defconfig"
LOG="$HOME/log.txt"

# Export arch and subarch
ARCH="arm64"
SUBARCH="arm64"
export ARCH SUBARCH

KERNEL_IMG=$KERNEL_DIR/out/arch/$ARCH/boot/Image.gz
KERNEL_DTBO=$KERNEL_DIR/out/arch/$ARCH/boot/dtbo.img

#export PATH="$HOME/proton-clang/bin:$PATH"
#export LD_LIBRARY_PATH="$HOME/proton-clang/lib:$LD_LIBRARY_PATH"
#export KBUILD_COMPILER_STRING="$($HOME/proton-clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"

# build_setup - enter kernel directory and get info for caption.
# also removes the previous kernel image, if one exists.
build_setup() {
    cd "$KERNEL_DIR" || echo -e "\nKernel directory ($KERNEL_DIR) does not exist" || exit 1

    [[ ! -d out ]] && mkdir out
    [[ -f "$KERNEL_IMG" ]] && rm "$KERNEL_IMG"
	find out/ -name "*.dtb*" -type f -delete
}

# build_config - builds .config file for device.
build_config() {
	make O=out $1 -j$(nproc --all)
}
# build_kernel - builds defconfig and kernel image using llvm tools, while saving the output to a specified log location
# only use after runing build_setup()
build_kernel() {

    BUILD_START=$(date +"%s")
    make -j$(nproc --all) O=out \
                PATH="$TC_DIR/bin:$PATH" \
                CC="ccache clang" \
                CROSS_COMPILE=$TC_DIR/bin/aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=$TC_DIR/bin/arm-linux-gnueabi- \
                LLVM=llvm- \
                AR=llvm-ar \
                NM=llvm-nm \
                OBJCOPY=llvm-objcopy \
                OBJDUMP=llvm-objdump \
                STRIP=llvm-strip |& tee $LOG

    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
}

# build_end - creates and sends zip
build_end() {

	if ! [ -a "$KERNEL_IMG" ]; then
        echo -e "\n> Build failed!"
#        tg_failed
        exit 1
    fi

    echo -e "\n> Build successful! generating flashable zip..."
	cd "$AK_DIR" || echo -e "\nAnykernel directory ($AK_DIR) does not exist" || exit 1
	git clean -fd
	mv "$KERNEL_IMG" "$AK_DIR"/zImage
	mv "$KERNEL_DTBO" "$AK_DIR"
	curl https://android.googlesource.com/platform/external/avb/+/refs/heads/master/avbtool.py?format=TEXT | base64 --decode > avbtool.py
	python3 avbtool.py add_hash_footer --image dtbo.img --partition_size=33554432 --partition_name dtbo
	ZIP_NAME=$KERNELNAME-$1-$(date +%Y-%m-%d_%H%M)
	zip -r9 "$ZIP_NAME".zip ./* -x .git README.md ./*placeholder avbtool.py

	# Sign zip if java is available
	if command -v java > /dev/null 2>&1; then
		curl -sLo zipsigner-4.0.jar https://github.com/baalajimaestro/AnyKernel3/raw/master/zipsigner-4.0.jar
		java -jar zipsigner-4.0.jar "$ZIP_NAME".zip "$ZIP_NAME"-signed.zip
		ZIP_NAME="$ZIP_NAME-signed.zip"
	fi

#	tg_pushzip "$ZIP_NAME" "Time taken: <code>$((DIFF / 60))m $((DIFF % 60))s</code>"
#	echo -e "\n> Sent zip through Telegram.\n> File: $ZIP_NAME"
}

# End function definitions

#COMMIT=$(git log --pretty=format:"%s" -1)
#COMMIT_SHA=$(git rev-parse --short HEAD)
#KERNEL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

#CAPTION=$(echo -e \
#"HEAD: <code>$COMMIT_SHA: </code><code>$COMMIT</code>
#Branch: <code>$KERNEL_BRANCH</code>")

#tg_sendinfo "-- Build Triggered --
#$CAPTION"

# Build device 1
build_setup
build_config $DEFCONFIG
build_kernel
build_end ${DEVICE}_reduced-dimens

# Use stock panel dimentions for miui vendor based roms
cd $KERNEL_DIR
git am patches/0001-Revert-ARM64-dts-sweet-Decrease-physical-panel-dimen.patch

# Build device 1 for MIUI
build_setup
build_config $DEFCONFIG
build_kernel
build_end ${DEVICE}_stock-dimens




    
    #rm -rf $out
   
	echo -e "";
	echo -e "";
	echo -e ${blu}"                 _    _  _  _     _ _   _ _    "${txtrst};
	echo -e ${blu}"    _ _ _ _     / \  |  _ \| | _ / _ \/ _ _|   "${txtrst};
	echo -e ${grn}"   |  _   _ \  / _ \ | |_) | |/ / | | \_ _ \   "${txtrst};
	echo -e ${ylw}"   | | | | | |/ _,_ \|  _ <|   <| |_| |_ _) |  "${txtrst};
	echo -e ${red}"   |_| |_| |_/_/   \_\_| \_\_|\_|\_ _/ \_ _/   "${txtrst};
	echo -e ${red}"     K E R N E L • G I N K G O • W I L L O W   "${txtrst};                                
	echo -e ${blu}"                                               "${txtrst};
	echo -e ${blu}"                                               "${txtrst};
	echo -e ${ppl}"            Xiaomi Redmi Note 8/8T             "${txtrst};
	echo -e ${ppl}"            by mARk-android@github             "${txtrst};
	echo -e ${blu}"                                               "${txtrst};
	echo -e ${blu}"   ******************************************* "${txtrst}; 
	echo -e "";
	echo -e "";
	echo -e "";
	echo -e "";   
