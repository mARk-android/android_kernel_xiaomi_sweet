#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# ----------------------------------------------------------------------
# tools.sh - Shell helper functions and tools to build kernel
#            with clang or gcc for Miui or AOSP Roms
#            everything must be configured in ./build.sh
#
# usage: Run './build.sh' from top level of kernel tree.
#        helper import function automatically
#
# Copyright (C) 2022 Marcin Kubiak mARk <r3066.funtab@gmail.com>
# Licensed under the terms of the GNU GPL License
# ----------------------------------------------------------------------

# specify colors utilized in the terminal
	red=$(tput setaf 1)         #  red
	grn=$(tput setaf 2)         #  green
	ylw=$(tput setaf 3)         #  yellow
	blu=$(tput setaf 4)         #  blue
	ppl=$(tput setaf 5)         #  purple
	cya=$(tput setaf 6)         #  cyan
	txtb=$(tput bold)           #  Bold
	bred=${txtb}$(tput setaf 1) #  red
	bgrn=${txtb}$(tput setaf 2) #  green
	bylw=${txtb}$(tput setaf 3) #  yellow
	bblu=${txtb}$(tput setaf 4) #  blue
	bppl=${txtb}$(tput setaf 5) #  purple
	bcya=${txtb}$(tput setaf 6) #  cyan
	trst=$(tput sgr0)         #  Reset
	rev=$(tput rev)             #  Reverse color
	pplrev=${rev}$(tput setaf 5)
	cyarev=${rev}$(tput setaf 6)
	ylwrev=${rev}$(tput setaf 3)
	blurev=${rev}$(tput setaf 4)
	blink=$(tput blink)
	dim=$(tput dim)
	clear=$(tput clear)



config_var () {
echo build_vers >> build_vers
TAG=$(grep VERSION Makefile | head -n1 | awk '{print $3}').$(grep PATCHLEVEL Makefile | head -n1 | awk '{print $3}').$(grep SUBLEVEL Makefile | head -n1 | awk '{print $3}');
COMMIT=$(git rev-parse --verify --short=8 HEAD)
COUNTER=$(cat -n build_vers | tail -1 | awk '{print $1}')
OKEY="\033[0;32m\xE2\x9C\x94\033[0m";
ERR="\033[0;31m\xE2\x9C\x95\033[0m";
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
STRIP="aarch64-linux-gnu-strip"
TIME=$(date +%Y%m%d-%H%M)
A3=AnyKernel3
TMP=$(mktemp $A3/XXXXXXXXXXX.$$.tmp)
export KBUILD_BUILD_TIMESTAMP="$(date -R | awk '{print $3}') $(date -R | awk '{print $2}') $(date -R | awk '{print $4}') $(date -R | awk '{print $5}') #$COUNTER"
export PATH="$TCDIR/bin:$PATH"
export LD_LIBRARY_PATH="$TCDIR/lib:$LD_LIBRARY_PATH"

	if [[ "${PATH,,}" == *"clang"* ]] && [ -e $TCDIR/bin/clang ]; then tc=1;
	export KBUILD_COMPILER_STRING="$($TCDIR/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
	export CC_STRING="$($KBUILD_COMPILER_STRING --version | head -n 1  | perl -pe 's/\((?:http|git).*?\)//gs')"
	elif [[ "${PATH,,}" == *"gcc"* ]]  && [ -e $TCDIR/bin/aarch64-elf-gcc ]; then tc=2
	export KBUILD_COMPILER_STRING="$($TCDIR/bin/aarch64-elf-gcc --version | head -n 1 | cut -d ')' -f 2 | awk '{print $1}')"
	export CROSS_COMPILE_ARM32=$TCDIRARM32/bin/arm-eabi-
	fi
	
export out=out
}


make_kernel () {
	make O=$out ARCH=arm64 $CONFIG > /dev/null
}


start_build () {
	if [ $tc == 1 ]; then
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

	elif [ $tc == 2 ]; then
		make -j$(nproc --all) O=$out \
			ARCH=arm64 \
			CC="aarch64-elf-gcc" \
			AR="aarch64-elf-ar" \
			NM="aarch64-elf-nm" \
			LD="aarch64-elf-ld.bfd" \
			AS="aarch64-elf-as" \
			OBJCOPY="aarch64-elf-objcopy" \
			OBJDUMP="aarch64-elf-objdump" \
			CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32

	else
	check_toolchain
	fi
}


check_toolchain () {
	if [ ! -d $TCDIR ]; then
	echo -e "   Your toolchain is:" $(clang --version | head -n 1) "\n                      $(gcc --version | head -n 1)\n\n"
	read -p "   Press enter to setup config"
	config_have_toolchain
	check_toolchain_path
	fi
}


