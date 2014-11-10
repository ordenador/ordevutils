#!/usr/bin/ksh
cd /home/padmin/advisor
nProcs=$( ps -fea | grep -w 'vios_advisor' | grep -v grep | wc -l )
if [ $nProcs -eq 0 ]; then
        HOSTNAME=`hostname`
        timestamp=`date +%Y%m%d-%H%M`
        ./vios_advisor -o '${HOSTNAME}_${timestamp}.xml' 60
fi
## delete old xml
/bin/find /home/padmin/advisor -name '*.xml' -mtime +180 | xargs -n10 rm
