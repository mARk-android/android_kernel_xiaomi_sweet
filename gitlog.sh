#!/bin/bash
#

echo -e "\nGenerate a changelog entry!\n";
now=$(date +%Y%m%d-%H%M)
export COUNTER=$( cat -n build_vers | tail -1 | awk '{print $1}')
export VERSION=4.14.275

# HEADER - make gillog all changes of branch tag with hash commit    
    git log --pretty=format:"%h  %s" |  awk 'NR == 1, NR == 400 { print $0 }' | cut -c 1-64 > AnyKernel3/gitlog.tmp
    sed  -i '1i\========================================='                    AnyKernel3/gitlog.tmp
    sed  -i "1i\Date: ${now}                #${COUNTER}"                      AnyKernel3/gitlog.tmp
    sed  -i "1i\mARkOS android R kernel-${VERSION} "                          AnyKernel3/gitlog.tmp
    sed  -i '1i\========================================='                    AnyKernel3/gitlog.tmp
    sed -n -e '/^======/,/Linux 4.14./p' AnyKernel3/gitlog.tmp | more | head -n -1  > AnyKernel3/gitlog
    rm AnyKernel3/gitlog.tmp
    
echo -e "\nDone!\n";
