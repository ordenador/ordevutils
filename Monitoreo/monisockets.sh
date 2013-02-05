## Para AIX, probado en 5300-12-02-1036
## EXEC: monisocket.sh > /dev/null 2>&1 &
while true; do
        fecha=`date '+%F'`
        hora=`date '+%T'`
        netstat -Aan > netstatAan.txt
        LISTEN=`cat netstatAan.txt | grep LISTEN | wc -l | sed 's/^[ v]*//'`
        ESTABLISHED=`cat netstatAan.txt | grep ESTABLISHED | wc -l | sed 's/^[ v]*//'`
        SYN_SENT=`cat netstatAan.txt | grep SYN_SENT | wc -l | sed 's/^[ v]*//'`
        SYN_RECV=`cat netstatAan.txt | grep SYN_RECV | wc -l | sed 's/^[ v]*//'`
        LAST_ACK=`cat netstatAan.txt | grep LAST_ACK | wc -l | sed 's/^[ v]*//'`
        CLOSE_WAIT=`cat netstatAan.txt | grep CLOSE_WAIT | wc -l | sed 's/^[ v]*//'`
        TIME_WAIT=`cat netstatAan.txt | grep TIME_WAIT | wc -l | sed 's/^[ v]*//'`
        CLOSED=`cat netstatAan.txt | grep CLOSED | wc -l | sed 's/^[ v]*//'`
        CLOSING=`cat netstatAan.txt | grep CLOSING | wc -l | sed 's/^[ v]*//'`
        FIN_WAIT1=`cat netstatAan.txt | grep FIN_WAIT1 | wc -l | sed 's/^[ v]*//'`
        FIN_WAIT2=`cat netstatAan.txt | grep FIN_WAIT2 | wc -l | sed 's/^[ v]*//'`

        echo "${fecha} ${hora}; ${LISTEN}; ${ESTABLISHED}; ${SYN_SENT}; ${SYN_RECV}; ${LAST_ACK}; ${CLOSE_WAIT}; ${TIME_WAIT}; ${CLOSED}; ${CLOSING}; ${FIN_WAIT1}; ${FIN_WAIT2}" >> netstatAan_${fecha}.csv

    sleep 60
done