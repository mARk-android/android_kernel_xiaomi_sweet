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

# import helper function
. ./tools.sh
    
# extra var
HEADER="K E R N E L • S W E E T • S W E E T I N"

export KBUILD_BUILD_USER="mARk"
export KBUILD_BUILD_HOST="linux"

TC=clang15_20220402f
PRODUCT=sweet
ANDROID=MiuiR
PLATFORM=sdmmagpie
CONFIG=sweet_user_defconfig
BLD_DIR=_BUILD_KERNEL

# select changelog or gitlog
LOG=changelog

# import variables
    config_var

# main script
    dp_header
    check_anykernel
    check_toolchain
    make_kernel
    start_build
    check_build
    
ZIPNAME="boot.mARkOS.$TAG.$ANDROID.$PRODUCT-$TIME.zip"

# packing and checking kernel image
if [ -f $b1 ] && [ -f $b2 ] && [ -f $b3 ]; then
    sign_dtbo
    mk_log
    do_zip
else
    print_error
fi;

    do_clean
    dp_footer
