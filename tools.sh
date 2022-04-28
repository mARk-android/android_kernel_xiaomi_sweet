#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# ----------------------------------------------------------------------
# tools.sh - Shell helper functions and tools
#
# usage: Run './build.sh' from top level of kernel tree.
#        helper import function automatically
#
# Copyright (C) 2022 Marcin Kubiak mARk <r3066.funtab@gmail.com>
# Licensed under the terms of the GNU GPL License
# ----------------------------------------------------------------------

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




config_var () {
echo build_vers >> build_vers
TAG=$(grep VERSION Makefile | head -n1 | awk '{print $3}').$(grep PATCHLEVEL Makefile | head -n1 | awk '{print $3}').$(grep SUBLEVEL Makefile | head -n1 | awk '{print $3}');
COMMIT=$(git rev-parse --verify --short=8 HEAD)
COUNTER=$(cat -n build_vers | tail -1 | awk '{print $1}')
CHECK_OK="\033[0;32m\xE2\x9C\x94\033[0m";
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
STRIP="aarch64-linux-gnu-strip"
TIME=$(date +%Y%m%d-%H%M)
A3=AnyKernel3
TMP=$(mktemp $A3/XXXXXXXXXXX.$$.tmp)
export KBUILD_BUILD_TIMESTAMP="$(date -R | awk '{print $3}') $(date -R | awk '{print $2}') $(date -R | awk '{print $4}') $(date -R | awk '{print $5}') #$COUNTER"
export PATH="$HOME/toolchain/$TC/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/toolchain/$TC/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$($HOME/toolchain/$TC/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export CC_STRING="$($KBUILD_COMPILER_STRING --version | head -n 1  | perl -pe 's/\((?:http|git).*?\)//gs')"
export out=out
}


# make function
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


make_kernel () {
# build kernel Image.gz dtbo.img
    make O=$out ARCH=arm64 $CONFIG > /dev/null
}


check_toolchain () {
    if [ ! -d $HOME/toolchain/$TC ]; then
    echo    "   Your toolchain is:" $(clang --version | head -n 1)
    read -p "   Press enter to setup config"
        config_have_toolchain
	check_toolchain_path
    fi;
}


config_have_toolchain () {
     if [ ! -d $HOME/toolchain/$TC ]; then
     echo  -e ${txtbld}${grn}"\\r   Toolchain:    "${txtrst}${red}$(clang --version | head -n 1)${txtrst};
     else
     echo  -e ${txtbld}${grn}"\\r   Toolchain:    "${txtrst}$(clang --version | head -n 1) ${CHECK_OK};
     fi;
}


check_anykernel () {
    if [ ! -d $A3 ]; then
	    git clone -q https://github.com/mark-android/$A3.git
    fi;
}


check_build () {
    b1="$out/arch/arm64/boot/Image.gz"
    b2="$out/arch/arm64/boot/dtbo.img"
    b3="$out/arch/arm64/boot/dts/qcom/$PLATFORM.dtb"
    cp -f $b1 $A3/zImage
    cp -f $b2 $A3
    cp -f $b3 $A3/dtb
    echo -e ${bldcya}"\n  ${CHECK_OK} Kernel compiled succesfully!\n    Zipping and packing modules...\n"${txtrst};
}


do_zip () {
    cd $A3
	if [ ! -d $KERNEL_DIR/$BLD_DIR ]; then
            mkdir $KERNEL_DIR/$BLD_DIR
	fi;
    zip -r9 "$KERNEL_DIR/$BLD_DIR/$ZIPNAME" *
    cd ..
   
    echo -e ${bldgrn}"\n  ${CHECK_OK} Zipping succesfully! \n"${txtrst};
    echo -e ${bldgrn}"\n  Build #$COUNTER completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo -e ${bldylw}"  Zip: $ZIPNAME" ${txtrst};
    echo -e "";
    echo -e "";
}


