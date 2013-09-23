#!/bin/bash
#
# Muestra cuantos conectados por socket tipo LISTEN
# Tambien, cuales son las IP conectados al socket tipo LISTEN
#
# Para Linux, probado en Red Hat Enterprise Linux AS release 4 (Nahant Update 7)
#
# EXEC: nohup /root/port_monit.sh 2>&1 &
#
##########################################################
cd /root
while true; do
        fecha=`date '+%F'`
        hora=`date '+%T'`
        netstat -na | grep tcp | grep LISTEN | awk '{print $4}' | awk -F: '{print $NF}' | while read line
        do aux=`lsof -nlP | grep -E "TCP|UDP"  | grep ":${line}->" | grep ESTABLISHED | wc -l`
        lsof -nlP | grep -E "TCP|UDP"  | grep ":${line}->" | grep ESTABLISHED| awk '{print $8}' | awk -F'->' '{print $NF}' | awk -F: '{print $1}' >> "port_${line}.log"
        mv -f "port_${line}.log" "port_${line}.log_aux"
        cat "port_${line}.log_aux" | sort | uniq > "port_${line}.log"
        rm -f "port_${line}.log_aux"
        echo $fecha" "$hora";"$line";"$aux >> port_monit_${fecha}.csv
        done
        sleep 10
done
