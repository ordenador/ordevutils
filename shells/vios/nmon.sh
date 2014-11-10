NMONFS=/home/nmon
#get the current time
eval $(date +"%H:%M" | awk -F: '{print "h="$1";m="$2}')
#sample interval in minutes
INTERVAL=1
#calculate number of samples until midnight
SAMPLES=$(( ((24-$h)*60-$m)/$INTERVAL ))
#run nmon data collection
/usr/bin/nmon -f -T -d -A -m ${NMONFS} -s $(( 60*$INTERVAL )) -c ${SAMPLES}
#compress files older than two days
/bin/find ${NMONFS} -name '*.nmon' -mtime +2 | xargs -n1 gzip $f
#remove files older than 1 year
/bin/find ${NMONFS} -name '*.nmon.gz' -mtime +365 | xargs -n10 rm
