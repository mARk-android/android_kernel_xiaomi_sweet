#!/bin/bash
#
# Copyright (c) 2021 CloudedQuartz
#

# Script to set up environment to build an android kernel
# Assumes required packages are already installed

# Config
CURRENT_DIR="$(pwd)"
KERNELNAME="mARkOS"
KERNEL_DIR="$CURRENT_DIR"
#AK_REPO="https://github.com/TheStaticDesign/AnyKernel3"
AK_BRANCH="sweet"
AK_DIR="$HOME/AnyKernel3"
TC_DIR="$HOME/toolchain/clang14_20210905/"
# End Config



#export KBUILD_BUILD_USER="mARk"
#export KBUILD_BUILD_HOST="linux"
#export PATH="$HOME/proton-clang/bin:$PATH"
#export LD_LIBRARY_PATH="$HOME/proton-clang/lib:$LD_LIBRARY_PATH"
#export KBUILD_COMPILER_STRING="$($HOME/proton-clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"







# clone_tc - clones proton clang to TC_DIR
#clone_tc() {
#	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git $TC_DIR
#}

# Clones anykernel
#clone_ak() {
#	git clone $AK_REPO $AK_DIR -b $AK_BRANCH
#}
# Actually do stuff
#clone_tc
#clone_ak

# Run build script
. ${CURRENT_DIR}/kernel_build.sh