check_toolchain_path () {
echo -e "\n   mARkOS script was unable to find the toolchain or the environment is misconfigured!\n";
options=("  Clone toolchain" "  Enter path to toolchain dir" "  Test path" "  Continue build kernel" "  Open build.sh" "  Exit")
select opt in "${options[@]}"
do
    case $opt in
        "  Clone toolchain")
            	echo "
   Clone toolchain from git and put to $HOME/toolchain/
   Then set dir name to TOOLCHAINDIR= environments path
   that looks something like $HOME/toolchain/clang15
                     "
            ;;
        "  Enter path to toolchain dir")
                read -e -p "Enter the path to the tolchain: $HOME/toolchain/" -i "" PATHTC
                export PATH="$HOME/toolchain/$PATHTC/bin:$PATH"
		echo $PATH
            ;;
        "  Test path")
        	 echo  ${txtrst}
    		 echo  ${txtbld}${grn}"   Toolchain:    "${txtrst}$(clang --version | head -n 1)
   		 echo  ${txtbld}${grn}"   Linker:       "${txtrst}$(gcc --version | head -n 1)
   		 echo  ${txtbld}${grn}"                 "${txtrst}$(ld.lld --version | head -n 1)
   		 echo  ${txtbld}${grn}"                 "${txtrst}$(ld --version | head -n 1)
            ;;
        "  Continue build kernel")
           	 echo -e ${dim}"\n"
            	 break
            ;;
        "  Open build.sh")
           	 echo -e ${dim}"\n"
            	 nano build.sh
            ;;
        "  Exit")
           	 exit
            ;;            
        *) echo "  invalid option: $REPLY";;
    esac
done
}


mk_log (){
    if [ "$LOG" == "changelog" ]; then
     do_changelog
    elif [ "$LOG" == "gitlog" ]; then
     do_gitlog
    else
     check_log
    fi;
}


check_log () {
    if [ ! -f $A3/changelog ]; then
    echo -e " ${txtrst}${bldred} YOU HAVE MISCOFIGURED CHANGELOG OR GITLOG  ${txtrst}  ${dim}    \n\n "
    else
    rm "$TMP"
    echo -e ${dim}"\\r  ${CHECK_OK} Done!                  \n  "${txtrst}${dim};
    sleep 2
    fi;
}


do_changelog_header () {
# make header builtin log
    sed  -i '1i\=============================================='              $TMP
    sed  -i "1i\Date: $TIME                 #$COUNTER"                       $TMP
    sed  -i "1i\mARkOS android $ANDROID kernel-$TAG"                         $TMP
    sed  -i '1i\============================================='               $TMP
    sed -n -e '/^======/,/v4.14./p' $TMP | more | head -n -1 > $A3/changelog
}


do_changelog () {
# make simply gitlog in newest kernel brunch or tag
    echo -e "\n    Generate changelog!";
    echo -n ${blink}"    Please wait!"${txtrst};
    git log --pretty=format:"  %s" |  awk 'NR == 1, NR == 400 { print $0 }' | cut -c 1-54 > $TMP
    do_changelog_header
    check_log
}


do_gitlog () {
# make gitlog in newest kernel brunch or tag with hash 9b
    echo -e "\n    Generate gitlog with sha!";
    echo -n ${blink}"    Please wait!"${txtrst};
    git log --abbrev=9 --pretty=format:"%h  %s" |  awk 'NR == 1, NR == 400 { print $0 }' | cut -c 1-54 > $TMP
    do_changelog_header
    check_log
}


dp_header () {
# host info view in header
    clear
    echo -e ' \n ';
    echo -e ${red}"   ${HEADER}   "${txtrst};  
    echo -e ${bldcya}'  =================================================='${txtrst};
    echo  ${txtbld}${ylw}"   Target:       "${txtrst}boot.$KBUILD_BUILD_USER.$TAG.$ANDROID.$PRODUCT-$COMMIT;
    echo  ${txtbld}${ppl}"   Builds:       "${txtrst}#$COUNTER;
    echo -e ' ';
    echo     ${txtbld}${grn}"   Platform:     "${txtrst}$(lsb_release -d | cut -c 14-70 ) $(uname -srm);
    echo                    "                 "Memory free: $(free -m | awk 'NR==2 {print $2-$3}')MB
    config_have_toolchain
    echo     ${txtbld}${grn}"   Linker:       "${txtrst}$(gcc --version | head -n 1)
    echo     ${txtbld}${grn}"                 "${txtrst}$(ld.lld --version | head -n 1)
    echo     ${txtbld}${grn}"                 "${txtrst}$(ld --version | head -n 1)
    echo -e ${bldcya}'  =================================================='${txtrst};
    echo -e ${dim};
}


dp_footer () {
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
}


do_clean () {
	cd $A3;
	echo -e "\n    Clean up kernel builds dir"; sleep 1;
		for rem in zImage dtb* *tmp *log* ; do
	 		prt=$(find . -type f -name $rem -exec rm -f "{}" +);
			$prt;
			#echo  "   Remove file: $rem" //print every removed files in list
		done;
	rm -rf ../$out
	echo -e "  ${CHECK_OK} Done! \n"${txtrst}; 
}


sign_dtbo () { python3 avbtool.py add_hash_footer --image $A3/dtbo.img --partition_size=33554432 --partition_name dtbo; }
print_error () { echo -e ${bldred}"\nCompilation failed!\n"${txtrst}; }