config_have_toolchain () {
	if [ ! -d $TCDIR ]; then
	echo  -e ${bgrn}"\\r   Toolchain:    "${trst}${red}$(clang --version | head -n 1)${trst};
	else
	echo  -e ${bgrn}"\\r   Toolchain:    "${trst}$(clang --version | head -n 1) ${OKEY};
	fi
}


check_anykernel () {
	if [ ! -d $A3 ]; then
	git clone -q https://github.com/mark-android/$A3.git
	fi
}


check_build () {
	if [ $ANDROID=*miui* ]; then
	IMG=Image.gz
	else
	IMG=Image.gz-dtb
	fi
	d1=arch/arm64/boot
	b1="$out/$d1/$IMG"
	b2="$out/$d1/dtbo.img"
	b3="$out/$d1/dts/qcom/$PLATFORM.dtb"
	cp -f $b1 $A3/zImage
	cp -f $b2 $A3
	cp -f $b3 $A3/dtb
	if [ -f $b1 ] && [ -f $A3/zImage ]; then
	echo -e ${bcya}"\n  ${OKEY} Kernel compiled succesfully!\n"${trst};
	fi
}


do_zip () {
		if [ ! -d $KERNEL_DIR/$BLD_DIR ]; then
		mkdir $KERNEL_DIR/$BLD_DIR
		fi
	cd $A3
	zip -r9 "$KERNEL_DIR/$BLD_DIR/$ZIPNAME" *
	cd ..

	echo -e ${bgrn}"\n  ${OKEY} Zipping succesfully! \n"${trst};
	echo -e ${bylw}"\n  Zip: $ZIPNAME" ${trst};
	echo -e ${bgrn}"  #$COUNTER: build time is: $((SECONDS / 60))m:$((SECONDS % 60))s \n${trst}"
}


check_toolchain_path () {

v1="  Clone toolchain"
v2="  Enter path to toolchain dir"
v3="  Test path"
v4="  Continue build kernel"
v5="  Open build.sh"
v6="  Exit"

echo -e "\n   mARkOS script was unable to find the toolchain or the environment is misconfigured!\n";

options=("$v1" "$v2" "$v3" "$v4" "$v5" "$v6")
select opt in "${options[@]}"
do
    case $opt in
	"$v1")
		echo ${dim}"
   Clone toolchain from git and put to $HOME/toolchain/
   Then set dir name to TOOLCHAINDIR= environments path
   that looks something like $HOME/toolchain/clang15
		"
	;;
	$v2)
                read -e -p "Enter full path to the tolchain: $HOME/_toolchain_dir_/" -i "" TCDr
                export PATH="$TCDr/bin:$PATH"
		echo $PATH
	;;
	$v3)
		echo  ${trst}
		echo  ${bgrn}"   Toolchain:    "${trst}$(clang --version | head -n 1)
		echo  ${bgrn}"   Linker:       "${trst}$(gcc --version | head -n 1)
		echo  ${bgrn}"                 "${trst}$(ld.lld --version | head -n 1)
		echo  ${bgrn}"                 "${trst}$(ld --version | head -n 1)
	;;
	$v4)
		echo -e ${dim}"\n"
		break
	;;
	$v5)
		echo -e ${dim}"\n"
		nano build.sh
	;;
	$v6)
		exit
	;;            
	*) echo "  Invalid option: $REPLY";;
    esac
done
}


mk_log () {
	if [ "$LOG" == "changelog" ]; then
	do_changelog
	elif [ "$LOG" == "gitlog" ]; then
	do_gitlog
	else
	check_log
	fi
}


check_log () {
	if [ ! -f $A3/changelog ]; then
	echo -e " ${trst}${bred} YOU HAVE MISCOFIGURED CHANGELOG OR GITLOG   \n\n"${trst}${dim};
	else
	rm "$TMP"
	echo -e "\\r  ${OKEY} Done!                         \n  "${trst}${dim}; sleep 2;
	fi
}


do_changelog_header () {
# make header builtin log and cut to previos kernel merge
	T=$(grep SUBLEVEL Makefile | head -n1 | awk '{print $3}');
	S=$(($T-1));
	sed  -i '1i\=============================================='   $TMP
	sed  -i "1i\Date: $TIME                 #$COUNTER"            $TMP
	sed  -i "1i\mARkOS android $ANDROID kernel-$TAG"              $TMP
	sed  -i '1i\=============================================='   $TMP
	sed -n -e "/^======/,/4.14.${S}/p" $TMP | more | head -n -1 > $A3/changelog
}


