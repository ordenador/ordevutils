#!/bin/ksh
#
# Para Linux
# 
# EXEC: nohup /bin/ksh /ruta/monisocket.sh &
#
# Autor: Mario Faúndez (Ordenador, mariofaundez@hotmail.com)
#
##########################################################
while true; do
        fecha=`date '+%F'`
        hora=`date '+%T'`
        netstat -an > netstatan.txt
        LISTEN=`cat netstatan.txt | grep LISTEN | wc -l | sed 's/^[ v]*//'`
        ESTABLISHED=`cat netstatan.txt | grep ESTABLISHED | wc -l | sed 's/^[ v]*//'`
        SYN_SENT=`cat netstatan.txt | grep SYN_SENT | wc -l | sed 's/^[ v]*//'`
        SYN_RECV=`cat netstatan.txt | grep SYN_RECV | wc -l | sed 's/^[ v]*//'`
        LAST_ACK=`cat netstatan.txt | grep LAST_ACK | wc -l | sed 's/^[ v]*//'`
        CLOSE_WAIT=`cat netstatan.txt | grep CLOSE_WAIT | wc -l | sed 's/^[ v]*//'`
        TIME_WAIT=`cat netstatan.txt | grep TIME_WAIT | wc -l | sed 's/^[ v]*//'`
        CLOSED=`cat netstatan.txt | grep CLOSED | wc -l | sed 's/^[ v]*//'`
        CLOSING=`cat netstatan.txt | grep CLOSING | wc -l | sed 's/^[ v]*//'`
        FIN_WAIT1=`cat netstatan.txt | grep FIN_WAIT1 | wc -l | sed 's/^[ v]*//'`
        FIN_WAIT2=`cat netstatan.txt | grep FIN_WAIT2 | wc -l | sed 's/^[ v]*//'`
        UNKNOWN=`cat netstatan.txt | grep UNKNOWN | wc -l | sed 's/^[ v]*//'`

        echo "${fecha} ${hora}; ${LISTEN}; ${ESTABLISHED}; ${SYN_SENT}; ${SYN_RECV}; ${LAST_ACK}; ${CLOSE_WAIT}; ${TIME_WAIT}; ${CLOSED}; ${CLOSING}; ${FIN_WAIT1}; ${FIN_WAIT2}; ${UNKNOWN}" >> netstatan_${fecha}.csv

    sleep 60
done
