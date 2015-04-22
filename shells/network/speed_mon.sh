#!/bin/ksh
fecha=`date '+%F'`
hora=`date '+%T'`
output=$(time dd if=/dev/zero count=10 bs=1024k | ssh nombre-o-ip-servidor dd of=/dev/null 2>&1 > /dev/null | awk '$0' ORS='\n')
bytes=`echo -e "${output}" | grep copied | awk '{print $1}'`  ## obtener bytes
kilobytes=$(( $bytes / 1024 ))                                ## transformar a Kilobytes
segs=`echo -e "${output}" | grep copied | awk '{print $6}'`   ## obtener segs
speed=`echo "${kilobytes} / ${segs}" | bc`                    ## calculo kilobytes/segs
echo ${fecha} ${hora}";"${speed} >> output.log