do_changelog () {
# make simply gitlog in newest kernel brunch or tag
	echo -e "\n    Generate changelog!";
	echo -n ${blink}"    Please wait!"${trst};
	git log --pretty=format:"  %s" |  awk 'NR == 1, NR == 400 { print $0 }' | cut -c 1-54 > $TMP
	do_changelog_header
	check_log
}


do_gitlog () {
# make gitlog in newest kernel brunch or tag with hash 9b
	echo -e "\n    Generate gitlog with sha!";
	echo -n ${blink}"    Please wait!"${trst};
	git log --abbrev=9 --pretty=format:"%h  %s" |  awk 'NR == 1, NR == 400 { print $0 }' | cut -c 1-54 > $TMP
	do_changelog_header
	check_log
}


dp_header () {
	clear
	echo -e ' \n ';
	echo -e ${red}"   ${HEADER}   "${trst};
	echo -e ${bcya}'  ======================================================'${trst};
	echo    ${bylw}"   Target:       "${trst}boot.$KBUILD_BUILD_USER.$TAG.$ANDROID.$PRODUCT-$COMMIT;
	echo    ${bppl}"   Builds:       "${trst}#$COUNTER;
	echo -e '';
	echo    ${bgrn}"   Platform:     "${trst}$(lsb_release -d | cut -c 14-70 ) $(uname -srm);
	echo	       "                 "Memory free: $(free -m | awk 'NR==2 {print $2-$3}')MB
	config_have_toolchain
	echo    ${bgrn}"   Linker:       "${trst}$(gcc --version | head -n 1)
	echo    ${bgrn}"                 "${trst}$(ld.lld --version | head -n 1)
	echo    ${bgrn}"                 "${trst}$(ld --version | head -n 1)
	echo -e ${bcya}'  ======================================================'${trst};
	echo -e ${dim};
}


dp_footer () {
	echo -e "\n\n\n";
	echo -e ${blu}"                 _    _  _  _     _ _   _ _    "${trst};
	echo -e ${blu}"    _ _ _ _     / \  |  _ \| | _ / _ \/ _ _|   "${trst};
	echo -e ${grn}"   |  _   _ \  / _ \ | |_) | |/ / | | \_ _ \   "${trst};
	echo -e ${ylw}"   | | | | | |/ _,_ \|  _ <|   <| |_| |_ _) |  "${trst};
	echo -e ${red}"   |_| |_| |_/_/   \_\_| \_\_|\_|\_ _/ \_ _/   "${trst};
	echo -e ${red}"         • K E R N E L • S W E E T •           "${trst};
	echo -e ${blu}"                                               "${trst};
	echo -e ${blu}"                                               "${trst};
	echo -e ${ppl}"            Xiaomi Redmi Note 10 Pro           "${trst};
	echo -e ${ppl}"            by mARk-android@github             "${trst};
	echo -e ${blu}"                                               "${trst};
	echo -e ${blu}"   ******************************************* "${trst};
	echo -e "\n\n\n";
}


do_clean_for () {
	cd $A3;	for rem in *Image* dtb* *tmp *log* *.ko; do
	prt=$(find . -type f -name $rem -exec rm -f "{}" +);
	$prt; done; cd .. ;
	rm -rf $out
}


do_clean () {
	echo -e "\n    Clean up kernel builds dir"; sleep 1;
	do_clean_for
	echo -e "  ${OKEY} Done! \n"${trst};
}


check_prev_build () {
	if [ -d $out ]; then
	echo -e  "\n   CLEAN UP YOUR OUT DIR FROM PREVIOUS BILDS\n"
	while true; do
		read -p "   Do you want to clean up? y/n " yn
		case $yn in
	[yY] )
		echo -n ${blink}"    Removing temporary files!"${trst}; sleep 1;
		do_clean_for
		echo -e "\\r  ${OKEY} Done!                         \n  "${trst}${dim};
		break
	;;
	[nN] )
		break
	;;
	* ) 
		echo -e  "\n   Invalid response"; 
	;;
	esac
	done
	fi
}


zip_signer () {
	if command -v java > /dev/null 2>&1; then
		java -jar zipsigner-4.0.jar "$KERNEL_DIR/$BLD_DIR/$ZIPNAME" "$KERNEL_DIR/$BLD_DIR/sign-$ZIPNAME"
	        echo -e ${bldgrn}"\n  ${OKEY} Signing zip succesfully! \n"${trst};
	fi
}


sign_dtbo () { python3 avbtool.py add_hash_footer --image $A3/dtbo.img --partition_size=33554432 --partition_name dtbo; }
print_error () { echo -e ${bred}"\n ${ERR} Compilation failed!\n"${trst}; }
